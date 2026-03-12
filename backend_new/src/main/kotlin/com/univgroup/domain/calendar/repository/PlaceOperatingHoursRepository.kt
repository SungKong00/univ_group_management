package com.univgroup.domain.calendar.repository

import com.univgroup.domain.calendar.entity.PlaceOperatingHours
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.time.DayOfWeek

/**
 * 장소 운영시간 Repository
 */
@Repository
interface PlaceOperatingHoursRepository : JpaRepository<PlaceOperatingHours, Long> {
    /**
     * 장소 ID로 모든 운영시간 조회
     */
    fun findByPlaceId(placeId: Long): List<PlaceOperatingHours>

    /**
     * 장소 ID와 요일로 운영시간 조회
     */
    fun findByPlaceIdAndDayOfWeek(placeId: Long, dayOfWeek: DayOfWeek): PlaceOperatingHours?

    /**
     * 장소 ID와 운영 여부로 조회
     */
    fun findByPlaceIdAndIsClosed(placeId: Long, isClosed: Boolean): List<PlaceOperatingHours>

    /**
     * 장소의 모든 운영시간 삭제
     */
    fun deleteByPlaceId(placeId: Long)
}
