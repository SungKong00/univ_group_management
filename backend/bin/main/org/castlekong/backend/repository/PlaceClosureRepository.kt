package org.castlekong.backend.repository

import org.castlekong.backend.entity.PlaceClosure
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDate
import java.util.Optional

/**
 * PlaceClosureRepository
 *
 * 장소 임시 휴무 데이터 접근 레포지토리
 */
@Repository
interface PlaceClosureRepository : JpaRepository<PlaceClosure, Long> {
    /**
     * 특정 장소의 모든 임시 휴무 조회 (정렬: 날짜)
     */
    @Query("SELECT pc FROM PlaceClosure pc WHERE pc.place.id = :placeId ORDER BY pc.closureDate")
    fun findByPlaceId(
        @Param("placeId") placeId: Long,
    ): List<PlaceClosure>

    /**
     * 특정 장소의 날짜 범위 내 임시 휴무 조회
     */
    @Query(
        "SELECT pc FROM PlaceClosure pc " +
            "WHERE pc.place.id = :placeId " +
            "AND pc.closureDate >= :from " +
            "AND pc.closureDate <= :to " +
            "ORDER BY pc.closureDate",
    )
    fun findByPlaceIdAndDateRange(
        @Param("placeId") placeId: Long,
        @Param("from") from: LocalDate,
        @Param("to") to: LocalDate,
    ): List<PlaceClosure>

    /**
     * 특정 장소의 특정 날짜 임시 휴무 조회
     */
    @Query("SELECT pc FROM PlaceClosure pc WHERE pc.place.id = :placeId AND pc.closureDate = :date")
    fun findByPlaceIdAndDate(
        @Param("placeId") placeId: Long,
        @Param("date") date: LocalDate,
    ): Optional<PlaceClosure>

    /**
     * 특정 장소의 모든 임시 휴무 삭제
     */
    fun deleteByPlaceId(placeId: Long)
}
