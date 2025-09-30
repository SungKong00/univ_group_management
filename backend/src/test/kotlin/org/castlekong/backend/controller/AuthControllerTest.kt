package org.castlekong.backend.controller

import com.fasterxml.jackson.databind.ObjectMapper
import com.ninjasquad.springmockk.MockkBean
import io.mockk.every
import org.castlekong.backend.dto.LoginResponse
import org.castlekong.backend.dto.RefreshTokenResponse
import org.castlekong.backend.dto.UserResponse
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.fixture.TestDataFactory
import org.castlekong.backend.security.JwtTokenProvider
import org.castlekong.backend.service.AuthService
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post
import org.springframework.test.web.servlet.result.MockMvcResultHandlers.print
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.*
import java.time.LocalDateTime

@WebMvcTest(
    controllers = [AuthController::class],
    excludeAutoConfiguration = [
        org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration::class,
        org.springframework.boot.autoconfigure.security.servlet.UserDetailsServiceAutoConfiguration::class,
    ],
)
@DisplayName("AuthController 웹 계층 테스트")
class AuthControllerTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @MockkBean
    private lateinit var authService: AuthService

    @MockkBean
    private lateinit var jwtTokenProvider: JwtTokenProvider

    @Nested
    @DisplayName("POST /api/auth/google 테스트")
    inner class GoogleLoginTest {
        @Test
        fun `should return 200 and tokens when valid Google token provided`() {
            // Given
            val googleLoginRequest = TestDataFactory.createGoogleLoginRequest()
            val userResponse =
                UserResponse(
                    id = 1L,
                    name = "테스트 사용자",
                    email = "test@example.com",
                    globalRole = "STUDENT",
                    isActive = true,
                    nickname = null,
                    profileImageUrl = null,
                    bio = null,
                    profileCompleted = false,
                    emailVerified = false,
                    createdAt = LocalDateTime.now(),
                    updatedAt = LocalDateTime.now(),
                )
            val loginResponse =
                LoginResponse(
                    accessToken = "valid.access.token",
                    tokenType = "Bearer",
                    expiresIn = 86400000L,
                    user = userResponse,
                )

            every { authService.authenticateWithGoogle(any()) } returns loginResponse

            // When & Then
            mockMvc.perform(
                post("/api/auth/google")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(googleLoginRequest)),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").value("valid.access.token"))
                .andExpect(jsonPath("$.data.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.data.expiresIn").value(86400000))
                .andExpect(jsonPath("$.data.user.id").value(1))
                .andExpect(jsonPath("$.data.user.email").value("test@example.com"))
                .andExpect(jsonPath("$.data.user.globalRole").value("STUDENT"))
        }

        @Test
        fun `should return 401 when invalid Google token provided`() {
            // Given
            val invalidGoogleLoginRequest = TestDataFactory.createInvalidGoogleTokenRequest()

            every { authService.authenticateWithGoogle(any()) } throws BusinessException(ErrorCode.INVALID_TOKEN)

            // When & Then
            mockMvc.perform(
                post("/api/auth/google")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(invalidGoogleLoginRequest)),
            )
                .andDo(print())
                .andExpect(status().isUnauthorized)
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("INVALID_TOKEN"))
                .andExpect(jsonPath("$.error.message").value(ErrorCode.INVALID_TOKEN.message))
        }

        @Test
        fun `should return 200 when valid Google access token provided`() {
            // Given
            val googleLoginRequest =
                org.castlekong.backend.dto.GoogleLoginRequest(
                    googleAuthToken = null,
                    googleAccessToken = "valid.google.access.token",
                )
            val userResponse =
                UserResponse(
                    id = 2L,
                    name = "액세스 토큰 사용자",
                    email = "accesstoken@example.com",
                    globalRole = "PROFESSOR",
                    isActive = true,
                    nickname = "교수님",
                    profileImageUrl = "https://example.com/professor.jpg",
                    bio = "교수 소개",
                    profileCompleted = true,
                    emailVerified = true,
                    createdAt = LocalDateTime.now(),
                    updatedAt = LocalDateTime.now(),
                )
            val loginResponse =
                LoginResponse(
                    accessToken = "valid.access.token.from.accesstoken",
                    tokenType = "Bearer",
                    expiresIn = 86400000L,
                    user = userResponse,
                )

            every { authService.authenticateWithGoogleAccessToken(any()) } returns loginResponse

            // When & Then
            mockMvc.perform(
                post("/api/auth/google")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(googleLoginRequest)),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").value("valid.access.token.from.accesstoken"))
                .andExpect(jsonPath("$.data.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.data.expiresIn").value(86400000))
                .andExpect(jsonPath("$.data.user.id").value(2))
                .andExpect(jsonPath("$.data.user.email").value("accesstoken@example.com"))
                .andExpect(jsonPath("$.data.user.globalRole").value("PROFESSOR"))
                .andExpect(jsonPath("$.data.user.nickname").value("교수님"))
                .andExpect(jsonPath("$.data.user.profileCompleted").value(true))
        }

        @Test
        fun `should return 401 when invalid Google access token provided`() {
            // Given
            val invalidGoogleLoginRequest =
                org.castlekong.backend.dto.GoogleLoginRequest(
                    googleAuthToken = null,
                    googleAccessToken = "invalid.google.access.token",
                )

            every { authService.authenticateWithGoogleAccessToken(any()) } throws BusinessException(ErrorCode.INVALID_TOKEN)

            // When & Then
            mockMvc.perform(
                post("/api/auth/google")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(invalidGoogleLoginRequest)),
            )
                .andDo(print())
                .andExpect(status().isUnauthorized)
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("INVALID_TOKEN"))
                .andExpect(jsonPath("$.error.message").value(ErrorCode.INVALID_TOKEN.message))
        }

        @Test
        fun `should return 400 when empty Google token provided`() {
            // Given
            val invalidGoogleLoginRequest = TestDataFactory.createInvalidGoogleLoginRequest()

            // When & Then
            mockMvc.perform(
                post("/api/auth/google")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(invalidGoogleLoginRequest)),
            )
                .andDo(print())
                .andExpect(status().isBadRequest)
        }
    }

    @Nested
    @DisplayName("토큰 갱신 및 검증 테스트")
    inner class TokenRefreshAndVerifyTest {
        @Test
        fun `should return new access token when refresh token valid`() {
            val requestBody = mapOf("refreshToken" to "valid.refresh.token")
            every { authService.refreshAccessToken("valid.refresh.token") } returns RefreshTokenResponse(
                accessToken = "new.access.token",
                tokenType = "Bearer",
                expiresIn = 86400000L,
            )

            mockMvc.perform(
                post("/api/auth/refresh")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(requestBody))
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").value("new.access.token"))
        }

        @Test
        fun `should return 400 when refresh token missing`() {
            val requestBody = mapOf("otherKey" to "value")
            mockMvc.perform(
                post("/api/auth/refresh")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(requestBody))
            )
                .andDo(print())
                .andExpect(status().isBadRequest)
        }

        @Test
        fun `should return user info when access token valid for verify`() {
            val userResponse =
                UserResponse(
                    id = 10L,
                    name = "검증 사용자",
                    email = "verify@example.com",
                    globalRole = "STUDENT",
                    isActive = true,
                    nickname = "verifyUser",
                    profileImageUrl = null,
                    bio = null,
                    profileCompleted = true,
                    emailVerified = true,
                    createdAt = java.time.LocalDateTime.now(),
                    updatedAt = java.time.LocalDateTime.now(),
                )
            every { authService.verifyToken() } returns userResponse

            mockMvc.perform(
                post("/api/auth/verify") // verify는 GET이지만 간혹 클라이언트 실수 방지: POST 호출 시 405 기대 가능
            ).andExpect(status().isMethodNotAllowed)

            mockMvc.perform(
                org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get("/api/auth/verify")
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.email").value("verify@example.com"))
        }
    }
}
