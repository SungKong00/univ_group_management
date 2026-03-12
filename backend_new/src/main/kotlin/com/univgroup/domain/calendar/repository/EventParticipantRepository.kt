package com.univgroup.domain.calendar.repository

import com.univgroup.domain.calendar.entity.EventParticipant
import com.univgroup.domain.calendar.entity.ParticipantStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

/**
 * 일정 참가자 Repository
 */
@Repository
interface EventParticipantRepository : JpaRepository<EventParticipant, Long> {
    /**
     * 그룹 일정 ID로 모든 참가자 조회
     */
    fun findByGroupEventId(groupEventId: Long): List<EventParticipant>

    /**
     * 사용자 ID로 모든 참가 일정 조회
     */
    fun findByUserId(userId: Long): List<EventParticipant>

    /**
     * 그룹 일정 ID와 사용자 ID로 참가자 조회
     */
    fun findByGroupEventIdAndUserId(groupEventId: Long, userId: Long): EventParticipant?

    /**
     * 그룹 일정 ID와 참가 상태로 참가자 조회
     */
    fun findByGroupEventIdAndStatus(groupEventId: Long, status: ParticipantStatus): List<EventParticipant>

    /**
     * 그룹 일정의 참가 상태별 참가자 수 조회
     */
    fun countByGroupEventIdAndStatus(groupEventId: Long, status: ParticipantStatus): Long

    /**
     * 사용자의 참가 여부 확인
     */
    fun existsByGroupEventIdAndUserId(groupEventId: Long, userId: Long): Boolean

    /**
     * 그룹 일정의 모든 참가자 삭제
     */
    fun deleteByGroupEventId(groupEventId: Long)
}
