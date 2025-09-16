package org.castlekong.backend.security

import org.castlekong.backend.entity.ChannelPermission
import org.castlekong.backend.repository.ChannelRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.UserRepository
import org.castlekong.backend.service.ChannelPermissionService
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Component

@Component("security")
class SecurityExpressionHelper(
    private val groupPermissionEvaluator: GroupPermissionEvaluator,
    private val groupRepository: GroupRepository,
    private val userRepository: UserRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val channelRepository: ChannelRepository,
    private val channelPermissionService: ChannelPermissionService,
) {
    fun hasGroupPerm(
        groupId: Long,
        permission: String,
    ): Boolean {
        val auth = SecurityContextHolder.getContext().authentication
        return groupPermissionEvaluator.hasPermission(auth, groupId, "GROUP", permission)
    }

    fun isOwner(groupId: Long): Boolean {
        val auth = SecurityContextHolder.getContext().authentication
        val email = auth?.name ?: return false
        val user = userRepository.findByEmail(email).orElse(null) ?: return false
        val group = groupRepository.findById(groupId).orElse(null) ?: return false
        return group.owner.id == user.id
    }

    /**
     * 사용자가 특정 그룹의 멤버인지 확인
     * 워크스페이스 접근 권한 검증에 사용
     */
    fun isGroupMember(groupId: Long): Boolean {
        val auth = SecurityContextHolder.getContext().authentication
        val email = auth?.name ?: return false
        val user = userRepository.findByEmail(email).orElse(null) ?: return false
        return groupMemberRepository.findByGroupIdAndUserId(groupId, user.id).isPresent
    }

    /**
     * 사용자가 특정 채널에서 특정 권한을 가지고 있는지 확인
     * 채널 권한 검증에 사용
     */
    fun hasChannelPermission(channelId: Long, permission: String): Boolean {
        val auth = SecurityContextHolder.getContext().authentication
        val email = auth?.name ?: return false
        val user = userRepository.findByEmail(email).orElse(null) ?: return false

        val channelPermission = try {
            ChannelPermission.valueOf(permission)
        } catch (e: IllegalArgumentException) {
            return false
        }

        return channelPermissionService.hasChannelPermission(channelId, user.id, channelPermission)
    }

    /**
     * 채널이 속한 그룹 ID 조회 (권한 검증용 헬퍼)
     */
    fun getChannelGroupId(channelId: Long): Long {
        return channelRepository.findById(channelId)
            .map { it.group.id }
            .orElseThrow { IllegalArgumentException("Channel not found: $channelId") }
    }
}
