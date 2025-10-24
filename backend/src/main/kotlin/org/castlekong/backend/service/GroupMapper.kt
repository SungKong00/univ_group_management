package org.castlekong.backend.service

import org.castlekong.backend.dto.GroupJoinRequestResponse
import org.castlekong.backend.dto.GroupMemberResponse
import org.castlekong.backend.dto.GroupResponse
import org.castlekong.backend.dto.GroupRoleResponse
import org.castlekong.backend.dto.GroupSummaryResponse
import org.castlekong.backend.dto.SubGroupRequestResponse
import org.castlekong.backend.dto.UserSummaryResponse
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupJoinRequest
import org.castlekong.backend.entity.GroupMember
import org.castlekong.backend.entity.GroupRole
import org.castlekong.backend.entity.SubGroupRequest
import org.castlekong.backend.entity.User
import org.castlekong.backend.repository.GroupRecruitmentRepository
import org.springframework.stereotype.Component
import java.time.LocalDateTime

@Component
class GroupMapper(
    private val groupRecruitmentRepository: GroupRecruitmentRepository,
) {
    /**
     * 그룹의 실제 모집 중 상태를 확인
     * - 활성 모집 공고가 존재하는지 확인
     * - 모집 공고 상태가 OPEN
     * - 현재 시각이 모집 기간 내
     */
    fun isGroupActuallyRecruiting(group: Group): Boolean {
        val now = LocalDateTime.now()
        return groupRecruitmentRepository.findByGroupId(group.id).any { recruitment ->
            recruitment.status == org.castlekong.backend.entity.RecruitmentStatus.OPEN &&
                recruitment.recruitmentStartDate <= now &&
                (recruitment.recruitmentEndDate == null || recruitment.recruitmentEndDate!! > now)
        }
    }

    fun toGroupResponse(group: Group): GroupResponse {
        return GroupResponse(
            id = group.id,
            name = group.name,
            description = group.description,
            profileImageUrl = group.profileImageUrl,
            owner = toUserSummaryResponse(group.owner),
            university = group.university,
            college = group.college,
            department = group.department,
            groupType = group.groupType,
            // 실제 모집 상태 확인
            isRecruiting = isGroupActuallyRecruiting(group),
            maxMembers = group.maxMembers,
            tags = group.tags,
            createdAt = group.createdAt,
            updatedAt = group.updatedAt,
        )
    }

    fun toGroupSummaryResponse(
        group: Group,
        memberCount: Int,
    ): GroupSummaryResponse {
        return GroupSummaryResponse(
            id = group.id,
            name = group.name,
            description = group.description,
            profileImageUrl = group.profileImageUrl,
            university = group.university,
            college = group.college,
            department = group.department,
            groupType = group.groupType,
            // 실제 모집 상태 확인
            isRecruiting = isGroupActuallyRecruiting(group),
            memberCount = memberCount,
            tags = group.tags,
        )
    }

    fun toGroupMemberResponse(groupMember: GroupMember): GroupMemberResponse {
        return GroupMemberResponse(
            id = groupMember.id,
            user = toUserSummaryResponse(groupMember.user),
            role = toGroupRoleResponse(groupMember.role),
            joinedAt = groupMember.joinedAt,
        )
    }

    fun toMemberBasicResponse(groupMember: GroupMember): org.castlekong.backend.dto.MemberBasicResponse {
        return org.castlekong.backend.dto.MemberBasicResponse(
            id = groupMember.id,
            user =
                org.castlekong.backend.dto.UserBasicInfo(
                    id = groupMember.user.id,
                    name = groupMember.user.name,
                    profileImageUrl = groupMember.user.profileImageUrl,
                    studentNo = groupMember.user.studentNo,
                    academicYear = groupMember.user.academicYear,
                ),
            role =
                org.castlekong.backend.dto.RoleBasicInfo(
                    id = groupMember.role.id,
                    name = groupMember.role.name,
                ),
        )
    }

    fun toGroupRoleResponse(groupRole: GroupRole): GroupRoleResponse {
        return GroupRoleResponse(
            id = groupRole.id,
            name = groupRole.name,
            permissions = groupRole.permissions.map { it.name }.toSet(),
            priority = groupRole.priority,
        )
    }

    fun toUserSummaryResponse(user: User): UserSummaryResponse {
        return UserSummaryResponse(
            id = user.id,
            name = user.name,
            email = user.email,
            profileImageUrl = user.profileImageUrl,
            studentNo = user.studentNo,
            academicYear = user.academicYear,
        )
    }

    fun toSubGroupRequestResponse(
        request: SubGroupRequest,
        memberCount: Int,
    ): SubGroupRequestResponse {
        return SubGroupRequestResponse(
            id = request.id,
            requester = toUserSummaryResponse(request.requester),
            parentGroup = toGroupSummaryResponse(request.parentGroup, memberCount),
            requestedGroupName = request.requestedGroupName,
            requestedGroupDescription = request.requestedGroupDescription,
            requestedUniversity = request.requestedUniversity,
            requestedCollege = request.requestedCollege,
            requestedDepartment = request.requestedDepartment,
            requestedGroupType = request.requestedGroupType,
            requestedMaxMembers = request.requestedMaxMembers,
            status = request.status.name,
            responseMessage = request.responseMessage,
            reviewedBy = request.reviewedBy?.let { toUserSummaryResponse(it) },
            reviewedAt = request.reviewedAt,
            createdAt = request.createdAt,
            updatedAt = request.updatedAt,
        )
    }

    fun toGroupJoinRequestResponse(
        request: GroupJoinRequest,
        memberCount: Int,
    ): GroupJoinRequestResponse {
        return GroupJoinRequestResponse(
            id = request.id,
            group = toGroupSummaryResponse(request.group, memberCount),
            user = toUserSummaryResponse(request.user),
            requestMessage = request.requestMessage,
            status = request.status.name,
            responseMessage = request.responseMessage,
            reviewedBy = request.reviewedBy?.let { toUserSummaryResponse(it) },
            reviewedAt = request.reviewedAt,
            createdAt = request.createdAt,
            updatedAt = request.updatedAt,
        )
    }
}
