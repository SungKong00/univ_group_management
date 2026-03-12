package com.univgroup.domain.permission.entity

import com.univgroup.domain.group.entity.GroupRole
import com.univgroup.domain.permission.ChannelPermission
import com.univgroup.domain.workspace.entity.Channel
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 채널-역할 바인딩 엔티티 (L2 권한)
 *
 * 특정 채널에서 특정 역할이 어떤 권한을 갖는지 정의한다.
 * Permission-Centric 바인딩: 권한별로 허용 역할을 지정하는 방식.
 *
 * 예시:
 * - '일반 멤버' 역할은 '공지사항' 채널에서 POST_READ만 가능
 * - '일반 멤버' 역할은 '자유게시판' 채널에서 POST_READ, POST_WRITE, COMMENT_WRITE 가능
 */
@Entity
@Table(
    name = "channel_role_bindings",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["channel_id", "group_role_id"])
    ]
)
data class ChannelRoleBinding(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "channel_id", nullable = false)
    val channel: Channel,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_role_id", nullable = false)
    val groupRole: GroupRole,

    @ElementCollection(targetClass = ChannelPermission::class, fetch = FetchType.EAGER)
    @CollectionTable(name = "channel_role_binding_permissions", joinColumns = [JoinColumn(name = "binding_id")])
    @Enumerated(EnumType.STRING)
    @Column(name = "permission", nullable = false, length = 50)
    val permissions: Set<ChannelPermission> = emptySet(),

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    fun hasPermission(permission: ChannelPermission): Boolean = permission in permissions

    override fun equals(other: Any?) = other is ChannelRoleBinding && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
