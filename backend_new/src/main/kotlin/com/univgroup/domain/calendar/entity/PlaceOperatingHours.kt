package com.univgroup.domain.calendar.entity

import jakarta.persistence.*
import java.time.DayOfWeek
import java.time.LocalDateTime
import java.time.LocalTime

/**
 * 장소 운영시간 엔티티
 *
 * 장소의 기본 운영시간을 요일별로 정의한다.
 */
@Entity
@Table(
    name = "place_operating_hours",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["place_id", "day_of_week"])
    ],
    indexes = [
        Index(name = "idx_operating_place", columnList = "place_id"),
        Index(name = "idx_operating_day", columnList = "place_id, day_of_week")
    ]
)
data class PlaceOperatingHours(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    val place: Place,

    @Enumerated(EnumType.STRING)
    @Column(name = "day_of_week", nullable = false, length = 10)
    val dayOfWeek: DayOfWeek,

    @Column(name = "start_time")
    val startTime: LocalTime?,

    @Column(name = "end_time")
    val endTime: LocalTime?,

    @Column(name = "is_closed", nullable = false)
    val isClosed: Boolean = false,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is PlaceOperatingHours && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
