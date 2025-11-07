package org.castlekong.backend.repository

import org.castlekong.backend.entity.PersonalSchedule
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query

interface PersonalScheduleRepository : JpaRepository<PersonalSchedule, Long> {
    @Query(
        """
        SELECT ps FROM PersonalSchedule ps
        WHERE ps.user.id = :userId
        ORDER BY
            CASE ps.dayOfWeek
                WHEN 'MONDAY' THEN 1
                WHEN 'TUESDAY' THEN 2
                WHEN 'WEDNESDAY' THEN 3
                WHEN 'THURSDAY' THEN 4
                WHEN 'FRIDAY' THEN 5
                WHEN 'SATURDAY' THEN 6
                WHEN 'SUNDAY' THEN 7
            END ASC,
            ps.startTime ASC
        """,
    )
    fun findByUserIdOrderByDayOfWeekAscStartTimeAsc(userId: Long): List<PersonalSchedule>
}
