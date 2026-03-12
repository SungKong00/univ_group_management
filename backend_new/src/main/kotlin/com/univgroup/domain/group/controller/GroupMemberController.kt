package com.univgroup.domain.group.controller

import com.univgroup.domain.group.dto.AddMemberRequest
import com.univgroup.domain.group.dto.ChangeMemberRoleRequest
import com.univgroup.domain.group.dto.GroupMemberDto
import com.univgroup.domain.group.entity.GroupMember
import com.univgroup.domain.group.service.GroupMemberService
import com.univgroup.domain.group.service.GroupRoleService
import com.univgroup.domain.group.service.GroupService
import com.univgroup.domain.permission.GroupPermission
import com.univgroup.domain.permission.evaluator.PermissionEvaluator
import com.univgroup.domain.user.service.IUserService
import com.univgroup.shared.controller.BaseController
import com.univgroup.shared.dto.ApiResponse
import org.springframework.data.domain.PageRequest
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.*

/**
 * 그룹 멤버 컨트롤러
 *
 * 역함수 패턴 적용: 권한 먼저 확인 → Service 호출
 */
@RestController
@RequestMapping("/api/groups/{groupId}/members")
class GroupMemberController(
    userService: IUserService,
    private val groupService: GroupService,
    private val groupMemberService: GroupMemberService,
    private val groupRoleService: GroupRoleService,
    private val permissionEvaluator: PermissionEvaluator,
) : BaseController(userService) {
    // ========== 멤버 조회 ==========

    /**
     * 그룹 멤버 목록 조회
     */
    @GetMapping
    fun getMembers(
        @PathVariable groupId: Long,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "50") size: Int,
        authentication: Authentication,
    ): ApiResponse<List<GroupMemberDto>> {
        val userId = getCurrentUserId(authentication)

        // 멤버만 조회 가능
        val isMember = groupMemberService.isMember(groupId, userId)

        if (!isMember) {
            permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.MEMBER_MANAGE)
        }

        val pageable = PageRequest.of(page, size)
        val members = groupMemberService.getMembers(groupId, pageable)

        return ApiResponse.success(members.content.map { GroupMemberDto.from(it) })
    }

    /**
     * 특정 멤버 조회
     */
    @GetMapping("/{userId}")
    fun getMember(
        @PathVariable groupId: Long,
        @PathVariable userId: Long,
        authentication: Authentication,
    ): ApiResponse<GroupMemberDto> {
        val currentUserId = getCurrentUserId(authentication)

        // 본인이거나 멤버 관리 권한 필요
        if (currentUserId != userId) {
            val isMember = groupMemberService.isMember(groupId, currentUserId)
            if (!isMember) {
                permissionEvaluator.requireGroupPermission(currentUserId, groupId, GroupPermission.MEMBER_MANAGE)
            }
        }

        val member = groupMemberService.getMemberOrThrow(groupId, userId)

        return ApiResponse.success(GroupMemberDto.from(member))
    }

    // ========== 멤버 관리 ==========

    /**
     * 멤버 추가
     */
    @PostMapping
    fun addMember(
        @PathVariable groupId: Long,
        @RequestBody request: AddMemberRequest,
        authentication: Authentication,
    ): ApiResponse<GroupMemberDto> {
        val currentUserId = getCurrentUserId(authentication)

        // 권한 확인
        permissionEvaluator.requireGroupPermission(currentUserId, groupId, GroupPermission.MEMBER_MANAGE)

        val group = groupService.getById(groupId)
        val user = userService.getById(request.userId)
        val role = groupRoleService.getById(request.roleId)

        val member =
            GroupMember(
                group = group,
                user = user,
                role = role,
            )

        val added = groupMemberService.addMember(member)

        return ApiResponse.success(GroupMemberDto.from(added))
    }

    /**
     * 멤버 역할 변경
     */
    @PatchMapping("/{userId}/role")
    fun changeMemberRole(
        @PathVariable groupId: Long,
        @PathVariable userId: Long,
        @RequestBody request: ChangeMemberRoleRequest,
        authentication: Authentication,
    ): ApiResponse<GroupMemberDto> {
        val currentUserId = getCurrentUserId(authentication)

        // 권한 확인
        permissionEvaluator.requireGroupPermission(currentUserId, groupId, GroupPermission.ROLE_MANAGE)

        val updated = groupMemberService.changeRole(groupId, userId, request.roleId)

        return ApiResponse.success(GroupMemberDto.from(updated))
    }

    /**
     * 멤버 제거
     */
    @DeleteMapping("/{userId}")
    fun removeMember(
        @PathVariable groupId: Long,
        @PathVariable userId: Long,
        authentication: Authentication,
    ): ApiResponse<Unit> {
        val currentUserId = getCurrentUserId(authentication)

        // 본인 탈퇴 또는 강제 퇴장 권한 확인
        if (currentUserId != userId) {
            permissionEvaluator.requireGroupPermission(currentUserId, groupId, GroupPermission.MEMBER_KICK)
        }

        groupMemberService.removeMember(groupId, userId)

        return ApiResponse.success(Unit)
    }
}
