package org.castlekong.backend.entity

import jakarta.persistence.*

/**
 * 역할 유형
 * OPERATIONAL: 운영 역할 (그룹장, 부그룹장 등)
 * SEGMENT: 분류 역할 (1학년, 2학년, 고학년 등)
 */
enum class RoleType {
    OPERATIONAL,
    SEGMENT
}

@Entity
@Table(
    name = "group_roles",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_id", "name"]),
    ],
)
data class GroupRole(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,
    @Column(nullable = false, length = 50)
    val name: String,
    @Column(name = "is_system_role", nullable = false)
    val isSystemRole: Boolean = false,
    @Enumerated(EnumType.STRING)
    @Column(name = "role_type", nullable = false, length = 20)
    val roleType: RoleType = RoleType.OPERATIONAL,
    @Column(nullable = false)
    val priority: Int = 0,
    @ElementCollection(targetClass = GroupPermission::class, fetch = FetchType.EAGER)
    @CollectionTable(name = "group_role_permissions", joinColumns = [JoinColumn(name = "group_role_id")])
    @Enumerated(EnumType.STRING)
    @Column(name = "permission", nullable = false, length = 50)
    val permissions: Set<GroupPermission> = emptySet(),
)
