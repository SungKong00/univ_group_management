package com.univgroup.domain.calendar.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 개인 일정 엔티티
 *
 * 사용자의 개인 일정을 나타낸다.
 */
@Entity
@Table(name = "personal_events")
data class PersonalEvent(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @Column(nullable = false, length = 200)
    val title: String,

    @Column(columnDefinition = "TEXT")
    val description: String? = null,

    @Column(name = "start_date", nullable = false)
    val startDate: LocalDateTime,

    @Column(name = "end_date", nullable = false)
    val endDate: LocalDateTime,

    @Column(name = "is_all_day", nullable = false)
    val isAllDay: Boolean = false,

    @Column(length = 7, nullable = false)
    val color: String = "#10B981",

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is PersonalEvent && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
