package org.castlekong.backend.repository

import org.castlekong.backend.entity.EventParticipant
import org.castlekong.backend.entity.ParticipantStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.Optional

/**
 * EventParticipant 엔티티의 Repository
 *
 * 그룹 일정의 참여자 관리를 위한 데이터 액세스 레이어입니다.
 */
@Repository
interface EventParticipantRepository : JpaRepository<EventParticipant, Long> {
    /**
     * 특정 그룹 일정의 모든 참여자 조회
     *
     * @param groupEventId 그룹 일정 ID
     * @return 해당 일정의 모든 참여자 목록
     */
    fun findByGroupEventId(groupEventId: Long): List<EventParticipant>

    /**
     * 특정 사용자가 참여하는 모든 일정 조회
     *
     * @param userId 사용자 ID
     * @return 해당 사용자의 모든 참여 일정 목록
     */
    fun findByUserId(userId: Long): List<EventParticipant>

    /**
     * 특정 그룹 일정의 특정 상태 참여자 수 조회
     *
     * @param groupEventId 그룹 일정 ID
     * @param status 참여 상태
     * @return 해당 상태의 참여자 수
     */
    fun countByGroupEventIdAndStatus(
        groupEventId: Long,
        status: ParticipantStatus,
    ): Long

    /**
     * 특정 그룹 일정의 특정 사용자 참여 정보 조회
     *
     * @param groupEventId 그룹 일정 ID
     * @param userId 사용자 ID
     * @return 참여 정보 (존재하지 않으면 Optional.empty())
     */
    fun findByGroupEventIdAndUserId(
        groupEventId: Long,
        userId: Long,
    ): Optional<EventParticipant>

    /**
     * 특정 사용자가 특정 상태로 참여하는 일정 조회
     *
     * @param userId 사용자 ID
     * @param status 참여 상태
     * @return 해당 상태의 참여 일정 목록
     */
    fun findByUserIdAndStatus(
        userId: Long,
        status: ParticipantStatus,
    ): List<EventParticipant>

    /**
     * 여러 그룹 일정의 참여자 배치 삭제
     *
     * 그룹 일정 삭제 시 관련된 모든 참여자 정보를 함께 삭제합니다.
     *
     * @param eventIds 삭제할 그룹 일정 ID 목록
     * @return 삭제된 레코드 수
     */
    @Modifying
    @Query("DELETE FROM EventParticipant ep WHERE ep.groupEvent.id IN :eventIds")
    fun deleteByGroupEventIds(
        @Param("eventIds") eventIds: List<Long>,
    ): Int
}
