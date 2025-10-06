package org.castlekong.backend.controller

import com.fasterxml.jackson.databind.ObjectMapper
import org.castlekong.backend.dto.*
import org.castlekong.backend.entity.*
import org.castlekong.backend.fixture.TestDataFactory
import org.castlekong.backend.repository.*
import org.castlekong.backend.security.JwtTokenProvider
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.http.MediaType
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*
import org.springframework.test.web.servlet.result.MockMvcResultHandlers.print
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.*
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@DisplayName("RecruitmentController 통합 테스트")
class RecruitmentControllerTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @Autowired
    private lateinit var jwtTokenProvider: JwtTokenProvider

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

    // Test data
    private lateinit var owner: User
    private lateinit var member: User
    private lateinit var outsider: User
    private lateinit var group: Group
    private lateinit var ownerRole: GroupRole
    private lateinit var memberRole: GroupRole
    private lateinit var ownerToken: String
    private lateinit var memberToken: String
    private lateinit var outsiderToken: String

    @BeforeEach
    fun setUp() {
        val suffix = System.nanoTime().toString()

        // Create users
        owner =
            userRepository.save(
                TestDataFactory.createTestUser(
                    name = "그룹장",
                    email = "owner-recruit-ctrl+$suffix@example.com",
                    globalRole = GlobalRole.STUDENT,
                ).copy(profileCompleted = true),
            )

        member =
            userRepository.save(
                TestDataFactory.createStudentUser(
                    name = "멤버",
                    email = "member-recruit-ctrl+$suffix@example.com",
                ).copy(profileCompleted = true),
            )

        outsider =
            userRepository.save(
                TestDataFactory.createStudentUser(
                    name = "외부인",
                    email = "outsider-recruit-ctrl+$suffix@example.com",
                ).copy(profileCompleted = true),
            )

        // Create group and roles
        group = createGroupWithRoles(owner)
        ownerRole = groupRoleRepository.findByGroupIdAndName(group.id!!, "OWNER").get()
        memberRole = groupRoleRepository.findByGroupIdAndName(group.id!!, "MEMBER").get()

        // Add member to group
        groupMemberRepository.save(
            TestDataFactory.createTestGroupMember(
                group = group,
                user = member,
                role = memberRole,
            ),
        )

        // Generate JWT tokens
        ownerToken = generateToken(owner)
        memberToken = generateToken(member)
        outsiderToken = generateToken(outsider)
    }

    private fun createGroupWithRoles(owner: User): Group {
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

    private fun generateToken(user: User): String {
        val authentication =
            UsernamePasswordAuthenticationToken(
                user.email,
                null,
                listOf(org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_${user.globalRole.name}")),
            )
        return jwtTokenProvider.generateAccessToken(authentication)
    }

    private fun createRecruitment(
        group: Group,
        title: String = "2025 신입 모집",
        status: RecruitmentStatus = RecruitmentStatus.OPEN,
        endDate: LocalDateTime = LocalDateTime.now().plusDays(10),
    ): GroupRecruitment {
        return groupRecruitmentRepository.save(
            GroupRecruitment(
                group = group,
                createdBy = owner,
                title = title,
                content = "모집 내용",
                maxApplicants = 30,
                status = status,
                recruitmentStartDate = LocalDateTime.now(),
                recruitmentEndDate = endDate,
                autoApprove = false,
                showApplicantCount = true,
                applicationQuestions = listOf("지원 동기?", "관련 경험?"),
            ),
        )
    }

    private fun createApplication(
        recruitment: GroupRecruitment,
        applicant: User,
        status: ApplicationStatus = ApplicationStatus.PENDING,
    ): RecruitmentApplication {
        return recruitmentApplicationRepository.save(
            RecruitmentApplication(
                recruitment = recruitment,
                applicant = applicant,
                motivation = "지원 동기입니다",
                questionAnswers = mapOf(0 to "답변1", 1 to "답변2"),
                status = status,
            ),
        )
    }

    // ===================================
    // 모집 공고 CRUD 테스트
    // ===================================
    @Nested
    @DisplayName("모집 공고 생성 테스트")
    inner class CreateRecruitmentTest {
        @Test
        @DisplayName("POST /api/groups/{groupId}/recruitments - 모집 공고 생성 성공")
        fun createRecruitment_success() {
            // Given
            val request =
                CreateRecruitmentRequest(
                    title = "2025 상반기 신입 모집",
                    content = "열정적인 동아리원을 모집합니다",
                    maxApplicants = 30,
                    recruitmentEndDate = LocalDateTime.now().plusDays(10),
                    autoApprove = false,
                    showApplicantCount = true,
                    applicationQuestions = listOf("자기소개", "지원동기"),
                )

            // When & Then
            mockMvc.perform(
                post("/api/groups/${group.id}/recruitments")
                    .header("Authorization", "Bearer $ownerToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isCreated)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.title").value("2025 상반기 신입 모집"))
                .andExpect(jsonPath("$.data.status").value("OPEN"))
                .andExpect(jsonPath("$.data.maxApplicants").value(30))
                .andExpect(jsonPath("$.data.currentApplicantCount").value(0))
        }

        @Test
        @DisplayName("POST /api/groups/{groupId}/recruitments - 권한 없는 멤버는 403")
        fun createRecruitment_forbiddenForMember() {
            // Given
            val request =
                CreateRecruitmentRequest(
                    title = "모집",
                    content = "내용",
                    maxApplicants = 10,
                    recruitmentEndDate = LocalDateTime.now().plusDays(5),
                    autoApprove = false,
                    showApplicantCount = true,
                    applicationQuestions = emptyList(),
                )

            // When & Then
            mockMvc.perform(
                post("/api/groups/${group.id}/recruitments")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isForbidden)
                .andExpect(jsonPath("$.success").value(false))
        }

        @Test
        @DisplayName("POST /api/groups/{groupId}/recruitments - 이미 활성 모집이 있으면 409")
        fun createRecruitment_alreadyOpenRecruitment() {
            // Given: 이미 활성 모집 존재
            createRecruitment(group, "기존 모집", RecruitmentStatus.OPEN)

            val request =
                CreateRecruitmentRequest(
                    title = "새 모집",
                    content = "내용",
                    maxApplicants = 10,
                    recruitmentEndDate = LocalDateTime.now().plusDays(5),
                    autoApprove = false,
                    showApplicantCount = true,
                    applicationQuestions = emptyList(),
                )

            // When & Then
            mockMvc.perform(
                post("/api/groups/${group.id}/recruitments")
                    .header("Authorization", "Bearer $ownerToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isConflict)
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("RECRUITMENT_ALREADY_EXISTS"))
        }
    }

    @Nested
    @DisplayName("활성 모집 조회 테스트")
    inner class GetActiveRecruitmentTest {
        @Test
        @DisplayName("GET /api/groups/{groupId}/recruitments - 활성 모집 조회 성공")
        fun getActiveRecruitment_success() {
            // Given
            val recruitment = createRecruitment(group, "활성 모집", RecruitmentStatus.OPEN)

            // When & Then
            mockMvc.perform(
                get("/api/groups/${group.id}/recruitments")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(recruitment.id))
                .andExpect(jsonPath("$.data.title").value("활성 모집"))
                .andExpect(jsonPath("$.data.status").value("OPEN"))
        }

        @Test
        @DisplayName("GET /api/groups/{groupId}/recruitments - 활성 모집이 없으면 null 반환")
        fun getActiveRecruitment_noActiveRecruitment() {
            // Given: No active recruitment

            // When & Then
            mockMvc.perform(
                get("/api/groups/${group.id}/recruitments")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").isEmpty)
        }
    }

    @Nested
    @DisplayName("모집 공고 수정 테스트")
    inner class UpdateRecruitmentTest {
        @Test
        @DisplayName("PUT /api/recruitments/{id} - 모집 공고 수정 성공")
        fun updateRecruitment_success() {
            // Given
            val recruitment = createRecruitment(group, "원래 제목", RecruitmentStatus.OPEN)
            val request =
                UpdateRecruitmentRequest(
                    title = "수정된 제목",
                    content = "수정된 내용",
                    maxApplicants = 50,
                    recruitmentEndDate = LocalDateTime.now().plusDays(15),
                    showApplicantCount = false,
                )

            // When & Then
            mockMvc.perform(
                put("/api/recruitments/${recruitment.id}")
                    .header("Authorization", "Bearer $ownerToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.title").value("수정된 제목"))
                .andExpect(jsonPath("$.data.maxApplicants").value(50))
                .andExpect(jsonPath("$.data.showApplicantCount").value(false))
        }

        @Test
        @DisplayName("PUT /api/recruitments/{id} - 권한 없는 사용자는 403")
        fun updateRecruitment_forbiddenForMember() {
            // Given
            val recruitment = createRecruitment(group, "제목", RecruitmentStatus.OPEN)
            val request =
                UpdateRecruitmentRequest(
                    title = "수정 시도",
                    content = "내용",
                    maxApplicants = 20,
                    recruitmentEndDate = LocalDateTime.now().plusDays(5),
                    showApplicantCount = true,
                )

            // When & Then
            mockMvc.perform(
                put("/api/recruitments/${recruitment.id}")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isForbidden)
                .andExpect(jsonPath("$.success").value(false))
        }

        @Test
        @DisplayName("PUT /api/recruitments/{id} - 마감된 모집은 수정 불가 (400)")
        fun updateRecruitment_closedRecruitment() {
            // Given
            val recruitment = createRecruitment(group, "마감된 모집", RecruitmentStatus.CLOSED)
            val request =
                UpdateRecruitmentRequest(
                    title = "수정 시도",
                    content = "내용",
                    maxApplicants = 20,
                    recruitmentEndDate = LocalDateTime.now().plusDays(5),
                    showApplicantCount = true,
                )

            // When & Then
            mockMvc.perform(
                put("/api/recruitments/${recruitment.id}")
                    .header("Authorization", "Bearer $ownerToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isBadRequest)
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("RECRUITMENT_NOT_ACTIVE"))
        }
    }

    @Nested
    @DisplayName("모집 조기 마감 테스트")
    inner class CloseRecruitmentTest {
        @Test
        @DisplayName("PATCH /api/recruitments/{id}/close - 조기 마감 성공")
        fun closeRecruitment_success() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)

            // When & Then
            mockMvc.perform(
                patch("/api/recruitments/${recruitment.id}/close")
                    .header("Authorization", "Bearer $ownerToken"),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("CLOSED"))
        }

        @Test
        @DisplayName("PATCH /api/recruitments/{id}/close - 권한 없는 사용자는 403")
        fun closeRecruitment_forbiddenForMember() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)

            // When & Then
            mockMvc.perform(
                patch("/api/recruitments/${recruitment.id}/close")
                    .header("Authorization", "Bearer $memberToken"),
            )
                .andDo(print())
                .andExpect(status().isForbidden)
                .andExpect(jsonPath("$.success").value(false))
        }

        @Test
        @DisplayName("PATCH /api/recruitments/{id}/close - 이미 마감된 모집은 400")
        fun closeRecruitment_alreadyClosed() {
            // Given
            val recruitment = createRecruitment(group, "마감된 모집", RecruitmentStatus.CLOSED)

            // When & Then
            mockMvc.perform(
                patch("/api/recruitments/${recruitment.id}/close")
                    .header("Authorization", "Bearer $ownerToken"),
            )
                .andDo(print())
                .andExpect(status().isBadRequest)
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("RECRUITMENT_NOT_ACTIVE"))
        }
    }

    @Nested
    @DisplayName("모집 공고 삭제 테스트")
    inner class DeleteRecruitmentTest {
        @Test
        @DisplayName("DELETE /api/recruitments/{id} - 모집 삭제 성공")
        fun deleteRecruitment_success() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)

            // When & Then
            mockMvc.perform(
                delete("/api/recruitments/${recruitment.id}")
                    .header("Authorization", "Bearer $ownerToken"),
            )
                .andDo(print())
                .andExpect(status().isNoContent)
        }

        @Test
        @DisplayName("DELETE /api/recruitments/{id} - 권한 없는 사용자는 403")
        fun deleteRecruitment_forbiddenForMember() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)

            // When & Then
            mockMvc.perform(
                delete("/api/recruitments/${recruitment.id}")
                    .header("Authorization", "Bearer $memberToken"),
            )
                .andDo(print())
                .andExpect(status().isForbidden)
                .andExpect(jsonPath("$.success").value(false))
        }

        @Test
        @DisplayName("DELETE /api/recruitments/{id} - 마감된 모집 삭제 시도하면 400")
        fun deleteRecruitment_closedRecruitment() {
            // Given
            val recruitment = createRecruitment(group, "마감된 모집", RecruitmentStatus.CLOSED)

            // When & Then
            mockMvc.perform(
                delete("/api/recruitments/${recruitment.id}")
                    .header("Authorization", "Bearer $ownerToken"),
            )
                .andDo(print())
                .andExpect(status().isBadRequest)
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("RECRUITMENT_NOT_ACTIVE"))
        }
    }

    @Nested
    @DisplayName("아카이브 조회 테스트")
    inner class GetArchivedRecruitmentsTest {
        @Test
        @DisplayName("GET /api/groups/{groupId}/recruitments/archive - 아카이브 조회 성공")
        fun getArchivedRecruitments_success() {
            // Given
            createRecruitment(group, "마감된 모집1", RecruitmentStatus.CLOSED)
            createRecruitment(group, "마감된 모집2", RecruitmentStatus.CLOSED)

            // When & Then
            mockMvc.perform(
                get("/api/groups/${group.id}/recruitments/archive")
                    .header("Authorization", "Bearer $ownerToken")
                    .param("page", "0")
                    .param("size", "20")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content").isArray)
                .andExpect(jsonPath("$.data.pagination.totalElements").value(2))
        }

        @Test
        @DisplayName("GET /api/groups/{groupId}/recruitments/archive - 권한 없는 사용자는 403")
        fun getArchivedRecruitments_forbiddenForMember() {
            // Given
            createRecruitment(group, "마감된 모집", RecruitmentStatus.CLOSED)

            // When & Then
            mockMvc.perform(
                get("/api/groups/${group.id}/recruitments/archive")
                    .header("Authorization", "Bearer $memberToken")
                    .param("page", "0")
                    .param("size", "20")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().isForbidden)
                .andExpect(jsonPath("$.success").value(false))
        }
    }

    @Nested
    @DisplayName("공개 모집 검색 테스트")
    inner class SearchPublicRecruitmentsTest {
        @Test
        @DisplayName("GET /api/recruitments/public - 공개 모집 검색 성공")
        fun searchPublicRecruitments_success() {
            // Given
            createRecruitment(group, "AI 동아리 모집", RecruitmentStatus.OPEN)
            createRecruitment(group, "웹 개발 모집", RecruitmentStatus.OPEN)

            // When & Then
            mockMvc.perform(
                get("/api/recruitments/public")
                    .param("keyword", "AI")
                    .param("page", "0")
                    .param("size", "20")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content").isArray)
        }

        @Test
        @DisplayName("GET /api/recruitments/public - 인증 없이 조회 가능")
        fun searchPublicRecruitments_withoutAuth() {
            // Given
            createRecruitment(group, "공개 모집", RecruitmentStatus.OPEN)

            // When & Then
            mockMvc.perform(
                get("/api/recruitments/public")
                    .param("page", "0")
                    .param("size", "20")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
        }
    }

    // ===================================
    // 지원서 관리 테스트
    // ===================================
    @Nested
    @DisplayName("지원서 제출 테스트")
    inner class SubmitApplicationTest {
        @Test
        @DisplayName("POST /api/recruitments/{id}/applications - 지원서 제출 성공")
        fun submitApplication_success() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)
            val request =
                CreateApplicationRequest(
                    motivation = "성장하고 싶습니다",
                    questionAnswers = mapOf(0 to "답변1", 1 to "답변2"),
                )

            // When & Then
            mockMvc.perform(
                post("/api/recruitments/${recruitment.id}/applications")
                    .header("Authorization", "Bearer $outsiderToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isCreated)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.motivation").value("성장하고 싶습니다"))
                .andExpect(jsonPath("$.data.status").value("PENDING"))
        }

        @Test
        @DisplayName("POST /api/recruitments/{id}/applications - 중복 지원 시 409")
        fun submitApplication_duplicate() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)
            createApplication(recruitment, outsider, ApplicationStatus.PENDING)

            val request =
                CreateApplicationRequest(
                    motivation = "또 지원합니다",
                    questionAnswers = mapOf(0 to "답변1", 1 to "답변2"),
                )

            // When & Then
            mockMvc.perform(
                post("/api/recruitments/${recruitment.id}/applications")
                    .header("Authorization", "Bearer $outsiderToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isConflict)
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("APPLICATION_ALREADY_EXISTS"))
        }

        @Test
        @DisplayName("POST /api/recruitments/{id}/applications - 마감된 모집에 지원 시 400")
        fun submitApplication_closedRecruitment() {
            // Given
            val recruitment = createRecruitment(group, "마감된 모집", RecruitmentStatus.CLOSED)
            val request =
                CreateApplicationRequest(
                    motivation = "지원합니다",
                    questionAnswers = mapOf(0 to "답변1", 1 to "답변2"),
                )

            // When & Then
            mockMvc.perform(
                post("/api/recruitments/${recruitment.id}/applications")
                    .header("Authorization", "Bearer $outsiderToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isBadRequest)
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("RECRUITMENT_NOT_ACTIVE"))
        }
    }

    @Nested
    @DisplayName("지원서 목록 조회 테스트")
    inner class GetApplicationsByRecruitmentTest {
        @Test
        @DisplayName("GET /api/recruitments/{id}/applications - 지원서 목록 조회 성공")
        fun getApplicationsByRecruitment_success() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)
            createApplication(recruitment, outsider, ApplicationStatus.PENDING)

            // When & Then
            mockMvc.perform(
                get("/api/recruitments/${recruitment.id}/applications")
                    .header("Authorization", "Bearer $ownerToken")
                    .param("page", "0")
                    .param("size", "20")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content").isArray)
                .andExpect(jsonPath("$.data.pagination.totalElements").value(1))
        }

        @Test
        @DisplayName("GET /api/recruitments/{id}/applications - 권한 없는 사용자는 403")
        fun getApplicationsByRecruitment_forbiddenForMember() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)
            createApplication(recruitment, outsider, ApplicationStatus.PENDING)

            // When & Then
            mockMvc.perform(
                get("/api/recruitments/${recruitment.id}/applications")
                    .header("Authorization", "Bearer $memberToken")
                    .param("page", "0")
                    .param("size", "20")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().isForbidden)
                .andExpect(jsonPath("$.success").value(false))
        }
    }

    @Nested
    @DisplayName("지원서 상세 조회 테스트")
    inner class GetApplicationTest {
        @Test
        @DisplayName("GET /api/applications/{id} - 본인 지원서 조회 성공")
        fun getApplication_successByApplicant() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)
            val application = createApplication(recruitment, outsider, ApplicationStatus.PENDING)

            // When & Then
            mockMvc.perform(
                get("/api/applications/${application.id}")
                    .header("Authorization", "Bearer $outsiderToken")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(application.id))
                .andExpect(jsonPath("$.data.motivation").value("지원 동기입니다"))
        }

        @Test
        @DisplayName("GET /api/applications/{id} - 모집 관리자 조회 성공")
        fun getApplication_successByOwner() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)
            val application = createApplication(recruitment, outsider, ApplicationStatus.PENDING)

            // When & Then
            mockMvc.perform(
                get("/api/applications/${application.id}")
                    .header("Authorization", "Bearer $ownerToken")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(application.id))
        }

        @Test
        @DisplayName("GET /api/applications/{id} - 권한 없는 사용자는 403")
        fun getApplication_forbiddenForOthers() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)
            val application = createApplication(recruitment, outsider, ApplicationStatus.PENDING)

            // When & Then
            mockMvc.perform(
                get("/api/applications/${application.id}")
                    .header("Authorization", "Bearer $memberToken")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().isForbidden)
                .andExpect(jsonPath("$.success").value(false))
        }
    }

    @Nested
    @DisplayName("지원서 심사 테스트")
    inner class ReviewApplicationTest {
        @Test
        @DisplayName("PATCH /api/applications/{id}/review - 지원서 승인 성공")
        fun reviewApplication_approve() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)
            val application = createApplication(recruitment, outsider, ApplicationStatus.PENDING)
            val request =
                ReviewApplicationRequest(
                    action = "APPROVE",
                    reviewComment = "환영합니다",
                )

            // When & Then
            mockMvc.perform(
                patch("/api/applications/${application.id}/review")
                    .header("Authorization", "Bearer $ownerToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("APPROVED"))
        }

        @Test
        @DisplayName("PATCH /api/applications/{id}/review - 지원서 거절 성공")
        fun reviewApplication_reject() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)
            val application = createApplication(recruitment, outsider, ApplicationStatus.PENDING)
            val request =
                ReviewApplicationRequest(
                    action = "REJECT",
                    reviewComment = "다음 기회에",
                )

            // When & Then
            mockMvc.perform(
                patch("/api/applications/${application.id}/review")
                    .header("Authorization", "Bearer $ownerToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("REJECTED"))
        }

        @Test
        @DisplayName("PATCH /api/applications/{id}/review - 권한 없는 사용자는 403")
        fun reviewApplication_forbiddenForMember() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)
            val application = createApplication(recruitment, outsider, ApplicationStatus.PENDING)
            val request =
                ReviewApplicationRequest(
                    action = "APPROVE",
                    reviewComment = "승인",
                )

            // When & Then
            mockMvc.perform(
                patch("/api/applications/${application.id}/review")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isForbidden)
                .andExpect(jsonPath("$.success").value(false))
        }

        @Test
        @DisplayName("PATCH /api/applications/{id}/review - 이미 심사된 지원서는 409")
        fun reviewApplication_alreadyReviewed() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)
            val application = createApplication(recruitment, outsider, ApplicationStatus.APPROVED)
            val request =
                ReviewApplicationRequest(
                    action = "REJECT",
                    reviewComment = "다시 거절",
                )

            // When & Then
            mockMvc.perform(
                patch("/api/applications/${application.id}/review")
                    .header("Authorization", "Bearer $ownerToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isConflict)
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("APPLICATION_ALREADY_REVIEWED"))
        }
    }

    @Nested
    @DisplayName("지원서 철회 테스트")
    inner class WithdrawApplicationTest {
        @Test
        @DisplayName("DELETE /api/applications/{id} - 지원서 철회 성공")
        fun withdrawApplication_success() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)
            val application = createApplication(recruitment, outsider, ApplicationStatus.PENDING)

            // When & Then
            mockMvc.perform(
                delete("/api/applications/${application.id}")
                    .header("Authorization", "Bearer $outsiderToken"),
            )
                .andDo(print())
                .andExpect(status().isNoContent)
        }

        @Test
        @DisplayName("DELETE /api/applications/{id} - 타인 지원서 철회 시도하면 403")
        fun withdrawApplication_forbiddenForOthers() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)
            val application = createApplication(recruitment, outsider, ApplicationStatus.PENDING)

            // When & Then
            mockMvc.perform(
                delete("/api/applications/${application.id}")
                    .header("Authorization", "Bearer $memberToken"),
            )
                .andDo(print())
                .andExpect(status().isForbidden)
                .andExpect(jsonPath("$.success").value(false))
        }

        @Test
        @DisplayName("DELETE /api/applications/{id} - 이미 심사된 지원서는 철회 불가 (409)")
        fun withdrawApplication_alreadyReviewed() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)
            val application = createApplication(recruitment, outsider, ApplicationStatus.APPROVED)

            // When & Then
            mockMvc.perform(
                delete("/api/applications/${application.id}")
                    .header("Authorization", "Bearer $outsiderToken"),
            )
                .andDo(print())
                .andExpect(status().isConflict)
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("APPLICATION_ALREADY_REVIEWED"))
        }
    }

    @Nested
    @DisplayName("모집 통계 조회 테스트")
    inner class GetRecruitmentStatsTest {
        @Test
        @DisplayName("GET /api/recruitments/{id}/stats - 통계 조회 성공")
        fun getRecruitmentStats_success() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)
            createApplication(recruitment, outsider, ApplicationStatus.PENDING)

            // When & Then
            mockMvc.perform(
                get("/api/recruitments/${recruitment.id}/stats")
                    .header("Authorization", "Bearer $ownerToken")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.totalApplications").value(1))
        }

        @Test
        @DisplayName("GET /api/recruitments/{id}/stats - 권한 없는 사용자는 403")
        fun getRecruitmentStats_forbiddenForMember() {
            // Given
            val recruitment = createRecruitment(group, "모집", RecruitmentStatus.OPEN)

            // When & Then
            mockMvc.perform(
                get("/api/recruitments/${recruitment.id}/stats")
                    .header("Authorization", "Bearer $memberToken")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().isForbidden)
                .andExpect(jsonPath("$.success").value(false))
        }
    }
}
