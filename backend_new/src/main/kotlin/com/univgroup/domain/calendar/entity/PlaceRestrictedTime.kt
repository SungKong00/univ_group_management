package com.univgroup.domain.calendar.entity

import jakarta.persistence.*
import java.time.DayOfWeek
import java.time.LocalDateTime
import java.time.LocalTime

/**
 * 장소 금지시간 엔티티
 *
 * 운영시간 내에서 예약 불가능한 시간대를 정의한다.
 * 매주 반복되는 주간 정책 (점심시간, 휴게시간 등)
 */
@Entity
@Table(
    name = "place_restricted_times",
    indexes = [
        Index(name = "idx_restricted_place", columnList = "place_id"),
        Index(name = "idx_restricted_day", columnList = "place_id, day_of_week")
    ]
)
data class PlaceRestrictedTime(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    val place: Place,

    @Enumerated(EnumType.STRING)
    @Column(name = "day_of_week", nullable = false, length = 10)
    val dayOfWeek: DayOfWeek,

    @Column(name = "start_time", nullable = false)
    val startTime: LocalTime,

    @Column(name = "end_time", nullable = false)
    val endTime: LocalTime,

    @Column(length = 100)
    val reason: String? = null,

    @Column(name = "display_order", nullable = false)
    val displayOrder: Int = 0,

    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is PlaceRestrictedTime && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
