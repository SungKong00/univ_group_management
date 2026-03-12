package org.castlekong.backend.service

import org.castlekong.backend.dto.GroupHierarchyNodeDto
import org.castlekong.backend.dto.GroupSummaryResponse
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.GroupRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class GroupHierarchyService(
    private val groupRepository: GroupRepository,
    private val groupService: GroupService,
    private val groupMapper: GroupMapper,
) {
    fun getAllGroupsForHierarchy(): List<GroupHierarchyNodeDto> {
        return groupRepository.findAll()
            .filter { it.deletedAt == null }
            .map { group ->
                val memberCount = groupService.getGroupMemberCountWithHierarchy(group)
                val isRecruiting = groupMapper.isGroupActuallyRecruiting(group)

                GroupHierarchyNodeDto(
                    id = group.id,
                    parentId = group.parent?.id,
                    name = group.name,
                    type = group.groupType,
                    isRecruiting = isRecruiting,
                    memberCount = memberCount.toInt(),
                )
            }
    }

    fun getSubGroups(parentGroupId: Long): List<GroupSummaryResponse> {
        if (!groupRepository.existsById(parentGroupId)) {
            throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        }

        return groupRepository.findByParentId(parentGroupId)
            .filter { it.deletedAt == null }
            .map { subGroup ->
                val memberCount = groupService.getGroupMemberCountWithHierarchy(subGroup)
                groupMapper.toGroupSummaryResponse(subGroup, memberCount.toInt())
            }
    }
}
