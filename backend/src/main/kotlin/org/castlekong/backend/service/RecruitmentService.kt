package org.castlekong.backend.service

import org.castlekong.backend.dto.*
import org.castlekong.backend.entity.*
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.mapper.RecruitmentMapper
import org.castlekong.backend.repository.*
import org.slf4j.LoggerFactory
import org.springframework.data.domain.Page
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Service
@Transactional(readOnly = true)
class RecruitmentService(
    private val groupRecruitmentRepository: GroupRecruitmentRepository,
    private val recruitmentApplicationRepository: RecruitmentApplicationRepository,
    private val groupRepository: GroupRepository,
    private val userRepository: UserRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val groupMemberService: GroupMemberService,
    private val recruitmentMapper: RecruitmentMapper,
) {
    companion object {
        private val logger = LoggerFactory.getLogger(RecruitmentService::class.java)
    }

    // 모집 게시글 관련 메서드

    @Transactional
    fun createRecruitment(
        groupId: Long,
        request: CreateRecruitmentRequest,
        createdById: Long,
    ): RecruitmentResponse {
        val group = groupRepository.findById(groupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        val createdBy = userRepository.findById(createdById)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        // 기존 활성 모집이 있는지 확인
        val existingRecruitment = groupRecruitmentRepository.findByGroupIdAndStatus(
            groupId = groupId,
            status = RecruitmentStatus.OPEN,
            pageable = PageRequest.of(0, 1)
        ).content.firstOrNull()

        if (existingRecruitment != null) {
            throw BusinessException(ErrorCode.RECRUITMENT_ALREADY_EXISTS)
        }

        val recruitment = GroupRecruitment(
            group = group,
            createdBy = createdBy,
            title = request.title,
            content = request.content,
            maxApplicants = request.maxApplicants,
            recruitmentEndDate = request.recruitmentEndDate,
            autoApprove = request.autoApprove,
            showApplicantCount = request.showApplicantCount,
            applicationQuestions = request.applicationQuestions,
        )

        val savedRecruitment = groupRecruitmentRepository.save(recruitment)
        logger.info("Created recruitment: ${savedRecruitment.id} for group: $groupId")

        val groupMemberCount = groupMemberRepository.countByGroupId(groupId).toInt()
        return recruitmentMapper.toRecruitmentResponse(savedRecruitment, 0, groupMemberCount)
    }

    fun getActiveRecruitment(groupId: Long): RecruitmentResponse? {
        val recruitment = groupRecruitmentRepository.findByGroupIdAndStatus(
            groupId = groupId,
            status = RecruitmentStatus.OPEN,
            pageable = PageRequest.of(0, 1)
        ).content.firstOrNull() ?: return null

        val applicantCount = recruitmentApplicationRepository.countByRecruitmentId(recruitment.id)
        val groupMemberCount = groupMemberRepository.countByGroupId(groupId).toInt()
        return recruitmentMapper.toRecruitmentResponse(recruitment, applicantCount.toInt(), groupMemberCount)
    }

    @Transactional
    fun updateRecruitment(
        recruitmentId: Long,
        request: UpdateRecruitmentRequest,
        userId: Long,
    ): RecruitmentResponse {
        val recruitment = groupRecruitmentRepository.findById(recruitmentId)
            .orElseThrow { BusinessException(ErrorCode.RECRUITMENT_NOT_FOUND) }

        if (recruitment.status != RecruitmentStatus.OPEN) {
            throw BusinessException(ErrorCode.RECRUITMENT_NOT_ACTIVE)
        }

        val updatedRecruitment = recruitment.copy(
            title = request.title ?: recruitment.title,
            content = request.content ?: recruitment.content,
            maxApplicants = request.maxApplicants ?: recruitment.maxApplicants,
            recruitmentEndDate = request.recruitmentEndDate ?: recruitment.recruitmentEndDate,
            autoApprove = request.autoApprove ?: recruitment.autoApprove,
            showApplicantCount = request.showApplicantCount ?: recruitment.showApplicantCount,
            applicationQuestions = request.applicationQuestions ?: recruitment.applicationQuestions,
            updatedAt = LocalDateTime.now(),
        )

        val savedRecruitment = groupRecruitmentRepository.save(updatedRecruitment)
        val applicantCount = recruitmentApplicationRepository.countByRecruitmentId(recruitmentId)
        val groupMemberCount = groupMemberRepository.countByGroupId(recruitment.group.id).toInt()

        return recruitmentMapper.toRecruitmentResponse(savedRecruitment, applicantCount.toInt(), groupMemberCount)
    }

    @Transactional
    fun closeRecruitment(recruitmentId: Long, userId: Long): RecruitmentResponse {
        val recruitment = groupRecruitmentRepository.findById(recruitmentId)
            .orElseThrow { BusinessException(ErrorCode.RECRUITMENT_NOT_FOUND) }

        if (recruitment.status != RecruitmentStatus.OPEN) {
            throw BusinessException(ErrorCode.RECRUITMENT_NOT_ACTIVE)
        }

        val closedRecruitment = recruitment.copy(
            status = RecruitmentStatus.CLOSED,
            closedAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now(),
        )

        val savedRecruitment = groupRecruitmentRepository.save(closedRecruitment)
        val applicantCount = recruitmentApplicationRepository.countByRecruitmentId(recruitmentId)
        val groupMemberCount = groupMemberRepository.countByGroupId(recruitment.group.id).toInt()

        logger.info("Closed recruitment: $recruitmentId by user: $userId")
        return recruitmentMapper.toRecruitmentResponse(savedRecruitment, applicantCount.toInt(), groupMemberCount)
    }

    @Transactional
    fun deleteRecruitment(recruitmentId: Long, userId: Long) {
        val recruitment = groupRecruitmentRepository.findById(recruitmentId)
            .orElseThrow { BusinessException(ErrorCode.RECRUITMENT_NOT_FOUND) }

        if (recruitment.status != RecruitmentStatus.OPEN) {
            throw BusinessException(ErrorCode.RECRUITMENT_NOT_ACTIVE)
        }

        // 지원서가 있는 경우 삭제 불가
        val applicationCount = recruitmentApplicationRepository.countByRecruitmentId(recruitmentId)
        if (applicationCount > 0) {
            throw BusinessException(ErrorCode.RECRUITMENT_HAS_APPLICATIONS)
        }

        groupRecruitmentRepository.delete(recruitment)
        logger.info("Deleted recruitment: $recruitmentId by user: $userId")
    }

    // 지원서 관련 메서드

    @Transactional
    fun submitApplication(
        recruitmentId: Long,
        request: CreateApplicationRequest,
        applicantId: Long,
    ): ApplicationResponse {
        val recruitment = groupRecruitmentRepository.findById(recruitmentId)
            .orElseThrow { BusinessException(ErrorCode.RECRUITMENT_NOT_FOUND) }

        val applicant = userRepository.findById(applicantId)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        // 모집 상태 확인
        if (recruitment.status != RecruitmentStatus.OPEN) {
            throw BusinessException(ErrorCode.RECRUITMENT_NOT_ACTIVE)
        }

        // 마감일 확인
        if (recruitment.recruitmentEndDate != null && recruitment.recruitmentEndDate.isBefore(LocalDateTime.now())) {
            throw BusinessException(ErrorCode.RECRUITMENT_EXPIRED)
        }

        // 이미 그룹 멤버인지 확인
        val existingMember = groupMemberRepository.findByGroupIdAndUserId(recruitment.group.id, applicantId)
        if (existingMember.isPresent) {
            throw BusinessException(ErrorCode.ALREADY_GROUP_MEMBER)
        }

        // 중복 지원 확인
        val existingApplication = recruitmentApplicationRepository.findByRecruitmentIdAndApplicantId(recruitmentId, applicantId)
        if (existingApplication.isPresent) {
            throw BusinessException(ErrorCode.APPLICATION_ALREADY_EXISTS)
        }

        // 최대 지원자 수 확인
        if (recruitment.maxApplicants != null) {
            val currentCount = recruitmentApplicationRepository.countByRecruitmentId(recruitmentId)
            if (currentCount >= recruitment.maxApplicants) {
                throw BusinessException(ErrorCode.RECRUITMENT_FULL)
            }
        }

        val application = RecruitmentApplication(
            recruitment = recruitment,
            applicant = applicant,
            motivation = request.motivation,
            questionAnswers = request.questionAnswers,
            status = if (recruitment.autoApprove) ApplicationStatus.APPROVED else ApplicationStatus.PENDING,
        )

        val savedApplication = recruitmentApplicationRepository.save(application)
        logger.info("Created application: ${savedApplication.id} for recruitment: $recruitmentId")

        // 자동 승인인 경우 그룹 가입 처리
        if (recruitment.autoApprove) {
            addUserToGroup(recruitment.group.id, applicantId)
        }

        return recruitmentMapper.toApplicationResponse(savedApplication)
    }

    fun getApplicationsByRecruitment(
        recruitmentId: Long,
        pageable: Pageable,
    ): Page<ApplicationSummaryResponse> {
        val applications = recruitmentApplicationRepository.findByRecruitmentIdOrderByAppliedAtDesc(recruitmentId, pageable)
        return applications.map { recruitmentMapper.toApplicationSummaryResponse(it) }
    }

    fun getApplication(applicationId: Long): ApplicationResponse {
        val application = recruitmentApplicationRepository.findById(applicationId)
            .orElseThrow { BusinessException(ErrorCode.APPLICATION_NOT_FOUND) }

        return recruitmentMapper.toApplicationResponse(application)
    }

    @Transactional
    fun reviewApplication(
        applicationId: Long,
        request: ReviewApplicationRequest,
        reviewerId: Long,
    ): ApplicationResponse {
        val application = recruitmentApplicationRepository.findById(applicationId)
            .orElseThrow { BusinessException(ErrorCode.APPLICATION_NOT_FOUND) }

        val reviewer = userRepository.findById(reviewerId)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        if (application.status != ApplicationStatus.PENDING) {
            throw BusinessException(ErrorCode.APPLICATION_ALREADY_REVIEWED)
        }

        val newStatus = when (request.action) {
            "APPROVE" -> ApplicationStatus.APPROVED
            "REJECT" -> ApplicationStatus.REJECTED
            else -> throw BusinessException(ErrorCode.INVALID_ACTION)
        }

        val reviewedApplication = application.copy(
            status = newStatus,
            reviewedBy = reviewer,
            reviewedAt = LocalDateTime.now(),
            reviewComment = request.reviewComment,
            updatedAt = LocalDateTime.now(),
        )

        val savedApplication = recruitmentApplicationRepository.save(reviewedApplication)

        // 승인된 경우 그룹 가입 처리
        if (newStatus == ApplicationStatus.APPROVED) {
            addUserToGroup(application.recruitment.group.id, application.applicant.id)
        }

        logger.info("Reviewed application: $applicationId with action: ${request.action}")
        return recruitmentMapper.toApplicationResponse(savedApplication)
    }

    @Transactional
    fun withdrawApplication(applicationId: Long, applicantId: Long): ApplicationResponse {
        val application = recruitmentApplicationRepository.findById(applicationId)
            .orElseThrow { BusinessException(ErrorCode.APPLICATION_NOT_FOUND) }

        if (application.applicant.id != applicantId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED)
        }

        if (application.status != ApplicationStatus.PENDING) {
            throw BusinessException(ErrorCode.APPLICATION_CANNOT_WITHDRAW)
        }

        val withdrawnApplication = application.copy(
            status = ApplicationStatus.WITHDRAWN,
            updatedAt = LocalDateTime.now(),
        )

        val savedApplication = recruitmentApplicationRepository.save(withdrawnApplication)
        logger.info("Withdrawn application: $applicationId")

        return recruitmentMapper.toApplicationResponse(savedApplication)
    }

    // 검색 및 조회 메서드

    fun searchPublicRecruitments(
        request: RecruitmentSearchRequest,
    ): Page<RecruitmentSummaryResponse> {
        val pageable = PageRequest.of(request.page, request.size)

        val recruitments = if (request.keyword.isNullOrBlank()) {
            groupRecruitmentRepository.findPublicActiveRecruitments(pageable = pageable)
        } else {
            groupRecruitmentRepository.searchActiveRecruitments(request.keyword, pageable = pageable)
        }

        return recruitments.map { recruitment ->
            val applicantCount = if (recruitment.showApplicantCount) {
                recruitmentApplicationRepository.countByRecruitmentId(recruitment.id).toInt()
            } else {
                null
            }
            recruitmentMapper.toRecruitmentSummaryResponse(recruitment, applicantCount)
        }
    }

    fun getArchivedRecruitments(groupId: Long, pageable: Pageable): Page<ArchivedRecruitmentResponse> {
        val archivedRecruitments = groupRecruitmentRepository.findByGroupIdAndStatus(
            groupId = groupId,
            status = RecruitmentStatus.CLOSED,
            pageable = pageable
        )

        return archivedRecruitments.map { recruitment ->
            val stats = getRecruitmentStats(recruitment.id)
            val groupMemberCount = groupMemberRepository.countByGroupId(groupId).toInt()
            recruitmentMapper.toArchivedRecruitmentResponse(recruitment, stats, groupMemberCount)
        }
    }

    fun getRecruitmentStats(recruitmentId: Long): RecruitmentStatsResponse {
        val totalApplications = recruitmentApplicationRepository.countByRecruitmentId(recruitmentId).toInt()
        val pendingApplications = recruitmentApplicationRepository.countByRecruitmentIdAndStatus(recruitmentId, ApplicationStatus.PENDING).toInt()
        val approvedApplications = recruitmentApplicationRepository.countByRecruitmentIdAndStatus(recruitmentId, ApplicationStatus.APPROVED).toInt()
        val rejectedApplications = recruitmentApplicationRepository.countByRecruitmentIdAndStatus(recruitmentId, ApplicationStatus.REJECTED).toInt()

        return RecruitmentStatsResponse(
            totalApplications = totalApplications,
            pendingApplications = pendingApplications,
            approvedApplications = approvedApplications,
            rejectedApplications = rejectedApplications,
        )
    }

    // 헬퍼 메서드

    private fun addUserToGroup(groupId: Long, userId: Long) {
        try {
            groupMemberService.joinGroup(groupId, userId)
            logger.info("Successfully added user: $userId to group: $groupId")
        } catch (e: Exception) {
            logger.error("Failed to add user: $userId to group: $groupId", e)
            throw e
        }
    }
}