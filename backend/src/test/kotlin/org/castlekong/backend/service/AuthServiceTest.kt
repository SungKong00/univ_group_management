package org.castlekong.backend.service

import io.mockk.*
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.castlekong.backend.dto.UserResponse
import org.castlekong.backend.entity.GlobalRole
import org.castlekong.backend.fixture.TestDataFactory
import org.castlekong.backend.security.JwtTokenProvider
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.security.core.Authentication

@DisplayName("AuthService 테스트")
class AuthServiceTest {
    private lateinit var authService: AuthService
    private lateinit var userService: UserService
    private lateinit var jwtTokenProvider: JwtTokenProvider

    @BeforeEach
    fun setUp() {
        userService = mockk()
        jwtTokenProvider = mockk()
        authService = AuthService(userService, jwtTokenProvider, "test-google-client-id")
    }

    @Nested
    @DisplayName("Google OAuth2 인증 테스트")
    inner class GoogleAuthenticateTest {
        @Test
        fun `should return login response when valid Google token provided`() {
            // Given
            val googleToken = "valid.google.token"
            val user = TestDataFactory.createTestUser()
            val expectedAccessToken = "valid.access.token"
            val userResponse =
                UserResponse(
                    id = user.id,
                    name = user.name,
                    email = user.email,
                    globalRole = user.globalRole.name,
                    isActive = user.isActive,
                    createdAt = user.createdAt,
                    updatedAt = user.updatedAt,
                )

            val googleUserInfo = GoogleUserInfo(
                email = user.email,
                name = user.name,
                profileImageUrl = null
            )

            every { userService.findOrCreateUser(any()) } returns user
            every { jwtTokenProvider.generateAccessToken(any<Authentication>()) } returns expectedAccessToken
            every { userService.convertToUserResponse(user) } returns userResponse

            // Mock the private method by using spyk
            val authServiceSpy = spyk(authService, recordPrivateCalls = true)
            every { authServiceSpy["verifyGoogleToken"](googleToken) } returns googleUserInfo

            // When
            val result = authServiceSpy.authenticateWithGoogle(googleToken)

            // Then
            assertThat(result.accessToken).isEqualTo(expectedAccessToken)
            assertThat(result.tokenType).isEqualTo("Bearer")
            assertThat(result.expiresIn).isEqualTo(86400000L)
            assertThat(result.user).isEqualTo(userResponse)

            verify { userService.findOrCreateUser(any()) }
            verify { jwtTokenProvider.generateAccessToken(any<Authentication>()) }
        }

        @Test
        fun `should throw exception when invalid Google token provided`() {
            // Given
            val invalidToken = "invalid.google.token"
            val authServiceSpy = spyk(authService, recordPrivateCalls = true)
            every { authServiceSpy["verifyGoogleToken"](invalidToken) } returns null

            // When & Then
            assertThatThrownBy { authServiceSpy.authenticateWithGoogle(invalidToken) }
                .isInstanceOf(IllegalArgumentException::class.java)
                .hasMessage("Invalid Google token")

            verify(exactly = 0) { userService.findOrCreateUser(any()) }
            verify(exactly = 0) { jwtTokenProvider.generateAccessToken(any<Authentication>()) }
        }

        @Test
        fun `should throw exception when user is inactive`() {
            // Given
            val googleToken = "valid.google.token"
            val inactiveUser = TestDataFactory.createInactiveUser()
            val googleUserInfo = GoogleUserInfo(
                email = inactiveUser.email,
                name = inactiveUser.name,
                profileImageUrl = null
            )

            every { userService.findOrCreateUser(any()) } returns inactiveUser
            val authServiceSpy = spyk(authService, recordPrivateCalls = true)
            every { authServiceSpy["verifyGoogleToken"](googleToken) } returns googleUserInfo

            // When & Then
            assertThatThrownBy { authServiceSpy.authenticateWithGoogle(googleToken) }
                .isInstanceOf(IllegalArgumentException::class.java)
                .hasMessage("비활성화된 사용자입니다")

            verify { userService.findOrCreateUser(any()) }
            verify(exactly = 0) { jwtTokenProvider.generateAccessToken(any<Authentication>()) }
        }

        @Test
        fun `should generate correct authorities for user global role`() {
            // Given
            val googleToken = "valid.google.token"
            val user = TestDataFactory.createTestUser(globalRole = GlobalRole.STUDENT)
            val expectedAccessToken = "valid.access.token"
            val userResponse =
                UserResponse(
                    id = user.id,
                    name = user.name,
                    email = user.email,
                    globalRole = user.globalRole.name,
                    isActive = user.isActive,
                    createdAt = user.createdAt,
                    updatedAt = user.updatedAt,
                )

            val googleUserInfo = GoogleUserInfo(
                email = user.email,
                name = user.name,
                profileImageUrl = null
            )

            every { userService.findOrCreateUser(any()) } returns user
            every { userService.convertToUserResponse(user) } returns userResponse

            val authSlot = slot<Authentication>()
            every { jwtTokenProvider.generateAccessToken(capture(authSlot)) } returns expectedAccessToken

            val authServiceSpy = spyk(authService, recordPrivateCalls = true)
            every { authServiceSpy["verifyGoogleToken"](googleToken) } returns googleUserInfo

            // When
            authServiceSpy.authenticateWithGoogle(googleToken)

            // Then
            assertThat(authSlot.captured).isNotNull
            assertThat(authSlot.captured.name).isEqualTo(user.email)
            assertThat(authSlot.captured.authorities).hasSize(1)
            assertThat(authSlot.captured.authorities.first().authority).isEqualTo("ROLE_STUDENT")
        }
    }
}
