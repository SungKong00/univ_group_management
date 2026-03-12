package com.univgroup.domain.group.controller

import com.univgroup.domain.group.dto.CreateRoleRequest
import com.univgroup.domain.group.dto.GroupRoleDto
import com.univgroup.domain.group.dto.UpdateRoleRequest
import com.univgroup.domain.group.service.GroupMemberService
import com.univgroup.domain.group.service.GroupRoleService
import com.univgroup.domain.permission.GroupPermission
import com.univgroup.domain.permission.evaluator.PermissionEvaluator
import com.univgroup.domain.user.service.IUserService
import com.univgroup.shared.controller.BaseController
import com.univgroup.shared.dto.ApiResponse
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.*

/**
 * 그룹 역할 컨트롤러
 *
 * 역함수 패턴 적용: 권한 먼저 확인 → Service 호출
 */
@RestController
@RequestMapping("/api/groups/{groupId}/roles")
class GroupRoleController(
    userService: IUserService,
    private val groupRoleService: GroupRoleService,
    private val groupMemberService: GroupMemberService,
    private val permissionEvaluator: PermissionEvaluator,
) : BaseController(userService) {
    // ========== 역할 조회 ==========

    /**
     * 그룹의 모든 역할 조회
     */
    @GetMapping
    fun getRoles(
        @PathVariable groupId: Long,
        authentication: Authentication,
    ): ApiResponse<List<GroupRoleDto>> {
        val userId = getCurrentUserId(authentication)

        // 멤버 확인
        val isMember = groupMemberService.isMember(groupId, userId)
        if (!isMember) {
            permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.ROLE_MANAGE)
        }

        val roles = groupRoleService.getRoles(groupId)
        val memberCounts = groupMemberService.getMemberCountByRole(groupId)

        val result =
            roles.map { role ->
                GroupRoleDto.from(role, memberCounts[role.id]?.toInt())
            }

        return ApiResponse.success(result)
    }

    /**
     * 특정 역할 조회
     */
    @GetMapping("/{roleId}")
    fun getRole(
        @PathVariable groupId: Long,
        @PathVariable roleId: Long,
        authentication: Authentication,
    ): ApiResponse<GroupRoleDto> {
        val userId = getCurrentUserId(authentication)

        // 멤버 확인
        val isMember = groupMemberService.isMember(groupId, userId)
        if (!isMember) {
            permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.ROLE_MANAGE)
        }

        val role = groupRoleService.getById(roleId)
        val memberCounts = groupMemberService.getMemberCountByRole(groupId)

        return ApiResponse.success(GroupRoleDto.from(role, memberCounts[roleId]?.toInt()))
    }

    // ========== 역할 관리 ==========

    /**
     * 커스텀 역할 생성
     */
    @PostMapping
    fun createRole(
        @PathVariable groupId: Long,
        @RequestBody request: CreateRoleRequest,
        authentication: Authentication,
    ): ApiResponse<GroupRoleDto> {
        val userId = getCurrentUserId(authentication)

        // 권한 확인
        permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.ROLE_MANAGE)

        val role =
            groupRoleService.createCustomRole(
                groupId = groupId,
                name = request.name,
                description = request.description,
                priority = request.priority,
                permissions = request.permissions,
            )

        return ApiResponse.success(GroupRoleDto.from(role))
    }

    /**
     * 역할 수정
     */
    @PatchMapping("/{roleId}")
    fun updateRole(
        @PathVariable groupId: Long,
        @PathVariable roleId: Long,
        @RequestBody request: UpdateRoleRequest,
        authentication: Authentication,
    ): ApiResponse<GroupRoleDto> {
        val userId = getCurrentUserId(authentication)

        // 권한 확인
        permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.ROLE_MANAGE)

        val updated =
            groupRoleService.updateRole(
                roleId = roleId,
                name = request.name,
                description = request.description,
                priority = request.priority,
                permissions = request.permissions,
            )

        return ApiResponse.success(GroupRoleDto.from(updated))
    }

    /**
     * 역할 삭제
     */
    @DeleteMapping("/{roleId}")
    fun deleteRole(
        @PathVariable groupId: Long,
        @PathVariable roleId: Long,
        authentication: Authentication,
    ): ApiResponse<Unit> {
        val userId = getCurrentUserId(authentication)

        // 권한 확인
        permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.ROLE_MANAGE)

        groupRoleService.deleteRole(roleId)

        return ApiResponse.success(Unit)
    }
}
