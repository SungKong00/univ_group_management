package org.castlekong.backend.mapper

import org.castlekong.backend.dto.*
import org.castlekong.backend.entity.GroupRecruitment
import org.castlekong.backend.entity.RecruitmentApplication
import org.castlekong.backend.service.GroupMapper
import org.springframework.stereotype.Component

@Component
class RecruitmentMapper(
    private val groupMapper: GroupMapper,
) {
    fun toRecruitmentResponse(
        recruitment: GroupRecruitment,
        currentApplicantCount: Int,
        groupMemberCount: Int = 0,
    ): RecruitmentResponse {
        return RecruitmentResponse(
            id = recruitment.id,
            group = groupMapper.toGroupSummaryResponse(recruitment.group, groupMemberCount),
            createdBy = groupMapper.toUserSummaryResponse(recruitment.createdBy),
            title = recruitment.title,
            content = recruitment.content,
            maxApplicants = recruitment.maxApplicants,
            currentApplicantCount = currentApplicantCount,
            recruitmentStartDate = recruitment.recruitmentStartDate,
            recruitmentEndDate = recruitment.recruitmentEndDate,
            status = recruitment.status,
            autoApprove = recruitment.autoApprove,
            showApplicantCount = recruitment.showApplicantCount,
            applicationQuestions = recruitment.applicationQuestions,
            createdAt = recruitment.createdAt,
            updatedAt = recruitment.updatedAt,
            closedAt = recruitment.closedAt,
        )
    }

    fun toRecruitmentSummaryResponse(
        recruitment: GroupRecruitment,
        currentApplicantCount: Int? = null,
    ): RecruitmentSummaryResponse {
        return RecruitmentSummaryResponse(
            id = recruitment.id,
            groupId = recruitment.group.id,
            groupName = recruitment.group.name,
            title = recruitment.title,
            content = recruitment.content,
            maxApplicants = recruitment.maxApplicants,
            currentApplicantCount = if (recruitment.showApplicantCount) currentApplicantCount else null,
            recruitmentEndDate = recruitment.recruitmentEndDate,
            status = recruitment.status,
            showApplicantCount = recruitment.showApplicantCount,
            createdAt = recruitment.createdAt,
        )
    }

    fun toApplicationResponse(application: RecruitmentApplication): ApplicationResponse {
        return ApplicationResponse(
            id = application.id,
            recruitment = toRecruitmentSummaryResponse(application.recruitment),
            applicant = groupMapper.toUserSummaryResponse(application.applicant),
            motivation = application.motivation,
            questionAnswers = application.questionAnswers,
            status = application.status,
            reviewedBy = application.reviewedBy?.let { groupMapper.toUserSummaryResponse(it) },
            reviewedAt = application.reviewedAt,
            reviewComment = application.reviewComment,
            appliedAt = application.appliedAt,
            updatedAt = application.updatedAt,
        )
    }

    fun toApplicationSummaryResponse(application: RecruitmentApplication): ApplicationSummaryResponse {
        return ApplicationSummaryResponse(
            id = application.id,
            applicant = groupMapper.toUserSummaryResponse(application.applicant),
            motivation = application.motivation,
            status = application.status,
            appliedAt = application.appliedAt,
        )
    }

    fun toArchivedRecruitmentResponse(
        recruitment: GroupRecruitment,
        stats: RecruitmentStatsResponse,
        groupMemberCount: Int = 0,
    ): ArchivedRecruitmentResponse {
        return ArchivedRecruitmentResponse(
            id = recruitment.id,
            group = groupMapper.toGroupSummaryResponse(recruitment.group, groupMemberCount),
            title = recruitment.title,
            totalApplications = stats.totalApplications,
            approvedApplications = stats.approvedApplications,
            rejectedApplications = stats.rejectedApplications,
            createdAt = recruitment.createdAt,
            closedAt = recruitment.closedAt ?: recruitment.createdAt, // fallback to createdAt if closedAt is null
        )
    }
}
