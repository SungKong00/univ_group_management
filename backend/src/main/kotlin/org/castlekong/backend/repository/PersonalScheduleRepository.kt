package org.castlekong.backend.repository

import org.castlekong.backend.entity.PersonalSchedule
import org.springframework.data.jpa.repository.JpaRepository

interface PersonalScheduleRepository : JpaRepository<PersonalSchedule, Long> {
    fun findByUserIdOrderByDayOfWeekAscStartTimeAsc(userId: Long): List<PersonalSchedule>
}
