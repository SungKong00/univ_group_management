package org.castlekong.backend.service

import org.castlekong.backend.dto.CreatePersonalEventRequest
import org.castlekong.backend.dto.PersonalEventResponse
import org.castlekong.backend.dto.UpdatePersonalEventRequest
import org.castlekong.backend.entity.PersonalEvent
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.PersonalEventRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.time.LocalDateTime

@Service
@Transactional
class PersonalEventService(
    private val personalEventRepository: PersonalEventRepository,
) {
    @Transactional(readOnly = true)
    fun getEvents(
        user: User,
        startDate: LocalDate,
        endDate: LocalDate,
    ): List<PersonalEventResponse> {
        if (endDate.isBefore(startDate)) {
            throw BusinessException(ErrorCode.PERSONAL_EVENT_INVALID_TIME)
        }
        val periodStart = startDate.atStartOfDay()
        val periodEnd = endDate.plusDays(1).atStartOfDay()
        return personalEventRepository
            .findEventsWithinPeriod(user.id, periodStart, periodEnd)
            .map { it.toResponse() }
    }

    fun createEvent(
        user: User,
        request: CreatePersonalEventRequest,
    ): PersonalEventResponse {
        val start = request.startDateTime ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
        val end = request.endDateTime ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
        validateTimeRange(start, end)
        val event =
            PersonalEvent(
                user = user,
                title = request.title.trim(),
                description = request.description?.trim().takeUnless { it.isNullOrEmpty() },
                location = request.location?.trim().takeUnless { it.isNullOrEmpty() },
                startDateTime = start,
                endDateTime = end,
                isAllDay = request.isAllDay,
                color = normalizeColor(request.color),
                createdAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now(),
            )
        val saved = personalEventRepository.save(event)
        return saved.toResponse()
    }

    fun updateEvent(
        user: User,
        eventId: Long,
        request: UpdatePersonalEventRequest,
    ): PersonalEventResponse {
        val existing = getOwnedEvent(user, eventId)
        val start = request.startDateTime ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
        val end = request.endDateTime ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
        validateTimeRange(start, end)
        val updated =
            existing.copy(
                title = request.title.trim(),
                description = request.description?.trim().takeUnless { it.isNullOrEmpty() },
                location = request.location?.trim().takeUnless { it.isNullOrEmpty() },
                startDateTime = start,
                endDateTime = end,
                isAllDay = request.isAllDay,
                color = normalizeColor(request.color),
                updatedAt = LocalDateTime.now(),
            )
        val saved = personalEventRepository.save(updated)
        return saved.toResponse()
    }

    fun deleteEvent(
        user: User,
        eventId: Long,
    ) {
        val existing = getOwnedEvent(user, eventId)
        personalEventRepository.delete(existing)
    }

    private fun getOwnedEvent(
        user: User,
        eventId: Long,
    ): PersonalEvent {
        val event =
            personalEventRepository.findById(eventId)
                .orElseThrow { BusinessException(ErrorCode.PERSONAL_EVENT_NOT_FOUND) }
        if (event.user.id != user.id) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
        return event
    }

    private fun validateTimeRange(
        start: LocalDateTime,
        end: LocalDateTime,
    ) {
        if (!end.isAfter(start)) {
            throw BusinessException(ErrorCode.PERSONAL_EVENT_INVALID_TIME)
        }
    }

    private fun normalizeColor(color: String): String {
        val value = color.trim()
        if (!COLOR_REGEX.matches(value)) {
            throw BusinessException(ErrorCode.INVALID_REQUEST)
        }
        return value.uppercase()
    }

    private fun PersonalEvent.toResponse(): PersonalEventResponse =
        PersonalEventResponse(
            id = id,
            title = title,
            description = description,
            location = location,
            startDateTime = startDateTime,
            endDateTime = endDateTime,
            isAllDay = isAllDay,
            color = color,
            createdAt = createdAt,
            updatedAt = updatedAt,
        )

    companion object {
        private val COLOR_REGEX = "^#[0-9A-Fa-f]{6}$".toRegex()
    }
}
