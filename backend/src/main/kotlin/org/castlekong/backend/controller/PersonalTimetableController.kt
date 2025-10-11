package org.castlekong.backend.controller

import jakarta.validation.Valid
import org.castlekong.backend.dto.ApiResponse
import org.castlekong.backend.dto.CreatePersonalScheduleRequest
import org.castlekong.backend.dto.PersonalScheduleResponse
import org.castlekong.backend.dto.UpdatePersonalScheduleRequest
import org.castlekong.backend.service.PersonalScheduleService
import org.castlekong.backend.service.UserService
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
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/timetable")
class PersonalTimetableController(
    private val personalScheduleService: PersonalScheduleService,
    userService: UserService,
) : BaseController(userService) {
    @GetMapping
    @PreAuthorize("isAuthenticated()")
    fun getPersonalSchedules(authentication: Authentication): ApiResponse<List<PersonalScheduleResponse>> {
        val user = getCurrentUser(authentication)
        val schedules = personalScheduleService.getSchedules(user)
        return ApiResponse.success(schedules)
    }

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.CREATED)
    fun createPersonalSchedule(
        authentication: Authentication,
        @Valid @RequestBody request: CreatePersonalScheduleRequest,
    ): ApiResponse<PersonalScheduleResponse> {
        val user = getCurrentUser(authentication)
        val response = personalScheduleService.createSchedule(user, request)
        return ApiResponse.success(response)
    }

    @PutMapping("/{scheduleId}")
    @PreAuthorize("isAuthenticated()")
    fun updatePersonalSchedule(
        authentication: Authentication,
        @PathVariable scheduleId: Long,
        @Valid @RequestBody request: UpdatePersonalScheduleRequest,
    ): ApiResponse<PersonalScheduleResponse> {
        val user = getCurrentUser(authentication)
        val response = personalScheduleService.updateSchedule(user, scheduleId, request)
        return ApiResponse.success(response)
    }

    @DeleteMapping("/{scheduleId}")
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deletePersonalSchedule(
        authentication: Authentication,
        @PathVariable scheduleId: Long,
    ): ApiResponse<Unit> {
        val user = getCurrentUser(authentication)
        personalScheduleService.deleteSchedule(user, scheduleId)
        return ApiResponse.success()
    }
}
