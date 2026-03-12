package com.univgroup.domain.calendar.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 장소 예약 엔티티
 *
 * GroupEvent와 1:1 관계로 연결된 장소 예약 정보
 */
@Entity
@Table(
    name = "place_reservations",
    indexes = [
        Index(name = "idx_reservation_place", columnList = "place_id"),
        Index(name = "idx_reservation_event", columnList = "group_event_id"),
        Index(name = "idx_reservation_user", columnList = "reserved_by")
    ]
)
data class PlaceReservation(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_event_id", nullable = false, unique = true)
    val groupEvent: GroupEvent,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    val place: Place,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reserved_by", nullable = false)
    val reservedBy: User,

    @Version
    @Column(nullable = false)
    val version: Long = 0,

    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is PlaceReservation && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
