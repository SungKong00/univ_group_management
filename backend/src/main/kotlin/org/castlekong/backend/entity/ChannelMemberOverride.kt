package org.castlekong.backend.entity

import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 채널별 개별 멤버 권한 오버라이드
 * 특정 사용자에게만 예외적으로 권한을 부여하거나 제거
 */
@Entity
@Table(
    name = "channel_member_overrides",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["channel_id", "user_id"])
    ]
)
data class ChannelMemberOverride(
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
     * 대상 사용자
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    /**
     * 추가로 허용할 권한들
     */
    @Column(name = "allow_permissions_mask", nullable = false)
    val allowPermissionsMask: Long = 0L,

    /**
     * 거부할 권한들
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
     * 역할 기반 권한에 멤버 오버라이드 적용
     * = (role_mask ∪ member_allow) - member_deny
     */
    fun applyToRolePermissions(roleMask: Long): Long {
        val combinedMask = roleMask or allowPermissionsMask
        return ChannelPermission.applyDenyPolicy(combinedMask, denyPermissionsMask)
    }

    /**
     * 추가 허용 권한 목록 반환
     */
    fun getAllowPermissions(): Set<ChannelPermission> {
        return ChannelPermission.fromMask(allowPermissionsMask)
    }

    /**
     * 거부 권한 목록 반환
     */
    fun getDenyPermissions(): Set<ChannelPermission> {
        return ChannelPermission.fromMask(denyPermissionsMask)
    }

    /**
     * 특정 권한이 명시적으로 허용되었는지 확인
     */
    fun isExplicitlyAllowed(permission: ChannelPermission): Boolean {
        return (allowPermissionsMask and permission.mask) != 0L
    }

    /**
     * 특정 권한이 명시적으로 거부되었는지 확인
     */
    fun isExplicitlyDenied(permission: ChannelPermission): Boolean {
        return (denyPermissionsMask and permission.mask) != 0L
    }

    companion object {
        /**
         * 추가 권한 부여를 위한 오버라이드 생성
         */
        fun createForAdditionalPermissions(
            channel: Channel,
            user: User,
            additionalPermissions: Set<ChannelPermission>
        ): ChannelMemberOverride {
            return ChannelMemberOverride(
                channel = channel,
                user = user,
                allowPermissionsMask = ChannelPermission.toMask(additionalPermissions)
            )
        }

        /**
         * 권한 제거를 위한 오버라이드 생성
         */
        fun createForDeniedPermissions(
            channel: Channel,
            user: User,
            deniedPermissions: Set<ChannelPermission>
        ): ChannelMemberOverride {
            return ChannelMemberOverride(
                channel = channel,
                user = user,
                denyPermissionsMask = ChannelPermission.toMask(deniedPermissions)
            )
        }

        /**
         * 혼합형 오버라이드 생성
         */
        fun createMixed(
            channel: Channel,
            user: User,
            additionalPermissions: Set<ChannelPermission> = emptySet(),
            deniedPermissions: Set<ChannelPermission> = emptySet()
        ): ChannelMemberOverride {
            val allowMask = ChannelPermission.toMask(additionalPermissions)
            val denyMask = ChannelPermission.toMask(deniedPermissions)

            // 충돌 사전 검증
            require(!ChannelPermission.hasConflict(allowMask, denyMask)) {
                "Allow 권한과 Deny 권한이 충돌합니다"
            }

            return ChannelMemberOverride(
                channel = channel,
                user = user,
                allowPermissionsMask = allowMask,
                denyPermissionsMask = denyMask
            )
        }
    }
}