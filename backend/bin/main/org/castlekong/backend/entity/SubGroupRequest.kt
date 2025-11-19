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
import java.time.LocalDateTime

@Entity
@Table(name = "sub_group_requests")
data class SubGroupRequest(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    // 신청자
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "requester_id", nullable = false)
    val requester: User,
    // 상위 그룹 (하위 그룹을 만들고 싶은 그룹)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_group_id", nullable = false)
    val parentGroup: Group,
    // 신청하려는 하위 그룹 정보
    @Column(nullable = false, length = 100)
    val requestedGroupName: String,
    @Column(length = 500)
    val requestedGroupDescription: String? = null,
    @Column(name = "requested_university", length = 100)
    val requestedUniversity: String? = null,
    @Column(name = "requested_college", length = 100)
    val requestedCollege: String? = null,
    @Column(name = "requested_department", length = 100)
    val requestedDepartment: String? = null,
    @Enumerated(EnumType.STRING)
    @Column(name = "requested_group_type", nullable = false, length = 20)
    val requestedGroupType: GroupType = GroupType.AUTONOMOUS,
    @Column(name = "requested_max_members")
    val requestedMaxMembers: Int? = null,
    // 신청 상태
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    val status: SubGroupRequestStatus = SubGroupRequestStatus.PENDING,
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

enum class SubGroupRequestStatus {
    PENDING, // 대기 중
    APPROVED, // 승인됨
    REJECTED, // 반려됨
}
