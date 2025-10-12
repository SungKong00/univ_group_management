package org.castlekong.backend.controller

import jakarta.validation.Valid
import org.castlekong.backend.dto.ApiResponse
import org.castlekong.backend.dto.CreateGroupEventRequest
import org.castlekong.backend.dto.GroupEventResponse
import org.castlekong.backend.dto.UpdateGroupEventRequest
import org.castlekong.backend.dto.UpdateScope
import org.castlekong.backend.service.GroupEventService
import org.castlekong.backend.service.UserService
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.HttpStatus
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController
import java.time.LocalDate

/**
 * 그룹 캘린더 일정 관리 컨트롤러
 */
@RestController
@RequestMapping("/api/groups/{groupId}/events")
class GroupEventController(
    private val groupEventService: GroupEventService,
    userService: UserService,
) : BaseController(userService) {
    /**
     * GET /api/groups/{groupId}/events?startDate={date}&endDate={date}
     * 그룹 캘린더 일정 목록 조회
     */
    @GetMapping
    @PreAuthorize("isAuthenticated()")
    fun getEvents(
        authentication: Authentication,
        @PathVariable groupId: Long,
        @RequestParam("startDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate,
        @RequestParam("endDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate,
    ): ApiResponse<List<GroupEventResponse>> {
        val user = getCurrentUser(authentication)
        val events = groupEventService.getEventsByDateRange(user, groupId, startDate, endDate)
        return ApiResponse.success(events)
    }

    /**
     * POST /api/groups/{groupId}/events
     * 그룹 일정 생성 (단일 or 반복)
     */
    @PostMapping
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.CREATED)
    fun createEvent(
        authentication: Authentication,
        @PathVariable groupId: Long,
        @Valid @RequestBody request: CreateGroupEventRequest,
    ): ApiResponse<List<GroupEventResponse>> {
        val user = getCurrentUser(authentication)
        val events = groupEventService.createEvent(user, groupId, request)
        return ApiResponse.success(events)
    }

    /**
     * PUT /api/groups/{groupId}/events/{eventId}
     * 그룹 일정 수정 (이 일정만 or 반복 전체)
     */
    @PutMapping("/{eventId}")
    @PreAuthorize("isAuthenticated()")
    fun updateEvent(
        authentication: Authentication,
        @PathVariable groupId: Long,
        @PathVariable eventId: Long,
        @Valid @RequestBody request: UpdateGroupEventRequest,
    ): ApiResponse<List<GroupEventResponse>> {
        val user = getCurrentUser(authentication)
        val events = groupEventService.updateEvent(user, groupId, eventId, request)
        return ApiResponse.success(events)
    }

    /**
     * DELETE /api/groups/{groupId}/events/{eventId}?scope={THIS_EVENT|ALL_EVENTS}
     * 그룹 일정 삭제
     */
    @DeleteMapping("/{eventId}")
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deleteEvent(
        authentication: Authentication,
        @PathVariable groupId: Long,
        @PathVariable eventId: Long,
        @RequestParam(defaultValue = "THIS_EVENT") scope: UpdateScope,
    ): ApiResponse<Unit> {
        val user = getCurrentUser(authentication)
        groupEventService.deleteEvent(user, groupId, eventId, scope)
        return ApiResponse.success()
    }
}
