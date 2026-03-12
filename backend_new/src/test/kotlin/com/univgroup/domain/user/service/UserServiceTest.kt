package com.univgroup.domain.user.service

import com.univgroup.domain.user.entity.User
import com.univgroup.domain.user.repository.UserRepository
import com.univgroup.shared.exception.ResourceNotFoundException
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import java.util.*

@DisplayName("UserService 단위 테스트")
class UserServiceTest {
    private lateinit var userService: UserService
    private lateinit var userRepository: UserRepository

    // Test Entities
    private lateinit var testUser: User

    @BeforeEach
    fun setUp() {
        userRepository = mockk()
        userService = UserService(userRepository)

        // Test User
        testUser = mockk(relaxed = true) {
            every { id } returns 1L
            every { email } returns "user@example.com"
            every { name } returns "Test User"
            every { nickname } returns "testuser"
            every { profileCompleted } returns false
        }
    }

    // ========== findById ==========

    @Test
    fun `findById should return user when user exists`() {
        // Given
        every { userRepository.findById(1L) } returns Optional.of(testUser)

        // When
        val result = userService.findById(1L)

        // Then
        assertThat(result).isNotNull
        assertThat(result?.id).isEqualTo(1L)
        assertThat(result?.email).isEqualTo("user@example.com")
        verify(exactly = 1) { userRepository.findById(1L) }
    }

    @Test
    fun `findById should return null when user does not exist`() {
        // Given
        every { userRepository.findById(999L) } returns Optional.empty()

        // When
        val result = userService.findById(999L)

        // Then
        assertThat(result).isNull()
        verify(exactly = 1) { userRepository.findById(999L) }
    }

    // ========== getById ==========

    @Test
    fun `getById should return user when user exists`() {
        // Given
        every { userRepository.findById(1L) } returns Optional.of(testUser)

        // When
        val result = userService.getById(1L)

        // Then
        assertThat(result).isNotNull
        assertThat(result.id).isEqualTo(1L)
        verify(exactly = 1) { userRepository.findById(1L) }
    }

    @Test
    fun `getById should throw ResourceNotFoundException when user does not exist`() {
        // Given
        every { userRepository.findById(999L) } returns Optional.empty()

        // When & Then
        assertThatThrownBy { userService.getById(999L) }
            .isInstanceOf(ResourceNotFoundException::class.java)
            .hasMessageContaining("사용자를 찾을 수 없습니다: 999")

        verify(exactly = 1) { userRepository.findById(999L) }
    }

    // ========== findByEmail ==========

    @Test
    fun `findByEmail should return user when email exists`() {
        // Given
        every { userRepository.findByEmail("user@example.com") } returns testUser

        // When
        val result = userService.findByEmail("user@example.com")

        // Then
        assertThat(result).isNotNull
        assertThat(result?.email).isEqualTo("user@example.com")
        verify(exactly = 1) { userRepository.findByEmail("user@example.com") }
    }

    @Test
    fun `findByEmail should return null when email does not exist`() {
        // Given
        every { userRepository.findByEmail("nonexistent@example.com") } returns null

        // When
        val result = userService.findByEmail("nonexistent@example.com")

        // Then
        assertThat(result).isNull()
        verify(exactly = 1) { userRepository.findByEmail("nonexistent@example.com") }
    }

    // ========== exists ==========

    @Test
    fun `exists should return true when user exists`() {
        // Given
        every { userRepository.existsById(1L) } returns true

        // When
        val result = userService.exists(1L)

        // Then
        assertThat(result).isTrue()
        verify(exactly = 1) { userRepository.existsById(1L) }
    }

    @Test
    fun `exists should return false when user does not exist`() {
        // Given
        every { userRepository.existsById(999L) } returns false

        // When
        val result = userService.exists(999L)

        // Then
        assertThat(result).isFalse()
        verify(exactly = 1) { userRepository.existsById(999L) }
    }

    // ========== isNicknameAvailable ==========

    @Test
    fun `isNicknameAvailable should return true when nickname is available`() {
        // Given
        every { userRepository.existsByNickname("newuser") } returns false

        // When
        val result = userService.isNicknameAvailable("newuser", null)

        // Then
        assertThat(result).isTrue()
        verify(exactly = 1) { userRepository.existsByNickname("newuser") }
    }

