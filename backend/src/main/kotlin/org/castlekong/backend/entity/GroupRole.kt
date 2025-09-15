package org.castlekong.backend.entity

import jakarta.persistence.*

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

    @Column(nullable = false)
    val priority: Int = 0,

    @ElementCollection(targetClass = GroupPermission::class, fetch = FetchType.EAGER)
    @CollectionTable(name = "group_role_permissions", joinColumns = [JoinColumn(name = "group_role_id")])
    @Enumerated(EnumType.STRING)
    @Column(name = "permission", nullable = false, length = 50)
    val permissions: Set<GroupPermission> = emptySet(),
)

