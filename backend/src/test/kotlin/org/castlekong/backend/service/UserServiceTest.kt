package org.castlekong.backend.service

import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.castlekong.backend.dto.ProfileUpdateRequest
import org.castlekong.backend.entity.GlobalRole
import org.castlekong.backend.entity.GroupType
import org.castlekong.backend.entity.User
import org.castlekong.backend.fixture.TestDataFactory
import org.castlekong.backend.repository.GroupJoinRequestRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.SubGroupRequestRepository
import org.castlekong.backend.repository.UserRepository
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.util.Optional

@DisplayName("UserService 테스트")
class UserServiceTest {
    private lateinit var userService: UserService
    private lateinit var userRepository: UserRepository
    private lateinit var groupRepository: GroupRepository
    private lateinit var groupMemberService: GroupMemberService
    private lateinit var groupJoinRequestRepository: GroupJoinRequestRepository
    private lateinit var subGroupRequestRepository: SubGroupRequestRepository
    private lateinit var groupMemberRepository: GroupMemberRepository
    private lateinit var groupMapper: GroupMapper

    @BeforeEach
    fun setUp() {
        userRepository = mockk()
        groupRepository = mockk()
        groupMemberService = mockk()
        groupJoinRequestRepository = mockk()
        subGroupRequestRepository = mockk()
        groupMemberRepository = mockk()
        groupMapper = mockk()

        userService =
            UserService(
                userRepository,
                groupRepository,
                groupMemberService,
                groupJoinRequestRepository,
                subGroupRequestRepository,
                groupMemberRepository,
                groupMapper,
            )
    }

    @Nested
    @DisplayName("findByEmail 테스트")
    inner class FindByEmailTest {
        @Test
        fun `should return user when email exists`() {
            // Given
            val email = TestDataFactory.TEST_EMAIL
            val user = TestDataFactory.createTestUser(email = email)
            every { userRepository.findByEmail(email) } returns Optional.of(user)

            // When
            val result = userService.findByEmail(email)

            // Then
            assertThat(result).isNotNull
            assertThat(result?.email).isEqualTo(email)
            verify { userRepository.findByEmail(email) }
        }

        @Test
        fun `should return null when email does not exist`() {
            // Given
            val email = "nonexistent@example.com"
            every { userRepository.findByEmail(email) } returns Optional.empty()

            // When
            val result = userService.findByEmail(email)

            // Then
            assertThat(result).isNull()
            verify { userRepository.findByEmail(email) }
        }
    }

    @Nested
    @DisplayName("findOrCreateUser 테스트")
    inner class FindOrCreateUserTest {
        @Test
        fun `should return existing user when user exists`() {
            // Given
            val googleUserInfo =
                GoogleUserInfo(
                    email = TestDataFactory.TEST_EMAIL,
                    name = TestDataFactory.TEST_NAME,
                    profileImageUrl = null,
                )
            val existingUser = TestDataFactory.createTestUser()
            every { userRepository.findByEmail(googleUserInfo.email) } returns Optional.of(existingUser)

            // When
            val result = userService.findOrCreateUser(googleUserInfo)

            // Then
            assertThat(result).isEqualTo(existingUser)
            verify { userRepository.findByEmail(googleUserInfo.email) }
            verify(exactly = 0) { userRepository.save(any()) }
            verify(exactly = 0) { userRepository.saveAndFlush(any()) }
        }

        @Test
        fun `should create new user when user does not exist`() {
            // Given
            val googleUserInfo =
                GoogleUserInfo(
                    email = "new@example.com",
                    name = "새 사용자",
                    profileImageUrl = "https://example.com/profile.jpg",
                )
            val newUser =
                User(
                    name = googleUserInfo.name,
                    email = googleUserInfo.email,
                    password = "",
                    globalRole = GlobalRole.STUDENT,
                )
            val savedUser = User(
                id = 1L,
                name = newUser.name,
                email = newUser.email,
                password = newUser.password,
                globalRole = newUser.globalRole,
                isActive = newUser.isActive,
                nickname = newUser.nickname,
                profileImageUrl = newUser.profileImageUrl,
                bio = newUser.bio,
                profileCompleted = newUser.profileCompleted,
                emailVerified = newUser.emailVerified,
                college = newUser.college,
                department = newUser.department,
                studentNo = newUser.studentNo,
                schoolEmail = newUser.schoolEmail,
                professorStatus = newUser.professorStatus,
                academicYear = newUser.academicYear,
                createdAt = newUser.createdAt,
                updatedAt = newUser.updatedAt,
            )

            every { userRepository.findByEmail(googleUserInfo.email) } returns Optional.empty()
            every { userRepository.saveAndFlush(any<User>()) } returns savedUser

            // When
            val result = userService.findOrCreateUser(googleUserInfo)

            // Then
            assertThat(result.id).isEqualTo(1L)
            assertThat(result.email).isEqualTo(googleUserInfo.email)
            assertThat(result.name).isEqualTo(googleUserInfo.name)
            assertThat(result.globalRole).isEqualTo(GlobalRole.STUDENT)
            assertThat(result.password).isEmpty()

            verify { userRepository.findByEmail(googleUserInfo.email) }
            verify { userRepository.saveAndFlush(any<User>()) }
        }
    }

