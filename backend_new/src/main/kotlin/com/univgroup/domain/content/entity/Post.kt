package com.univgroup.domain.content.entity

import com.univgroup.domain.user.entity.User
import com.univgroup.domain.workspace.entity.Channel
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 게시글 엔티티
 *
 * 채널에 작성되는 게시글을 나타낸다.
 */
@Entity
@Table(name = "posts")
data class Post(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "channel_id", nullable = false)
    val channel: Channel,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id", nullable = false)
    val author: User,

    @Column(nullable = false, columnDefinition = "TEXT")
    var content: String,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    var type: PostType = PostType.GENERAL,

    @Column(name = "is_pinned", nullable = false)
    var isPinned: Boolean = false,

    @Column(name = "pinned_at")
    var pinnedAt: LocalDateTime? = null,

    @Column(name = "view_count", nullable = false)
    var viewCount: Long = 0,

    @Column(name = "like_count", nullable = false)
    var likeCount: Long = 0,

    @Column(name = "comment_count", nullable = false)
    var commentCount: Long = 0,

    @Column(name = "last_commented_at")
    var lastCommentedAt: LocalDateTime? = null,

    @ElementCollection(targetClass = String::class, fetch = FetchType.LAZY)
    @CollectionTable(name = "post_attachments", joinColumns = [JoinColumn(name = "post_id")])
    @Column(name = "file_url", nullable = false, length = 500)
    val attachments: Set<String> = emptySet(),

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at")
    val updatedAt: LocalDateTime? = null
) {
    override fun equals(other: Any?) = other is Post && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()

    /**
     * 댓글 수 증가
     */
    fun incrementCommentCount() {
        commentCount++
        lastCommentedAt = LocalDateTime.now()
    }

    /**
     * 댓글 수 감소
     */
    fun decrementCommentCount() {
        if (commentCount > 0) {
            commentCount--
        }
    }
}

/**
 * 게시글 유형
 */
enum class PostType {
    GENERAL,      // 일반 게시글
    ANNOUNCEMENT, // 공지사항
    QUESTION,     // 질문
    POLL          // 투표
}
