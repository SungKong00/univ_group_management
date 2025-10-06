package org.castlekong.backend.service

import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.castlekong.backend.dto.CreateApplicationRequest
import org.castlekong.backend.dto.CreateRecruitmentRequest
import org.castlekong.backend.dto.ReviewApplicationRequest
import org.castlekong.backend.dto.UpdateRecruitmentRequest
import org.castlekong.backend.entity.ApplicationStatus
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.RecruitmentStatus
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.fixture.TestDataFactory
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRecruitmentRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.castlekong.backend.repository.RecruitmentApplicationRepository
import org.castlekong.backend.repository.UserRepository
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.test.context.ActiveProfiles
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class RecruitmentServiceIntegrationTest {
    @Autowired
    private lateinit var recruitmentService: RecruitmentService

    @Autowired
    private lateinit var userRepository: UserRepository

    @Autowired
    private lateinit var groupRepository: GroupRepository

    @Autowired
    private lateinit var groupRoleRepository: GroupRoleRepository

    @Autowired
    private lateinit var groupMemberRepository: GroupMemberRepository

    @Autowired
    private lateinit var groupRecruitmentRepository: GroupRecruitmentRepository

    @Autowired
    private lateinit var recruitmentApplicationRepository: RecruitmentApplicationRepository

    private lateinit var owner: User
    private lateinit var applicant: User
    private lateinit var reviewer: User
    private lateinit var group: Group

    @BeforeEach
    fun setUp() {
        val suffix = System.nanoTime().toString()
        owner =
            userRepository.save(
                TestDataFactory.createTestUser(
                    name = "그룹장",
                    email = "owner-recruit+$suffix@example.com",
                ).copy(profileCompleted = true),
            )

        applicant =
            userRepository.save(
                TestDataFactory.createStudentUser(
                    name = "지원자",
                    email = "applicant-recruit+$suffix@example.com",
                ),
            )

        reviewer = owner

        group = createGroupWithDefaultRoles(owner)
    }

    @Test
    @DisplayName("그룹장은 모집 공고를 생성할 수 있다")
    fun createRecruitment_Success() {
        val request =
            CreateRecruitmentRequest(
                title = "2025 상반기 신입 모집",
                content = "열정적인 동아리원을 모집합니다",
                maxApplicants = 5,
                recruitmentEndDate = LocalDateTime.now().plusDays(10),
                autoApprove = false,
                showApplicantCount = true,
                applicationQuestions = listOf("자기소개", "지원동기"),
            )

        val response = recruitmentService.createRecruitment(group.id!!, request, owner.id!!)

        assertThat(response.title).isEqualTo("2025 상반기 신입 모집")
        assertThat(response.status).isEqualTo(RecruitmentStatus.OPEN)
        assertThat(response.group.id).isEqualTo(group.id!!)
        assertThat(response.applicationQuestions).containsExactly("자기소개", "지원동기")

        val saved = groupRecruitmentRepository.findById(response.id)
        assertThat(saved).isPresent
        assertThat(saved.get().maxApplicants).isEqualTo(5)
    }

    @Test
    @DisplayName("활성 공고가 존재하면 새 공고를 생성할 수 없다")
    fun createRecruitment_DuplicateActive_ThrowsException() {
        val request =
            CreateRecruitmentRequest(
                title = "모집",
                recruitmentEndDate = LocalDateTime.now().plusDays(3),
                autoApprove = false,
            )

        recruitmentService.createRecruitment(group.id!!, request, owner.id!!)

        assertThatThrownBy { recruitmentService.createRecruitment(group.id!!, request, owner.id!!) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.RECRUITMENT_ALREADY_EXISTS)
    }

    @Test
    @DisplayName("모집 공고 정보를 수정할 수 있다")
    fun updateRecruitment_Success() {
        val recruitmentId = createRecruitment()
        val updateRequest =
            UpdateRecruitmentRequest(
                title = "수정된 모집 공고",
                content = "업데이트된 내용",
                maxApplicants = 10,
                autoApprove = true,
                showApplicantCount = false,
            )

        val response = recruitmentService.updateRecruitment(recruitmentId, updateRequest, owner.id!!)

        assertThat(response.title).isEqualTo("수정된 모집 공고")
        assertThat(response.maxApplicants).isEqualTo(10)
        assertThat(response.autoApprove).isTrue()
        assertThat(response.showApplicantCount).isFalse()

        val saved = groupRecruitmentRepository.findById(recruitmentId).get()
        assertThat(saved.title).isEqualTo("수정된 모집 공고")
        assertThat(saved.autoApprove).isTrue()
    }

    @Test
    @DisplayName("모집 공고를 마감할 수 있다")
    fun closeRecruitment_Success() {
        val recruitmentId = createRecruitment()

        val response = recruitmentService.closeRecruitment(recruitmentId, owner.id!!)

        assertThat(response.status).isEqualTo(RecruitmentStatus.CLOSED)
        assertThat(response.closedAt).isNotNull

        val saved = groupRecruitmentRepository.findById(recruitmentId).get()
        assertThat(saved.status).isEqualTo(RecruitmentStatus.CLOSED)
    }

    @Test
    @DisplayName("지원서가 존재하는 공고는 삭제할 수 없다")
    fun deleteRecruitment_WithApplications_ThrowsException() {
        val recruitmentId = createRecruitment()
        recruitmentService.submitApplication(recruitmentId, CreateApplicationRequest(motivation = "지원"), applicant.id!!)

        assertThatThrownBy { recruitmentService.deleteRecruitment(recruitmentId, owner.id!!) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.RECRUITMENT_HAS_APPLICATIONS)
    }

    @Test
    @DisplayName("지원서를 제출하면 PENDING 상태로 저장된다")
    fun submitApplication_Success() {
        val recruitmentId = createRecruitment()

        val response =
            recruitmentService.submitApplication(
                recruitmentId,
                CreateApplicationRequest(
                    motivation = "열심히 활동하겠습니다",
                    questionAnswers = mapOf(0 to "답변"),
                ),
                applicant.id!!,
            )

        assertThat(response.status).isEqualTo(ApplicationStatus.PENDING)
        assertThat(response.applicant.id).isEqualTo(applicant.id!!)

        val saved = recruitmentApplicationRepository.findById(response.id)
        assertThat(saved).isPresent
        assertThat(saved.get().motivation).isEqualTo("열심히 활동하겠습니다")
    }

    @Test
    @DisplayName("자동 승인 공고에 지원하면 즉시 그룹 멤버가 된다")
    fun submitApplication_AutoApprove_AddsMember() {
        val request =
            CreateRecruitmentRequest(
                title = "자동 승인 모집",
                autoApprove = true,
                recruitmentEndDate = LocalDateTime.now().plusDays(5),
            )
        val recruitmentId = recruitmentService.createRecruitment(group.id!!, request, owner.id!!).id

        val response =
            recruitmentService.submitApplication(
                recruitmentId,
                CreateApplicationRequest(motivation = "자동 승인"),
                applicant.id!!,
            )

        assertThat(response.status).isEqualTo(ApplicationStatus.APPROVED)

        val membership = groupMemberRepository.findByGroupIdAndUserId(group.id!!, applicant.id!!)
        assertThat(membership).isPresent
        assertThat(membership.get().role.name).isEqualTo("MEMBER")
    }

    @Test
    @DisplayName("지원서를 승인하면 그룹 멤버가 추가된다")
    fun reviewApplication_Approve_AddsMember() {
        val recruitmentId = createRecruitment()
        val application =
            recruitmentService.submitApplication(
                recruitmentId,
                CreateApplicationRequest(motivation = "승인 요청"),
                applicant.id!!,
            )

        val reviewRequest = ReviewApplicationRequest(action = "APPROVE", reviewComment = "좋은 지원서")
        val response = recruitmentService.reviewApplication(application.id, reviewRequest, reviewer.id!!)

        assertThat(response.status).isEqualTo(ApplicationStatus.APPROVED)
        assertThat(response.reviewedBy?.id).isEqualTo(reviewer.id!!)

        val membership = groupMemberRepository.findByGroupIdAndUserId(group.id!!, applicant.id!!)
        assertThat(membership).isPresent
    }

    @Test
    @DisplayName("지원서를 반려하면 멤버가 추가되지 않는다")
    fun reviewApplication_Reject_DoesNotAddMember() {
        val recruitmentId = createRecruitment()
        val application =
            recruitmentService.submitApplication(
                recruitmentId,
                CreateApplicationRequest(motivation = "반려 테스트"),
                applicant.id!!,
            )

        val reviewRequest = ReviewApplicationRequest(action = "REJECT", reviewComment = "요건 미충족")
        val response = recruitmentService.reviewApplication(application.id, reviewRequest, reviewer.id!!)

        assertThat(response.status).isEqualTo(ApplicationStatus.REJECTED)
        assertThat(response.reviewedBy?.id).isEqualTo(reviewer.id!!)

        val membership = groupMemberRepository.findByGroupIdAndUserId(group.id!!, applicant.id!!)
        assertThat(membership).isNotPresent
    }

    @Test
    @DisplayName("지원자는 본인 지원서를 철회할 수 있다")
    fun withdrawApplication_Success() {
        val recruitmentId = createRecruitment()
        val application =
            recruitmentService.submitApplication(
                recruitmentId,
                CreateApplicationRequest(motivation = "철회 예정"),
                applicant.id!!,
            )

        val response = recruitmentService.withdrawApplication(application.id, applicant.id!!)

        assertThat(response.status).isEqualTo(ApplicationStatus.WITHDRAWN)

        val saved = recruitmentApplicationRepository.findById(application.id).get()
        assertThat(saved.status).isEqualTo(ApplicationStatus.WITHDRAWN)
    }

    @Test
    @DisplayName("중복 지원은 허용되지 않는다")
    fun submitApplication_Duplicate_ThrowsException() {
        val recruitmentId = createRecruitment()

        recruitmentService.submitApplication(recruitmentId, CreateApplicationRequest(), applicant.id!!)

        assertThatThrownBy { recruitmentService.submitApplication(recruitmentId, CreateApplicationRequest(), applicant.id!!) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.APPLICATION_ALREADY_EXISTS)
    }

    private fun createRecruitment(): Long {
        val request =
            CreateRecruitmentRequest(
                title = "기본 모집",
                recruitmentEndDate = LocalDateTime.now().plusDays(7),
                autoApprove = false,
                showApplicantCount = true,
            )
        val response = recruitmentService.createRecruitment(group.id!!, request, owner.id!!)
        return response.id
    }

    private fun createGroupWithDefaultRoles(owner: User): Group {
        val group =
            groupRepository.save(
                TestDataFactory.createTestGroup(
                    name = "모집 테스트 그룹",
                    owner = owner,
                ),
            )

        val ownerRole = groupRoleRepository.save(TestDataFactory.createOwnerRole(group))
        groupRoleRepository.save(TestDataFactory.createAdvisorRole(group))
        groupRoleRepository.save(TestDataFactory.createMemberRole(group))

        groupMemberRepository.save(
            TestDataFactory.createTestGroupMember(
                group = group,
                user = owner,
                role = ownerRole,
            ),
        )

        return group
    }
}
