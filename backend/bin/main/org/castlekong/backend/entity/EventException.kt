package org.castlekong.backend.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.JoinColumn
import jakarta.persistence.ManyToOne
import jakarta.persistence.Table
import jakarta.persistence.UniqueConstraint
import java.time.LocalDate
import java.time.LocalDateTime

/**
 * 반복 일정의 예외 처리 엔티티
 *
 * 반복 일정(seriesId를 가진 GroupEvent)의 특정 날짜에 대한 예외 처리를 관리합니다.
 * 예: 매주 월요일 회의 중 특정 월요일만 취소 또는 시간 변경
 */
@Entity
@Table(
    name = "event_exceptions",
    uniqueConstraints = [
        UniqueConstraint(
            name = "uk_event_exception",
            columnNames = ["group_event_id", "exception_date"],
        ),
    ],
)
class EventException(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_event_id", nullable = false)
    val groupEvent: GroupEvent,
    /**
     * 예외가 적용되는 날짜
     * 반복 일정의 특정 발생 날짜를 지정
     */
    @Column(name = "exception_date", nullable = false)
    val exceptionDate: LocalDate,
    /**
     * 예외 유형
     * - CANCELLED: 해당 날짜 일정 취소
     * - RESCHEDULED: 일정 시간 변경 (newStartTime, newEndTime 필수)
     * - MODIFIED: 일정 내용 변경 (modifiedDescription 필수)
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    val type: ExceptionType = ExceptionType.CANCELLED,
    /**
     * 변경된 시작 시간 (type=RESCHEDULED인 경우 필수)
     */
    @Column(name = "new_start_time")
    val newStartTime: LocalDateTime? = null,
    /**
     * 변경된 종료 시간 (type=RESCHEDULED인 경우 필수)
     */
    @Column(name = "new_end_time")
    val newEndTime: LocalDateTime? = null,
    /**
     * 변경된 설명 (type=MODIFIED인 경우 필수)
     */
    @Column(name = "modified_description", columnDefinition = "TEXT")
    val modifiedDescription: String? = null,
    /**
     * 예외 사유 (선택사항)
     * 예: "강사 휴가", "공휴일", "장소 대관 불가" 등
     */
    @Column(columnDefinition = "TEXT")
    val reason: String? = null,
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),
) {
    init {
        // 검증: RESCHEDULED 타입인 경우 새로운 시간 정보 필수
        if (type == ExceptionType.RESCHEDULED) {
            require(newStartTime != null && newEndTime != null) {
                "RESCHEDULED 타입은 newStartTime과 newEndTime이 필수입니다."
            }
            require(newStartTime.isBefore(newEndTime)) {
                "newStartTime은 newEndTime보다 이전이어야 합니다."
            }
        }

        // 검증: MODIFIED 타입인 경우 변경된 설명 필수
        if (type == ExceptionType.MODIFIED) {
            require(!modifiedDescription.isNullOrBlank()) {
                "MODIFIED 타입은 modifiedDescription이 필수입니다."
            }
        }
    }

    override fun equals(other: Any?) = other is EventException && id != 0L && id == other.id

    override fun hashCode(): Int = id.hashCode()
}

/**
 * 반복 일정 예외 유형
 */
enum class ExceptionType {
    /** 해당 날짜 일정 취소 */
    CANCELLED,

    /** 일정 시간 변경 (newStartTime, newEndTime 필수) */
    RESCHEDULED,

    /** 일정 내용 변경 (modifiedDescription 필수) */
    MODIFIED,
}
