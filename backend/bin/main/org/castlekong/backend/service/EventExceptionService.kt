package org.castlekong.backend.service

import org.castlekong.backend.entity.EventException
import org.castlekong.backend.entity.ExceptionType
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.EventExceptionRepository
import org.castlekong.backend.repository.GroupEventRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.time.LocalDateTime

/**
 * EventException 관리 서비스
 *
 * 반복 일정의 예외 처리 비즈니스 로직을 처리합니다.
 */
@Service
@Transactional(readOnly = true)
class EventExceptionService(
    private val eventExceptionRepository: EventExceptionRepository,
    private val groupEventRepository: GroupEventRepository,
) {
    /**
     * 예외 생성
     *
     * @param groupEventId 그룹 일정 ID
     * @param exceptionDate 예외 날짜
     * @param type 예외 유형
     * @param newStartTime 변경된 시작 시간 (RESCHEDULED인 경우 필수)
     * @param newEndTime 변경된 종료 시간 (RESCHEDULED인 경우 필수)
     * @param modifiedDescription 변경된 설명 (MODIFIED인 경우 필수)
     * @param reason 예외 사유 (선택)
     * @return 생성된 예외 정보
     */
    @Transactional
    fun createException(
        groupEventId: Long,
        exceptionDate: LocalDate,
        type: ExceptionType,
        newStartTime: LocalDateTime? = null,
        newEndTime: LocalDateTime? = null,
        modifiedDescription: String? = null,
        reason: String? = null,
    ): EventException {
        val groupEvent =
            groupEventRepository.findById(groupEventId)
                .orElseThrow { BusinessException(ErrorCode.EVENT_NOT_FOUND) }

        // 반복 일정 검증
        if (groupEvent.seriesId.isNullOrBlank()) {
            throw BusinessException(ErrorCode.NOT_RECURRING_EVENT)
        }

        // 중복 예외 확인
        eventExceptionRepository.findByGroupEventIdAndExceptionDate(groupEventId, exceptionDate)
            .ifPresent {
                throw BusinessException(ErrorCode.EXCEPTION_ALREADY_EXISTS)
            }

        val exception =
            EventException(
                groupEvent = groupEvent,
                exceptionDate = exceptionDate,
                type = type,
                newStartTime = newStartTime,
                newEndTime = newEndTime,
                modifiedDescription = modifiedDescription,
                reason = reason,
            )

        return eventExceptionRepository.save(exception)
    }

    /**
     * 예외 수정
     *
     * @param exceptionId 예외 ID
     * @param type 예외 유형
     * @param newStartTime 변경된 시작 시간 (RESCHEDULED인 경우 필수)
     * @param newEndTime 변경된 종료 시간 (RESCHEDULED인 경우 필수)
     * @param modifiedDescription 변경된 설명 (MODIFIED인 경우 필수)
     * @param reason 예외 사유 (선택)
     * @return 수정된 예외 정보
     */
    @Transactional
    fun updateException(
        exceptionId: Long,
        type: ExceptionType,
        newStartTime: LocalDateTime? = null,
        newEndTime: LocalDateTime? = null,
        modifiedDescription: String? = null,
        reason: String? = null,
    ): EventException {
        val existing =
            eventExceptionRepository.findById(exceptionId)
                .orElseThrow { BusinessException(ErrorCode.EXCEPTION_NOT_FOUND) }

        val updated =
            EventException(
                id = existing.id,
                groupEvent = existing.groupEvent,
                exceptionDate = existing.exceptionDate,
                type = type,
                newStartTime = newStartTime,
                newEndTime = newEndTime,
                modifiedDescription = modifiedDescription,
                reason = reason,
                createdAt = existing.createdAt,
                updatedAt = LocalDateTime.now(),
            )

        return eventExceptionRepository.save(updated)
    }

    /**
     * 예외 삭제
     *
     * @param exceptionId 예외 ID
     */
    @Transactional
    fun deleteException(exceptionId: Long) {
        if (!eventExceptionRepository.existsById(exceptionId)) {
            throw BusinessException(ErrorCode.EXCEPTION_NOT_FOUND)
        }
        eventExceptionRepository.deleteById(exceptionId)
    }

    /**
     * 특정 그룹 일정의 특정 날짜 예외 조회
     *
     * @param groupEventId 그룹 일정 ID
     * @param exceptionDate 예외 날짜
     * @return 예외 정보 (없으면 null)
     */
    fun getException(
        groupEventId: Long,
        exceptionDate: LocalDate,
    ): EventException? {
        return eventExceptionRepository.findByGroupEventIdAndExceptionDate(groupEventId, exceptionDate)
            .orElse(null)
    }

    /**
     * 특정 그룹 일정의 모든 예외 조회
     *
     * @param groupEventId 그룹 일정 ID
     * @return 예외 목록
     */
    fun getExceptions(groupEventId: Long): List<EventException> {
        return eventExceptionRepository.findByGroupEventId(groupEventId)
    }

    /**
     * 특정 그룹 일정의 특정 기간 예외 조회
     *
     * @param groupEventId 그룹 일정 ID
     * @param startDate 시작 날짜
     * @param endDate 종료 날짜
     * @return 예외 목록
     */
    fun getExceptionsInPeriod(
        groupEventId: Long,
        startDate: LocalDate,
        endDate: LocalDate,
    ): List<EventException> {
        return eventExceptionRepository.findByGroupEventIdAndExceptionDateBetween(
            groupEventId,
            startDate,
            endDate,
        )
    }
}
