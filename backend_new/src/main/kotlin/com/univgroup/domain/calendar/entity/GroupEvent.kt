package com.univgroup.domain.calendar.entity

import com.univgroup.domain.group.entity.Group
import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 그룹 일정 엔티티
 *
 * 그룹 전체에 공지되는 일정을 나타낸다.
 */
@Entity
@Table(name = "group_events")
data class GroupEvent(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "creator_id", nullable = false)
    val creator: User,

    @Column(nullable = false, length = 200)
    val title: String,

    @Column(columnDefinition = "TEXT")
    val description: String? = null,

    // 장소 (3가지 모드: 없음/텍스트/장소선택)
    @Column(name = "location_text", length = 100)
    val locationText: String? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id")
    val place: Place? = null,

    @Column(name = "start_date", nullable = false)
    val startDate: LocalDateTime,

    @Column(name = "end_date", nullable = false)
    val endDate: LocalDateTime,

    @Column(name = "is_all_day", nullable = false)
    val isAllDay: Boolean = false,

    @Column(name = "is_official", nullable = false)
    val isOfficial: Boolean = false,

    @Enumerated(EnumType.STRING)
    @Column(name = "event_type", nullable = false, length = 20)
    val eventType: EventType = EventType.GENERAL,

    // 반복 일정
    @Column(name = "series_id", length = 50)
    val seriesId: String? = null,

    @Column(name = "recurrence_rule", columnDefinition = "TEXT")
    val recurrenceRule: String? = null,

    @Column(length = 7, nullable = false)
    val color: String = "#3B82F6",

    @Version
    @Column(nullable = false)
    val version: Long = 0,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    init {
        require(locationText.isNullOrBlank() || place == null) {
            "locationText와 place는 동시에 값을 가질 수 없습니다"
        }
    }

    override fun equals(other: Any?) = other is GroupEvent && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

/**
 * 일정 유형
 */
enum class EventType {
    GENERAL,   // 일반 공지형
    TARGETED,  // 대상 지정형
    RSVP       // 참여 신청형
}
