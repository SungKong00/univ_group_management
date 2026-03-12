package org.castlekong.backend.repository

import org.castlekong.backend.entity.PlaceRestrictedTime
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.DayOfWeek

/**
 * PlaceRestrictedTimeRepository
 *
 * 장소 금지시간 데이터 접근 레포지토리
 */
@Repository
interface PlaceRestrictedTimeRepository : JpaRepository<PlaceRestrictedTime, Long> {
    /**
     * 특정 장소의 모든 금지시간 조회 (정렬: displayOrder)
     */
    @Query("SELECT prt FROM PlaceRestrictedTime prt WHERE prt.place.id = :placeId ORDER BY prt.dayOfWeek, prt.displayOrder")
    fun findByPlaceId(
        @Param("placeId") placeId: Long,
    ): List<PlaceRestrictedTime>

    /**
     * 특정 장소의 특정 요일 금지시간 조회
     */
    @Query(
        "SELECT prt FROM PlaceRestrictedTime prt " +
            "WHERE prt.place.id = :placeId AND prt.dayOfWeek = :dayOfWeek " +
            "ORDER BY prt.displayOrder",
    )
    fun findByPlaceIdAndDayOfWeek(
        @Param("placeId") placeId: Long,
        @Param("dayOfWeek") dayOfWeek: DayOfWeek,
    ): List<PlaceRestrictedTime>

    /**
     * 특정 장소의 모든 금지시간 삭제
     */
    fun deleteByPlaceId(placeId: Long)
}
