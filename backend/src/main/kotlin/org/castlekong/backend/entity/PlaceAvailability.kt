package org.castlekong.backend.entity

import jakarta.persistence.*
import java.time.DayOfWeek
import java.time.LocalTime

/**
 * PlaceAvailability (운영 시간)
 *
 * 장소의 요일별 운영 시간을 나타내는 엔티티
 * - 같은 요일에 여러 시간대 허용 (예: 09:00-12:00, 14:00-18:00)
 * - 운영 시간 외에는 예약 불가
 */
@Entity
@Table(
    name = "place_availabilities",
    indexes = [
        Index(name = "idx_availability_place", columnList = "place_id"),
        Index(name = "idx_availability_day", columnList = "place_id, day_of_week"),
    ],
)
class PlaceAvailability(
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
    @Column(name = "display_order", nullable = false)
    var displayOrder: Int = 0,
    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalTime = LocalTime.now(),
) {
    /**
     * 주어진 시간 범위가 이 운영 시간 내에 포함되는지 확인
     */
    fun contains(
        start: LocalTime,
        end: LocalTime,
    ): Boolean {
        return !start.isBefore(startTime) && !end.isAfter(endTime)
    }

    /**
     * 시간 범위가 유효한지 확인 (종료 시간이 시작 시간보다 늦어야 함)
     */
    fun isValidTimeRange(): Boolean {
        return endTime.isAfter(startTime)
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is PlaceAvailability) return false
        return id != 0L && id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String {
        return "PlaceAvailability(id=$id, dayOfWeek=$dayOfWeek, startTime=$startTime, endTime=$endTime)"
    }
}
