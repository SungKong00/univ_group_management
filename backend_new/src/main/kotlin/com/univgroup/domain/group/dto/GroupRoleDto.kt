package com.univgroup.domain.group.dto

import com.univgroup.domain.group.entity.GroupRole
import com.univgroup.domain.permission.GroupPermission

/**
 * 그룹 역할 응답 DTO
 */
data class GroupRoleDto(
    val id: Long,
    val name: String,
    val description: String?,
    val isSystemRole: Boolean,
    val priority: Int,
    val permissions: Set<GroupPermission>,
    val memberCount: Int?,
) {
    companion object {
        fun from(
            role: GroupRole,
            memberCount: Int? = null,
        ): GroupRoleDto {
            return GroupRoleDto(
                id = role.id!!,
                name = role.name,
                description = role.description,
                isSystemRole = role.isSystemRole,
                priority = role.priority,
                permissions = role.permissions.toSet(),
                memberCount = memberCount,
            )
        }
    }
}

/**
 * 역할 생성 요청 DTO
 */
data class CreateRoleRequest(
    val name: String,
    val description: String? = null,
    val priority: Int = 50,
    val permissions: Set<GroupPermission> = emptySet(),
)

/**
 * 역할 수정 요청 DTO
 */
data class UpdateRoleRequest(
    val name: String? = null,
    val description: String? = null,
    val priority: Int? = null,
    val permissions: Set<GroupPermission>? = null,
)
