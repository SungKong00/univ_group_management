package org.castlekong.backend.entity

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(
    name = "recruitment_applications",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["recruitment_id", "applicant_id"]),
    ],
)
data class RecruitmentApplication(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recruitment_id", nullable = false)
    val recruitment: GroupRecruitment,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "applicant_id", nullable = false)
    val applicant: User,
    @Column(name = "motivation", columnDefinition = "TEXT")
    val motivation: String? = null,
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(
        name = "application_answers",
        joinColumns = [JoinColumn(name = "application_id")],
    )
    @MapKeyColumn(name = "question_index")
    @Column(name = "answer", columnDefinition = "TEXT")
    val questionAnswers: Map<Int, String> = emptyMap(),
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    val status: ApplicationStatus = ApplicationStatus.PENDING,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reviewed_by")
    val reviewedBy: User? = null,
    @Column(name = "reviewed_at")
    val reviewedAt: LocalDateTime? = null,
    @Column(name = "review_comment", length = 1000)
    val reviewComment: String? = null,
    @Column(name = "applied_at", nullable = false)
    val appliedAt: LocalDateTime = LocalDateTime.now(),
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),
)

enum class ApplicationStatus {
    PENDING, // 검토 대기
    APPROVED, // 승인됨
    REJECTED, // 거부됨
    WITHDRAWN, // 지원자가 철회
}
