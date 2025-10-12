package org.castlekong.backend.repository

import org.castlekong.backend.entity.GroupEvent
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import java.time.LocalDateTime

interface GroupEventRepository : JpaRepository<GroupEvent, Long> {
    /**
     * 그룹 ID와 날짜 범위로 일정 조회
     * 캘린더 뷰에서 특정 기간의 일정을 표시할 때 사용
     *
     * N+1 문제 해결: JOIN FETCH로 Group, User 한 번에 로드
     */
    @Query("""
        SELECT e FROM GroupEvent e
        JOIN FETCH e.group g
        JOIN FETCH e.creator c
        WHERE e.group.id = :groupId
        AND e.startDate >= :startDate
        AND e.startDate < :endDate
        ORDER BY e.startDate ASC
    """)
    fun findByGroupIdAndStartDateBetween(
        @Param("groupId") groupId: Long,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime,
    ): List<GroupEvent>

    /**
     * 반복 일정 시리즈 ID로 모든 인스턴스 조회
     * 반복 일정 전체 수정/삭제 시 사용
     */
    fun findBySeriesId(seriesId: String): List<GroupEvent>

    /**
     * 그룹 ID와 공식/비공식 구분으로 일정 조회
     */
    fun findByGroupIdAndIsOfficial(
        groupId: Long,
        isOfficial: Boolean,
    ): List<GroupEvent>

    /**
     * 반복 일정의 미래 인스턴스 조회
     * "이 일정 이후 모두 수정/삭제" 기능에 사용
     */
    @Query(
        """
        SELECT e FROM GroupEvent e
        WHERE e.group.id = :groupId
        AND e.seriesId = :seriesId
        AND e.startDate >= :fromDate
        ORDER BY e.startDate ASC
    """,
    )
    fun findFutureEventsBySeries(
        @Param("groupId") groupId: Long,
        @Param("seriesId") seriesId: String,
        @Param("fromDate") fromDate: LocalDateTime,
    ): List<GroupEvent>

    /**
     * 작성자 ID로 일정 조회
     * 비공식 일정 수정/삭제 권한 확인 시 사용
     */
    fun findByCreatorId(creatorId: Long): List<GroupEvent>

    /**
     * 그룹의 특정 날짜 일정 조회
     * 날짜별 일정 목록 표시 시 사용
     */
    @Query(
        """
        SELECT e FROM GroupEvent e
        WHERE e.group.id = :groupId
        AND DATE(e.startDate) = DATE(:date)
        ORDER BY e.startDate ASC
    """,
    )
    fun findByGroupIdAndDate(
        @Param("groupId") groupId: Long,
        @Param("date") date: LocalDateTime,
    ): List<GroupEvent>
}
