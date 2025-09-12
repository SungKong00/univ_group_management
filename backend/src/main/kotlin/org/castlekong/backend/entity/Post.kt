package org.castlekong.backend.entity

import jakarta.persistence.*
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

    @Column(nullable = false, length = 200)
    val title: String,

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

    @ElementCollection(targetClass = String::class, fetch = FetchType.LAZY)
    @CollectionTable(name = "post_attachments", joinColumns = [JoinColumn(name = "post_id")])
    @Column(name = "file_url", nullable = false, length = 500)
    val attachments: Set<String> = emptySet(),

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),
)

enum class PostType {
    GENERAL,
    ANNOUNCEMENT,
    QUESTION,
    POLL,
    FILE_SHARE
}