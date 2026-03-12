package com.univgroup.domain.workspace.controller

import com.univgroup.domain.group.service.GroupService
import com.univgroup.domain.permission.GroupPermission
import com.univgroup.domain.permission.evaluator.PermissionEvaluator
import com.univgroup.domain.user.service.IUserService
import com.univgroup.domain.workspace.dto.*
import com.univgroup.domain.workspace.entity.Channel
import com.univgroup.domain.workspace.service.ChannelService
import com.univgroup.domain.workspace.service.WorkspaceService
import com.univgroup.shared.controller.BaseController
import com.univgroup.shared.dto.ApiResponse
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.*

/**
 * 채널 컨트롤러
 *
 * 역함수 패턴 적용: 그룹 권한 먼저 확인 → Service 호출
 */
@RestController
@RequestMapping("/api/groups/{groupId}/workspaces/{workspaceId}/channels")
class ChannelController(
    userService: IUserService,
    private val channelService: ChannelService,
    private val workspaceService: WorkspaceService,
    private val groupService: GroupService,
    private val permissionEvaluator: PermissionEvaluator,
) : BaseController(userService) {
    // ========== 채널 조회 ==========

    /**
     * 워크스페이스의 채널 목록 조회
     */
    @GetMapping
    fun getChannels(
        @PathVariable groupId: Long,
        @PathVariable workspaceId: Long,
        authentication: Authentication,
    ): ApiResponse<List<ChannelDto>> {
        val userId = getCurrentUserId(authentication)

        // 채널 읽기 권한 확인
        permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.CHANNEL_READ)

        val channels = channelService.getChannelsByWorkspace(workspaceId)

        return ApiResponse.success(channels.map { ChannelDto.from(it) })
    }

    /**
     * 채널 상세 조회
     */
    @GetMapping("/{channelId}")
    fun getChannel(
        @PathVariable groupId: Long,
        @PathVariable workspaceId: Long,
        @PathVariable channelId: Long,
        authentication: Authentication,
    ): ApiResponse<ChannelDto> {
        val userId = getCurrentUserId(authentication)

        // 채널 읽기 권한 확인
        permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.CHANNEL_READ)

        val channel = channelService.getById(channelId)

        return ApiResponse.success(ChannelDto.from(channel))
    }

    // ========== 채널 생성/수정/삭제 ==========

    /**
     * 채널 생성
     */
    @PostMapping
    fun createChannel(
        @PathVariable groupId: Long,
        @PathVariable workspaceId: Long,
        @RequestBody request: CreateChannelRequest,
        authentication: Authentication,
    ): ApiResponse<ChannelDto> {
        val userId = getCurrentUserId(authentication)

        // 채널 관리 권한 확인
        permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.CHANNEL_MANAGE)

        val user = getCurrentUser(authentication)
        val workspace = workspaceService.getById(workspaceId)
        val group = groupService.getById(groupId)

        val channel =
            Channel(
                workspace = workspace,
                group = group,
                name = request.name,
                description = request.description,
                type = request.type,
                displayOrder = channelService.getChannelCount(workspaceId).toInt(),
                createdBy = user,
            )

        val created = channelService.createChannel(channel)

        return ApiResponse.success(ChannelDto.from(created))
    }

    /**
     * 채널 수정
     */
    @PatchMapping("/{channelId}")
    fun updateChannel(
        @PathVariable groupId: Long,
        @PathVariable workspaceId: Long,
        @PathVariable channelId: Long,
        @RequestBody request: UpdateChannelRequest,
        authentication: Authentication,
    ): ApiResponse<ChannelDto> {
        val userId = getCurrentUserId(authentication)

        // 채널 관리 권한 확인
        permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.CHANNEL_MANAGE)

        val updated =
            channelService.updateChannel(channelId) { channel ->
                request.name?.let { channel.name = it }
                request.description?.let { channel.description = it }
            }

        return ApiResponse.success(ChannelDto.from(updated))
    }

    /**
     * 채널 삭제
     */
    @DeleteMapping("/{channelId}")
    fun deleteChannel(
        @PathVariable groupId: Long,
        @PathVariable workspaceId: Long,
        @PathVariable channelId: Long,
        authentication: Authentication,
    ): ApiResponse<Unit> {
        val userId = getCurrentUserId(authentication)

        // 채널 관리 권한 확인
        permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.CHANNEL_MANAGE)

        channelService.deleteChannel(channelId)

        return ApiResponse.success(Unit)
    }

    /**
     * 채널 순서 변경
     */
    @PatchMapping("/reorder")
    fun reorderChannels(
        @PathVariable groupId: Long,
        @PathVariable workspaceId: Long,
        @RequestBody request: ReorderChannelsRequest,
        authentication: Authentication,
    ): ApiResponse<List<ChannelSummaryDto>> {
        val userId = getCurrentUserId(authentication)

        // 채널 관리 권한 확인
        permissionEvaluator.requireGroupPermission(userId, groupId, GroupPermission.CHANNEL_MANAGE)

        channelService.reorderChannels(workspaceId, request.channelIds)

        val channels = channelService.getChannelsByWorkspace(workspaceId)

        return ApiResponse.success(channels.map { ChannelSummaryDto.from(it) })
    }
}
