package org.castlekong.backend.dto

import jakarta.validation.constraints.Min
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Pattern
import jakarta.validation.constraints.Size
import org.castlekong.backend.entity.ApplicationStatus
import org.castlekong.backend.entity.RecruitmentStatus
import java.time.LocalDateTime

// 모집 게시글 관련 DTO

data class CreateRecruitmentRequest(
    @field:NotBlank(message = "모집 제목은 필수입니다")
    @field:Size(min = 1, max = 200, message = "모집 제목은 1자 이상 200자 이하여야 합니다")
    val title: String,
    @field:Size(max = 10000, message = "모집 내용은 10000자를 초과할 수 없습니다")
    val content: String? = null,
    @field:Min(value = 1, message = "최대 지원자 수는 1 이상이어야 합니다")
    val maxApplicants: Int? = null,
    val recruitmentEndDate: LocalDateTime? = null,
    val autoApprove: Boolean = false,
    val showApplicantCount: Boolean = true,
    val applicationQuestions: List<String> = emptyList(),
)

data class UpdateRecruitmentRequest(
    val title: String? = null,
    val content: String? = null,
    val maxApplicants: Int? = null,
    val recruitmentEndDate: LocalDateTime? = null,
    val autoApprove: Boolean? = null,
    val showApplicantCount: Boolean? = null,
    val applicationQuestions: List<String>? = null,
)

data class RecruitmentResponse(
    val id: Long,
    val group: GroupSummaryResponse,
    val createdBy: UserSummaryResponse,
    val title: String,
    val content: String?,
    val maxApplicants: Int?,
    val currentApplicantCount: Int,
    val recruitmentStartDate: LocalDateTime,
    val recruitmentEndDate: LocalDateTime?,
    val status: RecruitmentStatus,
    val autoApprove: Boolean,
    val showApplicantCount: Boolean,
    val applicationQuestions: List<String>,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val closedAt: LocalDateTime?,
)

data class RecruitmentSummaryResponse(
    val id: Long,
    val groupId: Long,
    val groupName: String,
    val title: String,
    val content: String?,
    val maxApplicants: Int?,
    val currentApplicantCount: Int?,
    val recruitmentEndDate: LocalDateTime?,
    val status: RecruitmentStatus,
    val showApplicantCount: Boolean,
    val createdAt: LocalDateTime,
)

// 지원서 관련 DTO

data class CreateApplicationRequest(
    @field:Size(max = 1000, message = "지원 동기는 1000자를 초과할 수 없습니다")
    val motivation: String? = null,
    val questionAnswers: Map<Int, String> = emptyMap(),
)

data class ApplicationResponse(
    val id: Long,
    val recruitment: RecruitmentSummaryResponse,
    val applicant: UserSummaryResponse,
    val motivation: String?,
    val questionAnswers: Map<Int, String>,
    val status: ApplicationStatus,
    val reviewedBy: UserSummaryResponse?,
    val reviewedAt: LocalDateTime?,
    val reviewComment: String?,
    val appliedAt: LocalDateTime,
    val updatedAt: LocalDateTime,
)

data class ApplicationSummaryResponse(
    val id: Long,
    val applicant: UserSummaryResponse,
    val motivation: String?,
    val status: ApplicationStatus,
    val appliedAt: LocalDateTime,
)

data class ReviewApplicationRequest(
    @field:NotBlank(message = "액션은 필수입니다")
    @field:Pattern(regexp = "^(APPROVE|REJECT)$", message = "액션은 APPROVE 또는 REJECT만 가능합니다")
    val action: String,
    @field:Size(max = 1000, message = "심사 코멘트는 1000자를 초과할 수 없습니다")
    val reviewComment: String? = null,
)

// 검색 및 필터링 DTO

data class RecruitmentSearchRequest(
    val keyword: String? = null,
    val page: Int = 0,
    val size: Int = 20,
)

data class RecruitmentStatsResponse(
    val totalApplications: Int,
    val pendingApplications: Int,
    val approvedApplications: Int,
    val rejectedApplications: Int,
)

// 아카이브 관련 DTO

data class ArchivedRecruitmentResponse(
    val id: Long,
    val group: GroupSummaryResponse,
    val title: String,
    val totalApplications: Int,
    val approvedApplications: Int,
    val rejectedApplications: Int,
    val createdAt: LocalDateTime,
    val closedAt: LocalDateTime,
)
