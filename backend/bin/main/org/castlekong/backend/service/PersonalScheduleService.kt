package org.castlekong.backend.service

import org.castlekong.backend.dto.CreatePersonalScheduleRequest
import org.castlekong.backend.dto.PersonalScheduleResponse
import org.castlekong.backend.dto.UpdatePersonalScheduleRequest
import org.castlekong.backend.entity.PersonalSchedule
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.PersonalScheduleRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime
import java.time.LocalTime

@Service
@Transactional
class PersonalScheduleService(
    private val personalScheduleRepository: PersonalScheduleRepository,
) {
    @Transactional(readOnly = true)
    fun getSchedules(user: User): List<PersonalScheduleResponse> =
        personalScheduleRepository
            .findByUserIdOrderByDayOfWeekAscStartTimeAsc(user.id)
            .map { it.toResponse() }

    fun createSchedule(
        user: User,
        request: CreatePersonalScheduleRequest,
    ): PersonalScheduleResponse {
        val dayOfWeek = request.dayOfWeek ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
        val start = request.startTime ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
        val end = request.endTime ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
        validateTimeRange(start, end)

        val schedule =
            PersonalSchedule(
                user = user,
                title = request.title.trim(),
                dayOfWeek = dayOfWeek,
                startTime = start,
                endTime = end,
                location = request.location?.trim().takeUnless { it.isNullOrEmpty() },
                color = normalizeColor(request.color),
                createdAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now(),
            )
        val saved = personalScheduleRepository.save(schedule)
        return saved.toResponse()
    }

    fun updateSchedule(
        user: User,
        scheduleId: Long,
        request: UpdatePersonalScheduleRequest,
    ): PersonalScheduleResponse {
        val existing = getOwnedSchedule(user, scheduleId)
        val dayOfWeek = request.dayOfWeek ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
        val start = request.startTime ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
        val end = request.endTime ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
        validateTimeRange(start, end)

        val updated =
            existing.copy(
                title = request.title.trim(),
                dayOfWeek = dayOfWeek,
                startTime = start,
                endTime = end,
                location = request.location?.trim().takeUnless { it.isNullOrEmpty() },
                color = normalizeColor(request.color),
                updatedAt = LocalDateTime.now(),
            )
        val saved = personalScheduleRepository.save(updated)
        return saved.toResponse()
    }

    fun deleteSchedule(
        user: User,
        scheduleId: Long,
    ) {
        val schedule = getOwnedSchedule(user, scheduleId)
        personalScheduleRepository.delete(schedule)
    }

    private fun getOwnedSchedule(
        user: User,
        scheduleId: Long,
    ): PersonalSchedule {
        val schedule =
            personalScheduleRepository.findById(scheduleId)
                .orElseThrow { BusinessException(ErrorCode.PERSONAL_SCHEDULE_NOT_FOUND) }
        if (schedule.user.id != user.id) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
        return schedule
    }

    private fun validateTimeRange(
        start: LocalTime,
        end: LocalTime,
    ) {
        if (!end.isAfter(start)) {
            throw BusinessException(ErrorCode.PERSONAL_SCHEDULE_INVALID_TIME)
        }
    }

    private fun normalizeColor(color: String): String {
        val value = color.trim()
        if (!COLOR_REGEX.matches(value)) {
            throw BusinessException(ErrorCode.INVALID_REQUEST)
        }
        return value.uppercase()
    }

    private fun PersonalSchedule.toResponse(): PersonalScheduleResponse =
        PersonalScheduleResponse(
            id = id,
            title = title,
            dayOfWeek = dayOfWeek,
            startTime = startTime,
            endTime = endTime,
            location = location,
            color = color,
        )

    companion object {
        private val COLOR_REGEX = "^#[0-9A-Fa-f]{6}$".toRegex()
    }
}
