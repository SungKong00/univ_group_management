package org.castlekong.backend.repository

import org.castlekong.backend.entity.PlaceOperatingHours
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.DayOfWeek
import java.util.Optional

/**
 * PlaceOperatingHoursRepository
 *
 * 장소 운영시간 데이터 접근 레포지토리
 */
@Repository
interface PlaceOperatingHoursRepository : JpaRepository<PlaceOperatingHours, Long> {
    /**
     * 특정 장소의 모든 운영시간 조회
     */
    @Query("SELECT poh FROM PlaceOperatingHours poh WHERE poh.place.id = :placeId ORDER BY poh.dayOfWeek")
    fun findByPlaceId(
        @Param("placeId") placeId: Long,
    ): List<PlaceOperatingHours>

    /**
     * 특정 장소의 특정 요일 운영시간 조회
     */
    @Query("SELECT poh FROM PlaceOperatingHours poh WHERE poh.place.id = :placeId AND poh.dayOfWeek = :dayOfWeek")
    fun findByPlaceIdAndDayOfWeek(
        @Param("placeId") placeId: Long,
        @Param("dayOfWeek") dayOfWeek: DayOfWeek,
    ): Optional<PlaceOperatingHours>

    /**
     * 특정 장소의 운영시간이 설정되어 있는지 확인
     */
    @Query("SELECT COUNT(poh) > 0 FROM PlaceOperatingHours poh WHERE poh.place.id = :placeId")
    fun existsByPlaceId(
        @Param("placeId") placeId: Long,
    ): Boolean

    /**
     * 특정 장소의 모든 운영시간 삭제
     */
    fun deleteByPlaceId(placeId: Long)
}
