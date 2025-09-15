package org.castlekong.backend.entity

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(
    name = "group_join_requests",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_id", "user_id", "status"])
    ]
)
data class GroupJoinRequest(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    // 가입하려는 그룹
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,

    // 가입 신청자
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    // 신청 메시지 (선택사항)
    @Column(name = "request_message", length = 500)
    val requestMessage: String? = null,

    // 신청 상태
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    val status: GroupJoinRequestStatus = GroupJoinRequestStatus.PENDING,

    // 승인/반려 시 메시지
    @Column(name = "response_message", length = 500)
    val responseMessage: String? = null,

    // 승인/반려 처리자
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reviewed_by_id")
    val reviewedBy: User? = null,

    // 승인/반려 처리 시간
    @Column(name = "reviewed_at")
    val reviewedAt: LocalDateTime? = null,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),
)

enum class GroupJoinRequestStatus {
    PENDING,    // 대기 중
    APPROVED,   // 승인됨
    REJECTED    // 반려됨
}