package org.castlekong.backend.service

import org.castlekong.backend.dto.ChannelRoleBindingResponse
import org.castlekong.backend.dto.CreateChannelRoleBindingRequest
import org.castlekong.backend.dto.UpdateChannelRoleBindingRequest
import org.castlekong.backend.entity.ChannelPermission
import org.castlekong.backend.entity.ChannelRoleBinding
import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.ChannelRepository
import org.castlekong.backend.repository.ChannelRoleBindingRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/**
 * 채널 권한 관리 서비스 (MVP 단순화 버전)
 * 개인 오버라이드 및 복잡한 템플릿 시스템 제거
 */
@Service
@Transactional
class ChannelPermissionManagementService(
    private val channelRepository: ChannelRepository,
    private val groupRoleRepository: GroupRoleRepository,
    private val channelRoleBindingRepository: ChannelRoleBindingRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val groupRepository: GroupRepository,
) {
    // === 권한 검증 헬퍼 메서드 ===

    /**
     * CHANNEL_MANAGE 권한 확인
     * - 그룹 소유자는 무조건 통과
     * - 그룹 멤버는 CHANNEL_MANAGE 권한 필요
     */
    private fun validateChannelManagePermission(
        groupId: Long,
        userId: Long,
    ) {
        val group =
            groupRepository.findByIdOrNull(groupId)
                ?: throw BusinessException(ErrorCode.GROUP_NOT_FOUND)

        // 그룹 소유자는 모든 권한 보유
        if (group.owner.id == userId) return

        // 멤버 조회
        val member =
            groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElse(null) ?: throw BusinessException(ErrorCode.FORBIDDEN)

        // 역할 권한 확인 (시스템 역할 + 커스텀 역할)
        val rolePerms =
            if (member.role.isSystemRole) {
                when (member.role.name.uppercase()) {
                    "그룹장" -> GroupPermission.entries.toSet()
                    "교수" -> GroupPermission.entries.toSet()
                    else -> emptySet()
                }
            } else {
                member.role.permissions
            }

        if (!rolePerms.contains(GroupPermission.CHANNEL_MANAGE)) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
    }

    // === 채널 역할 바인딩 관리 ===

    @Transactional(readOnly = true)
    fun getChannelRoleBindings(channelId: Long): List<ChannelRoleBindingResponse> {
        val bindings = channelRoleBindingRepository.findByChannelId(channelId)
        return bindings.map { binding ->
            ChannelRoleBindingResponse(
                id = binding.id,
                channelId = binding.channel.id,
                groupRoleId = binding.groupRole.id,
                groupRoleName = binding.groupRole.name,
                permissions = binding.permissions,
            )
        }
    }

    fun createChannelRoleBinding(
        channelId: Long,
        request: CreateChannelRoleBindingRequest,
        userId: Long,
    ): ChannelRoleBindingResponse {
        val channel =
            channelRepository.findByIdOrNull(channelId)
                ?: throw BusinessException(ErrorCode.CHANNEL_NOT_FOUND)

        // CHANNEL_MANAGE 권한 검증
        validateChannelManagePermission(channel.group.id, userId)

        val groupRole =
            groupRoleRepository.findByIdOrNull(request.groupRoleId)
                ?: throw BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND)

        // 역할이 같은 그룹에 속하는지 확인
        if (groupRole.group.id != channel.group.id) {
            throw BusinessException(ErrorCode.INVALID_REQUEST)
        }

        // 중복 바인딩 확인
        val existingBinding = channelRoleBindingRepository.findByChannelIdAndGroupRoleId(channelId, request.groupRoleId)
        if (existingBinding != null) {
            throw BusinessException(ErrorCode.INVALID_REQUEST)
        }

        val binding =
            ChannelRoleBinding.create(
                channel = channel,
                groupRole = groupRole,
                permissions = request.permissions,
            )

        val savedBinding = channelRoleBindingRepository.save(binding)

        return ChannelRoleBindingResponse(
            id = savedBinding.id,
            channelId = savedBinding.channel.id,
            groupRoleId = savedBinding.groupRole.id,
            groupRoleName = savedBinding.groupRole.name,
            permissions = savedBinding.permissions,
        )
    }

    fun updateChannelRoleBinding(
        bindingId: Long,
        request: UpdateChannelRoleBindingRequest,
    ): ChannelRoleBindingResponse {
        val binding =
            channelRoleBindingRepository.findByIdOrNull(bindingId)
                ?: throw IllegalArgumentException("Channel role binding not found: $bindingId")

        val updatedBinding =
            binding.copy(
                permissions = request.permissions ?: binding.permissions,
            )

        val savedBinding = channelRoleBindingRepository.save(updatedBinding)

        return ChannelRoleBindingResponse(
            id = savedBinding.id,
            channelId = savedBinding.channel.id,
            groupRoleId = savedBinding.groupRole.id,
            groupRoleName = savedBinding.groupRole.name,
            permissions = savedBinding.permissions,
        )
    }

    fun deleteChannelRoleBinding(bindingId: Long) {
        val binding =
            channelRoleBindingRepository.findByIdOrNull(bindingId)
                ?: throw IllegalArgumentException("Channel role binding not found: $bindingId")

        channelRoleBindingRepository.delete(binding)
    }

    // === 사용자 권한 조회 ===

    @Transactional(readOnly = true)
    fun getUserChannelPermissions(
        channelId: Long,
        userId: Long,
    ): Set<ChannelPermission> {
        val channel =
            channelRepository.findByIdOrNull(channelId)
                ?: throw IllegalArgumentException("Channel not found: $channelId")

        val member =
            groupMemberRepository.findByGroupIdAndUserId(channel.group.id, userId)
                .orElse(null) ?: return emptySet()

        val binding =
            channelRoleBindingRepository.findByChannelIdAndGroupRoleId(channelId, member.role.id)
                ?: return emptySet()

        return binding.permissions
    }

    @Transactional(readOnly = true)
    fun hasChannelPermission(
        channelId: Long,
        userId: Long,
        permission: ChannelPermission,
    ): Boolean {
        val userPermissions = getUserChannelPermissions(channelId, userId)
        return userPermissions.contains(permission)
    }
}
