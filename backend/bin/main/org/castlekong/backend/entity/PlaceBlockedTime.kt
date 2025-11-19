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
import java.time.LocalDateTime

/**
 * PlaceBlockedTime (예약 차단 시간)
 *
 * 장소의 특정 시간대를 예약 불가능하게 만드는 엔티티
 * - PlaceAvailability로 정의된 운영 시간 내에서 추가 차단
 * - 날짜 전체 차단 또는 부분 시간대 차단 모두 지원
 * - 차단 유형: 유지보수, 긴급, 휴일, 기타
 */
@Entity
@Table(
    name = "place_blocked_times",
    indexes = [
        Index(name = "idx_blocked_place", columnList = "place_id"),
        Index(name = "idx_blocked_date", columnList = "place_id, start_datetime, end_datetime"),
        Index(name = "idx_blocked_type", columnList = "block_type"),
        Index(name = "idx_blocked_creator", columnList = "created_by, created_at"),
    ],
)
class PlaceBlockedTime(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    var place: Place,
    @Column(name = "start_datetime", nullable = false)
    var startDatetime: LocalDateTime,
    @Column(name = "end_datetime", nullable = false)
    var endDatetime: LocalDateTime,
    @Enumerated(EnumType.STRING)
    @Column(name = "block_type", nullable = false, length = 20)
    var blockType: BlockType,
    @Column(name = "reason", length = 200)
    var reason: String? = null,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    var createdBy: User,
    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalDateTime = LocalDateTime.now(),
    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now(),
) {
    /**
     * 주어진 시간 범위와 겹치는지 확인
     */
    fun overlapsWith(
        start: LocalDateTime,
        end: LocalDateTime,
    ): Boolean {
        return !(end.isBefore(startDatetime) || start.isAfter(endDatetime))
    }

    /**
     * 시간 범위가 유효한지 확인
     */
    fun isValidTimeRange(): Boolean {
        return endDatetime.isAfter(startDatetime)
    }

    /**
     * 전일 차단 여부 확인
     */
    fun isFullDayBlock(): Boolean {
        val startTime = startDatetime.toLocalTime()
        val endTime = endDatetime.toLocalTime()
        return startTime.hour == 0 && startTime.minute == 0 &&
            endTime.hour == 23 && endTime.minute == 59
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is PlaceBlockedTime) return false
        return id != 0L && id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String {
        return "PlaceBlockedTime(id=$id, blockType=$blockType, start=$startDatetime, end=$endDatetime)"
    }
}

/**
 * BlockType (차단 유형)
 */
enum class BlockType {
    MAINTENANCE, // 유지보수
    EMERGENCY, // 긴급 상황
    HOLIDAY, // 휴일
    OTHER, // 기타
}
