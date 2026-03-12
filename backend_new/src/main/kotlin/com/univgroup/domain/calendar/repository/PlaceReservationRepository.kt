package com.univgroup.domain.calendar.repository

import com.univgroup.domain.calendar.entity.PlaceReservation
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

/**
 * 장소 예약 Repository
 */
@Repository
interface PlaceReservationRepository : JpaRepository<PlaceReservation, Long> {
    /**
     * 장소 ID로 모든 예약 조회
     */
    fun findByPlaceId(placeId: Long): List<PlaceReservation>

    /**
     * 그룹 일정 ID로 예약 조회
     */
    fun findByGroupEventId(groupEventId: Long): PlaceReservation?

    /**
     * 예약자 ID로 모든 예약 조회
     */
    fun findByReservedById(reservedById: Long): List<PlaceReservation>

    /**
     * 특정 기간 내의 장소 예약 조회
     */
    @Query("""
        SELECT r FROM PlaceReservation r
        JOIN r.groupEvent e
        WHERE r.place.id = :placeId
        AND e.startDatetime < :endTime
        AND e.endDatetime > :startTime
        ORDER BY e.startDatetime ASC
    """)
    fun findByPlaceIdAndTimeRange(
        placeId: Long,
        startTime: LocalDateTime,
        endTime: LocalDateTime
    ): List<PlaceReservation>

    /**
     * 장소의 특정 시간대에 예약 존재 여부 확인 (충돌 검사)
     */
    @Query("""
        SELECT CASE WHEN COUNT(r) > 0 THEN true ELSE false END
        FROM PlaceReservation r
        JOIN r.groupEvent e
        WHERE r.place.id = :placeId
        AND e.startDatetime < :endTime
        AND e.endDatetime > :startTime
    """)
    fun existsConflictingReservation(
        placeId: Long,
        startTime: LocalDateTime,
        endTime: LocalDateTime
    ): Boolean

    /**
     * 장소의 모든 예약 삭제
     */
    fun deleteByPlaceId(placeId: Long)
}
