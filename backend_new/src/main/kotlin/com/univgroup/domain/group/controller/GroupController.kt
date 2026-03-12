package com.univgroup.domain.group.controller

import com.univgroup.domain.group.dto.*
import com.univgroup.domain.group.entity.Group
import com.univgroup.domain.group.service.GroupMemberService
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
 * 그룹 컨트롤러
 *
 * 역함수 패턴 적용: 권한 먼저 확인 → Service 호출
 */
@RestController
@RequestMapping("/api/groups")
class GroupController(
    userService: IUserService,
    private val groupService: GroupService,
    private val groupMemberService: GroupMemberService,
    private val permissionEvaluator: PermissionEvaluator,
) : BaseController(userService) {
    // ========== 그룹 조회 ==========

    /**
     * 그룹 상세 조회
     */
    @GetMapping("/{groupId}")
    fun getGroup(
        @PathVariable groupId: Long,
        authentication: Authentication?,
    ): ApiResponse<GroupDto> {
        val group = groupService.getById(groupId)
        val memberCount = groupMemberService.getMemberCount(groupId)

        return ApiResponse.success(GroupDto.from(group, memberCount))
    }

    /**
     * 공개 그룹 검색
     */
    @GetMapping("/search")
    fun searchGroups(
        @RequestParam keyword: String,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int,
    ): ApiResponse<List<GroupSummaryDto>> {
        val pageable = PageRequest.of(page, size)
        val groups = groupService.searchGroups(keyword, pageable)

        val result =
            groups.content.map { group ->
                val memberCount = groupMemberService.getMemberCount(group.id!!)
                GroupSummaryDto.from(group, memberCount)
            }

        return ApiResponse.success(result)
    }

    /**
     * 내가 가입한 그룹 목록
     */
    @GetMapping("/my")
    fun getMyGroups(authentication: Authentication): ApiResponse<List<UserMembershipDto>> {
        val userId = getCurrentUserId(authentication)
        val memberships = groupMemberService.getUserMemberships(userId)

        return ApiResponse.success(memberships.map { UserMembershipDto.from(it) })
    }

    /**
     * 하위 그룹 조회
     */
    @GetMapping("/{groupId}/children")
    fun getChildren(
        @PathVariable groupId: Long,
    ): ApiResponse<List<GroupSummaryDto>> {
        val children = groupService.getChildren(groupId)

        val result =
            children.map { group ->
                val memberCount = groupMemberService.getMemberCount(group.id!!)
                GroupSummaryDto.from(group, memberCount)
            }

        return ApiResponse.success(result)
    }

    // ========== 그룹 생성/수정/삭제 ==========

    /**
     * 그룹 생성
     */
    @PostMapping
    fun createGroup(
        @RequestBody request: CreateGroupRequest,
        authentication: Authentication,
    ): ApiResponse<GroupDto> {
        val user = getCurrentUser(authentication)

        // 부모 그룹이 있는 경우 권한 확인
        request.parentId?.let { parentId ->
            permissionEvaluator.requireGroupPermission(
                user.id!!,
                parentId,
                GroupPermission.GROUP_MANAGE,
            )
        }

        val group =
            Group(
                name = request.name,
                description = request.description,
                owner = user,
                parent = request.parentId?.let { groupService.findById(it) },
                university = request.university,
                college = request.college,
                department = request.department,
                groupType = request.groupType,
                tags = request.tags,
            )

        val created = groupService.createGroup(group)

        return ApiResponse.success(GroupDto.from(created, 1))
    }

    /**
     * 그룹 정보 수정
     */
    @PatchMapping("/{groupId}")
    fun updateGroup(
        @PathVariable groupId: Long,
        @RequestBody request: UpdateGroupRequest,
        authentication: Authentication,
    ): ApiResponse<GroupDto> {
        val userId = getCurrentUserId(authentication)

        // 권한 확인
        permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.GROUP_MANAGE)

        val updated =
            groupService.updateGroup(groupId) { group ->
                request.name?.let { group.name = it }
                request.description?.let { group.description = it }
                request.profileImageUrl?.let { group.profileImageUrl = it }
            }

        val memberCount = groupMemberService.getMemberCount(groupId)

        return ApiResponse.success(GroupDto.from(updated, memberCount))
    }

    /**
     * 그룹 삭제
     */
    @DeleteMapping("/{groupId}")
    fun deleteGroup(
        @PathVariable groupId: Long,
        authentication: Authentication,
    ): ApiResponse<Unit> {
        val userId = getCurrentUserId(authentication)

        // 권한 확인 (그룹 삭제는 GROUP_DELETE 권한 필요)
        permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.GROUP_DELETE)

        groupService.deleteGroup(groupId)

        return ApiResponse.success(Unit)
    }
}
