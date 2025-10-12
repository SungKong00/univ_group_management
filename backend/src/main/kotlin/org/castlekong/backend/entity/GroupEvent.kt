package org.castlekong.backend.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.JoinColumn
import jakarta.persistence.ManyToOne
import jakarta.persistence.Table
import java.time.LocalDateTime

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
    @Column(length = 100)
    val location: String? = null,
    @Column(name = "start_date", nullable = false)
    val startDate: LocalDateTime,
    @Column(name = "end_date", nullable = false)
    val endDate: LocalDateTime,
    @Column(name = "is_all_day", nullable = false)
    val isAllDay: Boolean = false,
    @Column(name = "is_official", nullable = false)
    val isOfficial: Boolean = false,
    @Column(name = "event_type", nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    val eventType: EventType = EventType.GENERAL,
    @Column(name = "series_id", length = 50)
    val seriesId: String? = null,
    @Column(name = "recurrence_rule", columnDefinition = "TEXT")
    val recurrenceRule: String? = null,
    @Column(length = 7, nullable = false)
    val color: String = "#3B82F6",
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),
)

enum class EventType {
    GENERAL, // 일반 공지형 (MVP)
    TARGETED, // 대상 지정형 (Phase 2)
    RSVP, // 참여 신청형 (Phase 2)
}
