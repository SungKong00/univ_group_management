package com.univgroup.domain.calendar.entity

import com.univgroup.domain.group.entity.Group
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 장소 사용 그룹 엔티티
 *
 * 장소 사용 권한을 신청하고 승인받은 그룹을 나타낸다.
 * 관리 주체가 아닌 그룹이 장소를 사용하려면 승인 필요
 */
@Entity
@Table(
    name = "place_usage_groups",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["place_id", "group_id"])
    ],
    indexes = [
        Index(name = "idx_usage_group_place", columnList = "place_id"),
        Index(name = "idx_usage_group_group", columnList = "group_id"),
        Index(name = "idx_usage_group_status", columnList = "place_id, status")
    ]
)
data class PlaceUsageGroup(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    val place: Place,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    val status: UsageStatus = UsageStatus.PENDING,

    @Column(name = "rejection_reason", length = 500)
    val rejectionReason: String? = null,

    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is PlaceUsageGroup && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

/**
 * 사용 승인 상태
 */
enum class UsageStatus {
    PENDING,   // 승인 대기
    APPROVED,  // 승인됨
    REJECTED   // 거부됨
}
