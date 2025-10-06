package org.castlekong.backend.controller

import com.fasterxml.jackson.databind.ObjectMapper
import org.castlekong.backend.entity.GlobalRole
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupRole
import org.castlekong.backend.entity.User
import org.castlekong.backend.fixture.TestDataFactory
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.castlekong.backend.repository.UserRepository
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
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.result.MockMvcResultHandlers.print
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.*
import org.springframework.transaction.annotation.Transactional

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@DisplayName("MeController 통합 테스트")
class MeControllerTest {
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

    // Test data
    private lateinit var testUser: User
    private lateinit var testGroup: Group
    private lateinit var ownerRole: GroupRole
    private lateinit var token: String

    @BeforeEach
    fun setUp() {
        val suffix = System.nanoTime().toString()

        // Create test user
        testUser =
            userRepository.save(
                TestDataFactory.createTestUser(
                    name = "테스트 사용자",
                    email = "me-test-$suffix@example.com",
                    globalRole = GlobalRole.STUDENT,
                ).copy(
                    profileCompleted = true,
                    nickname = "테스터",
                    bio = "테스트 계정입니다",
                ),
            )

        // Create group and roles
        testGroup = createGroupWithRoles(testUser)

        // Generate JWT token
        token = generateToken(testUser)
    }

    private fun createGroupWithRoles(owner: User): Group {
        val group =
            groupRepository.save(
                TestDataFactory.createTestGroup(
                    name = "Me 테스트 그룹",
                    owner = owner,
                ),
            )

        ownerRole = groupRoleRepository.save(TestDataFactory.createOwnerRole(group))
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

    @Nested
    @DisplayName("내 정보 조회 테스트")
    inner class GetMeTest {
        @Test
        @DisplayName("GET /api/me - 내 정보 조회 성공")
        fun getMe_success() {
            // Given: 인증된 사용자

            // When & Then
            mockMvc.perform(
                get("/api/me")
                    .header("Authorization", "Bearer $token")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(testUser.id))
                .andExpect(jsonPath("$.data.email").value(testUser.email))
                .andExpect(jsonPath("$.data.name").value(testUser.name))
                .andExpect(jsonPath("$.data.globalRole").value(testUser.globalRole.name))
                .andExpect(jsonPath("$.data.nickname").value("테스터"))
                .andExpect(jsonPath("$.data.bio").value("테스트 계정입니다"))
                .andExpect(jsonPath("$.data.profileCompleted").value(true))
        }

        @Test
        @DisplayName("GET /api/me - 인증 없이 요청 시 401 또는 403")
        fun getMe_unauthorized() {
            // Given: 인증 토큰 없음

            // When & Then
            mockMvc.perform(
                get("/api/me")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().is4xxClientError) // 401 or 403 허용
        }

        @Test
        @DisplayName("GET /api/me - 잘못된 토큰으로 요청 시 401 또는 403")
        fun getMe_invalidToken() {
            // Given: 잘못된 토큰

            // When & Then
            mockMvc.perform(
                get("/api/me")
                    .header("Authorization", "Bearer invalid.token.here")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().is4xxClientError) // 401 or 403 허용
        }
    }

    @Nested
    @DisplayName("내 그룹 목록 조회 테스트")
    inner class GetMyGroupsTest {
        @Test
        @DisplayName("GET /api/me/groups - 내 그룹 목록 조회 성공")
        fun getMyGroups_success() {
            // Given: 사용자가 그룹에 속해 있음

            // When & Then
            mockMvc.perform(
                get("/api/me/groups")
                    .header("Authorization", "Bearer $token")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").isArray)
                .andExpect(jsonPath("$.data[0].id").value(testGroup.id))
                .andExpect(jsonPath("$.data[0].name").value(testGroup.name))
                .andExpect(jsonPath("$.data[0].role").value("OWNER"))
                .andExpect(jsonPath("$.data[0].permissions").isArray)
        }

        @Test
        @DisplayName("GET /api/me/groups - 그룹이 없는 사용자는 빈 배열 반환")
        fun getMyGroups_emptyForUserWithoutGroups() {
            // Given: 그룹에 속하지 않은 새 사용자
            val newUser =
                userRepository.save(
                    TestDataFactory.createTestUser(
                        name = "신규 사용자",
                        email = "new-user-${System.nanoTime()}@example.com",
                    ),
                )
            val newToken = generateToken(newUser)

            // When & Then
            mockMvc.perform(
                get("/api/me/groups")
                    .header("Authorization", "Bearer $newToken")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").isArray)
                .andExpect(jsonPath("$.data").isEmpty)
        }

        @Test
        @DisplayName("GET /api/me/groups - 인증 없이 요청 시 401 또는 403")
        fun getMyGroups_unauthorized() {
            // Given: 인증 토큰 없음

            // When & Then
            mockMvc.perform(
                get("/api/me/groups")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().is4xxClientError) // 401 or 403 허용
        }

        @Test
        @DisplayName("GET /api/me/groups - 여러 그룹에 속한 경우 레벨순 정렬")
        fun getMyGroups_sortedByLevel() {
            // Given: 사용자가 여러 그룹에 속함
            // 하위 그룹 생성 (level 1)
            val subGroup =
                groupRepository.save(
                    TestDataFactory.createTestGroup(
                        name = "하위 그룹",
                        owner = testUser,
                        parent = testGroup,
                    ),
                )
            val subGroupRole = groupRoleRepository.save(TestDataFactory.createOwnerRole(subGroup))
            groupMemberRepository.save(
                TestDataFactory.createTestGroupMember(
                    group = subGroup,
                    user = testUser,
                    role = subGroupRole,
                ),
            )

            // When & Then
            mockMvc.perform(
                get("/api/me/groups")
                    .header("Authorization", "Bearer $token")
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").isArray)
                .andExpect(jsonPath("$.data.length()").value(2))
                // 첫 번째는 상위 그룹 (level 0)
                .andExpect(jsonPath("$.data[0].id").value(testGroup.id))
                .andExpect(jsonPath("$.data[0].level").value(0))
                // 두 번째는 하위 그룹 (level 1)
                .andExpect(jsonPath("$.data[1].id").value(subGroup.id))
                .andExpect(jsonPath("$.data[1].level").value(1))
        }
    }
}
