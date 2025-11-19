package org.castlekong.backend.service

import org.castlekong.backend.entity.EventParticipant
import org.castlekong.backend.entity.ParticipantStatus
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.EventParticipantRepository
import org.castlekong.backend.repository.GroupEventRepository
import org.castlekong.backend.repository.UserRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

/**
 * EventParticipant 관리 서비스
 *
 * 그룹 일정의 참여자 관리 비즈니스 로직을 처리합니다.
 */
@Service
@Transactional(readOnly = true)
class EventParticipantService(
    private val eventParticipantRepository: EventParticipantRepository,
    private val groupEventRepository: GroupEventRepository,
    private val userRepository: UserRepository,
) {
    /**
     * 참여자 추가 또는 업데이트
     *
     * 이미 존재하는 참여자의 경우 상태를 업데이트합니다.
     *
     * @param groupEventId 그룹 일정 ID
     * @param userId 사용자 ID
     * @param status 참여 상태
     * @return 생성 또는 업데이트된 참여자 정보
     */
    @Transactional
    fun addOrUpdateParticipant(
        groupEventId: Long,
        userId: Long,
        status: ParticipantStatus,
    ): EventParticipant {
        val groupEvent =
            groupEventRepository.findById(groupEventId)
                .orElseThrow { BusinessException(ErrorCode.EVENT_NOT_FOUND) }

        val user =
            userRepository.findById(userId)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        // 기존 참여자 확인
        val existing = eventParticipantRepository.findByGroupEventIdAndUserId(groupEventId, userId)

        return if (existing.isPresent) {
            // 기존 참여자 상태 업데이트
            val participant = existing.get()
            val updated =
                EventParticipant(
                    id = participant.id,
                    groupEvent = participant.groupEvent,
                    user = participant.user,
                    status = status,
                    createdAt = participant.createdAt,
                    updatedAt = LocalDateTime.now(),
                )
            eventParticipantRepository.save(updated)
        } else {
            // 신규 참여자 추가
            val newParticipant =
                EventParticipant(
                    groupEvent = groupEvent,
                    user = user,
                    status = status,
                )
            eventParticipantRepository.save(newParticipant)
        }
    }

    /**
     * 참여 상태 업데이트
     *
     * @param participantId 참여자 ID
     * @param newStatus 새로운 참여 상태
     * @return 업데이트된 참여자 정보
     */
    @Transactional
    fun updateParticipantStatus(
        participantId: Long,
        newStatus: ParticipantStatus,
    ): EventParticipant {
        val participant =
            eventParticipantRepository.findById(participantId)
                .orElseThrow { BusinessException(ErrorCode.PARTICIPANT_NOT_FOUND) }

        val updated =
            EventParticipant(
                id = participant.id,
                groupEvent = participant.groupEvent,
                user = participant.user,
                status = newStatus,
                createdAt = participant.createdAt,
                updatedAt = LocalDateTime.now(),
            )

        return eventParticipantRepository.save(updated)
    }

    /**
     * 특정 그룹 일정의 모든 참여자 조회
     *
     * @param groupEventId 그룹 일정 ID
     * @return 참여자 목록
     */
    fun getParticipants(groupEventId: Long): List<EventParticipant> {
        return eventParticipantRepository.findByGroupEventId(groupEventId)
    }

    /**
     * 참여자 제거
     *
     * @param participantId 참여자 ID
     */
    @Transactional
    fun removeParticipant(participantId: Long) {
        if (!eventParticipantRepository.existsById(participantId)) {
            throw BusinessException(ErrorCode.PARTICIPANT_NOT_FOUND)
        }
        eventParticipantRepository.deleteById(participantId)
    }

    /**
     * 특정 그룹 일정의 수락한 참여자 수 조회
     *
     * @param groupEventId 그룹 일정 ID
     * @return 수락한 참여자 수
     */
    fun getAcceptedCount(groupEventId: Long): Long {
        return eventParticipantRepository.countByGroupEventIdAndStatus(
            groupEventId,
            ParticipantStatus.ACCEPTED,
        )
    }

    /**
     * 특정 사용자가 특정 일정에 참여하는지 확인
     *
     * @param groupEventId 그룹 일정 ID
     * @param userId 사용자 ID
     * @return 참여 정보 (없으면 null)
     */
    fun getParticipant(
        groupEventId: Long,
        userId: Long,
    ): EventParticipant? {
        return eventParticipantRepository.findByGroupEventIdAndUserId(groupEventId, userId)
            .orElse(null)
    }

    /**
     * 특정 사용자의 모든 참여 일정 조회
     *
     * @param userId 사용자 ID
     * @return 참여 일정 목록
     */
    fun getUserParticipations(userId: Long): List<EventParticipant> {
        return eventParticipantRepository.findByUserId(userId)
    }
}
