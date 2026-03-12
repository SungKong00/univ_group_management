package com.univgroup.domain.group.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 하위 그룹 요청 엔티티
 *
 * 사용자가 기존 그룹의 하위 그룹 생성을 요청한 내역을 나타낸다.
 */
@Entity
@Table(name = "sub_group_requests")
data class SubGroupRequest(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_group_id", nullable = false)
    val parentGroup: Group,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "requester_id", nullable = false)
    val requester: User,

    @Column(nullable = false, length = 100)
    val subGroupName: String,

    @Column(columnDefinition = "TEXT")
    val description: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val status: RequestStatus = RequestStatus.PENDING,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "processed_at")
    val processedAt: LocalDateTime? = null
) {
    override fun equals(other: Any?) = other is SubGroupRequest && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
