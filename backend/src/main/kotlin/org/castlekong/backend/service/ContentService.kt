package org.castlekong.backend.service

import org.castlekong.backend.dto.*
import org.castlekong.backend.entity.*
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.*
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
    private val overrideRepository: GroupMemberPermissionOverrideRepository,
    private val permissionService: org.castlekong.backend.security.PermissionService,
) {
    private fun systemRolePermissions(roleName: String): Set<GroupPermission> = when (roleName.uppercase()) {
        "OWNER" -> GroupPermission.entries.toSet()
        "ADVISOR" -> GroupPermission.entries
            .toSet()
            .minus(
                setOf(
                    GroupPermission.GROUP_MANAGE,
                    GroupPermission.ROLE_MANAGE,
                    GroupPermission.MEMBER_APPROVE,
                    GroupPermission.MEMBER_KICK,
                    GroupPermission.RECRUITMENT_CREATE,
                    GroupPermission.RECRUITMENT_UPDATE,
                    GroupPermission.RECRUITMENT_DELETE,
                ),
            )
        "MEMBER" -> setOf(
            GroupPermission.CHANNEL_READ,
            GroupPermission.POST_READ,
            GroupPermission.POST_CREATE,
            GroupPermission.COMMENT_READ,
            GroupPermission.COMMENT_CREATE,
        )
        else -> emptySet()
    }

    private fun getEffectivePermissions(groupId: Long, userId: Long): Set<GroupPermission> =
        permissionService.getEffective(groupId, userId, ::systemRolePermissions)

    private fun ensurePermission(groupId: Long, userId: Long, required: GroupPermission) {
        val effective = getEffectivePermissions(groupId, userId)
        if (!effective.contains(required)) throw BusinessException(ErrorCode.FORBIDDEN)
    }
    // Workspaces
    fun getWorkspacesByGroup(groupId: Long): List<WorkspaceResponse> {
        val group = groupRepository.findById(groupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        if (group.deletedAt != null) throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        val existing = workspaceRepository.findByGroup_Id(groupId)
        if (existing.isNotEmpty()) return existing.map { toWorkspaceResponse(it) }
        // ensure single default workspace
        val ws = Workspace(group = group, name = "기본 워크스페이스", description = null)
        return listOf(toWorkspaceResponse(workspaceRepository.save(ws)))
    }

    @Transactional
    fun createWorkspace(groupId: Long, request: CreateWorkspaceRequest): WorkspaceResponse {
        val group = groupRepository.findById(groupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        if (group.deletedAt != null) throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        val ws = Workspace(
            group = group,
            name = request.name,
            description = request.description,
        )
        return toWorkspaceResponse(workspaceRepository.save(ws))
    }

    @Transactional
    fun updateWorkspace(workspaceId: Long, request: UpdateWorkspaceRequest, requesterId: Long): WorkspaceResponse {
        val ws = workspaceRepository.findById(workspaceId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        ensurePermission(ws.group.id, requesterId, GroupPermission.GROUP_MANAGE)
        val updated = ws.copy(
            name = request.name ?: ws.name,
            description = request.description ?: ws.description,
            updatedAt = LocalDateTime.now(),
        )
        return toWorkspaceResponse(workspaceRepository.save(updated))
    }

    @Transactional
    fun deleteWorkspace(workspaceId: Long, requesterId: Long) {
        val ws = workspaceRepository.findById(workspaceId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        ensurePermission(ws.group.id, requesterId, GroupPermission.GROUP_MANAGE)
        // delete channels, posts, comments under workspace
        channelRepository.findByWorkspace_Id(workspaceId).forEach { ch ->
            postRepository.findByChannel_Id(ch.id).forEach { p ->
                commentRepository.findByPost_Id(p.id).forEach { commentRepository.delete(it) }
                postRepository.delete(p)
            }
            channelRepository.delete(ch)
        }
        workspaceRepository.delete(ws)
    }

    // Channels
    fun getChannelsByWorkspace(workspaceId: Long, requesterId: Long): List<ChannelResponse> {
        val workspace = workspaceRepository.findById(workspaceId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        ensurePermission(workspace.group.id, requesterId, GroupPermission.CHANNEL_READ)
        return channelRepository.findByWorkspace_Id(workspaceId).map { toChannelResponse(it) }
    }

    @Transactional
    fun createChannel(workspaceId: Long, request: CreateChannelRequest, creatorId: Long): ChannelResponse {
        val workspace = workspaceRepository.findById(workspaceId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        val group = workspace.group
        val creator = userRepository.findById(creatorId)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
        // permission: group owner or role has CHANNEL_WRITE
        validateChannelManagePermission(group.id, creator.id)
        val type = request.type?.let { runCatching { ChannelType.valueOf(it) }.getOrDefault(ChannelType.TEXT) } ?: ChannelType.TEXT
        val channel = Channel(
            group = group,
            workspace = workspace,
            name = request.name,
            description = request.description,
            type = type,
            isPrivate = false,
            displayOrder = 0,
            createdBy = creator,
        )
        return toChannelResponse(channelRepository.save(channel))
    }

    @Transactional
    fun updateChannel(channelId: Long, request: UpdateChannelRequest, userId: Long): ChannelResponse {
        val channel = channelRepository.findById(channelId)
            .orElseThrow { BusinessException(ErrorCode.CHANNEL_NOT_FOUND) }
        validateChannelManagePermission(channel.group.id, userId)
        val type = request.type?.let { runCatching { ChannelType.valueOf(it) }.getOrNull() } ?: channel.type
        val updated = channel.copy(
            name = request.name ?: channel.name,
            description = request.description ?: channel.description,
            type = type,
            updatedAt = LocalDateTime.now(),
        )
        return toChannelResponse(channelRepository.save(updated))
    }

    @Transactional
    fun deleteChannel(channelId: Long, userId: Long) {
        val channel = channelRepository.findById(channelId)
            .orElseThrow { BusinessException(ErrorCode.CHANNEL_NOT_FOUND) }
        validateChannelManagePermission(channel.group.id, userId)
        postRepository.findByChannel_Id(channelId).forEach { p ->
            commentRepository.findByPost_Id(p.id).forEach { commentRepository.delete(it) }
            postRepository.delete(p)
        }
        channelRepository.delete(channel)
    }

    // Posts
    fun getPosts(channelId: Long, requesterId: Long): List<PostResponse> {
        val channel = channelRepository.findById(channelId)
            .orElseThrow { BusinessException(ErrorCode.CHANNEL_NOT_FOUND) }
        ensurePermission(channel.group.id, requesterId, GroupPermission.POST_READ)
        return postRepository.findByChannel_Id(channelId).map { toPostResponse(it) }
    }

    fun getPost(postId: Long, requesterId: Long): PostResponse {
        val post = postRepository.findById(postId)
            .orElseThrow { BusinessException(ErrorCode.POST_NOT_FOUND) }
        ensurePermission(post.channel.group.id, requesterId, GroupPermission.POST_READ)
        return toPostResponse(post)
    }

    @Transactional
    fun createPost(channelId: Long, request: CreatePostRequest, authorId: Long): PostResponse {
        val channel = channelRepository.findById(channelId)
            .orElseThrow { BusinessException(ErrorCode.CHANNEL_NOT_FOUND) }
        val author = userRepository.findById(authorId)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
        ensurePermission(channel.group.id, author.id, GroupPermission.POST_CREATE)
        val type = request.type?.let { runCatching { PostType.valueOf(it) }.getOrDefault(PostType.GENERAL) } ?: PostType.GENERAL
        val post = Post(
            channel = channel,
            author = author,
            title = request.title ?: "",
            content = request.content,
            type = type,
        )
        return toPostResponse(postRepository.save(post))
    }

    @Transactional
    fun updatePost(postId: Long, request: UpdatePostRequest, requesterId: Long): PostResponse {
        val post = postRepository.findById(postId)
            .orElseThrow { BusinessException(ErrorCode.POST_NOT_FOUND) }
        if (post.author.id != requesterId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
        val type = request.type?.let { runCatching { PostType.valueOf(it) }.getOrNull() } ?: post.type
        val updated = post.copy(
            title = request.title ?: post.title,
            content = request.content ?: post.content,
            type = type,
            updatedAt = LocalDateTime.now(),
        )
        return toPostResponse(postRepository.save(updated))
    }

    @Transactional
    fun deletePost(postId: Long, requesterId: Long) {
        val post = postRepository.findById(postId)
            .orElseThrow { BusinessException(ErrorCode.POST_NOT_FOUND) }
        if (post.author.id != requesterId) {
            // allow moderators with POST_DELETE_ANY
            val groupId = post.channel.group.id
            val perms = getEffectivePermissions(groupId, requesterId)
            if (!perms.contains(GroupPermission.POST_DELETE_ANY)) {
                throw BusinessException(ErrorCode.FORBIDDEN)
            }
        }
        commentRepository.findByPost_Id(postId).forEach { commentRepository.delete(it) }
        postRepository.delete(post)
    }

    // Comments
    fun getComments(postId: Long, requesterId: Long): List<CommentResponse> {
        val post = postRepository.findById(postId)
            .orElseThrow { BusinessException(ErrorCode.POST_NOT_FOUND) }
        ensurePermission(post.channel.group.id, requesterId, GroupPermission.COMMENT_READ)
        return commentRepository.findByPost_Id(postId).map { toCommentResponse(it) }
    }

    @Transactional
    fun createComment(postId: Long, request: CreateCommentRequest, authorId: Long): CommentResponse {
        val post = postRepository.findById(postId)
            .orElseThrow { BusinessException(ErrorCode.POST_NOT_FOUND) }
        val author = userRepository.findById(authorId)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
        ensurePermission(post.channel.group.id, author.id, GroupPermission.COMMENT_CREATE)
        val parent = request.parentCommentId?.let {
            commentRepository.findById(it).orElseThrow { BusinessException(ErrorCode.COMMENT_NOT_FOUND) }
        }
        val comment = Comment(
            post = post,
            author = author,
            content = request.content,
            parentComment = parent,
        )
        return toCommentResponse(commentRepository.save(comment))
    }

    @Transactional
    fun updateComment(commentId: Long, request: UpdateCommentRequest, requesterId: Long): CommentResponse {
        val comment = commentRepository.findById(commentId)
            .orElseThrow { BusinessException(ErrorCode.COMMENT_NOT_FOUND) }
        if (comment.author.id != requesterId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
        val updated = comment.copy(
            content = request.content ?: comment.content,
            updatedAt = LocalDateTime.now(),
        )
        return toCommentResponse(commentRepository.save(updated))
    }

    @Transactional
    fun deleteComment(commentId: Long, requesterId: Long) {
        val comment = commentRepository.findById(commentId)
            .orElseThrow { BusinessException(ErrorCode.COMMENT_NOT_FOUND) }
        if (comment.author.id != requesterId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
        commentRepository.delete(comment)
    }

    // DTOs
    private fun toChannelResponse(channel: Channel) = ChannelResponse(
        id = channel.id,
        groupId = channel.group.id,
        name = channel.name,
        description = channel.description,
        type = channel.type.name,
        isPrivate = channel.isPrivate,
        displayOrder = channel.displayOrder,
        createdAt = channel.createdAt,
        updatedAt = channel.updatedAt,
    )

    private fun toWorkspaceResponse(workspace: Workspace) = WorkspaceResponse(
        id = workspace.id,
        groupId = workspace.group.id,
        name = workspace.name,
        description = workspace.description,
        createdAt = workspace.createdAt,
        updatedAt = workspace.updatedAt,
    )

    private fun toPostResponse(post: Post) = PostResponse(
        id = post.id,
        channelId = post.channel.id,
        author = toUserSummaryResponse(post.author),
        title = post.title,
        content = post.content,
        type = post.type.name,
        isPinned = post.isPinned,
        viewCount = post.viewCount,
        likeCount = post.likeCount,
        attachments = post.attachments,
        createdAt = post.createdAt,
        updatedAt = post.updatedAt,
    )

    private fun toCommentResponse(comment: Comment) = CommentResponse(
        id = comment.id,
        postId = comment.post.id,
        author = toUserSummaryResponse(comment.author),
        content = comment.content,
        parentCommentId = comment.parentComment?.id,
        likeCount = comment.likeCount,
        createdAt = comment.createdAt,
        updatedAt = comment.updatedAt,
    )

    private fun validateChannelManagePermission(groupId: Long, userId: Long) {
        val group = groupRepository.findById(groupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        if (group.owner.id == userId) return
        val member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId).orElseThrow { BusinessException(ErrorCode.FORBIDDEN) }
        val rolePerms = if (member.role.isSystemRole) systemRolePermissions(member.role.name) else member.role.permissions
        val override = overrideRepository.findByGroupIdAndUserId(groupId, userId).orElse(null)
        val effective = if (override != null) rolePerms.plus(override.allowedPermissions).minus(override.deniedPermissions) else rolePerms
        if (!effective.contains(GroupPermission.CHANNEL_MANAGE)) throw BusinessException(ErrorCode.FORBIDDEN)
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
