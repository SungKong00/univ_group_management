package org.castlekong.backend.service

import org.castlekong.backend.entity.ChannelPermission
import org.castlekong.backend.entity.ChannelRoleBinding
import org.castlekong.backend.entity.ChannelMemberOverride
import org.castlekong.backend.repository.*
import org.springframework.cache.annotation.Cacheable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/**
 * 채널별 권한 계산 및 검증 서비스
 * 완전한 Deny 우선 정책과 권한 상속 규칙을 적용
 */
@Service
@Transactional(readOnly = true)
class ChannelPermissionService(
    private val channelRepository: ChannelRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val channelRoleBindingRepository: ChannelRoleBindingRepository,
    private val channelMemberOverrideRepository: ChannelMemberOverrideRepository,
    private val permissionVersionService: PermissionVersionService
) {

    /**
     * 🎯 핵심 권한 검증 메소드
     * 사용자가 특정 채널에서 특정 권한을 가지고 있는지 확인
     *
     * @param channelId 대상 채널 ID
     * @param userId 사용자 ID
     * @param required 필요한 권한
     * @return 권한 보유 여부
     */
    @Cacheable(
        value = ["channel-permissions"],
        key = "#channelId + ':' + #userId + ':' + #required.name + ':' + @permissionVersionService.getVersion(#channelId)"
    )
    fun hasChannelPermission(
        channelId: Long,
        userId: Long,
        required: ChannelPermission
    ): Boolean {
        // 1. 사용자의 그룹 역할 조회
        val userRoles = getUserRolesInChannel(channelId, userId)

        // 2. 채널에 바인딩된 역할과의 교집합
        val boundRoles = getBoundRoles(channelId, userRoles)

        // 3. PUBLIC 채널 예외 처리
        if (boundRoles.isEmpty()) {
            return isPublicChannel(channelId) && required == ChannelPermission.CHANNEL_VIEW
        }

        // 4. 역할 기반 권한 계산
        val roleMask = computeRoleMask(boundRoles)

        // 5. 멤버 오버라이드 적용
        val withOverride = applyMemberOverride(channelId, userId, roleMask)

        // 6. 권한 상속 규칙 적용
        val finalMask = ChannelPermission.applyInheritance(withOverride)

        // 7. CHANNEL_VIEW 게이트 + 요청 권한 확인
        return hasPermissionInMask(finalMask, ChannelPermission.CHANNEL_VIEW) &&
               hasPermissionInMask(finalMask, required)
    }

    /**
     * 사용자의 특정 채널에서의 모든 권한 조회
     */
    fun getUserChannelPermissions(channelId: Long, userId: Long): Set<ChannelPermission> {
        val userRoles = getUserRolesInChannel(channelId, userId)
        val boundRoles = getBoundRoles(channelId, userRoles)

        if (boundRoles.isEmpty()) {
            return if (isPublicChannel(channelId)) {
                setOf(ChannelPermission.CHANNEL_VIEW)
            } else emptySet()
        }

        val roleMask = computeRoleMask(boundRoles)
        val withOverride = applyMemberOverride(channelId, userId, roleMask)
        val finalMask = ChannelPermission.applyInheritance(withOverride)

        return ChannelPermission.fromMask(finalMask)
    }

    /**
     * 🔧 역할별 권한 Union 계산 (Deny 우선 정책 적용)
     */
    private fun computeRoleMask(bindings: List<ChannelRoleBinding>): Long {
        var acc = 0L
        for (binding in bindings) {
            val templateMask = binding.template?.permissionsMask ?: 0L
            val allow = binding.allowPermissionsMask
            val deny = binding.denyPermissionsMask

            // Deny 우선: (template ∪ allow) - deny
            val perBinding = ChannelPermission.applyDenyPolicy(templateMask or allow, deny)
            acc = acc or perBinding
        }
        return acc
    }

    /**
     * 멤버 오버라이드 적용
     */
    private fun applyMemberOverride(channelId: Long, userId: Long, roleMask: Long): Long {
        val override = channelMemberOverrideRepository.findByChannelIdAndUserId(channelId, userId)
        return override?.applyToRolePermissions(roleMask) ?: roleMask
    }

    /**
     * 사용자가 특정 채널의 그룹에서 가진 역할들 조회
     */
    private fun getUserRolesInChannel(channelId: Long, userId: Long): List<Long> {
        // 1. 채널에서 그룹 ID 조회
        val channel = channelRepository.findById(channelId).orElse(null) ?: return emptyList()
        val groupId = channel.group.id

        // 2. 해당 그룹에서 사용자의 역할들 조회
        val membership = groupMemberRepository.findByGroupIdAndUserId(groupId, userId).orElse(null)
            ?: return emptyList()

        return listOf(membership.role.id)
    }

    /**
     * 채널에 바인딩된 역할들 중 사용자가 가진 역할들 반환
     */
    private fun getBoundRoles(channelId: Long, userRoleIds: List<Long>): List<ChannelRoleBinding> {
        if (userRoleIds.isEmpty()) return emptyList()
        return channelRoleBindingRepository.findByChannelIdAndGroupRoleIdIn(channelId, userRoleIds)
    }

    /**
     * PUBLIC 채널 여부 확인
     */
    private fun isPublicChannel(channelId: Long): Boolean {
        return channelRepository.findById(channelId)
            .map { it.isPublic }
            .orElse(false)
    }

    /**
     * 비트마스크에서 특정 권한 보유 여부 확인
     */
    private fun hasPermissionInMask(mask: Long, permission: ChannelPermission): Boolean {
        return (mask and permission.mask) != 0L
    }

    // === 관리용 메소드들 ===

    /**
     * 채널의 모든 역할 바인딩 조회
     */
    fun getChannelRoleBindings(channelId: Long): List<ChannelRoleBinding> {
        return channelRoleBindingRepository.findByChannelId(channelId)
    }

    /**
     * 채널의 모든 멤버 오버라이드 조회
     */
    fun getChannelMemberOverrides(channelId: Long): List<ChannelMemberOverride> {
        return channelMemberOverrideRepository.findByChannelId(channelId)
    }

    /**
     * 특정 사용자의 채널별 오버라이드 조회
     */
    fun getUserChannelOverride(channelId: Long, userId: Long): ChannelMemberOverride? {
        return channelMemberOverrideRepository.findByChannelIdAndUserId(channelId, userId)
    }

    /**
     * 권한 충돌 검증
     */
    fun validateNoConflict(allowMask: Long, denyMask: Long) {
        require(!ChannelPermission.hasConflict(allowMask, denyMask)) {
            "Allow 권한과 Deny 권한이 충돌합니다: allow=${allowMask}, deny=${denyMask}"
        }
    }

    /**
     * 권한 상속 일관성 검증
     */
    fun validateInheritanceConsistency(allowMask: Long, denyMask: Long) {
        // POST_UPDATE_ALL 허용인데 POST_UPDATE_OWN 거부하는 모순 체크
        if (hasPermissionInMask(allowMask, ChannelPermission.POST_UPDATE_ALL) &&
            hasPermissionInMask(denyMask, ChannelPermission.POST_UPDATE_OWN)) {
            throw IllegalArgumentException("POST_UPDATE_ALL 허용과 POST_UPDATE_OWN 거부가 모순됩니다")
        }

        if (hasPermissionInMask(allowMask, ChannelPermission.POST_DELETE_ALL) &&
            hasPermissionInMask(denyMask, ChannelPermission.POST_DELETE_OWN)) {
            throw IllegalArgumentException("POST_DELETE_ALL 허용과 POST_DELETE_OWN 거부가 모순됩니다")
        }

        if (hasPermissionInMask(allowMask, ChannelPermission.COMMENT_UPDATE_ALL) &&
            hasPermissionInMask(denyMask, ChannelPermission.COMMENT_UPDATE_OWN)) {
            throw IllegalArgumentException("COMMENT_UPDATE_ALL 허용과 COMMENT_UPDATE_OWN 거부가 모순됩니다")
        }

        if (hasPermissionInMask(allowMask, ChannelPermission.COMMENT_DELETE_ALL) &&
            hasPermissionInMask(denyMask, ChannelPermission.COMMENT_DELETE_OWN)) {
            throw IllegalArgumentException("COMMENT_DELETE_ALL 허용과 COMMENT_DELETE_OWN 거부가 모순됩니다")
        }
    }

    /**
     * 채널이 속한 그룹 ID 조회
     */
    fun getChannelGroupId(channelId: Long): Long {
        return channelRepository.findById(channelId)
            .map { it.group.id }
            .orElseThrow { IllegalArgumentException("Channel not found: $channelId") }
    }
}