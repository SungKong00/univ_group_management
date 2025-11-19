package org.castlekong.backend.repository

import org.castlekong.backend.entity.PersonalEvent
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import java.time.LocalDateTime

interface PersonalEventRepository : JpaRepository<PersonalEvent, Long> {
    @Query(
        """
        SELECT e FROM PersonalEvent e
        WHERE e.user.id = :userId
          AND e.startDateTime < :periodEnd
          AND e.endDateTime > :periodStart
        ORDER BY e.startDateTime ASC
        """,
    )
    fun findEventsWithinPeriod(
        @Param("userId") userId: Long,
        @Param("periodStart") periodStart: LocalDateTime,
        @Param("periodEnd") periodEnd: LocalDateTime,
    ): List<PersonalEvent>
}
