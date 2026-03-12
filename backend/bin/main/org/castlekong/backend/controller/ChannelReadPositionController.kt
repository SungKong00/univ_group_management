package org.castlekong.backend.controller

import jakarta.validation.Valid
import org.castlekong.backend.dto.ApiResponse
import org.castlekong.backend.dto.ChannelReadPositionResponse
import org.castlekong.backend.dto.UnreadCountResponse
import org.castlekong.backend.dto.UpdateReadPositionRequest
import org.castlekong.backend.service.ChannelReadPositionService
import org.castlekong.backend.service.UserService
import org.springframework.http.HttpStatus
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

/**
 * 채널 읽음 위치 관리 컨트롤러
 * 채널별 읽음 위치 저장/조회 및 읽지 않은 글 개수 조회
 */
@RestController
@RequestMapping("/api/channels")
class ChannelReadPositionController(
    private val channelReadPositionService: ChannelReadPositionService,
    userService: UserService,
) : BaseController(userService) {
    /**
     * 채널별 읽음 위치 조회
     * GET /api/channels/{channelId}/read-position
     */
    @GetMapping("/{channelId}/read-position")
    fun getReadPosition(
        @PathVariable channelId: Long,
        authentication: Authentication,
    ): ApiResponse<ChannelReadPositionResponse?> {
        val user = getCurrentUser(authentication)
        val response = channelReadPositionService.getReadPosition(user.id, channelId)
        return ApiResponse.success(response)
    }

    /**
     * 채널별 읽음 위치 업데이트
     * PUT /api/channels/{channelId}/read-position
     */
    @PutMapping("/{channelId}/read-position")
    @ResponseStatus(HttpStatus.OK)
    fun updateReadPosition(
        @PathVariable channelId: Long,
        @Valid @RequestBody request: UpdateReadPositionRequest,
        authentication: Authentication,
    ): ApiResponse<Unit> {
        val user = getCurrentUser(authentication)
        channelReadPositionService.updateReadPosition(user.id, channelId, request)
        return ApiResponse.success(Unit)
    }

    /**
     * 채널별 읽지 않은 글 개수 조회
     * GET /api/channels/{channelId}/unread-count
     */
    @GetMapping("/{channelId}/unread-count")
    fun getUnreadCount(
        @PathVariable channelId: Long,
        authentication: Authentication,
    ): ApiResponse<Int> {
        val user = getCurrentUser(authentication)
        val count = channelReadPositionService.getUnreadCount(user.id, channelId)
        return ApiResponse.success(count)
    }

    /**
     * 여러 채널의 읽지 않은 글 개수 일괄 조회
     * GET /api/channels/unread-counts?channelIds=1,2,3
     */
    @GetMapping("/unread-counts")
    fun getUnreadCounts(
        @RequestParam channelIds: List<Long>,
        authentication: Authentication,
    ): ApiResponse<List<UnreadCountResponse>> {
        val user = getCurrentUser(authentication)
        val counts = channelReadPositionService.getUnreadCountsForChannels(user.id, channelIds)
        return ApiResponse.success(counts)
    }
}
