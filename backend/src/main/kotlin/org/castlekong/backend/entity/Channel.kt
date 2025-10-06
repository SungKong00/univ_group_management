package org.castlekong.backend.entity

import jakarta.persistence.Column
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
import jakarta.persistence.UniqueConstraint
import java.time.LocalDateTime

@Entity
@Table(
    name = "channels",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_id", "name"]),
    ],
)
data class Channel(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "workspace_id")
    val workspace: Workspace? = null,
    @Column(nullable = false, length = 100)
    val name: String,
    @Column(length = 500)
    val description: String? = null,
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    val type: ChannelType = ChannelType.TEXT,
    @Column(name = "display_order", nullable = false)
    val displayOrder: Int = 0,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    val createdBy: User,
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),
)

enum class ChannelType {
    TEXT,
    VOICE,
    ANNOUNCEMENT,
}
