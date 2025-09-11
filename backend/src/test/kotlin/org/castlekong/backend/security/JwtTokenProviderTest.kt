package org.castlekong.backend.security

import io.mockk.*
import org.assertj.core.api.Assertions.assertThat
import org.castlekong.backend.fixture.TestDataFactory
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.test.util.ReflectionTestUtils

@DisplayName("JWT Token Provider 테스트")
class JwtTokenProviderTest {
    private lateinit var jwtTokenProvider: JwtTokenProvider

    @BeforeEach
    fun setUp() {
        jwtTokenProvider = JwtTokenProvider()

        // ReflectionTestUtils를 사용하여 private 필드 설정
        ReflectionTestUtils.setField(jwtTokenProvider, "secretKey", TestDataFactory.TEST_JWT_SECRET)
        ReflectionTestUtils.setField(jwtTokenProvider, "accessTokenExpiration", TestDataFactory.TEST_ACCESS_TOKEN_EXPIRATION)
        ReflectionTestUtils.setField(jwtTokenProvider, "refreshTokenExpiration", TestDataFactory.TEST_REFRESH_TOKEN_EXPIRATION)

        // @PostConstruct 메서드 수동 호출
        ReflectionTestUtils.invokeMethod<Unit>(jwtTokenProvider, "init")
    }

    @Nested
    @DisplayName("Access Token 생성 테스트")
    inner class GenerateAccessTokenTest {
        @Test
        fun `should generate valid access token when valid authentication provided`() {
            // Given
            val authentication = TestDataFactory.createAuthentication()

            // When
            val token = jwtTokenProvider.generateAccessToken(authentication)

            // Then
            assertThat(token).isNotNull
            assertThat(token).isNotEmpty
            assertThat(token.split(".")).hasSize(3) // JWT는 3개 부분으로 구성
        }

        @Test
        fun `should generate different tokens for different users`() {
            // Given
            val userAuth = TestDataFactory.createAuthentication("user@example.com")
            val adminAuth = TestDataFactory.createAuthentication("admin@example.com")

            // When
            val userToken = jwtTokenProvider.generateAccessToken(userAuth)
            val adminToken = jwtTokenProvider.generateAccessToken(adminAuth)

            // Then
            assertThat(userToken).isNotEqualTo(adminToken)
        }
    }

    @Nested
    @DisplayName("Refresh Token 생성 테스트")
    inner class GenerateRefreshTokenTest {
        @Test
        fun `should generate valid refresh token when valid authentication provided`() {
            // Given
            val authentication = TestDataFactory.createAuthentication()

            // When
            val token = jwtTokenProvider.generateRefreshToken(authentication)

            // Then
            assertThat(token).isNotNull
            assertThat(token).isNotEmpty
            assertThat(token.split(".")).hasSize(3)
        }

        @Test
        fun `should generate different access and refresh tokens`() {
            // Given
            val authentication = TestDataFactory.createAuthentication()

            // When
            val accessToken = jwtTokenProvider.generateAccessToken(authentication)
            val refreshToken = jwtTokenProvider.generateRefreshToken(authentication)

            // Then
            assertThat(accessToken).isNotEqualTo(refreshToken)
        }
    }

    @Nested
    @DisplayName("토큰 검증 테스트")
    inner class ValidateTokenTest {
        @Test
        fun `should return true when valid token provided`() {
            // Given
            val authentication = TestDataFactory.createAuthentication()
            val token = jwtTokenProvider.generateAccessToken(authentication)

            // When
            val isValid = jwtTokenProvider.validateToken(token)

            // Then
            assertThat(isValid).isTrue
        }

        @Test
        fun `should return false when invalid token provided`() {
            // Given
            val invalidToken = "invalid.jwt.token"

            // When
            val isValid = jwtTokenProvider.validateToken(invalidToken)

            // Then
            assertThat(isValid).isFalse
        }

        @Test
        fun `should return false when empty token provided`() {
            // Given
            val emptyToken = ""

            // When
            val isValid = jwtTokenProvider.validateToken(emptyToken)

            // Then
            assertThat(isValid).isFalse
        }

        @Test
        fun `should return false when malformed token provided`() {
            // Given
            val malformedToken = "malformed-token-without-dots"

            // When
            val isValid = jwtTokenProvider.validateToken(malformedToken)

            // Then
            assertThat(isValid).isFalse
        }
    }

    @Nested
    @DisplayName("토큰에서 사용자명 추출 테스트")
    inner class GetUsernameFromTokenTest {
        @Test
        fun `should extract correct username from valid token`() {
            // Given
            val email = TestDataFactory.TEST_EMAIL
            val authentication = TestDataFactory.createAuthentication(email)
            val token = jwtTokenProvider.generateAccessToken(authentication)

            // When
            val extractedUsername = jwtTokenProvider.getUsernameFromToken(token)

            // Then
            assertThat(extractedUsername).isEqualTo(email)
        }
    }

    @Nested
    @DisplayName("토큰에서 Authentication 추출 테스트")
    inner class GetAuthenticationTest {
        @Test
        fun `should extract correct authentication from valid token`() {
            // Given
            val email = TestDataFactory.TEST_EMAIL
            val originalAuth = TestDataFactory.createAuthentication(email)
            val token = jwtTokenProvider.generateAccessToken(originalAuth)

            // When
            val extractedAuth = jwtTokenProvider.getAuthentication(token)

            // Then
            assertThat(extractedAuth.name).isEqualTo(email)
            assertThat(extractedAuth.authorities).hasSize(1)
            assertThat(extractedAuth.authorities.first().authority).isEqualTo("ROLE_STUDENT")
        }

        @Test
        fun `should extract correct admin authentication from token`() {
            // Given
            val adminEmail = "admin@example.com"
            val adminAuth =
                TestDataFactory.createAuthentication(
                    adminEmail,
                    org.castlekong.backend.entity.GlobalRole.ADMIN,
                )
            val token = jwtTokenProvider.generateAccessToken(adminAuth)

            // When
            val extractedAuth = jwtTokenProvider.getAuthentication(token)

            // Then
            assertThat(extractedAuth.name).isEqualTo(adminEmail)
            assertThat(extractedAuth.authorities.first().authority).isEqualTo("ROLE_ADMIN")
        }
    }
}
