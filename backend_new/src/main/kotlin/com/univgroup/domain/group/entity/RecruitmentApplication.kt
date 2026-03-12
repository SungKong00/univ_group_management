package com.univgroup.domain.group.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * 모집 지원 엔티티
 *
 * 사용자가 그룹 모집 공고에 지원한 내역을 나타낸다.
 */
@Entity
@Table(
    name = "recruitment_applications",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["recruitment_id", "user_id"])
    ]
)
data class RecruitmentApplication(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recruitment_id", nullable = false)
    val recruitment: GroupRecruitment,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @Column(columnDefinition = "TEXT")
    val message: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val status: ApplicationStatus = ApplicationStatus.PENDING,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "processed_at")
    val processedAt: LocalDateTime? = null
) {
    override fun equals(other: Any?) = other is RecruitmentApplication && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

/**
 * 지원 상태
 */
enum class ApplicationStatus {
    PENDING,   // 대기 중
    APPROVED,  // 승인됨
    REJECTED   // 거부됨
}
