package com.univgroup.domain.workspace.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 채널 읽기 위치 엔티티
 *
 * 사용자별로 각 채널에서 마지막으로 읽은 게시글 위치를 추적한다.
 * 안 읽은 게시글 개수 계산에 사용된다.
 */
@Entity
@Table(
    name = "channel_read_positions",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["channel_id", "user_id"])
    ]
)
data class ChannelReadPosition(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "channel_id", nullable = false)
    val channel: Channel,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @Column(name = "last_read_post_id", nullable = false)
    val lastReadPostId: Long,

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is ChannelReadPosition && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
