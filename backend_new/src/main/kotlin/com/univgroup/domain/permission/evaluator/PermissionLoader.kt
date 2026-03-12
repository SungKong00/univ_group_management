package com.univgroup.domain.permission.evaluator

import com.univgroup.domain.group.repository.GroupMemberRepository
import com.univgroup.domain.group.repository.GroupRepository
import com.univgroup.domain.permission.ChannelPermission
import com.univgroup.domain.permission.GroupPermission
import com.univgroup.domain.permission.repository.ChannelRoleBindingRepository
import com.univgroup.domain.workspace.repository.ChannelRepository
import org.springframework.stereotype.Component

/**
 * 권한 로더
 *
 * 데이터베이스에서 권한 정보를 조회하는 역할.
 * PermissionEvaluator에서 캐시 미스 시 호출된다.
 */
@Component
class PermissionLoader(
    private val groupRepository: GroupRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val channelRepository: ChannelRepository,
    private val channelRoleBindingRepository: ChannelRoleBindingRepository,
) {
    /**
     * 사용자의 그룹 권한 로드
     *
     * 로직:
     * 1. GroupMember에서 사용자의 역할 조회
     * 2. GroupRole에서 역할의 권한 집합 조회
     * 3. 권한 집합 반환
     */
    fun loadGroupPermissions(
        userId: Long,
        groupId: Long,
    ): Set<GroupPermission> {
        val member =
            groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                ?: return emptySet()
        return member.role.permissions.toSet()
    }

    /**
     * 사용자의 채널 권한 로드
     *
     * 로직:
     * 1. 채널의 그룹 ID 조회
     * 2. GroupMember에서 사용자의 역할 조회
     * 3. ChannelRoleBinding에서 역할-채널 권한 조회
     * 4. 권한 집합 반환
     */
    fun loadChannelPermissions(
        userId: Long,
        channelId: Long,
    ): Set<ChannelPermission> {
        val channel =
            channelRepository.findById(channelId).orElse(null)
                ?: return emptySet()

        // Channel has direct reference to Group, no need to go through Workspace
        val member =
            groupMemberRepository.findByGroupIdAndUserId(channel.group.id!!, userId)
                ?: return emptySet()

        val binding =
            channelRoleBindingRepository.findByChannelIdAndGroupRoleId(channelId, member.role.id!!)
                ?: return emptySet()

        return binding.permissions.toSet()
    }

    /**
     * 사용자가 그룹 멤버인지 확인
     */
    fun isMember(
        userId: Long,
        groupId: Long,
    ): Boolean {
        return groupMemberRepository.existsByGroupIdAndUserId(groupId, userId)
    }

    /**
     * 사용자가 그룹 소유자인지 확인
     */
    fun isOwner(
        userId: Long,
        groupId: Long,
    ): Boolean {
        val group =
            groupRepository.findById(groupId).orElse(null)
                ?: return false
        return group.owner.id == userId
    }
}
