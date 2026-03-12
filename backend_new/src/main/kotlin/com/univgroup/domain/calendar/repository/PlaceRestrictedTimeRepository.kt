package com.univgroup.domain.calendar.repository

import com.univgroup.domain.calendar.entity.PlaceRestrictedTime
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.time.DayOfWeek

/**
 * 장소 금지시간 Repository
 */
@Repository
interface PlaceRestrictedTimeRepository : JpaRepository<PlaceRestrictedTime, Long> {
    /**
     * 장소 ID로 모든 금지시간 조회
     */
    fun findByPlaceId(placeId: Long): List<PlaceRestrictedTime>

    /**
     * 장소 ID와 요일로 금지시간 조회
     */
    fun findByPlaceIdAndDayOfWeek(placeId: Long, dayOfWeek: DayOfWeek): List<PlaceRestrictedTime>

    /**
     * 장소 ID로 금지시간을 displayOrder 순으로 조회
     */
    fun findByPlaceIdOrderByDisplayOrder(placeId: Long): List<PlaceRestrictedTime>

    /**
     * 장소의 모든 금지시간 삭제
     */
    fun deleteByPlaceId(placeId: Long)
}
