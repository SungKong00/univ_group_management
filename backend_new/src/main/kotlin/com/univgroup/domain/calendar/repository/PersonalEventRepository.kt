package com.univgroup.domain.calendar.repository

import com.univgroup.domain.calendar.entity.PersonalEvent
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

/**
 * 개인 일정 Repository
 */
@Repository
interface PersonalEventRepository : JpaRepository<PersonalEvent, Long> {
    /**
     * 사용자 ID로 모든 개인 일정 조회
     */
    fun findByUserId(userId: Long): List<PersonalEvent>

    /**
     * 특정 기간 내의 개인 일정 조회
     */
    @Query("""
        SELECT e FROM PersonalEvent e
        WHERE e.user.id = :userId
        AND e.startDatetime <= :endDate
        AND e.endDatetime >= :startDate
        ORDER BY e.startDatetime ASC
    """)
    fun findByUserIdAndDateRange(
        userId: Long,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<PersonalEvent>

    /**
     * 사용자의 반복 일정 조회
     */
    fun findByUserIdAndIsRecurringTrue(userId: Long): List<PersonalEvent>

    /**
     * 사용자의 모든 개인 일정 삭제
     */
    fun deleteByUserId(userId: Long)
}
