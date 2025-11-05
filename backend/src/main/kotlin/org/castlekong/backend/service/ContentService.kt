package org.castlekong.backend.service

import org.castlekong.backend.dto.ChannelResponse
import org.castlekong.backend.dto.CommentResponse
import org.castlekong.backend.dto.CreateChannelRequest
import org.castlekong.backend.dto.CreateChannelWithPermissionsRequest
import org.castlekong.backend.dto.CreateCommentRequest
import org.castlekong.backend.dto.CreatePostRequest
import org.castlekong.backend.dto.CreateWorkspaceRequest
import org.castlekong.backend.dto.PostResponse
import org.castlekong.backend.dto.UpdateChannelRequest
import org.castlekong.backend.dto.UpdateCommentRequest
import org.castlekong.backend.dto.UpdatePostRequest
import org.castlekong.backend.dto.UpdateWorkspaceRequest
import org.castlekong.backend.dto.UserSummaryResponse
import org.castlekong.backend.dto.WorkspaceResponse
import org.castlekong.backend.entity.Channel
import org.castlekong.backend.entity.ChannelPermission
import org.castlekong.backend.entity.ChannelRoleBinding
import org.castlekong.backend.entity.ChannelType
import org.castlekong.backend.entity.Comment
import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.entity.Post
import org.castlekong.backend.entity.PostType
import org.castlekong.backend.entity.User
import org.castlekong.backend.entity.Workspace
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.ChannelRepository
import org.castlekong.backend.repository.ChannelRoleBindingRepository
import org.castlekong.backend.repository.CommentRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.castlekong.backend.repository.PostRepository
import org.castlekong.backend.repository.UserRepository
import org.castlekong.backend.repository.WorkspaceRepository
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
            "그룹장" -> GroupPermission.entries.toSet()
            "교수" -> GroupPermission.entries.toSet() // MVP에서는 그룹장와 동일
            "멤버" -> emptySet() // 멤버는 기본적으로 워크스페이스 접근 가능, 별도 권한 불필요
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
        val channel =
            channelRepository.findById(channelId)
                .orElseThrow { BusinessException(ErrorCode.CHANNEL_NOT_FOUND) }

        val member =
            groupMemberRepository.findByGroupIdAndUserId(channel.group.id, userId)
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
    fun getWorkspacesByGroup(
        groupId: Long,
        requesterId: Long,
    ): List<WorkspaceResponse> {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        if (group.deletedAt != null) throw BusinessException(ErrorCode.GROUP_NOT_FOUND)

        // Check group membership
        groupMemberRepository.findByGroupIdAndUserId(groupId, requesterId)
            .orElseThrow { BusinessException(ErrorCode.FORBIDDEN) }

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
        if (channels.isEmpty()) return
        val channelIds = channels.map { it.id }
        // 1) 채널-역할 바인딩 제거
        channelRoleBindingRepository.deleteByChannelIds(channelIds)
        // 2) 포스트 ID 수집 후 댓글/포스트 벌크 삭제
        val postIds = postRepository.findPostIdsByChannelIds(channelIds)
        if (postIds.isNotEmpty()) {
            // 댓글 먼저
            commentRepository.deleteByPostIds(postIds)
            // 포스트 삭제
            postRepository.deleteByChannelIds(channelIds)
        }
        // 3) 채널 삭제 (개별 select 없이 일괄) - 현재 deleteAll(channels) 사용
        channelRepository.deleteAll(channels)
        logger.debug(
            "Workspace {} contents deleted: channels={}, posts={}, comments deleted in bulk",
            workspaceId,
            channelIds.size,
            postIds.size,
        )
    }

    // Channels
    fun getChannelsByWorkspace(
        workspaceId: Long,
        requesterId: Long,
    ): List<ChannelResponse> {
        val workspace =
            workspaceRepository.findById(workspaceId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        // 워크스페이스 접근은 그룹 멤버십으로 확인
        val member =
            groupMemberRepository.findByGroupIdAndUserId(workspace.group.id, requesterId)
                .orElseThrow { BusinessException(ErrorCode.FORBIDDEN) }
        // POST_READ 권한이 있는 채널만 필터링 (CHANNEL_VIEW 역할 흡수)
        return channelRepository.findByWorkspace_Id(workspaceId)
            .filter { channel ->
                hasChannelPermission(channel.id, requesterId, ChannelPermission.POST_READ)
            }
            .map { toChannelResponse(it) }
    }

    fun getChannelsByGroup(
        groupId: Long,
        requesterId: Long,
    ): List<ChannelResponse> {
        // 1. 그룹 존재 확인
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 2. 사용자 멤버십 확인
        val member =
            groupMemberRepository.findByGroupIdAndUserId(groupId, requesterId)
                .orElseThrow { BusinessException(ErrorCode.FORBIDDEN) }

        // 3. 채널 목록 직접 조회 (workspace 테이블 우회)
        // Note: 현재 구조에서는 채널이 group에 직접 연결되어 있음
        // POST_READ 권한이 있는 채널만 필터링 (CHANNEL_VIEW 역할 흡수)
        return channelRepository.findByGroup_Id(groupId)
            .filter { channel ->
                hasChannelPermission(channel.id, requesterId, ChannelPermission.POST_READ)
            }
            .map { toChannelResponse(it) }
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
        val type =
            request.type?.let { runCatching { ChannelType.valueOf(it) }.getOrDefault(ChannelType.TEXT) }
                ?: ChannelType.TEXT
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

        // 정책(2025-10-01 rev5): 새로 생성된 사용자 정의 채널은 권한 바인딩 0개 상태로 시작.
        // 기본 2개 초기 채널(공지/자유)만 ChannelInitializationService 에서 템플릿 부여.
        // UI 는 채널 생성 직후 권한 매트릭스 편집 화면으로 유도.
        // setupDefaultChannelPermissions(savedChannel)  // 자동 템플릿 부여 제거

        return toChannelResponse(savedChannel)
    }

    /**
     * 채널 생성 + 권한 설정 통합 API
     *
     * 채널 기본 정보와 역할별 권한을 한 번에 받아
     * 트랜잭션으로 원자적으로 처리합니다.
     *
     * @param workspaceId 워크스페이스 ID
     * @param request 채널 정보 + 권한 설정
     * @param creatorId 채널 생성자 ID
     * @return 생성된 채널 정보
     */
    @Transactional
    fun createChannelWithPermissions(
        workspaceId: Long,
        request: CreateChannelWithPermissionsRequest,
        creatorId: Long,
    ): ChannelResponse {
        // 1. Workspace 존재 확인
        val workspace =
            workspaceRepository.findById(workspaceId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        val group = workspace.group

        // 2. Creator 확인
        val creator =
            userRepository.findById(creatorId)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        // 3. CHANNEL_MANAGE 권한 검증
        validateChannelManagePermission(group.id, creator.id)

        // 4. 권한 요청 검증
        validateRolePermissionsRequest(group.id, request.rolePermissions)

        // 5. 채널 엔티티 생성
        val type =
            request.type?.let { runCatching { ChannelType.valueOf(it) }.getOrDefault(ChannelType.TEXT) }
                ?: ChannelType.TEXT

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

        // 6. 채널 저장
        val savedChannel = channelRepository.save(channel)

        // 7. 권한 바인딩 일괄 생성
        createChannelRoleBindingsBatch(savedChannel, request.rolePermissions)

        // 8. 응답 반환
        return toChannelResponse(savedChannel)
    }

    /**
     * 역할별 권한 요청 검증
     *
     * 1. rolePermissions가 비어있지 않은지 확인
     * 2. 모든 역할이 그룹에 존재하는지 확인
     * 3. POST_READ 권한을 가진 역할이 최소 1개 이상인지 확인
     */
    private fun validateRolePermissionsRequest(
        groupId: Long,
        rolePermissions: Map<Long, Set<String>>,
    ) {
        // 1. 빈 권한 체크
        if (rolePermissions.isEmpty()) {
            throw BusinessException(ErrorCode.EMPTY_ROLE_PERMISSIONS)
        }

        // 2. 역할 존재 확인
        val roleIds = rolePermissions.keys
        val existingRoles = groupRoleRepository.findAllById(roleIds)
        if (existingRoles.size != roleIds.size) {
            throw BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND)
        }

        // 3. 모든 역할이 해당 그룹 소속인지 확인
        val invalidRoles = existingRoles.filter { it.group.id != groupId }
        if (invalidRoles.isNotEmpty()) {
            throw BusinessException(
                ErrorCode.FORBIDDEN,
                "역할이 해당 그룹에 속하지 않습니다",
            )
        }

        // 4. POST_READ 권한 필수 체크
        val hasPostRead =
            rolePermissions.values.any { permissions ->
                permissions.contains("POST_READ")
            }
        if (!hasPostRead) {
            throw BusinessException(ErrorCode.MISSING_POST_READ_PERMISSION)
        }

        // 5. 각 역할의 권한이 비어있지 않은지 확인
        rolePermissions.forEach { (roleId, permissions) ->
            if (permissions.isEmpty()) {
                throw BusinessException(
                    ErrorCode.EMPTY_ROLE_PERMISSIONS,
                    "역할 ID $roleId 의 권한이 비어있습니다",
                )
            }
        }
    }

    /**
     * 채널 역할 바인딩 일괄 생성
     *
     * @param channel 생성된 채널
     * @param rolePermissions 역할별 권한 맵
     */
    private fun createChannelRoleBindingsBatch(
        channel: Channel,
        rolePermissions: Map<Long, Set<String>>,
    ) {
        val bindings = rolePermissions.map { (roleId, permissionStrings) ->
            // 역할 조회
            val role =
                groupRoleRepository.findById(roleId)
                    .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }

            // String -> ChannelPermission 변환
            val permissions =
                permissionStrings
                    .mapNotNull { permStr ->
                        try {
                            ChannelPermission.valueOf(permStr)
                        } catch (e: IllegalArgumentException) {
                            logger.warn("Invalid permission string: $permStr")
                            null
                        }
                    }
                    .toMutableSet()

            // ChannelRoleBinding 생성
            ChannelRoleBinding(
                channel = channel,
                groupRole = role,
                permissions = permissions,
            )
        }

        // 일괄 저장
        channelRoleBindingRepository.saveAll(bindings)

        logger.info("Created ${bindings.size} channel role bindings for channel ${channel.id}")
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
            Channel(
                id = channel.id,
                group = channel.group,
                workspace = channel.workspace,
                name = request.name ?: channel.name,
                description = request.description ?: channel.description,
                type = type,
                displayOrder = channel.displayOrder,
                createdBy = channel.createdBy,
                createdAt = channel.createdAt,
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
        // 단일 채널용 벌크 삭제
        channelRoleBindingRepository.deleteByChannelIds(listOf(channelId))
        val postIds = postRepository.findPostIdsByChannelIds(listOf(channelId))
        if (postIds.isNotEmpty()) {
            commentRepository.deleteByPostIds(postIds)
            postRepository.deleteByChannelIds(listOf(channelId))
        }
        logger.debug("Channel {} contents deleted: posts={}, comments deleted in bulk", channelId, postIds.size)
    }

    // Posts
    fun getPosts(
        channelId: Long,
        requesterId: Long,
    ): List<PostResponse> {
        val channel =
            channelRepository.findById(channelId)
                .orElseThrow { BusinessException(ErrorCode.CHANNEL_NOT_FOUND) }
        // 워크스페이스 접근은 그룹 멤버십으로 확인
        val member =
            groupMemberRepository.findByGroupIdAndUserId(channel.group.id, requesterId)
                .orElseThrow { BusinessException(ErrorCode.FORBIDDEN) }
        return postRepository.findByChannel_Id(channelId).map { toPostResponse(it) }
    }

    fun getPost(
        postId: Long,
        requesterId: Long,
    ): PostResponse {
        val post =
            postRepository.findById(postId)
                .orElseThrow { BusinessException(ErrorCode.POST_NOT_FOUND) }
        // 워크스페이스 접근은 그룹 멤버십으로 확인
        val member =
            groupMemberRepository.findByGroupIdAndUserId(post.channel.group.id, requesterId)
                .orElseThrow { BusinessException(ErrorCode.FORBIDDEN) }
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
        // 워크스페이스 접근은 그룹 멤버십으로 확인
        val authorMember =
            groupMemberRepository.findByGroupIdAndUserId(channel.group.id, author.id)
                .orElseThrow { BusinessException(ErrorCode.FORBIDDEN) }
        ensureChannelPermission(channelId, author.id, ChannelPermission.POST_WRITE)
        val type =
            request.type?.let { runCatching { PostType.valueOf(it) }.getOrDefault(PostType.GENERAL) }
                ?: PostType.GENERAL
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
            if (!perms.contains(GroupPermission.MEMBER_MANAGE)) {
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
        // 워크스페이스 접근은 그룹 멤버십으로 확인
        val member =
            groupMemberRepository.findByGroupIdAndUserId(post.channel.group.id, requesterId)
                .orElseThrow { BusinessException(ErrorCode.FORBIDDEN) }
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
        // 워크스페이스 접근은 그룹 멤버십으로 확인
        val authorMember =
            groupMemberRepository.findByGroupIdAndUserId(post.channel.group.id, author.id)
                .orElseThrow { BusinessException(ErrorCode.FORBIDDEN) }
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
            // 권한은 ChannelRoleBinding으로 관리
            isPrivate = false,
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
        val member =
            groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow { BusinessException(ErrorCode.FORBIDDEN) }
        val rolePerms =
            if (member.role.isSystemRole) systemRolePermissions(member.role.name) else member.role.permissions
        // MVP 단순화: 오버라이드 제거, 역할 권한만 확인
        if (!rolePerms.contains(GroupPermission.CHANNEL_MANAGE)) throw BusinessException(ErrorCode.FORBIDDEN)
    }

    // moved to top and expanded
}

// removed compat response; using WorkspaceResponse

private fun toUserSummaryResponse(user: User): UserSummaryResponse {
    return UserSummaryResponse(
        id = user.id,
        name = user.name,
        email = user.email,
        profileImageUrl = user.profileImageUrl,
    )
}
