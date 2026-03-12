package com.univgroup.domain.calendar.repository

import com.univgroup.domain.calendar.entity.GroupEvent
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

/**
 * 그룹 일정 Repository
 */
@Repository
interface GroupEventRepository : JpaRepository<GroupEvent, Long> {
    /**
     * 그룹 ID로 모든 일정 조회
     */
    fun findByGroupId(groupId: Long): List<GroupEvent>

    /**
     * 생성자 ID로 모든 일정 조회
     */
    fun findByCreatedById(createdById: Long): List<GroupEvent>

    /**
     * 특정 기간 내의 그룹 일정 조회
     */
    @Query("""
        SELECT e FROM GroupEvent e
        WHERE e.group.id = :groupId
        AND e.startDatetime <= :endDate
        AND e.endDatetime >= :startDate
        ORDER BY e.startDatetime ASC
    """)
    fun findByGroupIdAndDateRange(
        groupId: Long,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<GroupEvent>

    /**
     * 그룹의 반복 일정 조회
     */
    fun findByGroupIdAndIsRecurringTrue(groupId: Long): List<GroupEvent>

    /**
     * 그룹의 모든 일정 삭제
     */
    fun deleteByGroupId(groupId: Long)
}
