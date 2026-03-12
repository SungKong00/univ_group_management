package com.univgroup.domain.calendar.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 예약 차단 시간 엔티티
 *
 * 장소의 특정 시간대를 예약 불가능하게 만든다.
 */
@Entity
@Table(
    name = "place_blocked_times",
    indexes = [
        Index(name = "idx_blocked_place", columnList = "place_id"),
        Index(name = "idx_blocked_date", columnList = "place_id, start_datetime, end_datetime"),
        Index(name = "idx_blocked_type", columnList = "block_type")
    ]
)
data class PlaceBlockedTime(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    val place: Place,

    @Column(name = "start_datetime", nullable = false)
    val startDatetime: LocalDateTime,

    @Column(name = "end_datetime", nullable = false)
    val endDatetime: LocalDateTime,

    @Enumerated(EnumType.STRING)
    @Column(name = "block_type", nullable = false, length = 20)
    val blockType: BlockType,

    @Column(length = 200)
    val reason: String? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    val createdBy: User,

    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is PlaceBlockedTime && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

/**
 * 차단 유형
 */
enum class BlockType {
    MAINTENANCE,  // 유지보수
    EMERGENCY,    // 긴급
    HOLIDAY,      // 휴일
    OTHER         // 기타
}
