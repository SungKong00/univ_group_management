package com.univgroup.domain.group.dto

import com.univgroup.domain.group.entity.GroupMember
import java.time.LocalDateTime

/**
 * 그룹 멤버 응답 DTO
 */
data class GroupMemberDto(
    val id: Long,
    val userId: Long,
    val userName: String,
    val userNickname: String?,
    val userProfileImageUrl: String?,
    val roleId: Long,
    val roleName: String,
    val isSystemRole: Boolean,
    val rolePriority: Int,
    val joinedAt: LocalDateTime,
) {
    companion object {
        fun from(member: GroupMember): GroupMemberDto {
            return GroupMemberDto(
                id = member.id!!,
                userId = member.user.id!!,
                userName = member.user.name,
                userNickname = member.user.nickname,
                userProfileImageUrl = member.user.profileImageUrl,
                roleId = member.role.id!!,
                roleName = member.role.name,
                isSystemRole = member.role.isSystemRole,
                rolePriority = member.role.priority,
                joinedAt = member.joinedAt,
            )
        }
    }
}

/**
 * 멤버 추가 요청 DTO
 */
data class AddMemberRequest(
    val userId: Long,
    val roleId: Long,
)

/**
 * 멤버 역할 변경 요청 DTO
 */
data class ChangeMemberRoleRequest(
    val roleId: Long,
)

/**
 * 사용자의 그룹 멤버십 DTO
 */
data class UserMembershipDto(
    val groupId: Long,
    val groupName: String,
    val groupType: String,
    val roleId: Long,
    val roleName: String,
    val joinedAt: LocalDateTime,
) {
    companion object {
        fun from(member: GroupMember): UserMembershipDto {
            return UserMembershipDto(
                groupId = member.group.id!!,
                groupName = member.group.name,
                groupType = member.group.groupType.name,
                roleId = member.role.id!!,
                roleName = member.role.name,
                joinedAt = member.joinedAt,
            )
        }
    }
}
