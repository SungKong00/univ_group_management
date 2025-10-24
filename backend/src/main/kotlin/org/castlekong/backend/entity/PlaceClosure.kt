package org.castlekong.backend.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Index
import jakarta.persistence.JoinColumn
import jakarta.persistence.ManyToOne
import jakarta.persistence.Table
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime

/**
 * PlaceClosure (장소 임시 휴무)
 *
 * 특정 날짜의 임시 휴무 관리
 * - 전일 휴무 또는 부분 시간 휴무 지원
 * - 월간뷰를 통해 관리
 *
 * **설계 결정사항**:
 * - isFullDay = true: 전일 휴무 (startTime, endTime null)
 * - isFullDay = false: 부분 시간 휴무 (startTime, endTime 필수)
 */
@Entity
@Table(
    name = "place_closures",
    indexes = [
        Index(name = "idx_closure_place", columnList = "place_id"),
        Index(name = "idx_closure_date", columnList = "place_id, closure_date"),
    ],
)
class PlaceClosure(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    var place: Place,
    @Column(name = "closure_date", nullable = false)
    var closureDate: LocalDate,
    @Column(name = "is_full_day", nullable = false)
    var isFullDay: Boolean = true,
    @Column(name = "start_time")
    var startTime: LocalTime? = null,
    @Column(name = "end_time")
    var endTime: LocalTime? = null,
    @Column(name = "reason", length = 200)
    var reason: String? = null,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    var createdBy: User,
    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalDateTime = LocalDateTime.now(),
) {
    /**
     * 주어진 날짜와 시간이 휴무에 해당하는지 확인
     */
    fun isClosedAt(
        date: LocalDate,
        time: LocalTime,
    ): Boolean {
        if (closureDate != date) return false
        if (isFullDay) return true

        // 부분 시간 휴무 확인
        return startTime != null &&
            endTime != null &&
            !time.isBefore(startTime) &&
            !time.isAfter(endTime)
    }

    /**
     * 주어진 날짜와 시간 범위가 휴무와 겹치는지 확인
     */
    fun overlapsWithTimeRange(
        date: LocalDate,
        start: LocalTime,
        end: LocalTime,
    ): Boolean {
        if (closureDate != date) return false
        if (isFullDay) return true

        // 부분 시간 휴무와의 겹침 확인
        return startTime != null &&
            endTime != null &&
            !(end.isBefore(startTime) || start.isAfter(endTime))
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is PlaceClosure) return false
        return id != 0L && id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String {
        return "PlaceClosure(id=$id, closureDate=$closureDate, isFullDay=$isFullDay, reason=$reason)"
    }
}
