package com.univgroup.domain.group.entity

import com.univgroup.domain.permission.GroupPermission
import jakarta.persistence.*

/**
 * 그룹 역할 엔티티
 *
 * 그룹 내에서 사용되는 역할(예: 그룹장, 운영진, 멤버)을 정의한다.
 * 각 역할은 GroupPermission 집합을 가지며, 이를 통해 RBAC를 구현한다.
 */
@Entity
@Table(
    name = "group_roles",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_id", "name"])
    ]
)
data class GroupRole(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,

    @Column(nullable = false, length = 50)
    var name: String,

    @Column(length = 500)
    var description: String? = null,

    // 시스템 역할 (그룹장/교수/멤버) 불변
    @Column(name = "is_system_role", nullable = false)
    val isSystemRole: Boolean = false,

    // 역할 타입
    @Enumerated(EnumType.STRING)
    @Column(name = "role_type", nullable = false, length = 20)
    var roleType: RoleType = RoleType.OPERATIONAL,

    // 우선순위
    @Column(nullable = false)
    var priority: Int = 0,

    // 권한 Set
    @ElementCollection(targetClass = GroupPermission::class, fetch = FetchType.EAGER)
    @CollectionTable(name = "group_role_permissions", joinColumns = [JoinColumn(name = "group_role_id")])
    @Enumerated(EnumType.STRING)
    @Column(name = "permission", nullable = false, length = 50)
    var permissions: MutableSet<GroupPermission> = mutableSetOf()
) {
    fun update(name: String? = null, description: String? = null, priority: Int? = null) {
        name?.let { this.name = it }
        description?.let { this.description = it }
        priority?.let { this.priority = it }
    }

    fun replacePermissions(newPermissions: Collection<GroupPermission>) {
        permissions.clear()
        permissions.addAll(newPermissions)
    }

    override fun equals(other: Any?) = other is GroupRole && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

/**
 * 역할 타입
 */
enum class RoleType {
    OPERATIONAL,  // 운영 역할 (그룹장, 부그룹장 등)
    SEGMENT       // 분류 역할 (1학년, 2학년, 고학년 등)
}
