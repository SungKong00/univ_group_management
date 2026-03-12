package com.univgroup.domain.calendar.repository

import com.univgroup.domain.calendar.entity.PlaceClosure
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.time.LocalDate

/**
 * 장소 휴무일 Repository
 */
@Repository
interface PlaceClosureRepository : JpaRepository<PlaceClosure, Long> {
    /**
     * 장소 ID로 모든 휴무일 조회
     */
    fun findByPlaceId(placeId: Long): List<PlaceClosure>

    /**
     * 특정 기간 내의 휴무일 조회
     */
    @Query("""
        SELECT c FROM PlaceClosure c
        WHERE c.place.id = :placeId
        AND c.closureDate >= :startDate
        AND c.closureDate <= :endDate
        ORDER BY c.closureDate ASC
    """)
    fun findByPlaceIdAndDateRange(
        placeId: Long,
        startDate: LocalDate,
        endDate: LocalDate
    ): List<PlaceClosure>

    /**
     * 장소의 특정 날짜에 휴무일 존재 여부 확인
     */
    fun existsByPlaceIdAndClosureDate(placeId: Long, closureDate: LocalDate): Boolean

    /**
     * 장소의 모든 휴무일 삭제
     */
    fun deleteByPlaceId(placeId: Long)
}
