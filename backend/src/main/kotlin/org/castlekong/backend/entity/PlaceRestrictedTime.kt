package org.castlekong.backend.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Index
import jakarta.persistence.JoinColumn
import jakarta.persistence.ManyToOne
import jakarta.persistence.Table
import java.time.DayOfWeek
import java.time.LocalDateTime
import java.time.LocalTime

/**
 * PlaceRestrictedTime (장소 금지시간)
 *
 * 운영시간 내에서 예약 불가능한 시간대 정의
 * - 매주 반복되는 주간 정책 (점심시간, 휴게시간 등)
 * - 여러 개 설정 가능
 *
 * **설계 결정사항**:
 * - 운영시간 밖에도 설정 가능 (향후 운영시간 변경 대비)
 * - 검증 단계에서 운영시간을 먼저 확인하므로 문제 없음
 */
@Entity
@Table(
    name = "place_restricted_times",
    indexes = [
        Index(name = "idx_restricted_place", columnList = "place_id"),
        Index(name = "idx_restricted_day", columnList = "place_id, day_of_week"),
    ],
)
class PlaceRestrictedTime(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    var place: Place,
    @Enumerated(EnumType.STRING)
    @Column(name = "day_of_week", nullable = false, length = 10)
    var dayOfWeek: DayOfWeek,
    @Column(name = "start_time", nullable = false)
    var startTime: LocalTime,
    @Column(name = "end_time", nullable = false)
    var endTime: LocalTime,
    @Column(name = "reason", length = 100)
    var reason: String? = null,
    @Column(name = "display_order", nullable = false)
    var displayOrder: Int = 0,
    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalDateTime = LocalDateTime.now(),
    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now(),
) {
    /**
     * 주어진 시간과 겹치는지 확인
     */
    fun overlapsWith(
        start: LocalTime,
        end: LocalTime,
    ): Boolean {
        return !(end.isBefore(startTime) || start.isAfter(endTime))
    }

    /**
     * 금지시간 정보 업데이트
     */
    fun update(
        startTime: LocalTime,
        endTime: LocalTime,
        reason: String?,
    ): PlaceRestrictedTime {
        this.startTime = startTime
        this.endTime = endTime
        this.reason = reason
        this.updatedAt = LocalDateTime.now()
        return this
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is PlaceRestrictedTime) return false
        return id != 0L && id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String {
        return "PlaceRestrictedTime(id=$id, dayOfWeek=$dayOfWeek, startTime=$startTime, endTime=$endTime, reason=$reason)"
    }
}
