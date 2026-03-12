package com.univgroup.domain.calendar.service

import com.univgroup.domain.calendar.entity.*
import com.univgroup.domain.calendar.repository.*
import com.univgroup.domain.group.service.IGroupService
import com.univgroup.domain.user.service.IUserService
import com.univgroup.shared.dto.ErrorCode
import com.univgroup.shared.exception.ConflictException
import com.univgroup.shared.exception.ResourceNotFoundException
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

/**
 * Calendar Domain Service 구현체
 *
 * Clean Architecture 원칙:
 * - 다른 도메인의 Repository를 직접 접근하지 않음
 * - IGroupService, IUserService를 통해 도메인 간 통신
 * - 비즈니스 로직만 포함
 * - 트랜잭션 경계 설정
 */
@Service
@Transactional(readOnly = true)
class CalendarService(
    private val groupEventRepository: GroupEventRepository,
    private val personalEventRepository: PersonalEventRepository,
    private val placeRepository: PlaceRepository,
    private val placeReservationRepository: PlaceReservationRepository,
    private val groupService: IGroupService,
    private val userService: IUserService
) : ICalendarService {

    // ========== 그룹 일정 ==========

    override fun getGroupEvent(eventId: Long): GroupEvent {
        return groupEventRepository.findById(eventId)
            .orElseThrow {
                ResourceNotFoundException(
                    ErrorCode.CALENDAR_EVENT_NOT_FOUND,
                    "그룹 일정을 찾을 수 없습니다: $eventId"
                )
            }
    }

    override fun getGroupEvents(groupId: Long): List<GroupEvent> {
        return groupEventRepository.findByGroupId(groupId)
    }

    override fun getGroupEventsByDateRange(
        groupId: Long,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<GroupEvent> {
        return groupEventRepository.findByGroupIdAndDateRange(groupId, startDate, endDate)
    }

    @Transactional
    override fun createGroupEvent(
        groupId: Long,
        createdById: Long,
        title: String,
        description: String?,
        startDatetime: LocalDateTime,
        endDatetime: LocalDateTime,
        location: String?,
        isRecurring: Boolean,
        placeId: Long?
    ): GroupEvent {
        // 그룹 존재 확인
        val group = groupService.getById(groupId)
        val createdBy = userService.getById(createdById)

        // 장소 예약이 필요한 경우, 충돌 검사
        if (placeId != null) {
            val place = getPlace(placeId)
            if (!isPlaceAvailable(placeId, startDatetime, endDatetime)) {
                throw ConflictException(
                    ErrorCode.PLACE_RESERVATION_CONFLICT,
                    "해당 시간에 이미 예약이 있습니다"
                )
            }
        }

        val event = GroupEvent(
            group = group,
            creator = createdBy,
            title = title,
            description = description,
            startDate = startDatetime,
            endDate = endDatetime,
            locationText = location
        )

        val savedEvent = groupEventRepository.save(event)

        // 장소 예약 생성
        if (placeId != null) {
            createPlaceReservation(savedEvent.id, placeId, createdById)
        }

        return savedEvent
    }

    @Transactional
    override fun updateGroupEvent(
        eventId: Long,
        title: String?,
        description: String?,
        startDatetime: LocalDateTime?,
        endDatetime: LocalDateTime?,
        location: String?
    ): GroupEvent {
        val event = getGroupEvent(eventId)

        val updatedEvent = event.copy(
            title = title ?: event.title,
            description = description ?: event.description,
            startDate = startDatetime ?: event.startDate,
            endDate = endDatetime ?: event.endDate,
            locationText = location ?: event.locationText
        )

        return groupEventRepository.save(updatedEvent)
    }

    @Transactional
    override fun deleteGroupEvent(eventId: Long) {
        val event = getGroupEvent(eventId)
        groupEventRepository.delete(event)
    }

    // ========== 개인 일정 ==========

    override fun getPersonalEvent(eventId: Long): PersonalEvent {
        return personalEventRepository.findById(eventId)
            .orElseThrow {
                ResourceNotFoundException(
                    ErrorCode.CALENDAR_EVENT_NOT_FOUND,
                    "개인 일정을 찾을 수 없습니다: $eventId"
                )
            }
    }

    override fun getPersonalEvents(userId: Long): List<PersonalEvent> {
        return personalEventRepository.findByUserId(userId)
    }

    override fun getPersonalEventsByDateRange(
        userId: Long,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<PersonalEvent> {
        return personalEventRepository.findByUserIdAndDateRange(userId, startDate, endDate)
    }

    @Transactional
    override fun createPersonalEvent(
        userId: Long,
        title: String,
        description: String?,
        startDatetime: LocalDateTime,
        endDatetime: LocalDateTime,
        location: String?,
        isRecurring: Boolean
    ): PersonalEvent {
        // 사용자 존재 확인
        val user = userService.getById(userId)

        val event = PersonalEvent(
            user = user,
            title = title,
            description = description,
            startDate = startDatetime,
            endDate = endDatetime
        )

        return personalEventRepository.save(event)
    }

    @Transactional
    override fun updatePersonalEvent(
        eventId: Long,
        title: String?,
        description: String?,
        startDatetime: LocalDateTime?,
        endDatetime: LocalDateTime?,
        location: String?
    ): PersonalEvent {
        val event = getPersonalEvent(eventId)

        val updatedEvent = event.copy(
            title = title ?: event.title,
            description = description ?: event.description,
            startDate = startDatetime ?: event.startDate,
            endDate = endDatetime ?: event.endDate
        )

        return personalEventRepository.save(updatedEvent)
    }

    @Transactional
    override fun deletePersonalEvent(eventId: Long) {
        val event = getPersonalEvent(eventId)
        personalEventRepository.delete(event)
    }

    // ========== 장소 ==========

    override fun getPlace(placeId: Long): Place {
        return placeRepository.findById(placeId)
            .orElseThrow {
                ResourceNotFoundException(
                    ErrorCode.PLACE_NOT_FOUND,
                    "장소를 찾을 수 없습니다: $placeId"
                )
            }
    }

    override fun getAllActivePlaces(): List<Place> {
        return placeRepository.findAllActive()
    }

    override fun getPlacesByGroup(groupId: Long): List<Place> {
        return placeRepository.findActiveByGroupId(groupId)
    }

    override fun isPlaceAvailable(
        placeId: Long,
        startTime: LocalDateTime,
        endTime: LocalDateTime
    ): Boolean {
        return !placeReservationRepository.existsConflictingReservation(placeId, startTime, endTime)
    }

    @Transactional
    override fun createPlaceReservation(
        groupEventId: Long,
        placeId: Long,
        reservedById: Long
    ): PlaceReservation {
        val groupEvent = getGroupEvent(groupEventId)
        val place = getPlace(placeId)
        val reservedBy = userService.getById(reservedById)

        // 충돌 검사
        if (!isPlaceAvailable(placeId, groupEvent.startDate, groupEvent.endDate)) {
            throw ConflictException(
                ErrorCode.PLACE_RESERVATION_CONFLICT,
                "해당 시간에 이미 예약이 있습니다"
            )
        }

        val reservation = PlaceReservation(
            groupEvent = groupEvent,
            place = place,
            reservedBy = reservedBy
        )

        return placeReservationRepository.save(reservation)
    }
}
