package org.castlekong.backend.controller

import jakarta.validation.Valid
import org.castlekong.backend.dto.AdminStatsResponse
import org.castlekong.backend.dto.ApiResponse
import org.castlekong.backend.dto.CreateGroupRequest
import org.castlekong.backend.dto.CreateGroupRoleRequest
import org.castlekong.backend.dto.CreateSubGroupRequest
import org.castlekong.backend.dto.GroupHierarchyNodeDto
import org.castlekong.backend.dto.GroupJoinRequestResponse
import org.castlekong.backend.dto.GroupMemberResponse
import org.castlekong.backend.dto.GroupResponse
import org.castlekong.backend.dto.GroupRoleResponse
import org.castlekong.backend.dto.GroupSummaryResponse
import org.castlekong.backend.dto.JoinGroupRequest
import org.castlekong.backend.dto.PagedApiResponse
import org.castlekong.backend.dto.PaginationInfo
import org.castlekong.backend.dto.ReviewGroupJoinRequestRequest
import org.castlekong.backend.dto.ReviewSubGroupRequestRequest
import org.castlekong.backend.dto.SubGroupRequestResponse
import org.castlekong.backend.dto.UpdateGroupRequest
import org.castlekong.backend.dto.UpdateGroupRoleRequest
import org.castlekong.backend.dto.UpdateMemberRoleRequest
import org.castlekong.backend.dto.WorkspaceDto
import org.castlekong.backend.security.SecurityExpressionHelper
import org.castlekong.backend.service.AdminStatsService
import org.castlekong.backend.service.GroupManagementService
import org.castlekong.backend.service.GroupMemberService
import org.castlekong.backend.service.GroupRequestService
import org.castlekong.backend.service.GroupRoleService
import org.castlekong.backend.service.UserService
import org.castlekong.backend.service.WorkspaceManagementService
import org.springframework.data.domain.Pageable
import org.springframework.http.HttpStatus
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/groups")
class GroupController(
    private val groupManagementService: GroupManagementService,
    private val groupMemberService: GroupMemberService,
    private val groupRequestService: GroupRequestService,
    private val workspaceManagementService: WorkspaceManagementService,
    private val adminStatsService: AdminStatsService,
    private val groupRoleService: GroupRoleService,
    userService: UserService,
    private val securityExpressionHelper: SecurityExpressionHelper,
    private val permissionService: org.castlekong.backend.security.PermissionService,
) : BaseController(userService) {
    @PostMapping
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.CREATED)
    fun createGroup(
        @Valid @RequestBody request: CreateGroupRequest,
        authentication: Authentication,
    ): ApiResponse<GroupResponse> {
        val user = getUserByEmail(authentication.name)
        val response = groupManagementService.createGroup(request, user.id)
        return ApiResponse.success(response)
    }

    @GetMapping
    fun getGroups(pageable: Pageable): PagedApiResponse<GroupSummaryResponse> {
        val response = groupManagementService.getGroups(pageable)
        val pagination = PaginationInfo.fromSpringPage(response)
        return PagedApiResponse.success(response.content, pagination)
    }

    @GetMapping("/all")
    @io.swagger.v3.oas.annotations.Operation(summary = "모든 그룹 조회", description = "페이징 없이 모든 그룹의 요약 정보를 반환합니다.")
    fun getAllGroups(): ApiResponse<List<GroupSummaryResponse>> {
        val response = groupManagementService.getAllGroups()
        return ApiResponse.success(response)
    }

    // Explore/검색 API
    @GetMapping("/explore")
    fun exploreGroups(
        pageable: Pageable,
        @RequestParam(required = false) recruiting: Boolean?,
        // 쉼표로 구분된 그룹 타입 목록 (예: "UNIVERSITY,COLLEGE,DEPARTMENT")
        @RequestParam(required = false) groupTypes: String?,
        @RequestParam(required = false) university: String?,
        @RequestParam(required = false) college: String?,
        @RequestParam(required = false) department: String?,
        @RequestParam(required = false) q: String?,
        // comma-separated
        @RequestParam(required = false) tags: String?,
    ): PagedApiResponse<GroupSummaryResponse> {
        // Parse comma-separated groupTypes into List<GroupType>
        val groupTypeList =
            groupTypes?.split(',')
                ?.mapNotNull { typeString ->
                    try {
                        org.castlekong.backend.entity.GroupType.valueOf(typeString.trim().uppercase())
                    } catch (e: IllegalArgumentException) {
                        null // Ignore invalid group types
                    }
                } ?: emptyList()

        val tagSet =
            tags?.split(',')?.map { it.trim() }?.filter { it.isNotEmpty() }?.toSet() ?: emptySet()
        val response =
            groupManagementService.searchGroups(
                pageable,
                recruiting,
                groupTypeList,
                university,
                college,
                department,
                q,
                tagSet,
            )
        val pagination = PaginationInfo.fromSpringPage(response)
        return PagedApiResponse.success(response.content, pagination)
    }

    @GetMapping("/hierarchy")
    @io.swagger.v3.oas.annotations.Operation(
        summary = "전체 계열/학과 계층 구조 조회",
        description = "온보딩 시 계열/학과 선택 UI를 구성하기 위한 전체 그룹 목록을 반환합니다.",
    )
    fun getGroupHierarchy(): ApiResponse<List<GroupHierarchyNodeDto>> {
        val groups = groupManagementService.getAllGroupsForHierarchy()
        return ApiResponse.success(groups)
    }

    @GetMapping("/{groupId}")
    fun getGroup(
        @PathVariable groupId: Long,
    ): ApiResponse<GroupResponse> {
        val response = groupManagementService.getGroup(groupId)
        return ApiResponse.success(response)
    }

    @PutMapping("/{groupId}")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'GROUP_MANAGE')")
    fun updateGroup(
        @PathVariable groupId: Long,
        @Valid @RequestBody request: UpdateGroupRequest,
        authentication: Authentication,
    ): ApiResponse<GroupResponse> {
        val user = getUserByEmail(authentication.name)
        val response = groupManagementService.updateGroup(groupId, request, user.id)
        return ApiResponse.success(response)
    }

    @DeleteMapping("/{groupId}")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'GROUP_MANAGE')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deleteGroup(
        @PathVariable groupId: Long,
        authentication: Authentication,
    ): ApiResponse<Unit> {
        val user = getUserByEmail(authentication.name)
        groupManagementService.deleteGroup(groupId, user.id)
        return ApiResponse.success()
    }

    @PostMapping("/{groupId}/join")
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.CREATED)
    fun createJoinRequest(
        @PathVariable groupId: Long,
        @RequestBody request: JoinGroupRequest,
        authentication: Authentication,
    ): ApiResponse<GroupJoinRequestResponse> {
        val user = getUserByEmail(authentication.name)
        val response = groupRequestService.createGroupJoinRequest(groupId, request.message, user.id)
        return ApiResponse.success(response)
    }

    @DeleteMapping("/{groupId}/leave")
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun leaveGroup(
        @PathVariable groupId: Long,
        authentication: Authentication,
    ): ApiResponse<Unit> {
        val user = getUserByEmail(authentication.name)
        groupMemberService.leaveGroup(groupId, user.id)
        return ApiResponse.success()
    }

    @GetMapping("/{groupId}/members")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'MEMBER_MANAGE')")
    fun getGroupMembers(
        @PathVariable groupId: Long,
        pageable: Pageable,
    ): PagedApiResponse<GroupMemberResponse> {
        val response = groupMemberService.getGroupMembers(groupId, pageable)
        val pagination = PaginationInfo.fromSpringPage(response)
        return PagedApiResponse.success(response.content, pagination)
    }

    // 내 멤버십 조회 (멤버 여부 판별용)
    @GetMapping("/{groupId}/members/me")
    @PreAuthorize("isAuthenticated()")
    fun getMyMembership(
        @PathVariable groupId: Long,
        authentication: Authentication,
    ): ApiResponse<GroupMemberResponse> {
        val user = getUserByEmail(authentication.name)
        val response = groupMemberService.getMyMembership(groupId, user.id)
        return ApiResponse.success(response)
    }

    // 멤버 역할 변경
    @PutMapping("/{groupId}/members/{userId}/role")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'MEMBER_MANAGE')")
    fun updateMemberRole(
        @PathVariable groupId: Long,
        @PathVariable userId: Long,
        @Valid @RequestBody request: UpdateMemberRoleRequest,
        authentication: Authentication,
    ): ApiResponse<GroupMemberResponse> {
        val user = getUserByEmail(authentication.name)
        val response = groupMemberService.updateMemberRole(groupId, userId, request.roleId, user.id)
        return ApiResponse.success(response)
    }

    // 멤버 강제 탈퇴
    @DeleteMapping("/{groupId}/members/{userId}")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'MEMBER_MANAGE')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun removeMember(
        @PathVariable groupId: Long,
        @PathVariable userId: Long,
        authentication: Authentication,
    ): ApiResponse<Unit> {
        val user = getUserByEmail(authentication.name)
        groupMemberService.removeMember(groupId, userId, user.id)
        return ApiResponse.success()
    }

    // Group Role 관련 엔드포인트
    @PostMapping("/{groupId}/roles")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'MEMBER_MANAGE')")
    @ResponseStatus(HttpStatus.CREATED)
    fun createGroupRole(
        @PathVariable groupId: Long,
        @Valid @RequestBody request: CreateGroupRoleRequest,
        authentication: Authentication,
    ): ApiResponse<GroupRoleResponse> {
        val user = getUserByEmail(authentication.name)
        val response = groupRoleService.createGroupRole(groupId, request, user.id)
        return ApiResponse.success(response)
    }

    @GetMapping("/{groupId}/roles")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'MEMBER_MANAGE')")
    fun getGroupRoles(
        @PathVariable groupId: Long,
    ): ApiResponse<List<GroupRoleResponse>> {
        val response = groupRoleService.getGroupRoles(groupId)
        return ApiResponse.success(response)
    }

    @GetMapping("/{groupId}/roles/{roleId}")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'MEMBER_MANAGE')")
    fun getGroupRole(
        @PathVariable groupId: Long,
        @PathVariable roleId: Long,
    ): ApiResponse<GroupRoleResponse> {
        val response = groupRoleService.getGroupRole(groupId, roleId)
        return ApiResponse.success(response)
    }

    @PutMapping("/{groupId}/roles/{roleId}")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'MEMBER_MANAGE')")
    fun updateGroupRole(
        @PathVariable groupId: Long,
        @PathVariable roleId: Long,
        @Valid @RequestBody request: UpdateGroupRoleRequest,
        authentication: Authentication,
    ): ApiResponse<GroupRoleResponse> {
        val user = getUserByEmail(authentication.name)
        val response = groupRoleService.updateGroupRole(groupId, roleId, request, user.id)
        return ApiResponse.success(response)
    }

    @DeleteMapping("/{groupId}/roles/{roleId}")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'MEMBER_MANAGE')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deleteGroupRole(
        @PathVariable groupId: Long,
        @PathVariable roleId: Long,
        authentication: Authentication,
    ): ApiResponse<Unit> {
        val user = getUserByEmail(authentication.name)
        groupRoleService.deleteGroupRole(groupId, roleId, user.id)
        return ApiResponse.success()
    }

    // === 그룹 가입 신청 관리 ===

    @GetMapping("/{groupId}/join-requests")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'MEMBER_MANAGE')")
    fun getGroupJoinRequests(
        @PathVariable groupId: Long,
    ): ApiResponse<List<GroupJoinRequestResponse>> {
        val response = groupRequestService.getGroupJoinRequestsByGroup(groupId)
        return ApiResponse.success(response)
    }

    @PatchMapping("/{groupId}/join-requests/{requestId}")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'MEMBER_MANAGE')")
    fun reviewGroupJoinRequest(
        @PathVariable groupId: Long,
        @PathVariable requestId: Long,
        @Valid @RequestBody request: ReviewGroupJoinRequestRequest,
        authentication: Authentication,
    ): ApiResponse<GroupJoinRequestResponse> {
        val user = getUserByEmail(authentication.name)
        val response = groupRequestService.reviewGroupJoinRequest(requestId, request, user.id)
        return ApiResponse.success(response)
    }

    // === 하위 그룹 생성 신청 관리 ===

    @PostMapping("/{groupId}/sub-groups/requests")
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.CREATED)
    fun createSubGroupRequest(
        @PathVariable groupId: Long,
        @Valid @RequestBody request: CreateSubGroupRequest,
        authentication: Authentication,
    ): ApiResponse<SubGroupRequestResponse> {
        val user = getUserByEmail(authentication.name)
        val response = groupRequestService.createSubGroupRequest(groupId, request, user.id)
        return ApiResponse.success(response)
    }

    @GetMapping("/{groupId}/sub-groups/requests")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'GROUP_MANAGE')")
    fun getSubGroupRequests(
        @PathVariable groupId: Long,
    ): ApiResponse<List<SubGroupRequestResponse>> {
        val response = groupRequestService.getSubGroupRequestsByParentGroup(groupId)
        return ApiResponse.success(response)
    }

    @PatchMapping("/{groupId}/sub-groups/requests/{requestId}")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'GROUP_MANAGE')")
    fun reviewSubGroupRequest(
        @PathVariable groupId: Long,
        @PathVariable requestId: Long,
        @Valid @RequestBody request: ReviewSubGroupRequestRequest,
        authentication: Authentication,
    ): ApiResponse<SubGroupRequestResponse> {
        val user = getUserByEmail(authentication.name)
        val response = groupRequestService.reviewSubGroupRequest(requestId, request, user.id)
        return ApiResponse.success(response)
    }

    // === 하위 그룹 조회 ===

    @GetMapping("/{groupId}/sub-groups")
    fun getSubGroups(
        @PathVariable groupId: Long,
    ): ApiResponse<List<GroupSummaryResponse>> {
        val response = groupManagementService.getSubGroups(groupId)
        return ApiResponse.success(response)
    }

    // === 지도교수 관리 ===

    @PostMapping("/{groupId}/professors/{professorId}")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'GROUP_MANAGE')")
    @ResponseStatus(HttpStatus.CREATED)
    fun assignProfessor(
        @PathVariable groupId: Long,
        @PathVariable professorId: Long,
        authentication: Authentication,
    ): ApiResponse<GroupMemberResponse> {
        val user = getUserByEmail(authentication.name)
        val response = groupMemberService.assignProfessor(groupId, professorId, user.id)
        return ApiResponse.success(response)
    }

    @DeleteMapping("/{groupId}/professors/{professorId}")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'GROUP_MANAGE')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun removeProfessor(
        @PathVariable groupId: Long,
        @PathVariable professorId: Long,
        authentication: Authentication,
    ): ApiResponse<Unit> {
        val user = getUserByEmail(authentication.name)
        groupMemberService.removeProfessor(groupId, professorId, user.id)
        return ApiResponse.success()
    }

    @GetMapping("/{groupId}/professors")
    fun getProfessors(
        @PathVariable groupId: Long,
    ): ApiResponse<List<GroupMemberResponse>> {
        val response = groupMemberService.getProfessors(groupId)
        return ApiResponse.success(response)
    }

    // === 그룹장 권한 위임 ===

    @PostMapping("/{groupId}/transfer-ownership/{newOwnerId}")
    @PreAuthorize("hasPermission(#groupId, 'GROUP', 'GROUP_MANAGE')")
    fun transferOwnership(
        @PathVariable groupId: Long,
        @PathVariable newOwnerId: Long,
        authentication: Authentication,
    ): ApiResponse<GroupMemberResponse> {
        val user = getUserByEmail(authentication.name)
        val response = groupMemberService.transferOwnership(groupId, newOwnerId, user.id)
        return ApiResponse.success(response)
    }

    // === 워크스페이스 조회 (명세서 요구사항) ===
    @GetMapping("/{groupId}/workspace")
    @PreAuthorize("@security.isGroupMember(#groupId)")
    fun getWorkspace(
        @PathVariable groupId: Long,
        authentication: Authentication,
    ): ApiResponse<WorkspaceDto> {
        val user = getUserByEmail(authentication.name)
        val response = workspaceManagementService.getWorkspace(groupId, user.id)
        return ApiResponse.success(response)
    }

    // === 관리자 통계 ===
    @GetMapping("/{groupId}/admin/stats")
    @PreAuthorize("@security.isGroupMember(#groupId)")
    fun getAdminStats(
        @PathVariable groupId: Long,
    ): ApiResponse<AdminStatsResponse> {
        val stats = adminStatsService.getStats(groupId)
        return ApiResponse.success(stats)
    }

    // === 멤버십 체크 ===
    @GetMapping("/{groupId}/membership/check")
    @PreAuthorize("isAuthenticated()")
    @io.swagger.v3.oas.annotations.Operation(summary = "그룹 멤버십 체크", description = "현재 사용자가 특정 그룹의 멤버인지 확인합니다.")
    fun checkGroupMembership(
        @PathVariable groupId: Long,
    ): ApiResponse<Boolean> {
        val isMember = securityExpressionHelper.isGroupMember(groupId)
        return ApiResponse.success(isMember)
    }

    @PostMapping("/membership/check")
    @PreAuthorize("isAuthenticated()")
    @io.swagger.v3.oas.annotations.Operation(summary = "다중 그룹 멤버십 체크", description = "현재 사용자가 여러 그룹의 멤버인지 배치로 확인합니다.")
    fun checkBatchGroupMembership(
        @RequestBody groupIds: List<Long>,
    ): ApiResponse<Map<Long, Boolean>> {
        val membershipMap =
            groupIds.associateWith { groupId ->
                securityExpressionHelper.isGroupMember(groupId)
            }
        return ApiResponse.success(membershipMap)
    }

    // === 권한 조회 ===
    @GetMapping("/{groupId}/permissions")
    @PreAuthorize("@security.isGroupMember(#groupId)")
    @io.swagger.v3.oas.annotations.Operation(
        summary = "내 그룹 권한 조회",
        description = "현재 사용자가 특정 그룹에서 가지는 권한 목록을 반환합니다.",
    )
    fun getMyPermissions(
        @PathVariable groupId: Long,
        authentication: Authentication,
    ): ApiResponse<Set<String>> {
        val user = getUserByEmail(authentication.name)
        val permissions =
            permissionService.getEffective(groupId, user.id) { roleName ->
                systemRolePermissions(roleName)
            }
        return ApiResponse.success(permissions.map { it.name }.toSet())
    }

    private fun systemRolePermissions(roleName: String): Set<org.castlekong.backend.entity.GroupPermission> {
        return when (roleName.uppercase()) {
            "그룹장" -> org.castlekong.backend.entity.GroupPermission.entries.toSet()
            "교수" -> org.castlekong.backend.entity.GroupPermission.entries.toSet()
            "멤버" -> emptySet()
            else -> emptySet()
        }
    }
}
