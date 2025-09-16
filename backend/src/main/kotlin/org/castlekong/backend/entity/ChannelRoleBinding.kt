package org.castlekong.backend.entity

import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 채널별 역할 바인딩
 * 특정 채널에 어떤 GroupRole이 어떤 권한을 갖는지 정의
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
     * 적용할 권한 템플릿 (nullable - 커스텀 권한 사용 시)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "template_id")
    val template: ChannelPermissionTemplate? = null,

    /**
     * 추가로 허용할 권한들 (템플릿에 추가)
     */
    @Column(name = "allow_permissions_mask", nullable = false)
    val allowPermissionsMask: Long = 0L,

    /**
     * 거부할 권한들 (템플릿에서 제외)
     */
    @Column(name = "deny_permissions_mask", nullable = false)
    val denyPermissionsMask: Long = 0L,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    init {
        // Allow와 Deny 충돌 검증
        require(!ChannelPermission.hasConflict(allowPermissionsMask, denyPermissionsMask)) {
            "Allow 권한과 Deny 권한이 충돌합니다: " +
                "allow=${allowPermissionsMask}, deny=${denyPermissionsMask}"
        }
    }

    /**
     * 최종 권한 비트마스크 계산
     * = (template_mask ∪ allow_mask) - deny_mask
     */
    fun calculateEffectivePermissions(): Long {
        val templateMask = template?.permissionsMask ?: 0L
        val combinedMask = templateMask or allowPermissionsMask
        return ChannelPermission.applyDenyPolicy(combinedMask, denyPermissionsMask)
    }

    /**
     * 특정 권한 보유 여부 확인
     */
    fun hasPermission(permission: ChannelPermission): Boolean {
        val effectiveMask = calculateEffectivePermissions()
        return (effectiveMask and permission.mask) != 0L
    }

    /**
     * 최종 권한 목록 반환
     */
    fun getEffectivePermissions(): Set<ChannelPermission> {
        return ChannelPermission.fromMask(calculateEffectivePermissions())
    }

    companion object {
        /**
         * 템플릿 기반 바인딩 생성
         */
        fun createWithTemplate(
            channel: Channel,
            groupRole: GroupRole,
            template: ChannelPermissionTemplate
        ): ChannelRoleBinding {
            return ChannelRoleBinding(
                channel = channel,
                groupRole = groupRole,
                template = template
            )
        }

        /**
         * 커스텀 권한 바인딩 생성
         */
        fun createWithCustomPermissions(
            channel: Channel,
            groupRole: GroupRole,
            allowPermissions: Set<ChannelPermission> = emptySet(),
            denyPermissions: Set<ChannelPermission> = emptySet()
        ): ChannelRoleBinding {
            val allowMask = ChannelPermission.toMask(allowPermissions)
            val denyMask = ChannelPermission.toMask(denyPermissions)

            // 충돌 사전 검증
            require(!ChannelPermission.hasConflict(allowMask, denyMask)) {
                "Allow 권한과 Deny 권한이 충돌합니다"
            }

            return ChannelRoleBinding(
                channel = channel,
                groupRole = groupRole,
                allowPermissionsMask = allowMask,
                denyPermissionsMask = denyMask
            )
        }

        /**
         * 혼합형 바인딩 생성 (템플릿 + 오버라이드)
         */
        fun createWithTemplateAndOverride(
            channel: Channel,
            groupRole: GroupRole,
            template: ChannelPermissionTemplate,
            additionalAllowPermissions: Set<ChannelPermission> = emptySet(),
            denyPermissions: Set<ChannelPermission> = emptySet()
        ): ChannelRoleBinding {
            val allowMask = ChannelPermission.toMask(additionalAllowPermissions)
            val denyMask = ChannelPermission.toMask(denyPermissions)

            // 충돌 사전 검증
            require(!ChannelPermission.hasConflict(allowMask, denyMask)) {
                "Allow 권한과 Deny 권한이 충돌합니다"
            }

            return ChannelRoleBinding(
                channel = channel,
                groupRole = groupRole,
                template = template,
                allowPermissionsMask = allowMask,
                denyPermissionsMask = denyMask
            )
        }
    }
}