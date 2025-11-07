package org.castlekong.backend.controller

import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.entity.User
import org.castlekong.backend.fixture.TestDataFactory
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.castlekong.backend.repository.UserRepository
import org.castlekong.backend.security.JwtTokenProvider
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.http.MediaType
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.result.MockMvcResultHandlers.print
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status
import org.springframework.transaction.annotation.Transactional

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@DisplayName("GroupController - 권한 조회 API 통합 테스트")
class GroupPermissionControllerIntegrationTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

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

    // Test data
    private lateinit var owner: User
    private lateinit var member: User
    private lateinit var nonMember: User
    private lateinit var group: Group
    private lateinit var ownerToken: String
    private lateinit var memberToken: String
    private lateinit var nonMemberToken: String

    @BeforeEach
    fun setUp() {
        // 그룹장 (모든 권한 보유)
        val ownerBase = TestDataFactory.createTestUser(
            name = "그룹장",
            email = TestDataFactory.uniqueEmail("owner-perm"),
        )
        owner = userRepository.save(
            User(
                id = ownerBase.id,
                name = ownerBase.name,
                email = ownerBase.email,
                password = ownerBase.password,
                globalRole = ownerBase.globalRole,
                isActive = ownerBase.isActive,
                nickname = ownerBase.nickname,
                profileImageUrl = ownerBase.profileImageUrl,
                bio = ownerBase.bio,
                profileCompleted = true,
                emailVerified = ownerBase.emailVerified,
                college = ownerBase.college,
                department = ownerBase.department,
                studentNo = ownerBase.studentNo,
                schoolEmail = ownerBase.schoolEmail,
                professorStatus = ownerBase.professorStatus,
                academicYear = ownerBase.academicYear,
                createdAt = ownerBase.createdAt,
                updatedAt = ownerBase.updatedAt,
            )
        )

        // 일반 멤버 (권한 없음)
        member =
            userRepository.save(
                TestDataFactory.createStudentUser(
                    name = "일반 멤버",
                    email = TestDataFactory.uniqueEmail("member-perm"),
                ),
            )

        // 비멤버
        nonMember =
            userRepository.save(
                TestDataFactory.createStudentUser(
                    name = "비멤버",
                    email = TestDataFactory.uniqueEmail("nonmember-perm"),
                ),
            )

        // 그룹 및 역할 설정
        group = createGroupWithRoles(owner)

        // 멤버 추가
        val memberRole = groupRoleRepository.findByGroupIdAndName(group.id, "멤버").get()
        groupMemberRepository.save(
            TestDataFactory.createTestGroupMember(
                group = group,
                user = member,
                role = memberRole,
            ),
        )

        // JWT 토큰 생성
        ownerToken = generateToken(owner)
        memberToken = generateToken(member)
        nonMemberToken = generateToken(nonMember)
    }

    private fun createGroupWithRoles(ownerUser: User): Group {
        val testGroup =
            groupRepository.save(
                TestDataFactory.createTestGroup(
                    name = "권한 테스트 그룹",
                    owner = ownerUser,
                ),
            )

        val ownerRole = TestDataFactory.createOwnerRole(testGroup)
        ownerRole.replacePermissions(GroupPermission.entries.toList()) // 모든 권한
        groupRoleRepository.save(ownerRole)

        val advisorRole = TestDataFactory.createAdvisorRole(testGroup)
        advisorRole.replacePermissions(GroupPermission.entries.toList()) // 모든 권한
        groupRoleRepository.save(advisorRole)

        val memberRole = TestDataFactory.createMemberRole(testGroup)
        memberRole.replacePermissions(emptyList()) // 권한 없음
        groupRoleRepository.save(memberRole)

        groupMemberRepository.save(
            TestDataFactory.createTestGroupMember(
                group = testGroup,
                user = ownerUser,
                role = ownerRole,
            ),
        )

        return testGroup
    }

    private fun generateToken(user: User): String {
        val authentication =
            UsernamePasswordAuthenticationToken(
                user.email,
                null,
                listOf(SimpleGrantedAuthority("ROLE_${user.globalRole.name}")),
            )
        return jwtTokenProvider.generateAccessToken(authentication)
    }

    @Test
    @DisplayName("GET /api/groups/{groupId}/permissions - 그룹장은 모든 권한 조회 성공")
    fun getMyPermissions_Owner_ReturnsAllPermissions() {
        // When & Then
        mockMvc.perform(
            get("/api/groups/${group.id}/permissions")
                .header("Authorization", "Bearer $ownerToken")
                .accept(MediaType.APPLICATION_JSON),
        )
            .andDo(print())
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data").isArray)
            .andExpect(jsonPath("$.data.length()").value(GroupPermission.entries.size))
            .andExpect(jsonPath("$.data[?(@=='GROUP_MANAGE')]").exists())
            .andExpect(jsonPath("$.data[?(@=='MEMBER_MANAGE')]").exists())
            .andExpect(jsonPath("$.data[?(@=='CHANNEL_MANAGE')]").exists())
            .andExpect(jsonPath("$.data[?(@=='RECRUITMENT_MANAGE')]").exists())
            .andExpect(jsonPath("$.data[?(@=='CALENDAR_MANAGE')]").exists())
    }

    @Test
    @DisplayName("GET /api/groups/{groupId}/permissions - 일반 멤버는 빈 권한 배열 반환")
    fun getMyPermissions_RegularMember_ReturnsEmpty() {
        // When & Then
        mockMvc.perform(
            get("/api/groups/${group.id}/permissions")
                .header("Authorization", "Bearer $memberToken")
                .accept(MediaType.APPLICATION_JSON),
        )
            .andDo(print())
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data").isArray)
            .andExpect(jsonPath("$.data.length()").value(0))
    }

    @Test
    @DisplayName("GET /api/groups/{groupId}/permissions - 비멤버는 403 Forbidden")
    fun getMyPermissions_NonMember_Forbidden() {
        // When & Then
        mockMvc.perform(
            get("/api/groups/${group.id}/permissions")
                .header("Authorization", "Bearer $nonMemberToken")
                .accept(MediaType.APPLICATION_JSON),
        )
            .andDo(print())
            .andExpect(status().isForbidden)
    }
}
