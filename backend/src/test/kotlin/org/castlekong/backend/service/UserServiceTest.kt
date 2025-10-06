package org.castlekong.backend.service

import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.castlekong.backend.dto.ProfileUpdateRequest
import org.castlekong.backend.entity.GlobalRole
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
    private lateinit var groupManagementService: GroupManagementService
    private lateinit var groupMemberService: GroupMemberService
    private lateinit var groupJoinRequestRepository: GroupJoinRequestRepository
    private lateinit var subGroupRequestRepository: SubGroupRequestRepository
    private lateinit var groupMemberRepository: GroupMemberRepository

    @BeforeEach
    fun setUp() {
        userRepository = mockk()
        groupRepository = mockk()
        groupManagementService = mockk()
        groupMemberService = mockk()
        groupJoinRequestRepository = mockk()
        subGroupRequestRepository = mockk()
        groupMemberRepository = mockk()

        userService =
            UserService(
                userRepository,
                groupRepository,
                groupMemberService,
                groupJoinRequestRepository,
                subGroupRequestRepository,
                groupMemberRepository,
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
            val savedUser = newUser.copy(id = 1L)

            every { userRepository.findByEmail(googleUserInfo.email) } returns Optional.empty()
            every { userRepository.save(any<User>()) } returns savedUser

            // When
            val result = userService.findOrCreateUser(googleUserInfo)

            // Then
            assertThat(result.id).isEqualTo(1L)
            assertThat(result.email).isEqualTo(googleUserInfo.email)
            assertThat(result.name).isEqualTo(googleUserInfo.name)
            assertThat(result.globalRole).isEqualTo(GlobalRole.STUDENT)
            assertThat(result.password).isEmpty()

            verify { userRepository.findByEmail(googleUserInfo.email) }
            verify { userRepository.save(any<User>()) }
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
            val updatedUser =
                existingUser.copy(
                    globalRole = GlobalRole.PROFESSOR,
                    nickname = request.nickname,
                    profileImageUrl = request.profileImageUrl,
                    bio = request.bio,
                    profileCompleted = true,
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
    @DisplayName("convertToUserResponse 테스트")
    inner class ConvertToUserResponseTest {
        @Test
        fun `should convert user to user response correctly`() {
            // Given
            val user =
                TestDataFactory.createTestUser(
                    id = 1L,
                    email = "test@example.com",
                    name = "테스트 사용자",
                    globalRole = GlobalRole.PROFESSOR,
                ).copy(
                    nickname = "테스트닉네임",
                    profileImageUrl = "https://example.com/profile.jpg",
                    bio = "테스트 자기소개",
                    profileCompleted = true,
                    emailVerified = true,
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
