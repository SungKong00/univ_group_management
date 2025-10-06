package org.castlekong.backend.entity

import jakarta.persistence.*

/**
 * 역할 유형
 * OPERATIONAL: 운영 역할 (그룹장, 부그룹장 등)
 * SEGMENT: 분류 역할 (1학년, 2학년, 고학년 등)
 */
enum class RoleType {
    OPERATIONAL,
    SEGMENT,
}

@Entity
@Table(
    name = "group_roles",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_id", "name"]),
    ],
)
class GroupRole(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    var group: Group,
    @Column(nullable = false, length = 50)
    var name: String,
    @Column(name = "is_system_role", nullable = false)
    var isSystemRole: Boolean = false,
    @Enumerated(EnumType.STRING)
    @Column(name = "role_type", nullable = false, length = 20)
    var roleType: RoleType = RoleType.OPERATIONAL,
    @Column(nullable = false)
    var priority: Int = 0,
    @ElementCollection(targetClass = GroupPermission::class, fetch = FetchType.EAGER)
    @CollectionTable(name = "group_role_permissions", joinColumns = [JoinColumn(name = "group_role_id")])
    @Enumerated(EnumType.STRING)
    @Column(name = "permission", nullable = false, length = 50)
    var permissions: MutableSet<GroupPermission> = mutableSetOf(),
) {
    /**
     * 부분 업데이트 헬퍼
     */
    fun update(
        name: String? = null,
        priority: Int? = null,
    ) {
        name?.let { this.name = it }
        priority?.let { this.priority = it }
    }

    /**
     * 권한 전체 교체 (clear & addAll) – mutable Set 일관성 유지
     */
    fun replacePermissions(newPermissions: Collection<GroupPermission>) {
        permissions.clear()
        permissions.addAll(newPermissions)
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is GroupRole) return false
        // 영속화 전 엔티티는 동일성 비교 제외
        if (id == 0L || other.id == 0L) return false
        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String = "GroupRole(id=$id, name=$name, priority=$priority, system=$isSystemRole)"
}
