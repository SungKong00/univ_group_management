package org.castlekong.backend.entity

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "group_recruitments")
class GroupRecruitment(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    val createdBy: User,

    @Column(nullable = false, length = 200)
    var title: String,

    @Column(columnDefinition = "TEXT")
    var content: String? = null,

    @Column(name = "max_applicants")
    var maxApplicants: Int? = null,

    @Column(name = "recruitment_start_date", nullable = false)
    val recruitmentStartDate: LocalDateTime = LocalDateTime.now(),

    @Column(name = "recruitment_end_date")
    var recruitmentEndDate: LocalDateTime? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    var status: RecruitmentStatus = RecruitmentStatus.OPEN,

    @Column(name = "auto_approve", nullable = false)
    var autoApprove: Boolean = false,

    @Column(name = "show_applicant_count", nullable = false)
    var showApplicantCount: Boolean = true,

    @ElementCollection(targetClass = String::class, fetch = FetchType.EAGER)
    @CollectionTable(name = "recruitment_questions", joinColumns = [JoinColumn(name = "recruitment_id")])
    @Column(name = "question", nullable = false, length = 500)
    var applicationQuestions: List<String> = emptyList(),

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "closed_at")
    var closedAt: LocalDateTime? = null,
)

enum class RecruitmentStatus {
    DRAFT,      // 임시저장
    OPEN,       // 모집 중
    CLOSED,     // 모집 마감
    CANCELLED   // 모집 취소
}