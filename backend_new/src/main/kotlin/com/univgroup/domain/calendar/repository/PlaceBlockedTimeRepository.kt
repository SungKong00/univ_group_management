package com.univgroup.domain.calendar.repository

import com.univgroup.domain.calendar.entity.BlockType
import com.univgroup.domain.calendar.entity.PlaceBlockedTime
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

/**
 * 예약 차단 시간 Repository
 */
@Repository
interface PlaceBlockedTimeRepository : JpaRepository<PlaceBlockedTime, Long> {
    /**
     * 장소 ID로 모든 차단 시간 조회
     */
    fun findByPlaceId(placeId: Long): List<PlaceBlockedTime>

    /**
     * 장소 ID와 차단 유형으로 조회
     */
    fun findByPlaceIdAndBlockType(placeId: Long, blockType: BlockType): List<PlaceBlockedTime>

    /**
     * 특정 기간 내의 차단 시간 조회
     */
    @Query("""
        SELECT bt FROM PlaceBlockedTime bt
        WHERE bt.place.id = :placeId
        AND bt.startDatetime < :endTime
        AND bt.endDatetime > :startTime
        ORDER BY bt.startDatetime ASC
    """)
    fun findByPlaceIdAndTimeRange(
        placeId: Long,
        startTime: LocalDateTime,
        endTime: LocalDateTime
    ): List<PlaceBlockedTime>

    /**
     * 장소의 모든 차단 시간 삭제
     */
    fun deleteByPlaceId(placeId: Long)
}
