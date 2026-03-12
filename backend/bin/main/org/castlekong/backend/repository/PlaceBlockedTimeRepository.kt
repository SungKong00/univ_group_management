package org.castlekong.backend.repository

import org.castlekong.backend.entity.BlockType
import org.castlekong.backend.entity.PlaceBlockedTime
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

/**
 * PlaceBlockedTimeRepository
 *
 * 장소 차단 시간 조회 및 관리를 위한 Repository
 */
@Repository
interface PlaceBlockedTimeRepository : JpaRepository<PlaceBlockedTime, Long> {
    /**
     * 시간 충돌 검사 (예약 가능 여부 확인용)
     */
    @Query(
        """
        SELECT bt FROM PlaceBlockedTime bt
        WHERE bt.place.id = :placeId
        AND bt.startDatetime < :endDatetime
        AND bt.endDatetime > :startDatetime
    """,
    )
    fun findConflicts(
        @Param("placeId") placeId: Long,
        @Param("startDatetime") startDatetime: LocalDateTime,
        @Param("endDatetime") endDatetime: LocalDateTime,
    ): List<PlaceBlockedTime>

    /**
     * 날짜 범위의 차단 시간 조회 (설계 문서 요구사항)
     * - Phase 1: 데이터 모델 구현에서 요구되는 메서드
     * - 예약 가능 검증 3단계 중 Step 2 (차단 시간 확인)에서 사용
     */
    @Query(
        """
        SELECT bt FROM PlaceBlockedTime bt
        WHERE bt.place.id = :placeId
        AND bt.startDatetime < :endDate
        AND bt.endDatetime > :startDate
        ORDER BY bt.startDatetime
    """,
    )
    fun findByPlaceIdAndDateRange(
        @Param("placeId") placeId: Long,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime,
    ): List<PlaceBlockedTime>

    /**
     * 특정 기간의 차단 시간 목록 조회
     */
    @Query(
        """
        SELECT bt FROM PlaceBlockedTime bt
        JOIN FETCH bt.createdBy
        WHERE bt.place.id = :placeId
        AND bt.startDatetime < :endDatetime
        AND bt.endDatetime > :startDatetime
        ORDER BY bt.startDatetime
    """,
    )
    fun findByPlaceIdAndTimeRange(
        @Param("placeId") placeId: Long,
        @Param("startDatetime") startDatetime: LocalDateTime,
        @Param("endDatetime") endDatetime: LocalDateTime,
    ): List<PlaceBlockedTime>

    /**
     * 장소의 모든 차단 시간 조회
     */
    @Query(
        """
        SELECT bt FROM PlaceBlockedTime bt
        WHERE bt.place.id = :placeId
        ORDER BY bt.startDatetime
    """,
    )
    fun findByPlaceId(
        @Param("placeId") placeId: Long,
    ): List<PlaceBlockedTime>

    /**
     * 차단 유형별 조회
     */
    @Query(
        """
        SELECT bt FROM PlaceBlockedTime bt
        WHERE bt.place.id = :placeId
        AND bt.blockType = :blockType
        ORDER BY bt.startDatetime
    """,
    )
    fun findByPlaceIdAndBlockType(
        @Param("placeId") placeId: Long,
        @Param("blockType") blockType: BlockType,
    ): List<PlaceBlockedTime>

    /**
     * 관리자가 생성한 차단 시간 조회
     */
    @Query(
        """
        SELECT bt FROM PlaceBlockedTime bt
        WHERE bt.createdBy.id = :userId
        ORDER BY bt.createdAt DESC
    """,
    )
    fun findByCreatedBy(
        @Param("userId") userId: Long,
    ): List<PlaceBlockedTime>

    /**
     * 미래 차단 시간 조회
     */
    @Query(
        """
        SELECT bt FROM PlaceBlockedTime bt
        WHERE bt.place.id = :placeId
        AND bt.endDatetime > :now
        ORDER BY bt.startDatetime
    """,
    )
    fun findFutureBlockedTimes(
        @Param("placeId") placeId: Long,
        @Param("now") now: LocalDateTime,
    ): List<PlaceBlockedTime>
}
