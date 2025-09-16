package org.castlekong.backend.entity

import jakarta.persistence.*

@Entity
@Table(
    name = "group_member_overrides",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_id", "user_id"]),
    ],
)
data class GroupMemberPermissionOverride(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,
    @ElementCollection(targetClass = GroupPermission::class, fetch = FetchType.EAGER)
    @CollectionTable(name = "group_member_allowed_permissions", joinColumns = [JoinColumn(name = "override_id")])
    @Enumerated(EnumType.STRING)
    @Column(name = "permission", nullable = false, length = 50)
    val allowedPermissions: Set<GroupPermission> = emptySet(),
    @ElementCollection(targetClass = GroupPermission::class, fetch = FetchType.EAGER)
    @CollectionTable(name = "group_member_denied_permissions", joinColumns = [JoinColumn(name = "override_id")])
    @Enumerated(EnumType.STRING)
    @Column(name = "permission", nullable = false, length = 50)
    val deniedPermissions: Set<GroupPermission> = emptySet(),
)
