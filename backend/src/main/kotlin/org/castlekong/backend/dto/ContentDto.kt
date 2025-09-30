package org.castlekong.backend.dto

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size
import java.time.LocalDateTime

// Workspace DTOs
data class CreateWorkspaceRequest(
    @field:NotBlank(message = "워크스페이스 이름은 필수입니다")
    @field:Size(min = 1, max = 100, message = "워크스페이스 이름은 1자 이상 100자 이하여야 합니다")
    val name: String,
    @field:Size(max = 500, message = "설명은 500자를 초과할 수 없습니다")
    val description: String? = null,
)

data class UpdateWorkspaceRequest(
    val name: String? = null,
    val description: String? = null,
)

data class WorkspaceResponse(
    val id: Long,
    val groupId: Long,
    val name: String,
    val description: String?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
)

// Channel DTOs
data class CreateChannelRequest(
    @field:NotBlank(message = "채널 이름은 필수입니다")
    @field:Size(min = 1, max = 100, message = "채널 이름은 1자 이상 100자 이하여야 합니다")
    val name: String,
    @field:Size(max = 500, message = "설명은 500자를 초과할 수 없습니다")
    val description: String? = null,
    val type: String? = null,
)

data class UpdateChannelRequest(
    val name: String? = null,
    val description: String? = null,
    val type: String? = null,
)

data class ChannelResponse(
    val id: Long,
    val groupId: Long,
    val name: String,
    val description: String?,
    val type: String,
    val isPrivate: Boolean,
    val displayOrder: Int,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
)

// Post DTOs
data class CreatePostRequest(
    @field:NotBlank(message = "내용은 필수입니다")
    val content: String,
    val type: String? = null,
)

data class UpdatePostRequest(
    val content: String? = null,
    val type: String? = null,
)

data class PostResponse(
    val id: Long,
    val channelId: Long,
    val author: UserSummaryResponse,
    val content: String,
    val type: String,
    val isPinned: Boolean,
    val viewCount: Long,
    val likeCount: Long,
    val commentCount: Long,
    val lastCommentedAt: LocalDateTime?,
    val attachments: Set<String>,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
)

// Comment DTOs
data class CreateCommentRequest(
    @field:NotBlank(message = "내용은 필수입니다")
    val content: String,
    val parentCommentId: Long? = null,
)

data class UpdateCommentRequest(
    val content: String? = null,
)

data class CommentResponse(
    val id: Long,
    val postId: Long,
    val author: UserSummaryResponse,
    val content: String,
    val parentCommentId: Long?,
    val likeCount: Long,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
)

// 명세서에서 요구하는 WorkspaceDto
data class WorkspaceDto(
    val groupId: Long,
    val groupName: String,
    val myRole: String,
    val myMembership: GroupMemberResponse,
    val notices: List<PostResponse>,
    val channels: List<ChannelResponse>,
    val members: List<GroupMemberResponse>,
)
