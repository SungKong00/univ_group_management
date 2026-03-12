package com.univgroup.domain.content.dto

import com.univgroup.domain.content.entity.Comment
import java.time.LocalDateTime

/**
 * 댓글 응답 DTO
 */
data class CommentDto(
    val id: Long,
    val postId: Long,
    val authorId: Long,
    val authorName: String,
    val authorProfileImageUrl: String?,
    val parentCommentId: Long?,
    val content: String,
    val likeCount: Long,
    val isDeleted: Boolean,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val replies: List<CommentDto>?,
) {
    companion object {
        fun from(
            comment: Comment,
            includeReplies: Boolean = false,
            replies: List<Comment> = emptyList(),
        ): CommentDto {
            return CommentDto(
                id = comment.id!!,
                postId = comment.post.id!!,
                authorId = comment.author.id!!,
                authorName = comment.author.name,
                authorProfileImageUrl = comment.author.profileImageUrl,
                parentCommentId = comment.parentComment?.id,
                content = comment.content,
                likeCount = comment.likeCount,
                isDeleted = comment.isDeleted,
                createdAt = comment.createdAt,
                updatedAt = comment.updatedAt,
                replies = if (includeReplies) replies.map { from(it) } else null,
            )
        }
    }
}

/**
 * 댓글 생성 요청 DTO
 */
data class CreateCommentRequest(
    val content: String,
    val parentCommentId: Long? = null,
)

/**
 * 댓글 수정 요청 DTO
 */
data class UpdateCommentRequest(
    val content: String,
)
