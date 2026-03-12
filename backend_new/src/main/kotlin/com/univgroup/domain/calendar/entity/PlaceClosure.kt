package com.univgroup.domain.calendar.entity

import jakarta.persistence.*
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime

/**
 * 장소 임시 휴무 엔티티
 *
 * 특정 날짜의 임시 휴무를 관리한다.
 */
@Entity
@Table(
    name = "place_closures",
    indexes = [
        Index(name = "idx_closure_place", columnList = "place_id"),
        Index(name = "idx_closure_date", columnList = "place_id, closure_date")
    ]
)
data class PlaceClosure(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    val place: Place,

    @Column(name = "closure_date", nullable = false)
    val closureDate: LocalDate,

    @Column(name = "is_full_day", nullable = false)
    val isFullDay: Boolean = true,

    @Column(name = "start_time")
    val startTime: LocalTime? = null,

    @Column(name = "end_time")
    val endTime: LocalTime? = null,

    @Column(length = 200)
    val reason: String? = null,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is PlaceClosure && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
