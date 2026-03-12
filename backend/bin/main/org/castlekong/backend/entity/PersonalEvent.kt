package org.castlekong.backend.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.JoinColumn
import jakarta.persistence.ManyToOne
import jakarta.persistence.Table
import java.time.LocalDateTime

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
    @Column(length = 100)
    val location: String? = null,
    @Column(name = "start_date_time", nullable = false)
    val startDateTime: LocalDateTime,
    @Column(name = "end_date_time", nullable = false)
    val endDateTime: LocalDateTime,
    @Column(name = "is_all_day", nullable = false)
    val isAllDay: Boolean = false,
    @Column(length = 7, nullable = false)
    val color: String = "#3B82F6",
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),
)
