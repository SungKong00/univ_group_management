package org.castlekong.backend.service

import org.castlekong.backend.dto.CreateGroupRequest
import org.castlekong.backend.dto.GroupResponse
import org.castlekong.backend.dto.GroupSummaryResponse
import org.castlekong.backend.dto.UpdateGroupRequest
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupType
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.UserRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Pageable
import org.springframework.data.domain.Sort
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Service
@Transactional(readOnly = true)
class GroupService(
    private val groupRepository: GroupRepository,
    private val userRepository: UserRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val groupMapper: GroupMapper,
) {
    @Transactional
    fun createGroup(
        request: CreateGroupRequest,
        ownerId: Long,
    ): Group {
        val owner =
            userRepository.findById(ownerId)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        // 부모 그룹 확인 (하위 그룹 생성 시)
        val parentGroup =
            request.parentId?.let { parentId ->
                groupRepository.findById(parentId)
                    .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
            }

        val group =
            Group(
                name = request.name,
                description = request.description,
                profileImageUrl = request.profileImageUrl,
                owner = owner,
                parent = parentGroup,
                university = request.university,
                college = request.college,
                department = request.department,
                groupType = request.groupType,
                maxMembers = request.maxMembers,
                tags = request.tags,
            )

        return groupRepository.save(group)
    }

    fun getGroup(groupId: Long): GroupResponse {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        if (group.deletedAt != null) throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        return groupMapper.toGroupResponse(group)
    }

    fun getGroups(pageable: Pageable): Page<GroupSummaryResponse> {
        val sortedPageable =
            PageRequest.of(pageable.pageNumber, pageable.pageSize, Sort.by(Sort.Direction.DESC, "createdAt", "id"))
        return groupRepository.findByDeletedAtIsNull(sortedPageable)
            .map { group ->
                val memberCount = getGroupMemberCountWithHierarchy(group)
                groupMapper.toGroupSummaryResponse(group, memberCount.toInt())
            }
    }

    fun getAllGroups(): List<GroupSummaryResponse> {
        return getAllGroupsChunked()
    }

    fun getAllGroupsChunked(chunkSize: Int = 100): List<GroupSummaryResponse> {
        val allGroups = mutableListOf<GroupSummaryResponse>()
        var offset = 0

        do {
            val chunk =
                groupRepository.findAll(PageRequest.of(offset / chunkSize, chunkSize))
                    .content
                    .filter { it.deletedAt == null }
                    .map { group ->
                        val memberCount = getGroupMemberCountWithHierarchy(group)
                        groupMapper.toGroupSummaryResponse(group, memberCount.toInt())
                    }

            allGroups.addAll(chunk)
            offset += chunkSize
        } while (chunk.size == chunkSize)

        return allGroups
    }

    fun getGroupMemberCountWithHierarchy(group: Group): Long {
        return when (group.groupType) {
            GroupType.UNIVERSITY, GroupType.COLLEGE -> {
                // 대학교나 계열인 경우 하위 그룹 멤버들도 포함하여 집계
                // H2 호환: 2단계 쿼리 (하위 그룹 ID 조회 + IN 쿼리)
                val descendantIds = groupRepository.findAllDescendantIds(group.id)
                if (descendantIds.isEmpty()) {
                    0L
                } else {
                    groupMemberRepository.countByGroupIdIn(descendantIds)
                }
            }

            else -> {
                // 학과나 기타 그룹인 경우 직접 가입 멤버만 집계
                groupMemberRepository.countByGroupId(group.id)
            }
        }
    }

    @Transactional
    fun updateGroup(
        groupId: Long,
        request: UpdateGroupRequest,
        userId: Long,
    ): GroupResponse {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 권한 확인 (그룹 소유자만 수정 가능)
        if (group.owner.id != userId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }

        // 새 Group 객체 생성 (data class copy() 제거됨)
        val updatedGroup =
            Group(
                id = group.id,
                name = request.name ?: group.name,
                description = request.description ?: group.description,
                profileImageUrl = request.profileImageUrl ?: group.profileImageUrl,
                owner = group.owner,
                parent = group.parent,
                university = group.university,
                college = group.college,
                department = group.department,
                groupType = request.groupType ?: group.groupType,
                maxMembers = request.maxMembers ?: group.maxMembers,
                defaultChannelsCreated = group.defaultChannelsCreated,
                tags = request.tags ?: group.tags,
                createdAt = group.createdAt,
                updatedAt = LocalDateTime.now(),
                deletedAt = group.deletedAt,
            )

        return groupMapper.toGroupResponse(groupRepository.save(updatedGroup))
    }

    fun searchGroups(
        pageable: Pageable,
        recruiting: Boolean?,
        groupTypes: List<GroupType>,
        university: String?,
        college: String?,
        department: String?,
        q: String?,
        tags: Set<String>,
    ): Page<GroupSummaryResponse> {
        return groupRepository.search(
            recruiting,
            groupTypes,
            groupTypes.size,
            university,
            college,
            department,
            q,
            tags,
            tags.size,
            // 현재 시각 전달
            LocalDateTime.now(),
            pageable,
        ).map { g ->
            val memberCount = getGroupMemberCountWithHierarchy(g)
            groupMapper.toGroupSummaryResponse(g, memberCount.toInt())
        }
    }
}
