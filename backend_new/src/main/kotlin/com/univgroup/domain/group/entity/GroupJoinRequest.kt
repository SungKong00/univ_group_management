package com.univgroup.domain.group.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 그룹 가입 신청 엔티티
 *
 * 사용자가 그룹에 가입을 신청한 내역을 나타낸다.
 */
@Entity
@Table(
    name = "group_join_requests",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_id", "user_id"])
    ]
)
data class GroupJoinRequest(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @Column(columnDefinition = "TEXT")
    val message: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val status: RequestStatus = RequestStatus.PENDING,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "processed_at")
    val processedAt: LocalDateTime? = null
) {
    override fun equals(other: Any?) = other is GroupJoinRequest && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

/**
 * 요청 상태
 */
enum class RequestStatus {
    PENDING,   // 대기 중
    APPROVED,  // 승인됨
    REJECTED   // 거부됨
}
