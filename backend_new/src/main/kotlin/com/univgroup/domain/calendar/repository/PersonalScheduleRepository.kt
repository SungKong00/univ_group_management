package com.univgroup.domain.calendar.repository

import com.univgroup.domain.calendar.entity.PersonalSchedule
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.time.DayOfWeek

/**
 * 개인 고정 시간표 Repository
 */
@Repository
interface PersonalScheduleRepository : JpaRepository<PersonalSchedule, Long> {
    /**
     * 사용자 ID로 모든 시간표 조회
     */
    fun findByUserId(userId: Long): List<PersonalSchedule>

    /**
     * 사용자 ID와 요일로 시간표 조회
     */
    fun findByUserIdAndDayOfWeek(userId: Long, dayOfWeek: DayOfWeek): List<PersonalSchedule>

    /**
     * 사용자 ID와 활성화 상태로 시간표 조회
     */
    fun findByUserIdAndIsActiveTrue(userId: Long): List<PersonalSchedule>

    /**
     * 사용자의 특정 요일의 활성화된 시간표 조회
     */
    fun findByUserIdAndDayOfWeekAndIsActiveTrue(userId: Long, dayOfWeek: DayOfWeek): List<PersonalSchedule>

    /**
     * 사용자의 모든 시간표 삭제
     */
    fun deleteByUserId(userId: Long)
}
