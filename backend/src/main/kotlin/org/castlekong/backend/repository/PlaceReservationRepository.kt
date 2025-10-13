package org.castlekong.backend.repository

import org.castlekong.backend.entity.PlaceReservation
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

/**
 * PlaceReservationRepository
 *
 * 장소 예약 조회 및 관리를 위한 Repository
 * - 시간 충돌 검사 (낙관적 락 기반 동시성 제어)
 * - 날짜 범위 조회 (장소 캘린더 뷰)
 * - 사용자별 예약 조회
 */
@Repository
interface PlaceReservationRepository : JpaRepository<PlaceReservation, Long> {
    /**
     * 시간 충돌 검사 쿼리
     *
     * 특정 장소에서 주어진 시간대와 겹치는 예약 조회
     * - 충돌 로직: (start1 < end2) AND (end1 > start2)
     * - 수정 시 자기 자신은 제외
     *
     * @param placeId 장소 ID
     * @param startDateTime 예약 시작 시간
     * @param endDateTime 예약 종료 시간
     * @param excludeReservationId 제외할 예약 ID (수정 시, nullable)
     * @return 겹치는 예약 목록
     */
    @Query(
        """
        SELECT pr FROM PlaceReservation pr
        JOIN FETCH pr.groupEvent ge
        JOIN FETCH pr.place p
        WHERE pr.place.id = :placeId
        AND ge.startDate < :endDateTime
        AND ge.endDate > :startDateTime
        AND (:excludeReservationId IS NULL OR pr.id != :excludeReservationId)
        ORDER BY ge.startDate ASC
    """,
    )
    fun findOverlappingReservations(
        @Param("placeId") placeId: Long,
        @Param("startDateTime") startDateTime: LocalDateTime,
        @Param("endDateTime") endDateTime: LocalDateTime,
        @Param("excludeReservationId") excludeReservationId: Long? = null,
    ): List<PlaceReservation>

    /**
     * 날짜 범위 조회 (단일 장소)
     *
     * 특정 장소의 특정 기간 예약 목록
     * - 장소 캘린더 뷰에서 사용
     * - N+1 방지: JOIN FETCH로 GroupEvent, Place 한 번에 로드
     *
     * @param placeId 장소 ID
     * @param startDate 조회 시작 날짜
     * @param endDate 조회 종료 날짜
     * @return 예약 목록 (시작 시간 순)
     */
    @Query(
        """
        SELECT pr FROM PlaceReservation pr
        JOIN FETCH pr.groupEvent ge
        JOIN FETCH pr.place p
        WHERE pr.place.id = :placeId
        AND ge.startDate >= :startDate
        AND ge.startDate < :endDate
        ORDER BY ge.startDate ASC
    """,
    )
    fun findByPlaceIdAndDateRange(
        @Param("placeId") placeId: Long,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime,
    ): List<PlaceReservation>

    /**
     * GroupEvent 기반 조회
     *
     * GroupEvent와 1:1 관계이므로 단일 결과 반환
     * - 일정 삭제 시 예약 확인용
     * - 일정 조회 시 장소 정보 연동
     *
     * @param groupEventId 그룹 일정 ID
     * @return 연결된 예약 (없으면 null)
     */
    @Query(
        """
        SELECT pr FROM PlaceReservation pr
        JOIN FETCH pr.groupEvent ge
        JOIN FETCH pr.place p
        WHERE pr.groupEvent.id = :groupEventId
    """,
    )
    fun findByGroupEventId(
        @Param("groupEventId") groupEventId: Long,
    ): PlaceReservation?

    /**
     * 다중 장소 날짜 범위 조회
     *
     * 여러 장소의 특정 기간 예약 목록
     * - 프론트엔드 멀티 플레이스 뷰용
     * - 건물별 전체 예약 조회 시 사용
     *
     * @param placeIds 장소 ID 목록
     * @param startDate 조회 시작 날짜
     * @param endDate 조회 종료 날짜
     * @return 예약 목록 (시작 시간 순)
     */
    @Query(
        """
        SELECT pr FROM PlaceReservation pr
        JOIN FETCH pr.groupEvent ge
        JOIN FETCH pr.place p
        WHERE pr.place.id IN :placeIds
        AND ge.startDate >= :startDate
        AND ge.startDate < :endDate
        ORDER BY ge.startDate ASC
    """,
    )
    fun findByPlaceIdsAndDateRange(
        @Param("placeIds") placeIds: List<Long>,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime,
    ): List<PlaceReservation>

    /**
     * 사용자별 예약 조회
     *
     * 특정 사용자의 예약 목록
     * - 내 예약 조회 기능
     * - 예약 취소 권한 확인
     *
     * @param userId 사용자 ID
     * @param startDate 조회 시작 날짜
     * @param endDate 조회 종료 날짜
     * @return 예약 목록 (시작 시간 순)
     */
    @Query(
        """
        SELECT pr FROM PlaceReservation pr
        JOIN FETCH pr.groupEvent ge
        JOIN FETCH pr.place p
        WHERE pr.reservedBy.id = :userId
        AND ge.startDate >= :startDate
        AND ge.startDate < :endDate
        ORDER BY ge.startDate ASC
    """,
    )
    fun findByReservedByAndDateRange(
        @Param("userId") userId: Long,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime,
    ): List<PlaceReservation>
}
