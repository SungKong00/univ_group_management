package org.castlekong.backend.service

import org.castlekong.backend.dto.*
import org.castlekong.backend.entity.*
import org.springframework.stereotype.Component

@Component
class GroupMapper {
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
            visibility = group.visibility,
            groupType = group.groupType,
            isRecruiting = group.isRecruiting,
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
            visibility = group.visibility,
            groupType = group.groupType,
            isRecruiting = group.isRecruiting,
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
