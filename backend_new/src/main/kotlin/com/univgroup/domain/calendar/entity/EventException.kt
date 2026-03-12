package com.univgroup.domain.calendar.entity

import jakarta.persistence.*
import java.time.LocalDate
import java.time.LocalDateTime

/**
 * 반복 일정 예외 엔티티
 *
 * 반복 일정의 특정 날짜에 대한 예외 처리를 관리한다.
 * 예: 매주 월요일 회의 중 특정 월요일만 취소 또는 시간 변경
 */
@Entity
@Table(
    name = "event_exceptions",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_event_id", "exception_date"])
    ]
)
data class EventException(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_event_id", nullable = false)
    val groupEvent: GroupEvent,

    @Column(name = "exception_date", nullable = false)
    val exceptionDate: LocalDate,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    val type: ExceptionType = ExceptionType.CANCELLED,

    @Column(name = "new_start_time")
    val newStartTime: LocalDateTime? = null,

    @Column(name = "new_end_time")
    val newEndTime: LocalDateTime? = null,

    @Column(name = "modified_description", columnDefinition = "TEXT")
    val modifiedDescription: String? = null,

    @Column(columnDefinition = "TEXT")
    val reason: String? = null,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    init {
        if (type == ExceptionType.RESCHEDULED) {
            require(newStartTime != null && newEndTime != null) {
                "RESCHEDULED 타입은 newStartTime과 newEndTime이 필수입니다."
            }
            require(newStartTime.isBefore(newEndTime)) {
                "newStartTime은 newEndTime보다 이전이어야 합니다."
            }
        }

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
    CANCELLED,    // 해당 날짜 일정 취소
    RESCHEDULED,  // 일정 시간 변경
    MODIFIED      // 일정 내용 변경
}
