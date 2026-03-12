package com.univgroup.domain.workspace.controller

import com.univgroup.domain.group.service.GroupService
import com.univgroup.domain.permission.GroupPermission
import com.univgroup.domain.permission.evaluator.PermissionEvaluator
import com.univgroup.domain.user.service.IUserService
import com.univgroup.domain.workspace.dto.*
import com.univgroup.domain.workspace.entity.Workspace
import com.univgroup.domain.workspace.service.WorkspaceService
import com.univgroup.shared.controller.BaseController
import com.univgroup.shared.dto.ApiResponse
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.*

/**
 * 워크스페이스 컨트롤러
 *
 * 역함수 패턴 적용: 그룹 권한 먼저 확인 → Service 호출
 */
@RestController
@RequestMapping("/api/groups/{groupId}/workspaces")
class WorkspaceController(
    userService: IUserService,
    private val workspaceService: WorkspaceService,
    private val groupService: GroupService,
    private val permissionEvaluator: PermissionEvaluator,
) : BaseController(userService) {
    // ========== 워크스페이스 조회 ==========

    /**
     * 그룹의 워크스페이스 목록 조회
     */
    @GetMapping
    fun getWorkspaces(
        @PathVariable groupId: Long,
        authentication: Authentication,
    ): ApiResponse<List<WorkspaceDto>> {
        val userId = getCurrentUserId(authentication)

        // 채널 읽기 권한 확인
        permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.CHANNEL_READ)

        val workspaces = workspaceService.getWorkspacesByGroup(groupId)

        val result =
            workspaces.map { workspace ->
                val channelCount = workspaceService.getChannelCount(workspace.id!!).toInt()
                WorkspaceDto.from(workspace, channelCount)
            }

        return ApiResponse.success(result)
    }

    /**
     * 워크스페이스 상세 조회
     */
    @GetMapping("/{workspaceId}")
    fun getWorkspace(
        @PathVariable groupId: Long,
        @PathVariable workspaceId: Long,
        authentication: Authentication,
    ): ApiResponse<WorkspaceDto> {
        val userId = getCurrentUserId(authentication)

        // 채널 읽기 권한 확인
        permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.CHANNEL_READ)

        val workspace = workspaceService.getById(workspaceId)
        val channelCount = workspaceService.getChannelCount(workspaceId).toInt()

        return ApiResponse.success(WorkspaceDto.from(workspace, channelCount))
    }

    // ========== 워크스페이스 생성/수정/삭제 ==========

    /**
     * 워크스페이스 생성
     */
    @PostMapping
    fun createWorkspace(
        @PathVariable groupId: Long,
        @RequestBody request: CreateWorkspaceRequest,
        authentication: Authentication,
    ): ApiResponse<WorkspaceDto> {
        val userId = getCurrentUserId(authentication)

        // 워크스페이스 관리 권한 확인
        permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.WORKSPACE_MANAGE)

        val group = groupService.getById(groupId)

        val workspace =
            Workspace(
                group = group,
                name = request.name,
                description = request.description,
            )

        val created = workspaceService.createWorkspace(workspace)

        return ApiResponse.success(WorkspaceDto.from(created, 0))
    }

    /**
     * 워크스페이스 수정
     */
    @PatchMapping("/{workspaceId}")
    fun updateWorkspace(
        @PathVariable groupId: Long,
        @PathVariable workspaceId: Long,
        @RequestBody request: UpdateWorkspaceRequest,
        authentication: Authentication,
    ): ApiResponse<WorkspaceDto> {
        val userId = getCurrentUserId(authentication)

        // 워크스페이스 관리 권한 확인
        permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.WORKSPACE_MANAGE)

        val updated =
            workspaceService.updateWorkspace(workspaceId) { workspace ->
                request.name?.let { workspace.name = it }
                request.description?.let { workspace.description = it }
            }

        val channelCount = workspaceService.getChannelCount(workspaceId).toInt()

        return ApiResponse.success(WorkspaceDto.from(updated, channelCount))
    }

    /**
     * 워크스페이스 삭제
     */
    @DeleteMapping("/{workspaceId}")
    fun deleteWorkspace(
        @PathVariable groupId: Long,
        @PathVariable workspaceId: Long,
        authentication: Authentication,
    ): ApiResponse<Unit> {
        val userId = getCurrentUserId(authentication)

        // 워크스페이스 관리 권한 확인
        permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.WORKSPACE_MANAGE)

        workspaceService.deleteWorkspace(workspaceId)

        return ApiResponse.success(Unit)
    }
}
