package org.castlekong.backend.service

import org.castlekong.backend.dto.*
import org.castlekong.backend.entity.*
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.*
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Service
@Transactional(readOnly = true)
class ContentService(
    private val groupRepository: GroupRepository,
    private val userRepository: UserRepository,
    private val workspaceRepository: WorkspaceRepository,
    private val channelRepository: ChannelRepository,
    private val postRepository: PostRepository,
    private val commentRepository: CommentRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val channelRoleBindingRepository: ChannelRoleBindingRepository,
    private val groupRoleRepository: GroupRoleRepository,
    private val permissionService: org.castlekong.backend.security.PermissionService,
) {
    private val logger = LoggerFactory.getLogger(javaClass)
    private fun systemRolePermissions(roleName: String): Set<GroupPermission> =
        when (roleName.uppercase()) {
            "OWNER" -> GroupPermission.entries.toSet()
            "ADVISOR" -> GroupPermission.entries.toSet() // MVP에서는 OWNER와 동일
            "MEMBER" -> setOf(GroupPermission.WORKSPACE_ACCESS)
            else -> emptySet()
        }

    private fun getEffectivePermissions(
        groupId: Long,
        userId: Long,
    ): Set<GroupPermission> = permissionService.getEffective(groupId, userId, ::systemRolePermissions)

    private fun ensurePermission(
        groupId: Long,
        userId: Long,
        required: GroupPermission,
    ) {
        val effective = getEffectivePermissions(groupId, userId)
        if (!effective.contains(required)) throw BusinessException(ErrorCode.FORBIDDEN)
    }

    private fun hasChannelPermission(
        channelId: Long,
        userId: Long,
        required: ChannelPermission,
    ): Boolean {
        val channel = channelRepository.findById(channelId)
            .orElseThrow { BusinessException(ErrorCode.CHANNEL_NOT_FOUND) }

        val member = groupMemberRepository.findByGroupIdAndUserId(channel.group.id, userId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND) }

        // 사용자의 역할에 대한 채널 권한 바인딩 조회
        val bindings = channelRoleBindingRepository.findByChannelIdAndGroupRoleId(channelId, member.role.id)

        return bindings?.hasPermission(required) ?: false
    }

    private fun ensureChannelPermission(
        channelId: Long,
        userId: Long,
        required: ChannelPermission,
    ) {
        if (!hasChannelPermission(channelId, userId, required)) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
    }

    // Workspaces
    fun getWorkspacesByGroup(groupId: Long): List<WorkspaceResponse> {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        if (group.deletedAt != null) throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        val existing = workspaceRepository.findByGroup_Id(groupId)
        if (existing.isNotEmpty()) return existing.map { toWorkspaceResponse(it) }
        // ensure single default workspace
        val ws = Workspace(group = group, name = "기본 워크스페이스", description = null)
        return listOf(toWorkspaceResponse(workspaceRepository.save(ws)))
    }

    @Transactional
    fun createWorkspace(
        groupId: Long,
        request: CreateWorkspaceRequest,
    ): WorkspaceResponse {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        if (group.deletedAt != null) throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        val ws =
            Workspace(
                group = group,
                name = request.name,
                description = request.description,
            )
        return toWorkspaceResponse(workspaceRepository.save(ws))
    }

    @Transactional
    fun updateWorkspace(
        workspaceId: Long,
        request: UpdateWorkspaceRequest,
        requesterId: Long,
    ): WorkspaceResponse {
        val ws =
            workspaceRepository.findById(workspaceId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        ensurePermission(ws.group.id, requesterId, GroupPermission.GROUP_MANAGE)
        val updated =
            ws.copy(
                name = request.name ?: ws.name,
                description = request.description ?: ws.description,
                updatedAt = LocalDateTime.now(),
            )
        return toWorkspaceResponse(workspaceRepository.save(updated))
    }

    @Transactional
    fun deleteWorkspace(
        workspaceId: Long,
        requesterId: Long,
    ) {
        val ws =
            workspaceRepository.findById(workspaceId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        ensurePermission(ws.group.id, requesterId, GroupPermission.GROUP_MANAGE)

        // 배치로 워크스페이스 하위 컨텐츠 삭제
        deleteWorkspaceContentsBatch(workspaceId)
        workspaceRepository.delete(ws)
    }

    @Transactional
    fun deleteWorkspaceContentsBatch(workspaceId: Long) {
        val channels = channelRepository.findByWorkspace_Id(workspaceId)
        val channelIds = channels.map { it.id }

        if (channelIds.isNotEmpty()) {
            // 배치 크기로 청크 단위 처리
            val batchSize = 50
            channelIds.chunked(batchSize).forEach { chunk ->
                // 게시물 ID들을 한 번에 조회
                val postIds = postRepository.findPostIdsByChannelIds(chunk)

                if (postIds.isNotEmpty()) {
                    // 댓글들을 배치로 삭제
                    postIds.chunked(batchSize).forEach { postChunk ->
                        commentRepository.deleteByPostIds(postChunk)
                    }
                    // 게시물들을 배치로 삭제
                    postRepository.deleteByChannelIds(chunk)
                }
            }
            // 채널들을 배치로 삭제
            channelRepository.deleteAll(channels)
        }
    }

    // Channels
    fun getChannelsByWorkspace(
        workspaceId: Long,
        requesterId: Long,
    ): List<ChannelResponse> {
        val workspace =
            workspaceRepository.findById(workspaceId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        ensurePermission(workspace.group.id, requesterId, GroupPermission.WORKSPACE_ACCESS)
        return channelRepository.findByWorkspace_Id(workspaceId).map { toChannelResponse(it) }
    }

    @Transactional
    fun createChannel(
        workspaceId: Long,
        request: CreateChannelRequest,
        creatorId: Long,
    ): ChannelResponse {
        val workspace =
            workspaceRepository.findById(workspaceId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        val group = workspace.group
        val creator =
            userRepository.findById(creatorId)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
        // permission: group owner or role has CHANNEL_WRITE
        validateChannelManagePermission(group.id, creator.id)
        val type = request.type?.let { runCatching { ChannelType.valueOf(it) }.getOrDefault(ChannelType.TEXT) } ?: ChannelType.TEXT
        val channel =
            Channel(
                group = group,
                workspace = workspace,
                name = request.name,
                description = request.description,
                type = type,
                displayOrder = 0,
                createdBy = creator,
            )
        val savedChannel = channelRepository.save(channel)

        // 새 채널에 기본 권한 바인딩 설정
        setupDefaultChannelPermissions(savedChannel)

        return toChannelResponse(savedChannel)
    }

    @Transactional
    fun updateChannel(
        channelId: Long,
        request: UpdateChannelRequest,
        userId: Long,
    ): ChannelResponse {
        val channel =
            channelRepository.findById(channelId)
                .orElseThrow { BusinessException(ErrorCode.CHANNEL_NOT_FOUND) }
        validateChannelManagePermission(channel.group.id, userId)
        val type = request.type?.let { runCatching { ChannelType.valueOf(it) }.getOrNull() } ?: channel.type
        val updated =
            channel.copy(
                name = request.name ?: channel.name,
                description = request.description ?: channel.description,
                type = type,
                updatedAt = LocalDateTime.now(),
            )
        return toChannelResponse(channelRepository.save(updated))
    }

    @Transactional
    fun deleteChannel(
        channelId: Long,
        userId: Long,
    ) {
        val channel =
            channelRepository.findById(channelId)
                .orElseThrow { BusinessException(ErrorCode.CHANNEL_NOT_FOUND) }
        validateChannelManagePermission(channel.group.id, userId)

        // 배치로 채널 컨텐츠 삭제
        deleteChannelContentsBatch(channelId)
        channelRepository.delete(channel)
    }

    @Transactional
    fun deleteChannelContentsBatch(channelId: Long) {
        val postIds = postRepository.findPostIdsByChannelIds(listOf(channelId))

        if (postIds.isNotEmpty()) {
            // 배치 크기로 청크 단위 처리
            val batchSize = 50
            postIds.chunked(batchSize).forEach { chunk ->
                // 댓글들을 배치로 삭제
                commentRepository.deleteByPostIds(chunk)
            }
            // 게시물들을 배치로 삭제
            postRepository.deleteByChannelIds(listOf(channelId))
        }
    }

    // Posts
    fun getPosts(
        channelId: Long,
        requesterId: Long,
    ): List<PostResponse> {
        val channel =
            channelRepository.findById(channelId)
                .orElseThrow { BusinessException(ErrorCode.CHANNEL_NOT_FOUND) }
        ensurePermission(channel.group.id, requesterId, GroupPermission.WORKSPACE_ACCESS)
        return postRepository.findByChannel_Id(channelId).map { toPostResponse(it) }
    }

    fun getPost(
        postId: Long,
        requesterId: Long,
    ): PostResponse {
        val post =
            postRepository.findById(postId)
                .orElseThrow { BusinessException(ErrorCode.POST_NOT_FOUND) }
        ensurePermission(post.channel.group.id, requesterId, GroupPermission.WORKSPACE_ACCESS)
        return toPostResponse(post)
    }

    @Transactional
    fun createPost(
        channelId: Long,
        request: CreatePostRequest,
        authorId: Long,
    ): PostResponse {
        val channel =
            channelRepository.findById(channelId)
                .orElseThrow { BusinessException(ErrorCode.CHANNEL_NOT_FOUND) }
        val author =
            userRepository.findById(authorId)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
        ensurePermission(channel.group.id, author.id, GroupPermission.WORKSPACE_ACCESS)
        ensureChannelPermission(channelId, author.id, ChannelPermission.POST_WRITE)
        val type = request.type?.let { runCatching { PostType.valueOf(it) }.getOrDefault(PostType.GENERAL) } ?: PostType.GENERAL
        val post =
            Post(
                channel = channel,
                author = author,
                content = request.content,
                type = type,
            )
        return toPostResponse(postRepository.save(post))
    }

    @Transactional
    fun updatePost(
        postId: Long,
        request: UpdatePostRequest,
        requesterId: Long,
    ): PostResponse {
        val post =
            postRepository.findById(postId)
                .orElseThrow { BusinessException(ErrorCode.POST_NOT_FOUND) }
        if (post.author.id != requesterId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
        val type = request.type?.let { runCatching { PostType.valueOf(it) }.getOrNull() } ?: post.type
        val updated =
            post.copy(
                content = request.content ?: post.content,
                type = type,
                updatedAt = LocalDateTime.now(),
            )
        return toPostResponse(postRepository.save(updated))
    }

    @Transactional
    fun deletePost(
        postId: Long,
        requesterId: Long,
    ) {
        val post =
            postRepository.findById(postId)
                .orElseThrow { BusinessException(ErrorCode.POST_NOT_FOUND) }
        if (post.author.id != requesterId) {
            // allow moderators with POST_DELETE_ANY
            val groupId = post.channel.group.id
            val perms = getEffectivePermissions(groupId, requesterId)
            if (!perms.contains(GroupPermission.ADMIN_MANAGE)) {
                throw BusinessException(ErrorCode.FORBIDDEN)
            }
        }

        // 배치로 댓글 삭제
        deletePostCommentsBatch(postId)
        postRepository.delete(post)
    }

    @Transactional
    fun deletePostCommentsBatch(postId: Long) {
        // 댓글들을 배치로 삭제
        commentRepository.deleteByPostIds(listOf(postId))
    }

    // Comments
    fun getComments(
        postId: Long,
        requesterId: Long,
    ): List<CommentResponse> {
        val post =
            postRepository.findById(postId)
                .orElseThrow { BusinessException(ErrorCode.POST_NOT_FOUND) }
        ensurePermission(post.channel.group.id, requesterId, GroupPermission.WORKSPACE_ACCESS)
        return commentRepository.findByPost_Id(postId).map { toCommentResponse(it) }
    }

    @Transactional
    fun createComment(
        postId: Long,
        request: CreateCommentRequest,
        authorId: Long,
    ): CommentResponse {
        val post =
            postRepository.findById(postId)
                .orElseThrow { BusinessException(ErrorCode.POST_NOT_FOUND) }
        val author =
            userRepository.findById(authorId)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
        ensurePermission(post.channel.group.id, author.id, GroupPermission.WORKSPACE_ACCESS)
        val parent =
            request.parentCommentId?.let {
                commentRepository.findById(it).orElseThrow { BusinessException(ErrorCode.COMMENT_NOT_FOUND) }
            }
        val comment =
            Comment(
                post = post,
                author = author,
                content = request.content,
                parentComment = parent,
            )
        val savedComment = commentRepository.save(comment)
        postRepository.updateCommentStats(post.id, 1, savedComment.createdAt)
        return toCommentResponse(savedComment)
    }

    @Transactional
    fun updateComment(
        commentId: Long,
        request: UpdateCommentRequest,
        requesterId: Long,
    ): CommentResponse {
        val comment =
            commentRepository.findById(commentId)
                .orElseThrow { BusinessException(ErrorCode.COMMENT_NOT_FOUND) }
        if (comment.author.id != requesterId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
        val updated =
            comment.copy(
                content = request.content ?: comment.content,
                updatedAt = LocalDateTime.now(),
            )
        return toCommentResponse(commentRepository.save(updated))
    }

    @Transactional
    fun deleteComment(
        commentId: Long,
        requesterId: Long,
    ) {
        val comment =
            commentRepository.findById(commentId)
                .orElseThrow { BusinessException(ErrorCode.COMMENT_NOT_FOUND) }
        if (comment.author.id != requesterId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
        val postId = comment.post.id
        commentRepository.delete(comment)
        val latestComment = commentRepository.findTop1ByPost_IdOrderByCreatedAtDesc(postId)
        postRepository.updateCommentStats(postId, -1, latestComment?.createdAt)
    }

    // DTOs
    private fun toChannelResponse(channel: Channel) =
        ChannelResponse(
            id = channel.id,
            groupId = channel.group.id,
            name = channel.name,
            description = channel.description,
            type = channel.type.name,
            isPrivate = false, // 권한은 ChannelRoleBinding으로 관리
            displayOrder = channel.displayOrder,
            createdAt = channel.createdAt,
            updatedAt = channel.updatedAt,
        )

    private fun toWorkspaceResponse(workspace: Workspace) =
        WorkspaceResponse(
            id = workspace.id,
            groupId = workspace.group.id,
            name = workspace.name,
            description = workspace.description,
            createdAt = workspace.createdAt,
            updatedAt = workspace.updatedAt,
        )

    private fun toPostResponse(post: Post) =
        PostResponse(
            id = post.id,
            channelId = post.channel.id,
            author = toUserSummaryResponse(post.author),
            content = post.content,
            type = post.type.name,
            isPinned = post.isPinned,
            viewCount = post.viewCount,
            likeCount = post.likeCount,
            commentCount = post.commentCount,
            lastCommentedAt = post.lastCommentedAt,
            attachments = post.attachments,
            createdAt = post.createdAt,
            updatedAt = post.updatedAt,
        )

    private fun toCommentResponse(comment: Comment) =
        CommentResponse(
            id = comment.id,
            postId = comment.post.id,
            author = toUserSummaryResponse(comment.author),
            content = comment.content,
            parentCommentId = comment.parentComment?.id,
            likeCount = comment.likeCount,
            createdAt = comment.createdAt,
            updatedAt = comment.updatedAt,
        )

    private fun validateChannelManagePermission(
        groupId: Long,
        userId: Long,
    ) {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        if (group.owner.id == userId) return
        val member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId).orElseThrow { BusinessException(ErrorCode.FORBIDDEN) }
        val rolePerms = if (member.role.isSystemRole) systemRolePermissions(member.role.name) else member.role.permissions
        // MVP 단순화: 오버라이드 제거, 역할 권한만 확인
        if (!rolePerms.contains(GroupPermission.CHANNEL_MANAGE)) throw BusinessException(ErrorCode.FORBIDDEN)
    }

    private fun setupDefaultChannelPermissions(channel: Channel) {
        try {
            // 그룹의 기본 역할들 조회
            val ownerRole = groupRoleRepository.findByGroupIdAndName(channel.group.id, "OWNER")
                .orElse(null) ?: return // OWNER 역할이 없으면 스킵
            val memberRole = groupRoleRepository.findByGroupIdAndName(channel.group.id, "MEMBER")
                .orElse(null) ?: return // MEMBER 역할이 없으면 스킵

            // OWNER 역할에 대한 전체 권한 바인딩
            val ownerBinding = ChannelRoleBinding.create(
                channel = channel,
                groupRole = ownerRole,
                permissions = setOf(
                    ChannelPermission.CHANNEL_VIEW,
                    ChannelPermission.POST_READ,
                    ChannelPermission.POST_WRITE,
                    ChannelPermission.COMMENT_WRITE,
                    ChannelPermission.FILE_UPLOAD
                )
            )

            // MEMBER 역할에 대한 기본 권한 바인딩 (읽기/쓰기 권한)
            val memberBinding = ChannelRoleBinding.create(
                channel = channel,
                groupRole = memberRole,
                permissions = setOf(
                    ChannelPermission.CHANNEL_VIEW,
                    ChannelPermission.POST_READ,
                    ChannelPermission.POST_WRITE,
                    ChannelPermission.COMMENT_WRITE
                )
            )

            channelRoleBindingRepository.save(ownerBinding)
            channelRoleBindingRepository.save(memberBinding)
        } catch (e: Exception) {
            // 권한 바인딩 실패는 로그만 기록하고 채널 생성은 계속 진행
            // 이렇게 하면 채널은 생성되지만 권한이 없는 상태가 됨
            logger.error("채널 권한 바인딩 설정 실패 - 채널 ID: {}, 에러: {}", channel.id, e.message)
        }
    }

    // moved to top and expanded
}

// removed compat response; using WorkspaceResponse

private fun toUserSummaryResponse(user: org.castlekong.backend.entity.User): UserSummaryResponse {
    return UserSummaryResponse(
        id = user.id,
        name = user.name,
        email = user.email,
        profileImageUrl = user.profileImageUrl,
    )
}
