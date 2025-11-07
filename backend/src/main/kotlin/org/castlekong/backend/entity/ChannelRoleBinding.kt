package org.castlekong.backend.entity

import jakarta.persistence.CollectionTable
import jakarta.persistence.Column
import jakarta.persistence.ElementCollection
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

/**
 * 채널별 역할 바인딩
 * 특정 채널에 어떤 GroupRole이 어떤 권한을 갖는지 정의
 */
@Entity
@Table(
    name = "channel_role_bindings",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["channel_id", "group_role_id"]),
    ],
)
class ChannelRoleBinding(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    /**
     * 대상 채널
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "channel_id", nullable = false)
    val channel: Channel,
    /**
     * 바인딩할 그룹 역할
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_role_id", nullable = false)
    val groupRole: GroupRole,
    /**
     * 채널에서 이 역할이 가지는 권한들 (단순한 Set 기반)
     */
    @ElementCollection(targetClass = ChannelPermission::class, fetch = FetchType.EAGER)
    @CollectionTable(name = "channel_role_binding_permissions", joinColumns = [JoinColumn(name = "binding_id")])
    @Enumerated(EnumType.STRING)
    @Column(name = "permission", nullable = false, length = 50)
    val permissions: Set<ChannelPermission> = emptySet(),
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),
) {
    override fun equals(other: Any?) = other is ChannelRoleBinding && id != 0L && id == other.id

    override fun hashCode(): Int = id.hashCode()

    /**
     * 특정 권한 보유 여부 확인
     */
    fun hasPermission(permission: ChannelPermission): Boolean {
        return permission in permissions
    }

    companion object {
        /**
         * 단순한 권한 바인딩 생성
         */
        fun create(
            channel: Channel,
            groupRole: GroupRole,
            permissions: Set<ChannelPermission>,
        ): ChannelRoleBinding {
            return ChannelRoleBinding(
                channel = channel,
                groupRole = groupRole,
                permissions = permissions,
            )
        }
    }
}
