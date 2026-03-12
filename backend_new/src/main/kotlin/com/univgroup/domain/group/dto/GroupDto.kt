package com.univgroup.domain.group.dto

import com.univgroup.domain.group.entity.Group
import com.univgroup.domain.group.entity.GroupType
import java.time.LocalDateTime

/**
 * 그룹 응답 DTO
 */
data class GroupDto(
    val id: Long,
    val name: String,
    val description: String?,
    val ownerId: Long,
    val ownerName: String,
    val parentId: Long?,
    val university: String?,
    val college: String?,
    val department: String?,
    val groupType: GroupType,
    val profileImageUrl: String?,
    val tags: Set<String>,
    val memberCount: Int?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
) {
    companion object {
        fun from(
            group: Group,
            memberCount: Int? = null,
        ): GroupDto {
            return GroupDto(
                id = group.id!!,
                name = group.name,
                description = group.description,
                ownerId = group.owner.id!!,
                ownerName = group.owner.name,
                parentId = group.parent?.id,
                university = group.university,
                college = group.college,
                department = group.department,
                groupType = group.groupType,
                profileImageUrl = group.profileImageUrl,
                tags = group.tags.toSet(),
                memberCount = memberCount,
                createdAt = group.createdAt,
                updatedAt = group.updatedAt,
            )
        }
    }
}

/**
 * 그룹 요약 DTO (목록용)
 */
data class GroupSummaryDto(
    val id: Long,
    val name: String,
    val description: String?,
    val groupType: GroupType,
    val profileImageUrl: String?,
    val memberCount: Int?,
) {
    companion object {
        fun from(
            group: Group,
            memberCount: Int? = null,
        ): GroupSummaryDto {
            return GroupSummaryDto(
                id = group.id!!,
                name = group.name,
                description = group.description,
                groupType = group.groupType,
                profileImageUrl = group.profileImageUrl,
                memberCount = memberCount,
            )
        }
    }
}

/**
 * 그룹 생성 요청 DTO
 */
data class CreateGroupRequest(
    val name: String,
    val description: String? = null,
    val parentId: Long? = null,
    val university: String? = null,
    val college: String? = null,
    val department: String? = null,
    val groupType: GroupType = GroupType.AUTONOMOUS,
    val tags: Set<String> = emptySet(),
)

/**
 * 그룹 수정 요청 DTO
 */
data class UpdateGroupRequest(
    val name: String? = null,
    val description: String? = null,
    val profileImageUrl: String? = null,
    val tags: Set<String>? = null,
)
