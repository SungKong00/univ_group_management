package org.castlekong.backend.repository

import org.castlekong.backend.entity.EventException
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDate
import java.util.Optional

/**
 * EventException 엔티티의 Repository
 *
 * 반복 일정의 예외 처리를 위한 데이터 액세스 레이어입니다.
 */
@Repository
interface EventExceptionRepository : JpaRepository<EventException, Long> {
    /**
     * 특정 그룹 일정의 모든 예외 조회
     *
     * @param groupEventId 그룹 일정 ID
     * @return 해당 일정의 모든 예외 목록
     */
    fun findByGroupEventId(groupEventId: Long): List<EventException>

    /**
     * 특정 그룹 일정의 특정 날짜 예외 조회
     *
     * @param groupEventId 그룹 일정 ID
     * @param exceptionDate 예외 날짜
     * @return 예외 정보 (존재하지 않으면 Optional.empty())
     */
    fun findByGroupEventIdAndExceptionDate(
        groupEventId: Long,
        exceptionDate: LocalDate,
    ): Optional<EventException>

    /**
     * 특정 그룹 일정의 특정 기간 예외 조회
     *
     * @param groupEventId 그룹 일정 ID
     * @param startDate 시작 날짜 (포함)
     * @param endDate 종료 날짜 (포함)
     * @return 해당 기간의 예외 목록
     */
    fun findByGroupEventIdAndExceptionDateBetween(
        groupEventId: Long,
        startDate: LocalDate,
        endDate: LocalDate,
    ): List<EventException>

    /**
     * 여러 그룹 일정의 예외 배치 삭제
     *
     * 그룹 일정 삭제 시 관련된 모든 예외 정보를 함께 삭제합니다.
     *
     * @param eventIds 삭제할 그룹 일정 ID 목록
     * @return 삭제된 레코드 수
     */
    @Modifying
    @Query("DELETE FROM EventException ee WHERE ee.groupEvent.id IN :eventIds")
    fun deleteByGroupEventIds(
        @Param("eventIds") eventIds: List<Long>,
    ): Int
}
