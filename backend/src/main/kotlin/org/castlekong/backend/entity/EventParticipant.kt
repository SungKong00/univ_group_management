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
import jakarta.persistence.UniqueConstraint
import java.time.LocalDateTime

/**
 * 그룹 일정의 참여자 관리 엔티티
 *
 * RSVP형 일정(EventType.RSVP)에서 사용자의 참여 상태를 추적합니다.
 * 대상 지정형 일정(EventType.TARGETED)에서는 초대 대상자를 관리합니다.
 */
@Entity
@Table(
    name = "event_participants",
    uniqueConstraints = [
        UniqueConstraint(
            name = "uk_event_participant",
            columnNames = ["group_event_id", "user_id"],
        ),
    ],
)
class EventParticipant(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_event_id", nullable = false)
    val groupEvent: GroupEvent,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,
    /**
     * 참여 상태
     * - PENDING: 초대됨 (아직 응답 안 함)
     * - ACCEPTED: 수락 (참여 확정)
     * - REJECTED: 거절 (불참)
     * - TENTATIVE: 미정 (참석 여부 불확실)
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    val status: ParticipantStatus = ParticipantStatus.PENDING,
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),
) {
    override fun equals(other: Any?) = other is EventParticipant && id != 0L && id == other.id

    override fun hashCode(): Int = id.hashCode()
}

/**
 * 참여자의 참여 상태
 */
enum class ParticipantStatus {
    /** 초대됨 (아직 응답 안 함) */
    PENDING,

    /** 수락 (참여 확정) */
    ACCEPTED,

    /** 거절 (불참) */
    REJECTED,

    /** 미정 (참석 여부 불확실) */
    TENTATIVE,
}
