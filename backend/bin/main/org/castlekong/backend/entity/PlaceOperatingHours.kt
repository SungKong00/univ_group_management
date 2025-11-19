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
import jakarta.persistence.UniqueConstraint
import java.time.DayOfWeek
import java.time.LocalDateTime
import java.time.LocalTime

/**
 * PlaceOperatingHours (장소 운영시간)
 *
 * 장소의 기본 운영시간을 요일별로 정의
 * - 각 요일당 하나의 시간대만 허용 (단순화)
 * - 운영시간 외에는 예약 불가
 * - 매주 반복되는 기본 정책
 *
 * **설계 결정사항**:
 * - 요일별 단일 시간대 (시작시간 - 종료시간)
 * - 운영시간 외에는 예약 불가
 * - isClosed로 특정 요일 휴무 설정 가능
 */
@Entity
@Table(
    name = "place_operating_hours",
    uniqueConstraints = [
        UniqueConstraint(
            name = "uk_operating_hours",
            columnNames = ["place_id", "day_of_week"],
        ),
    ],
    indexes = [
        Index(name = "idx_operating_place", columnList = "place_id"),
        Index(name = "idx_operating_day", columnList = "place_id, day_of_week"),
    ],
)
class PlaceOperatingHours(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    var place: Place,
    @Enumerated(EnumType.STRING)
    @Column(name = "day_of_week", nullable = false, length = 10)
    var dayOfWeek: DayOfWeek,
    @Column(name = "start_time", nullable = true)
    var startTime: LocalTime?,
    @Column(name = "end_time", nullable = true)
    var endTime: LocalTime?,
    @Column(name = "is_closed", nullable = false)
    var isClosed: Boolean = false,
    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalDateTime = LocalDateTime.now(),
    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now(),
) {
    /**
     * 주어진 시간이 운영시간 내에 있는지 확인
     */
    fun contains(time: LocalTime): Boolean {
        if (isClosed || startTime == null || endTime == null) return false
        return !time.isBefore(startTime) && !time.isAfter(endTime)
    }

    /**
     * 주어진 시간 범위가 운영시간 내에 완전히 포함되는지 확인
     */
    fun fullyContains(
        start: LocalTime,
        end: LocalTime,
    ): Boolean {
        if (isClosed || startTime == null || endTime == null) return false
        return !start.isBefore(startTime) && !end.isAfter(endTime)
    }

    /**
     * 운영시간 정보 업데이트
     */
    fun update(
        startTime: LocalTime?,
        endTime: LocalTime?,
        isClosed: Boolean,
    ): PlaceOperatingHours {
        this.startTime = startTime
        this.endTime = endTime
        this.isClosed = isClosed
        this.updatedAt = LocalDateTime.now()
        return this
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is PlaceOperatingHours) return false
        return id != 0L && id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String {
        return "PlaceOperatingHours(id=$id, dayOfWeek=$dayOfWeek, startTime=$startTime, endTime=$endTime, isClosed=$isClosed)"
    }
}
