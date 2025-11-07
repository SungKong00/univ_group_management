package org.castlekong.backend.controller

import jakarta.validation.Valid
import org.castlekong.backend.dto.ApiResponse
import org.castlekong.backend.dto.CreatePersonalEventRequest
import org.castlekong.backend.dto.PersonalEventResponse
import org.castlekong.backend.dto.UpdatePersonalEventRequest
import org.castlekong.backend.service.PersonalEventService
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

@RestController
@RequestMapping("/api/calendar")
class PersonalCalendarController(
    private val personalEventService: PersonalEventService,
    userService: UserService,
) : BaseController(userService) {
    @GetMapping
    @PreAuthorize("isAuthenticated()")
    fun getPersonalEvents(
        authentication: Authentication,
        @RequestParam("start") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) start: LocalDate,
        @RequestParam("end") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) end: LocalDate,
    ): ApiResponse<List<PersonalEventResponse>> {
        val user = getCurrentUser(authentication)
        val events = personalEventService.getEvents(user, start, end)
        return ApiResponse.success(events)
    }

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.CREATED)
    fun createPersonalEvent(
        authentication: Authentication,
        @Valid @RequestBody request: CreatePersonalEventRequest,
    ): ApiResponse<PersonalEventResponse> {
        val user = getCurrentUser(authentication)
        val response = personalEventService.createEvent(user, request)
        return ApiResponse.success(response)
    }

    @PutMapping("/{eventId}")
    @PreAuthorize("isAuthenticated()")
    fun updatePersonalEvent(
        authentication: Authentication,
        @PathVariable eventId: Long,
        @Valid @RequestBody request: UpdatePersonalEventRequest,
    ): ApiResponse<PersonalEventResponse> {
        val user = getCurrentUser(authentication)
        val response = personalEventService.updateEvent(user, eventId, request)
        return ApiResponse.success(response)
    }

    @DeleteMapping("/{eventId}")
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deletePersonalEvent(
        authentication: Authentication,
        @PathVariable eventId: Long,
    ): ApiResponse<Unit> {
        val user = getCurrentUser(authentication)
        personalEventService.deleteEvent(user, eventId)
        return ApiResponse.success()
    }
}
