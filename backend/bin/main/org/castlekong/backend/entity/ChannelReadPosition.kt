package org.castlekong.backend.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import jakarta.persistence.UniqueConstraint
import java.time.LocalDateTime

@Entity
@Table(
    name = "channel_read_positions",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["user_id", "channel_id"]),
    ],
)
class ChannelReadPosition(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    @Column(name = "user_id", nullable = false)
    val userId: Long,
    @Column(name = "channel_id", nullable = false)
    val channelId: Long,
    @Column(name = "last_read_post_id", nullable = false)
    var lastReadPostId: Long,
    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now(),
) {
    override fun equals(other: Any?) = other is ChannelReadPosition && id != 0L && id == other.id

    override fun hashCode(): Int = id.hashCode()
}