    @Nested
    @DisplayName("completeProfile 테스트")
    inner class CompleteProfileTest {
        @Test
        fun `should update user profile successfully`() {
            // Given
            val userId = 1L
            val request =
                ProfileUpdateRequest(
                    globalRole = "PROFESSOR",
                    nickname = "테스트닉네임",
                    profileImageUrl = "https://example.com/new-profile.jpg",
                    bio = "테스트 자기소개",
                )
            val existingUser = TestDataFactory.createTestUser(id = userId)
            val updatedUser = User(
                id = existingUser.id,
                name = existingUser.name,
                email = existingUser.email,
                password = existingUser.password,
                globalRole = GlobalRole.PROFESSOR,
                isActive = existingUser.isActive,
                nickname = request.nickname,
                profileImageUrl = request.profileImageUrl,
                bio = request.bio,
                profileCompleted = true,
                emailVerified = existingUser.emailVerified,
                college = existingUser.college,
                department = existingUser.department,
                studentNo = existingUser.studentNo,
                schoolEmail = existingUser.schoolEmail,
                professorStatus = existingUser.professorStatus,
                academicYear = existingUser.academicYear,
                createdAt = existingUser.createdAt,
                updatedAt = existingUser.updatedAt,
            )

            every { userRepository.findById(userId) } returns Optional.of(existingUser)
            every { userRepository.save(any<User>()) } returns updatedUser

            // When
            val result = userService.completeProfile(userId, request)

            // Then
            assertThat(result.globalRole).isEqualTo(GlobalRole.PROFESSOR)
            assertThat(result.nickname).isEqualTo(request.nickname)
            assertThat(result.profileImageUrl).isEqualTo(request.profileImageUrl)
            assertThat(result.bio).isEqualTo(request.bio)
            assertThat(result.profileCompleted).isTrue()

            verify { userRepository.findById(userId) }
            verify { userRepository.save(any<User>()) }
        }

        @Test
        fun `should throw exception when user not found`() {
            // Given
            val userId = 999L
            val request =
                ProfileUpdateRequest(
                    globalRole = "STUDENT",
                    nickname = "테스트닉네임",
                    profileImageUrl = null,
                    bio = null,
                )
            every { userRepository.findById(userId) } returns Optional.empty()

            // When & Then
            assertThatThrownBy { userService.completeProfile(userId, request) }
                .isInstanceOf(IllegalArgumentException::class.java)
                .hasMessage("사용자를 찾을 수 없습니다: $userId")

            verify { userRepository.findById(userId) }
            verify(exactly = 0) { userRepository.save(any()) }
        }

        @Test
        fun `should handle invalid global role`() {
            // Given
            val userId = 1L
            val request =
                ProfileUpdateRequest(
                    globalRole = "INVALID_ROLE",
                    nickname = "테스트닉네임",
                    profileImageUrl = null,
                    bio = null,
                )
            val existingUser = TestDataFactory.createTestUser(id = userId)

            every { userRepository.findById(userId) } returns Optional.of(existingUser)

            // When & Then
            assertThatThrownBy { userService.completeProfile(userId, request) }
                .isInstanceOf(IllegalArgumentException::class.java)
                .hasMessageContaining("INVALID_ROLE")

            verify { userRepository.findById(userId) }
            verify(exactly = 0) { userRepository.save(any()) }
        }
    }

