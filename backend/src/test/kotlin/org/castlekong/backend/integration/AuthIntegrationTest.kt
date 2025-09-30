package org.castlekong.backend.integration

import com.fasterxml.jackson.databind.ObjectMapper
import org.castlekong.backend.fixture.TestDataFactory
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.http.MediaType
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post
import org.springframework.test.web.servlet.result.MockMvcResultHandlers.print
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.*

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DisplayName("인증 API 통합 테스트")
class AuthIntegrationTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @Nested
    @DisplayName("Google OAuth2 통합 테스트")
    inner class GoogleOAuthIntegrationTest {
        @Test
        fun `should return 401 when invalid Google token provided`() {
            // Given
            val invalidGoogleLoginRequest = TestDataFactory.createInvalidGoogleTokenRequest()

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
        }

        @Test
        fun `should return 400 when empty Google token provided`() {
            // Given
            val invalidRequest = TestDataFactory.createInvalidGoogleLoginRequest()

            // When & Then
            mockMvc.perform(
                post("/api/auth/google")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(invalidRequest)),
            )
                .andDo(print())
                .andExpect(status().isBadRequest)
        }

        @Test
        fun `should return 403 for non-existent endpoints`() {
            // Given
            val request = TestDataFactory.createGoogleLoginRequest()

            // When & Then - Test removed login endpoint (returns 403 due to security)
            mockMvc.perform(
                post("/api/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isForbidden)

            // When & Then - Test removed register endpoint (returns 403 due to security)
            mockMvc.perform(
                post("/api/auth/register")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isForbidden)
        }
    }
}
