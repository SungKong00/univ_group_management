package com.univgroup.domain.workspace.entity

import com.univgroup.domain.group.entity.Group
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 워크스페이스 엔티티
 *
 * 그룹 내 콘텐츠를 담는 최상위 컨테이너.
 * 현재는 그룹당 단일 워크스페이스 개념으로 사용된다.
 */
@Entity
@Table(
    name = "workspaces",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_id", "name"])
    ]
)
data class Workspace(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,

    @Column(nullable = false, length = 100)
    var name: String,

    @Column(length = 500)
    var description: String? = null,

    @Column(name = "display_order", nullable = false)
    var displayOrder: Int = 0,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is Workspace && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