    @Nested
    @DisplayName("submitSignupProfile 테스트")
    inner class SubmitSignupProfileTest {
        @Test
        fun `should join user to department, college, and university groups`() {
            // Given
            val userId = 1L
            val user = TestDataFactory.createTestUser(id = userId)
            val owner = TestDataFactory.createTestUser(id = 99L, email = "owner@test.com")

            // 그룹 계층 구조: 한신대학교 -> AI/SW계열 -> AI/SW학과
            val university =
                TestDataFactory.createTestGroup(
                    id = 1L,
                    name = "한신대학교",
                    owner = owner,
                    university = "한신대학교",
                    groupType = GroupType.UNIVERSITY,
                )
            val college =
                TestDataFactory.createTestGroup(
                    id = 2L,
                    name = "AI/SW계열",
                    owner = owner,
                    parent = university,
                    university = "한신대학교",
                    college = "AI/SW계열",
                    groupType = GroupType.COLLEGE,
                )
            val department =
                TestDataFactory.createTestGroup(
                    id = 3L,
                    name = "AI/SW학과",
                    owner = owner,
                    parent = college,
                    university = "한신대학교",
                    college = "AI/SW계열",
                    department = "AI/SW학과",
                    groupType = GroupType.DEPARTMENT,
                )

            val request =
                org.castlekong.backend.dto.SignupProfileRequest(
                    name = "테스트 사용자",
                    nickname = "닉네임",
                    college = "AI/SW계열",
                    dept = "AI/SW학과",
                    studentNo = "20201234",
                    academicYear = 1,
                    schoolEmail = "test@handshin.ac.kr",
                    role = "STUDENT",
                )

            val updatedUser =
                User(
                    id = user.id,
                    name = request.name,
                    email = user.email,
                    password = user.password,
                    globalRole = GlobalRole.STUDENT,
                    isActive = user.isActive,
                    nickname = request.nickname,
                    profileImageUrl = user.profileImageUrl,
                    bio = user.bio,
                    profileCompleted = true,
                    emailVerified = user.emailVerified,
                    college = request.college,
                    department = request.dept,
                    studentNo = request.studentNo,
                    schoolEmail = request.schoolEmail,
                    professorStatus = user.professorStatus,
                    academicYear = request.academicYear,
                    createdAt = user.createdAt,
                    updatedAt = user.updatedAt,
                )

            every { userRepository.findById(userId) } returns Optional.of(user)
            every { userRepository.existsByNicknameIgnoreCase(request.nickname) } returns false
            every { userRepository.save(any<User>()) } returns updatedUser
            every {
                groupRepository.findByUniversityAndCollegeAndDepartment(
                    "한신대학교",
                    "AI/SW계열",
                    "AI/SW학과",
                )
            } returns listOf(department)
            every { groupMemberService.joinGroup(3L, userId) } returns mockk()
            every { groupMemberService.joinGroup(2L, userId) } returns mockk()
            every { groupMemberService.joinGroup(1L, userId) } returns mockk()

            // When
            val result = userService.submitSignupProfile(userId, request)

            // Then
            assertThat(result.profileCompleted).isTrue()
            assertThat(result.nickname).isEqualTo(request.nickname)
            assertThat(result.college).isEqualTo(request.college)
            assertThat(result.department).isEqualTo(request.dept)

            // 3개 그룹(학과, 계열, 대학교) 모두 가입 확인
            verify { groupMemberService.joinGroup(3L, userId) } // 학과
            verify { groupMemberService.joinGroup(2L, userId) } // 계열
            verify { groupMemberService.joinGroup(1L, userId) } // 대학교
        }

        @Test
        fun `should handle college-only selection`() {
            // Given
            val userId = 1L
            val user = TestDataFactory.createTestUser(id = userId)
            val owner = TestDataFactory.createTestUser(id = 99L, email = "owner@test.com")

            val university =
                TestDataFactory.createTestGroup(
                    id = 1L,
                    name = "한신대학교",
                    owner = owner,
                    university = "한신대학교",
                    groupType = GroupType.UNIVERSITY,
                )
            val college =
                TestDataFactory.createTestGroup(
                    id = 2L,
                    name = "AI/SW계열",
                    owner = owner,
                    parent = university,
                    university = "한신대학교",
                    college = "AI/SW계열",
                    groupType = GroupType.COLLEGE,
                )

            val request =
                org.castlekong.backend.dto.SignupProfileRequest(
                    name = "테스트 사용자",
                    nickname = "닉네임",
                    college = "AI/SW계열",
                    dept = null,
                    studentNo = "20201234",
                    academicYear = 1,
                    schoolEmail = "test@handshin.ac.kr",
                    role = "STUDENT",
                )

            val updatedUser =
                User(
                    id = user.id,
                    name = request.name,
                    email = user.email,
                    password = user.password,
                    globalRole = GlobalRole.STUDENT,
                    isActive = user.isActive,
                    nickname = request.nickname,
                    profileImageUrl = user.profileImageUrl,
                    bio = user.bio,
                    profileCompleted = true,
                    emailVerified = user.emailVerified,
                    college = request.college,
                    department = request.dept,
                    studentNo = request.studentNo,
                    schoolEmail = request.schoolEmail,
                    professorStatus = user.professorStatus,
                    academicYear = request.academicYear,
                    createdAt = user.createdAt,
                    updatedAt = user.updatedAt,
                )

            every { userRepository.findById(userId) } returns Optional.of(user)
            every { userRepository.existsByNicknameIgnoreCase(request.nickname) } returns false
            every { userRepository.save(any<User>()) } returns updatedUser
            every {
                groupRepository.findByUniversityAndCollegeAndDepartment(
                    "한신대학교",
                    "AI/SW계열",
                    null,
                )
            } returns listOf(college)
            every { groupMemberService.joinGroup(2L, userId) } returns mockk()
            every { groupMemberService.joinGroup(1L, userId) } returns mockk()

            // When
            val result = userService.submitSignupProfile(userId, request)

            // Then
            assertThat(result.profileCompleted).isTrue()

            // 2개 그룹(계열, 대학교) 가입 확인
            verify { groupMemberService.joinGroup(2L, userId) } // 계열
            verify { groupMemberService.joinGroup(1L, userId) } // 대학교
        }
    }