    @Test
    fun `isNicknameAvailable should return false when nickname is taken`() {
        // Given
        every { userRepository.existsByNickname("testuser") } returns true

        // When
        val result = userService.isNicknameAvailable("testuser", null)

        // Then
        assertThat(result).isFalse()
        verify(exactly = 1) { userRepository.existsByNickname("testuser") }
    }

    @Test
    fun `isNicknameAvailable should exclude current user when updating`() {
        // Given
        every { userRepository.existsByNicknameAndIdNot("testuser", 1L) } returns false

        // When
        val result = userService.isNicknameAvailable("testuser", 1L)

        // Then
        assertThat(result).isTrue()
        verify(exactly = 1) { userRepository.existsByNicknameAndIdNot("testuser", 1L) }
    }

    // ========== findOrCreateByEmail ==========

    @Test
    fun `findOrCreateByEmail should return existing user when email exists`() {
        // Given
        every { userRepository.findByEmail("user@example.com") } returns testUser

        // When
        val result = userService.findOrCreateByEmail("user@example.com", "Test User")

        // Then
        assertThat(result).isNotNull
        assertThat(result.id).isEqualTo(1L)
        verify(exactly = 1) { userRepository.findByEmail("user@example.com") }
        verify(exactly = 0) { userRepository.save(any()) }
    }

    @Test
    fun `findOrCreateByEmail should create new user when email does not exist`() {
        // Given
        val newUser = mockk<User>(relaxed = true) {
            every { id } returns 2L
            every { email } returns "newuser@example.com"
            every { name } returns "New User"
        }
        every { userRepository.findByEmail("newuser@example.com") } returns null
        every { userRepository.save(any()) } returns newUser

        // When
        val result = userService.findOrCreateByEmail("newuser@example.com", "New User")

        // Then
        assertThat(result).isNotNull
        assertThat(result.id).isEqualTo(2L)
        verify(exactly = 1) { userRepository.findByEmail("newuser@example.com") }
        verify(exactly = 1) { userRepository.save(any()) }
    }

    // ========== updateProfile ==========

    @Test
    fun `updateProfile should update user successfully`() {
        // Given
        every { userRepository.findById(1L) } returns Optional.of(testUser)
        every { userRepository.save(any()) } returns testUser

        // When
        userService.updateProfile(1L) { _ ->
            // Update logic
        }

        // Then
        verify(exactly = 1) { userRepository.findById(1L) }
        verify(exactly = 1) { userRepository.save(any()) }
    }

    // ========== updateNickname ==========

    @Test
    fun `updateNickname should update nickname when available`() {
        // Given
        val updatedUser = testUser.copy(nickname = "newuser")
        every { userRepository.existsByNicknameAndIdNot("newuser", 1L) } returns false
        every { userRepository.findById(1L) } returns Optional.of(testUser)
        every { userRepository.save(any()) } returns updatedUser

        // When
        userService.updateNickname(1L, "newuser")

        // Then
        verify(exactly = 1) { userRepository.existsByNicknameAndIdNot("newuser", 1L) }
        verify(exactly = 1) { userRepository.findById(1L) }
        verify(exactly = 1) { userRepository.save(any()) }
    }

    @Test
    fun `updateNickname should throw IllegalArgumentException when nickname is taken`() {
        // Given
        every { userRepository.existsByNicknameAndIdNot("testuser", 1L) } returns true

        // When & Then
        assertThatThrownBy { userService.updateNickname(1L, "testuser") }
            .isInstanceOf(IllegalArgumentException::class.java)
            .hasMessageContaining("이미 사용 중인 닉네임입니다: testuser")

        verify(exactly = 1) { userRepository.existsByNicknameAndIdNot("testuser", 1L) }
        verify(exactly = 0) { userRepository.findById(any()) }
        verify(exactly = 0) { userRepository.save(any()) }
    }

    // ========== completeProfile ==========

    @Test
    fun `completeProfile should mark profile as completed`() {
        // Given
        val completedUser = testUser.copy(profileCompleted = true)
        every { userRepository.findById(1L) } returns Optional.of(testUser)
        every { userRepository.save(any()) } returns completedUser

        // When
        userService.completeProfile(1L)

        // Then
        verify(exactly = 1) { userRepository.findById(1L) }
        verify(exactly = 1) { userRepository.save(any()) }
    }
}
