package com.univgroup.domain.calendar.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 그룹 일정 참여자 엔티티
 *
 * RSVP형 일정에서 사용자의 참여 상태를 추적한다.
 */
@Entity
@Table(
    name = "event_participants",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_event_id", "user_id"])
    ]
)
data class EventParticipant(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_event_id", nullable = false)
    val groupEvent: GroupEvent,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    val status: ParticipantStatus = ParticipantStatus.PENDING,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is EventParticipant && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

/**
 * 참여자 상태
 */
enum class ParticipantStatus {
    PENDING,    // 초대됨 (응답 대기)
    ACCEPTED,   // 수락 (참여 확정)
    REJECTED,   // 거절 (불참)
    TENTATIVE   // 미정 (참석 여부 불확실)
}