    @Nested
    @DisplayName("convertToUserResponse 테스트")
    inner class ConvertToUserResponseTest {
        @Test
        fun `should convert user to user response correctly`() {
            // Given
            val userBase = TestDataFactory.createTestUser(
                id = 1L,
                email = "test@example.com",
                name = "테스트 사용자",
                globalRole = GlobalRole.PROFESSOR,
            )
            val user = User(
                id = userBase.id,
                name = userBase.name,
                email = userBase.email,
                password = userBase.password,
                globalRole = userBase.globalRole,
                isActive = userBase.isActive,
                nickname = "테스트닉네임",
                profileImageUrl = "https://example.com/profile.jpg",
                bio = "테스트 자기소개",
                profileCompleted = true,
                emailVerified = true,
                college = userBase.college,
                department = userBase.department,
                studentNo = userBase.studentNo,
                schoolEmail = userBase.schoolEmail,
                professorStatus = userBase.professorStatus,
                academicYear = userBase.academicYear,
                createdAt = userBase.createdAt,
                updatedAt = userBase.updatedAt,
            )

            // When
            val result = userService.convertToUserResponse(user)

            // Then
            assertThat(result.id).isEqualTo(user.id)
            assertThat(result.name).isEqualTo(user.name)
            assertThat(result.email).isEqualTo(user.email)
            assertThat(result.globalRole).isEqualTo(user.globalRole.name)
            assertThat(result.isActive).isEqualTo(user.isActive)
            assertThat(result.nickname).isEqualTo(user.nickname)
            assertThat(result.profileImageUrl).isEqualTo(user.profileImageUrl)
            assertThat(result.bio).isEqualTo(user.bio)
            assertThat(result.profileCompleted).isEqualTo(user.profileCompleted)
            assertThat(result.emailVerified).isEqualTo(user.emailVerified)
            assertThat(result.createdAt).isEqualTo(user.createdAt)
            assertThat(result.updatedAt).isEqualTo(user.updatedAt)
        }

        @Test
        fun `should handle user with minimal information`() {
            // Given
            val user = TestDataFactory.createTestUser()

            // When
            val result = userService.convertToUserResponse(user)

            // Then
            assertThat(result.id).isEqualTo(user.id)
            assertThat(result.name).isEqualTo(user.name)
            assertThat(result.email).isEqualTo(user.email)
            assertThat(result.globalRole).isEqualTo(user.globalRole.name)
            assertThat(result.isActive).isEqualTo(user.isActive)
            assertThat(result.nickname).isNull()
            assertThat(result.profileImageUrl).isNull()
            assertThat(result.bio).isNull()
            assertThat(result.profileCompleted).isFalse()
            assertThat(result.emailVerified).isTrue() // User 엔티티에서 기본값이 true
        }
    }
}
