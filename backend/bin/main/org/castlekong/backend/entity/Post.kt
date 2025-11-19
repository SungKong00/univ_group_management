package org.castlekong.backend.entity

import jakarta.persistence.CollectionTable
import jakarta.persistence.Column
import jakarta.persistence.ElementCollection
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.JoinColumn
import jakarta.persistence.ManyToOne
import jakarta.persistence.Table
import java.time.LocalDateTime

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
    val content: String,
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    val type: PostType = PostType.GENERAL,
    @Column(name = "is_pinned", nullable = false)
    val isPinned: Boolean = false,
    @Column(name = "view_count", nullable = false)
    val viewCount: Long = 0,
    @Column(name = "like_count", nullable = false)
    val likeCount: Long = 0,
    @Column(name = "comment_count", nullable = false)
    val commentCount: Long = 0,
    @Column(name = "last_commented_at")
    val lastCommentedAt: LocalDateTime? = null,
    @ElementCollection(targetClass = String::class, fetch = FetchType.LAZY)
    @CollectionTable(name = "post_attachments", joinColumns = [JoinColumn(name = "post_id")])
    @Column(name = "file_url", nullable = false, length = 500)
    val attachments: Set<String> = emptySet(),
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),
    @Column(name = "updated_at", nullable = true)
    val updatedAt: LocalDateTime? = null,
)

enum class PostType {
    GENERAL,
    ANNOUNCEMENT,
    QUESTION,
    POLL,
}
