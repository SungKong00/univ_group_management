package org.castlekong.backend.service

import org.castlekong.backend.dto.AdminStatsResponse
import org.castlekong.backend.entity.GroupJoinRequestStatus
import org.castlekong.backend.repository.ChannelRepository
import org.castlekong.backend.repository.GroupJoinRequestRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class AdminStatsService(
    private val groupRepository: GroupRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val groupRoleRepository: GroupRoleRepository,
    private val channelRepository: ChannelRepository,
    private val groupJoinRequestRepository: GroupJoinRequestRepository,
) {
    fun getStats(groupId: Long): AdminStatsResponse {
        // 존재 체크 (없으면 예외)
        groupRepository.findById(groupId).orElseThrow { IllegalArgumentException("Group not found: $groupId") }

        val pending = groupJoinRequestRepository.countByGroupIdAndStatus(groupId, GroupJoinRequestStatus.PENDING)
        val members = groupMemberRepository.countByGroupId(groupId)
        val roles = groupRoleRepository.findByGroupId(groupId).size.toLong()
        val channels =
            try {
                // 새로 추가한 count 메서드 사용 (없는 경우 size 계산 fallback)
                channelRepository.countByGroup_Id(groupId)
            } catch (e: Exception) {
                channelRepository.findByGroup_Id(groupId).size.toLong()
            }
        return AdminStatsResponse(
            pendingCount = pending.toInt(),
            memberCount = members.toInt(),
            roleCount = roles.toInt(),
            channelCount = channels.toInt(),
        )
    }
}
