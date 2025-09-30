package org.castlekong.backend.service

import io.mockk.*
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.castlekong.backend.dto.UserResponse
import org.castlekong.backend.entity.GlobalRole
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
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
    private lateinit var googleIdTokenVerifierPort: GoogleIdTokenVerifierPort
    private lateinit var googleUserInfoFetcherPort: GoogleUserInfoFetcherPort

    @BeforeEach
    fun setUp() {
        userService = mockk()
        jwtTokenProvider = mockk(relaxed = true) // generateRefreshToken 누락 시 예외 방지
        googleIdTokenVerifierPort = mockk()
        googleUserInfoFetcherPort = mockk()
        authService =
            AuthService(
                userService,
                jwtTokenProvider,
                googleIdTokenVerifierPort,
                googleUserInfoFetcherPort,
            )
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
                    nickname = user.nickname,
                    profileImageUrl = user.profileImageUrl,
                    bio = user.bio,
                    profileCompleted = user.profileCompleted,
                    emailVerified = user.emailVerified,
                    createdAt = user.createdAt,
                    updatedAt = user.updatedAt,
                )

            val googleUserInfo =
                GoogleUserInfo(
                    email = user.email,
                    name = user.name,
                    profileImageUrl = null,
                )

            every { userService.findOrCreateUser(any()) } returns user
            every { jwtTokenProvider.generateAccessToken(any<Authentication>()) } returns expectedAccessToken
            every { jwtTokenProvider.generateRefreshToken(any<Authentication>()) } returns "refresh.token"
            every { userService.convertToUserResponse(user) } returns userResponse
            every { googleIdTokenVerifierPort.verify(googleToken) } returns googleUserInfo

            // When
            val result = authService.authenticateWithGoogle(googleToken)

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
            every { googleIdTokenVerifierPort.verify(invalidToken) } returns null

            // When & Then
            assertThatThrownBy { authService.authenticateWithGoogle(invalidToken) }
                .isInstanceOf(BusinessException::class.java)
                .hasMessage(ErrorCode.INVALID_TOKEN.message)

            verify(exactly = 0) { userService.findOrCreateUser(any()) }
            verify(exactly = 0) { jwtTokenProvider.generateAccessToken(any<Authentication>()) }
        }

        @Test
        fun `should throw exception when user is inactive`() {
            // Given
            val googleToken = "valid.google.token"
            val inactiveUser = TestDataFactory.createInactiveUser()
            val googleUserInfo =
                GoogleUserInfo(
                    email = inactiveUser.email,
                    name = inactiveUser.name,
                    profileImageUrl = null,
                )

            every { userService.findOrCreateUser(any()) } returns inactiveUser
            every { jwtTokenProvider.generateRefreshToken(any<Authentication>()) } returns "refresh.token"
            every { googleIdTokenVerifierPort.verify(googleToken) } returns googleUserInfo

            // When & Then
            assertThatThrownBy { authService.authenticateWithGoogle(googleToken) }
                .isInstanceOf(BusinessException::class.java)
                .hasMessage(ErrorCode.UNAUTHORIZED.message)

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
                    nickname = user.nickname,
                    profileImageUrl = user.profileImageUrl,
                    bio = user.bio,
                    profileCompleted = user.profileCompleted,
                    emailVerified = user.emailVerified,
                    createdAt = user.createdAt,
                    updatedAt = user.updatedAt,
                )

            val googleUserInfo =
                GoogleUserInfo(
                    email = user.email,
                    name = user.name,
                    profileImageUrl = null,
                )

            every { userService.findOrCreateUser(any()) } returns user
            every { userService.convertToUserResponse(user) } returns userResponse

            val authSlot = slot<Authentication>()
            every { jwtTokenProvider.generateAccessToken(capture(authSlot)) } returns expectedAccessToken
            every { jwtTokenProvider.generateRefreshToken(any<Authentication>()) } returns "refresh.token"
            every { googleIdTokenVerifierPort.verify(googleToken) } returns googleUserInfo

            // When
            authService.authenticateWithGoogle(googleToken)

            // Then
            assertThat(authSlot.captured).isNotNull
            assertThat(authSlot.captured.name).isEqualTo(user.email)
            assertThat(authSlot.captured.authorities).hasSize(1)
            assertThat(authSlot.captured.authorities.first().authority).isEqualTo("ROLE_STUDENT")
        }
    }

    @Nested
    @DisplayName("Google Access Token 인증 테스트")
    inner class GoogleAccessTokenAuthenticateTest {
        @Test
        fun `should return login response when valid Google access token provided`() {
            // Given
            val googleAccessToken = "valid.google.access.token"
            val user = TestDataFactory.createTestUser()
            val expectedAccessToken = "valid.access.token"
            val userResponse =
                UserResponse(
                    id = user.id,
                    name = user.name,
                    email = user.email,
                    globalRole = user.globalRole.name,
                    isActive = user.isActive,
                    nickname = user.nickname,
                    profileImageUrl = user.profileImageUrl,
                    bio = user.bio,
                    profileCompleted = user.profileCompleted,
                    emailVerified = user.emailVerified,
                    createdAt = user.createdAt,
                    updatedAt = user.updatedAt,
                )

            val googleUserInfo =
                GoogleUserInfo(
                    email = user.email,
                    name = user.name,
                    profileImageUrl = null,
                )

            every { userService.findOrCreateUser(any()) } returns user
            every { jwtTokenProvider.generateAccessToken(any<Authentication>()) } returns expectedAccessToken
            every { jwtTokenProvider.generateRefreshToken(any<Authentication>()) } returns "refresh.token"
            every { userService.convertToUserResponse(user) } returns userResponse
            every { googleUserInfoFetcherPort.fetch(googleAccessToken) } returns googleUserInfo

            // When
            val result = authService.authenticateWithGoogleAccessToken(googleAccessToken)

            // Then
            assertThat(result.accessToken).isEqualTo(expectedAccessToken)
            assertThat(result.tokenType).isEqualTo("Bearer")
            assertThat(result.expiresIn).isEqualTo(86400000L)
            assertThat(result.user).isEqualTo(userResponse)

            verify { userService.findOrCreateUser(any()) }
            verify { jwtTokenProvider.generateAccessToken(any<Authentication>()) }
        }

        @Test
        fun `should throw exception when invalid Google access token provided`() {
            // Given
            val invalidToken = "invalid.google.access.token"
            every { googleUserInfoFetcherPort.fetch(invalidToken) } returns null

            // When & Then
            assertThatThrownBy { authService.authenticateWithGoogleAccessToken(invalidToken) }
                .isInstanceOf(BusinessException::class.java)
                .hasMessage(ErrorCode.INVALID_TOKEN.message)

            verify(exactly = 0) { userService.findOrCreateUser(any()) }
            verify(exactly = 0) { jwtTokenProvider.generateAccessToken(any<Authentication>()) }
        }

        @Test
        fun `should throw exception when user is inactive with access token`() {
            // Given
            val googleAccessToken = "valid.google.access.token"
            val inactiveUser = TestDataFactory.createInactiveUser()
            val googleUserInfo =
                GoogleUserInfo(
                    email = inactiveUser.email,
                    name = inactiveUser.name,
                    profileImageUrl = null,
                )

            every { userService.findOrCreateUser(any()) } returns inactiveUser
            every { jwtTokenProvider.generateRefreshToken(any<Authentication>()) } returns "refresh.token"
            every { googleUserInfoFetcherPort.fetch(googleAccessToken) } returns googleUserInfo

            // When & Then
            assertThatThrownBy { authService.authenticateWithGoogleAccessToken(googleAccessToken) }
                .isInstanceOf(BusinessException::class.java)
                .hasMessage(ErrorCode.UNAUTHORIZED.message)

            verify { userService.findOrCreateUser(any()) }
            verify(exactly = 0) { jwtTokenProvider.generateAccessToken(any<Authentication>()) }
        }

        @Test
        fun `should generate correct authorities for user global role with access token`() {
            // Given
            val googleAccessToken = "valid.google.access.token"
            val user = TestDataFactory.createTestUser(globalRole = GlobalRole.PROFESSOR)
            val expectedAccessToken = "valid.access.token"
            val userResponse =
                UserResponse(
                    id = user.id,
                    name = user.name,
                    email = user.email,
                    globalRole = user.globalRole.name,
                    isActive = user.isActive,
                    nickname = user.nickname,
                    profileImageUrl = user.profileImageUrl,
                    bio = user.bio,
                    profileCompleted = user.profileCompleted,
                    emailVerified = user.emailVerified,
                    createdAt = user.createdAt,
                    updatedAt = user.updatedAt,
                )

            val googleUserInfo =
                GoogleUserInfo(
                    email = user.email,
                    name = user.name,
                    profileImageUrl = null,
                )

            every { userService.findOrCreateUser(any()) } returns user
            every { userService.convertToUserResponse(user) } returns userResponse

            val authSlot = slot<Authentication>()
            every { jwtTokenProvider.generateAccessToken(capture(authSlot)) } returns expectedAccessToken
            every { jwtTokenProvider.generateRefreshToken(any<Authentication>()) } returns "refresh.token"
            every { googleUserInfoFetcherPort.fetch(googleAccessToken) } returns googleUserInfo

            // When
            authService.authenticateWithGoogleAccessToken(googleAccessToken)

            // Then
            assertThat(authSlot.captured).isNotNull
            assertThat(authSlot.captured.name).isEqualTo(user.email)
            assertThat(authSlot.captured.authorities).hasSize(1)
            assertThat(authSlot.captured.authorities.first().authority).isEqualTo("ROLE_PROFESSOR")
        }
    }

    @Nested
    @DisplayName("토큰 검증 및 갱신 테스트")
    inner class TokenVerifyAndRefreshTest {
        @Test
        fun `verifyToken - SecurityContext 인증 사용자 정보 반환`() {
            val user = TestDataFactory.createTestUser()
            val auth: Authentication = mockk {
                every { name } returns user.email
            }
            // 실제 SecurityContext 사용 (static mock 제거)
            val context = org.springframework.security.core.context.SecurityContextHolder.createEmptyContext()
            context.authentication = auth
            org.springframework.security.core.context.SecurityContextHolder.setContext(context)

            every { userService.findByEmail(user.email) } returns user
            every { userService.convertToUserResponse(user) } returns UserResponse(
                id = user.id,
                name = user.name,
                email = user.email,
                globalRole = user.globalRole.name,
                isActive = user.isActive,
                nickname = user.nickname,
                profileImageUrl = user.profileImageUrl,
                bio = user.bio,
                profileCompleted = user.profileCompleted,
                emailVerified = user.emailVerified,
                createdAt = user.createdAt,
                updatedAt = user.updatedAt,
            )

            val result = authService.verifyToken()
            assertThat(result.email).isEqualTo(user.email)

            org.springframework.security.core.context.SecurityContextHolder.clearContext()
        }

        @Test
        fun `refreshAccessToken - 유효한 리프레시 토큰으로 새 액세스 토큰 발급`() {
            val refreshToken = "refresh.jwt"
            val user = TestDataFactory.createTestUser()
            val authentication: Authentication = mockk {
                every { name } returns user.email
            }
            every { jwtTokenProvider.validateToken(refreshToken) } returns true
            every { jwtTokenProvider.getAuthentication(refreshToken) } returns authentication
            every { userService.findByEmail(user.email) } returns user
            every { jwtTokenProvider.generateAccessToken(authentication) } returns "new.access.jwt"

            val result = authService.refreshAccessToken(refreshToken)
            assertThat(result.accessToken).isEqualTo("new.access.jwt")
            assertThat(result.tokenType).isEqualTo("Bearer")
        }
    }
}
