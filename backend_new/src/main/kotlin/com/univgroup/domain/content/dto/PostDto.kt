package com.univgroup.domain.content.dto

import com.univgroup.domain.content.entity.Post
import com.univgroup.domain.content.entity.PostType
import java.time.LocalDateTime

/**
 * 게시글 응답 DTO
 */
data class PostDto(
    val id: Long,
    val channelId: Long,
    val authorId: Long,
    val authorName: String,
    val authorProfileImageUrl: String?,
    val content: String,
    val type: PostType,
    val isPinned: Boolean,
    val pinnedAt: LocalDateTime?,
    val viewCount: Long,
    val likeCount: Long,
    val commentCount: Long,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime?,
) {
    companion object {
        fun from(post: Post): PostDto {
            return PostDto(
                id = post.id!!,
                channelId = post.channel.id!!,
                authorId = post.author.id!!,
                authorName = post.author.name,
                authorProfileImageUrl = post.author.profileImageUrl,
                content = post.content,
                type = post.type,
                isPinned = post.isPinned,
                pinnedAt = post.pinnedAt,
                viewCount = post.viewCount,
                likeCount = post.likeCount,
                commentCount = post.commentCount,
                createdAt = post.createdAt,
                updatedAt = post.updatedAt,
            )
        }
    }
}

/**
 * 게시글 요약 DTO (목록용)
 */
data class PostSummaryDto(
    val id: Long,
    val channelId: Long,
    val authorName: String,
    val contentPreview: String,
    val type: PostType,
    val isPinned: Boolean,
    val viewCount: Long,
    val commentCount: Long,
    val createdAt: LocalDateTime,
) {
    companion object {
        fun from(
            post: Post,
            previewLength: Int = 100,
        ): PostSummaryDto {
            return PostSummaryDto(
                id = post.id!!,
                channelId = post.channel.id!!,
                authorName = post.author.name,
                contentPreview = post.content.take(previewLength),
                type = post.type,
                isPinned = post.isPinned,
                viewCount = post.viewCount,
                commentCount = post.commentCount,
                createdAt = post.createdAt,
            )
        }
    }
}

/**
 * 게시글 생성 요청 DTO
 */
data class CreatePostRequest(
    val content: String,
    val type: PostType = PostType.GENERAL,
)

/**
 * 게시글 수정 요청 DTO
 */
data class UpdatePostRequest(
    val content: String? = null,
    val type: PostType? = null,
)
