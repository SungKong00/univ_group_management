package org.castlekong.backend.service

import org.castlekong.backend.dto.*
import org.castlekong.backend.entity.*
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.*
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Service
@Transactional(readOnly = true)
class GroupRequestService(
    private val groupRepository: GroupRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val groupRoleRepository: GroupRoleRepository,
    private val userRepository: UserRepository,
    private val groupJoinRequestRepository: GroupJoinRequestRepository,
    private val subGroupRequestRepository: SubGroupRequestRepository,
    private val groupMapper: GroupMapper,
    private val groupManagementService: GroupManagementService,
) {
    // === 하위 그룹 생성 신청 관련 메서드들 ===

    @Transactional
    fun createSubGroupRequest(
        parentGroupId: Long,
        request: CreateSubGroupRequest,
        requesterId: Long,
    ): SubGroupRequestResponse {
        val requester =
            userRepository.findById(requesterId)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        val parentGroup =
            groupRepository.findById(parentGroupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        val subGroupRequest =
            SubGroupRequest(
                requester = requester,
                parentGroup = parentGroup,
                requestedGroupName = request.requestedGroupName,
                requestedGroupDescription = request.requestedGroupDescription,
                requestedUniversity = request.requestedUniversity,
                requestedCollege = request.requestedCollege,
                requestedDepartment = request.requestedDepartment,
                requestedGroupType = request.requestedGroupType,
                requestedMaxMembers = request.requestedMaxMembers,
            )

        val saved = subGroupRequestRepository.save(subGroupRequest)
        val memberCount = groupMemberRepository.countByGroupId(parentGroup.id).toInt()
        return groupMapper.toSubGroupRequestResponse(saved, memberCount)
    }

    fun getSubGroupRequestsByParentGroup(parentGroupId: Long): List<SubGroupRequestResponse> {
        if (!groupRepository.existsById(parentGroupId)) {
            throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        }

        return subGroupRequestRepository.findByParentGroupId(parentGroupId)
            .map {
                val memberCount = groupMemberRepository.countByGroupId(it.parentGroup.id).toInt()
                groupMapper.toSubGroupRequestResponse(it, memberCount)
            }
    }

    @Transactional
    fun reviewSubGroupRequest(
        requestId: Long,
        reviewRequest: ReviewSubGroupRequestRequest,
        reviewerId: Long,
    ): SubGroupRequestResponse {
        val request =
            subGroupRequestRepository.findById(requestId)
                .orElseThrow { BusinessException(ErrorCode.REQUEST_NOT_FOUND) }

        val reviewer =
            userRepository.findById(reviewerId)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        // 그룹장만 승인/반려 가능
        if (request.parentGroup.owner.id != reviewerId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }

        val status =
            when (reviewRequest.action) {
                "APPROVE" -> SubGroupRequestStatus.APPROVED
                "REJECT" -> SubGroupRequestStatus.REJECTED
                else -> throw BusinessException(ErrorCode.INVALID_REQUEST)
            }

        val updatedRequest =
            request.copy(
                status = status,
                responseMessage = reviewRequest.responseMessage,
                reviewedBy = reviewer,
                reviewedAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now(),
            )

        val saved = subGroupRequestRepository.save(updatedRequest)

        // 승인 시 실제 하위 그룹 생성
        if (status == SubGroupRequestStatus.APPROVED) {
            val createGroupRequest =
                CreateGroupRequest(
                    name = request.requestedGroupName,
                    description = request.requestedGroupDescription,
                    parentId = request.parentGroup.id,
                    university = request.requestedUniversity,
                    college = request.requestedCollege,
                    department = request.requestedDepartment,
                    groupType = request.requestedGroupType,
                    maxMembers = request.requestedMaxMembers,
                )
            groupManagementService.createGroup(createGroupRequest, request.requester.id)
        }

        val memberCount = groupMemberRepository.countByGroupId(request.parentGroup.id).toInt()
        return groupMapper.toSubGroupRequestResponse(saved, memberCount)
    }

    // === 그룹 가입 신청 관련 메서드들 ===

    @Transactional
    fun createGroupJoinRequest(
        groupId: Long,
        requestMessage: String?,
        userId: Long,
    ): GroupJoinRequestResponse {
        val user =
            userRepository.findById(userId)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 이미 멤버인지 확인
        if (groupMemberRepository.findByGroupIdAndUserId(groupId, userId).isPresent) {
            throw BusinessException(ErrorCode.ALREADY_GROUP_MEMBER)
        }

        // 이미 대기 중인 신청이 있는지 확인
        if (groupJoinRequestRepository.findByGroupIdAndUserId(groupId, userId).isPresent) {
            throw BusinessException(ErrorCode.REQUEST_ALREADY_EXISTS)
        }

        val joinRequest =
            GroupJoinRequest(
                group = group,
                user = user,
                requestMessage = requestMessage,
            )

        val saved = groupJoinRequestRepository.save(joinRequest)
        val memberCount = groupMemberRepository.countByGroupId(group.id).toInt()
        return groupMapper.toGroupJoinRequestResponse(saved, memberCount)
    }

    fun getGroupJoinRequestsByGroup(groupId: Long): List<GroupJoinRequestResponse> {
        if (!groupRepository.existsById(groupId)) {
            throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        }

        return groupJoinRequestRepository.findByGroupIdAndStatus(groupId, GroupJoinRequestStatus.PENDING)
            .map {
                val memberCount = groupMemberRepository.countByGroupId(it.group.id).toInt()
                groupMapper.toGroupJoinRequestResponse(it, memberCount)
            }
    }

    @Transactional
    fun reviewGroupJoinRequest(
        requestId: Long,
        reviewRequest: ReviewGroupJoinRequestRequest,
        reviewerId: Long,
    ): GroupJoinRequestResponse {
        val request =
            groupJoinRequestRepository.findById(requestId)
                .orElseThrow { BusinessException(ErrorCode.REQUEST_NOT_FOUND) }

        val reviewer =
            userRepository.findById(reviewerId)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        // 그룹장만 승인/반려 가능
        if (request.group.owner.id != reviewerId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }

        val status =
            when (reviewRequest.action) {
                "APPROVE" -> GroupJoinRequestStatus.APPROVED
                "REJECT" -> GroupJoinRequestStatus.REJECTED
                else -> throw BusinessException(ErrorCode.INVALID_REQUEST)
            }

        val updatedRequest =
            request.copy(
                status = status,
                responseMessage = reviewRequest.responseMessage,
                reviewedBy = reviewer,
                reviewedAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now(),
            )

        val saved = groupJoinRequestRepository.save(updatedRequest)

        // 승인 시 실제 그룹에 멤버 추가
        if (status == GroupJoinRequestStatus.APPROVED) {
            val memberRole =
                groupRoleRepository.findByGroupIdAndName(request.group.id, "MEMBER")
                    .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }

            val groupMember =
                GroupMember(
                    group = request.group,
                    user = request.user,
                    role = memberRole,
                    joinedAt = LocalDateTime.now(),
                )
            groupMemberRepository.save(groupMember)
        }

        val memberCount = groupMemberRepository.countByGroupId(request.group.id).toInt()
        return groupMapper.toGroupJoinRequestResponse(saved, memberCount)
    }
}
