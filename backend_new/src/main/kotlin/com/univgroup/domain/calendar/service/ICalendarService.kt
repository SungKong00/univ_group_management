package com.univgroup.domain.calendar.service

import com.univgroup.domain.calendar.entity.*
import java.time.LocalDate
import java.time.LocalDateTime

/**
 * Calendar Domain Service Interface
 *
 * 그룹 일정, 개인 일정, 장소 예약 관리 비즈니스 로직을 정의한다.
 * Phase 2에서는 기본적인 CRUD만 구현하며,
 * Phase 3에서 권한 검증 로직이 추가된다.
 */
interface ICalendarService {
    // ========== 그룹 일정 ==========

    /**
     * 그룹 일정 조회
     * @throws ResourceNotFoundException 일정이 존재하지 않을 경우
     */
    fun getGroupEvent(eventId: Long): GroupEvent

    /**
     * 그룹의 모든 일정 조회
     */
    fun getGroupEvents(groupId: Long): List<GroupEvent>

    /**
     * 그룹의 특정 기간 일정 조회
     */
    fun getGroupEventsByDateRange(
        groupId: Long,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<GroupEvent>

    /**
     * 그룹 일정 생성
     * @throws ResourceNotFoundException 그룹이 존재하지 않을 경우
     * @throws ConflictException 장소 예약 충돌 시
     */
    fun createGroupEvent(
        groupId: Long,
        createdById: Long,
        title: String,
        description: String?,
        startDatetime: LocalDateTime,
        endDatetime: LocalDateTime,
        location: String?,
        isRecurring: Boolean = false,
        placeId: Long? = null
    ): GroupEvent

    /**
     * 그룹 일정 수정
     * @throws ResourceNotFoundException 일정이 존재하지 않을 경우
     */
    fun updateGroupEvent(
        eventId: Long,
        title: String?,
        description: String?,
        startDatetime: LocalDateTime?,
        endDatetime: LocalDateTime?,
        location: String?
    ): GroupEvent

    /**
     * 그룹 일정 삭제
     * @throws ResourceNotFoundException 일정이 존재하지 않을 경우
     */
    fun deleteGroupEvent(eventId: Long)

    // ========== 개인 일정 ==========

    /**
     * 개인 일정 조회
     * @throws ResourceNotFoundException 일정이 존재하지 않을 경우
     */
    fun getPersonalEvent(eventId: Long): PersonalEvent

    /**
     * 사용자의 모든 개인 일정 조회
     */
    fun getPersonalEvents(userId: Long): List<PersonalEvent>

    /**
     * 사용자의 특정 기간 개인 일정 조회
     */
    fun getPersonalEventsByDateRange(
        userId: Long,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<PersonalEvent>

    /**
     * 개인 일정 생성
     * @throws ResourceNotFoundException 사용자가 존재하지 않을 경우
     */
    fun createPersonalEvent(
        userId: Long,
        title: String,
        description: String?,
        startDatetime: LocalDateTime,
        endDatetime: LocalDateTime,
        location: String?,
        isRecurring: Boolean = false
    ): PersonalEvent

    /**
     * 개인 일정 수정
     * @throws ResourceNotFoundException 일정이 존재하지 않을 경우
     */
    fun updatePersonalEvent(
        eventId: Long,
        title: String?,
        description: String?,
        startDatetime: LocalDateTime?,
        endDatetime: LocalDateTime?,
        location: String?
    ): PersonalEvent

    /**
     * 개인 일정 삭제
     * @throws ResourceNotFoundException 일정이 존재하지 않을 경우
     */
    fun deletePersonalEvent(eventId: Long)

    // ========== 장소 ==========

    /**
     * 장소 조회
     * @throws ResourceNotFoundException 장소가 존재하지 않을 경우
     */
    fun getPlace(placeId: Long): Place

    /**
     * 모든 활성화된 장소 조회
     */
    fun getAllActivePlaces(): List<Place>

    /**
     * 그룹이 관리하는 장소 조회
     */
    fun getPlacesByGroup(groupId: Long): List<Place>

    /**
     * 장소 예약 가능 여부 확인
     * @return true if available, false if conflicting
     */
    fun isPlaceAvailable(
        placeId: Long,
        startTime: LocalDateTime,
        endTime: LocalDateTime
    ): Boolean

    /**
     * 장소 예약 생성 (GroupEvent와 함께)
     * @throws ConflictException 예약 충돌 시
     */
    fun createPlaceReservation(
        groupEventId: Long,
        placeId: Long,
        reservedById: Long
    ): PlaceReservation
}
