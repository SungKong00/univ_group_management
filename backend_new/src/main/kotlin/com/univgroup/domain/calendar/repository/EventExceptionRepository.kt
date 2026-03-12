package com.univgroup.domain.calendar.repository

import com.univgroup.domain.calendar.entity.EventException
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.time.LocalDate

/**
 * 반복 일정 예외 Repository
 */
@Repository
interface EventExceptionRepository : JpaRepository<EventException, Long> {
    /**
     * 그룹 일정 ID로 모든 예외 조회
     */
    fun findByGroupEventId(groupEventId: Long): List<EventException>

    /**
     * 그룹 일정 ID와 날짜로 예외 조회
     */
    fun findByGroupEventIdAndExceptionDate(groupEventId: Long, exceptionDate: LocalDate): EventException?

    /**
     * 그룹 일정의 특정 날짜에 예외 존재 여부 확인
     */
    fun existsByGroupEventIdAndExceptionDate(groupEventId: Long, exceptionDate: LocalDate): Boolean

    /**
     * 그룹 일정의 모든 예외 삭제
     */
    fun deleteByGroupEventId(groupEventId: Long)
}
