package org.castlekong.backend.repository

import org.castlekong.backend.entity.PlaceAvailability
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.DayOfWeek

/**
 * PlaceAvailabilityRepository
 *
 * 장소 운영 시간 조회 및 관리를 위한 Repository
 */
@Repository
interface PlaceAvailabilityRepository : JpaRepository<PlaceAvailability, Long> {

    /**
     * 장소의 모든 운영 시간 조회
     */
    @Query("""
        SELECT pa FROM PlaceAvailability pa
        WHERE pa.place.id = :placeId
        ORDER BY pa.dayOfWeek, pa.displayOrder, pa.startTime
    """)
    fun findByPlaceId(@Param("placeId") placeId: Long): List<PlaceAvailability>

    /**
     * 특정 요일의 운영 시간 조회
     */
    @Query("""
        SELECT pa FROM PlaceAvailability pa
        WHERE pa.place.id = :placeId
        AND pa.dayOfWeek = :dayOfWeek
        ORDER BY pa.displayOrder, pa.startTime
    """)
    fun findByPlaceIdAndDayOfWeek(
        @Param("placeId") placeId: Long,
        @Param("dayOfWeek") dayOfWeek: DayOfWeek
    ): List<PlaceAvailability>

    /**
     * 장소의 운영 시간 일괄 삭제
     */
    @Modifying
    @Query("DELETE FROM PlaceAvailability pa WHERE pa.place.id = :placeId")
    fun deleteByPlaceId(@Param("placeId") placeId: Long)

    /**
     * 장소가 특정 요일에 운영하는지 확인
     */
    @Query("""
        SELECT CASE WHEN COUNT(pa) > 0 THEN true ELSE false END
        FROM PlaceAvailability pa
        WHERE pa.place.id = :placeId
        AND pa.dayOfWeek = :dayOfWeek
    """)
    fun existsByPlaceIdAndDayOfWeek(
        @Param("placeId") placeId: Long,
        @Param("dayOfWeek") dayOfWeek: DayOfWeek
    ): Boolean
}
