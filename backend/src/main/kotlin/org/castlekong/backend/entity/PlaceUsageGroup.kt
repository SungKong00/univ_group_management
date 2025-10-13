package org.castlekong.backend.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Index
import jakarta.persistence.JoinColumn
import jakarta.persistence.ManyToOne
import jakarta.persistence.Table
import jakarta.persistence.UniqueConstraint
import java.time.LocalDateTime

/**
 * PlaceUsageGroup (사용 그룹)
 *
 * 장소 사용 권한을 신청하고 승인받은 그룹을 나타내는 엔티티
 * - 관리 주체가 아닌 그룹이 장소를 사용하려면 승인 필요
 * - 승인 상태: PENDING, APPROVED, REJECTED
 */
@Entity
@Table(
    name = "place_usage_groups",
    uniqueConstraints = [
        UniqueConstraint(
            name = "uk_place_usage_group",
            columnNames = ["place_id", "group_id"],
        ),
    ],
    indexes = [
        Index(name = "idx_usage_group_place", columnList = "place_id"),
        Index(name = "idx_usage_group_group", columnList = "group_id"),
        Index(name = "idx_usage_group_status", columnList = "place_id, status"),
    ],
)
class PlaceUsageGroup(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    var place: Place,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    var group: Group,
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    var status: UsageStatus = UsageStatus.PENDING,
    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalDateTime = LocalDateTime.now(),
    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now(),
) {
    /**
     * 승인 처리
     */
    fun approve(): PlaceUsageGroup {
        this.status = UsageStatus.APPROVED
        this.updatedAt = LocalDateTime.now()
        return this
    }

    /**
     * 거절 처리
     */
    fun reject(): PlaceUsageGroup {
        this.status = UsageStatus.REJECTED
        this.updatedAt = LocalDateTime.now()
        return this
    }

    /**
     * 승인 여부 확인
     */
    fun isApproved(): Boolean = status == UsageStatus.APPROVED

    /**
     * 대기 중 여부 확인
     */
    fun isPending(): Boolean = status == UsageStatus.PENDING

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is PlaceUsageGroup) return false
        return id != 0L && id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String {
        return "PlaceUsageGroup(id=$id, status=$status)"
    }
}

/**
 * UsageStatus (사용 승인 상태)
 */
enum class UsageStatus {
    PENDING, // 대기 중
    APPROVED, // 승인됨
    REJECTED, // 거절됨
}
