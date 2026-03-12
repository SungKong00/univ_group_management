package com.univgroup.domain.calendar.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.DayOfWeek
import java.time.LocalDateTime
import java.time.LocalTime

/**
 * 개인 스케줄 엔티티
 *
 * 매주 반복되는 개인 스케줄(수업, 동아리 활동 등)을 나타낸다.
 */
@Entity
@Table(name = "personal_schedules")
data class PersonalSchedule(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @Column(nullable = false, length = 200)
    val title: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "day_of_week", nullable = false, length = 20)
    val dayOfWeek: DayOfWeek,

    @Column(name = "start_time", nullable = false)
    val startTime: LocalTime,

    @Column(name = "end_time", nullable = false)
    val endTime: LocalTime,

    @Column(length = 200)
    val location: String? = null,

    @Column(length = 7, nullable = false)
    val color: String = "#3B82F6",

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is PersonalSchedule && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
