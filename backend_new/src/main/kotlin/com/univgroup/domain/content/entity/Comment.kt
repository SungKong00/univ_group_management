package com.univgroup.domain.content.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 댓글 엔티티
 *
 * 게시글에 달리는 댓글을 나타낸다.
 * parentComment를 통해 대댓글(답글) 기능을 지원한다.
 */
@Entity
@Table(name = "comments")
data class Comment(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id", nullable = false)
    val post: Post,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id", nullable = false)
    val author: User,

    @Column(nullable = false, columnDefinition = "TEXT")
    var content: String,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_comment_id")
    val parentComment: Comment? = null,

    @Column(name = "like_count", nullable = false)
    var likeCount: Long = 0,

    @Column(name = "is_deleted", nullable = false)
    var isDeleted: Boolean = false,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is Comment && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()

    /**
     * 대댓글 수 (동적 계산 필요 시 Repository에서 구현)
     */
    fun getReplyCount(): Long = 0L // TODO: Repository에서 count 조회

    /**
     * Soft Delete 처리
     */
    fun softDelete() {
        isDeleted = true
        content = "[삭제된 댓글입니다]"
        updatedAt = LocalDateTime.now()
    }
}
