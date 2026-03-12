package com.univgroup.domain.workspace.entity

import com.univgroup.domain.group.entity.Group
import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 채널 엔티티
 *
 * 워크스페이스 내의 주제별 게시판.
 * 채널별로 다른 권한을 설정할 수 있다 (ChannelRoleBinding).
 */
@Entity
@Table(
    name = "channels",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_id", "name"])
    ]
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
    var name: String,

    @Column(length = 500)
    var description: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    val type: ChannelType = ChannelType.TEXT,

    @Column(name = "display_order", nullable = false)
    var displayOrder: Int = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    val createdBy: User,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is Channel && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

/**
 * 채널 유형
 */
enum class ChannelType {
    TEXT,         // 일반 게시판
    VOICE,        // 음성 채널
    ANNOUNCEMENT  // 공지사항
}
