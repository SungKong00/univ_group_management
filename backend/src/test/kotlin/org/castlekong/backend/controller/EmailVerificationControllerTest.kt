package org.castlekong.backend.controller

import com.fasterxml.jackson.databind.ObjectMapper
import com.ninjasquad.springmockk.MockkBean
import io.mockk.every
import io.mockk.just
import io.mockk.runs
import org.castlekong.backend.dto.EmailSendRequest
import org.castlekong.backend.dto.EmailVerifyRequest
import org.castlekong.backend.security.JwtTokenProvider
import org.castlekong.backend.service.EmailVerificationService
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.http.MediaType
import org.springframework.security.test.context.support.WithMockUser
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.content
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status

@WebMvcTest(controllers = [EmailVerificationController::class])
class EmailVerificationControllerTest {
    @Autowired lateinit var mockMvc: MockMvc

    @Autowired lateinit var objectMapper: ObjectMapper

    @MockkBean lateinit var emailVerificationService: EmailVerificationService

    @MockkBean lateinit var jwtTokenProvider: JwtTokenProvider

    @Test
    @WithMockUser(username = "user@example.com")
    fun sendCode_success() {
        every { emailVerificationService.sendCode(any(), any()) } just runs
        val req = EmailSendRequest(email = "student@hs.ac.kr")

        mockMvc.perform(
            post("/api/email/verification/send")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)),
        )
            .andExpect(status().isOk)
            .andExpect(content().contentType(MediaType.APPLICATION_JSON))
    }

    @Test
    @WithMockUser(username = "user@example.com")
    fun verifyCode_success() {
        every { emailVerificationService.verifyCode(any(), any()) } just runs
        val req = EmailVerifyRequest(email = "student@hs.ac.kr", code = "123456")

        mockMvc.perform(
            post("/api/email/verification/verify")
                .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)),
        )
            .andExpect(status().isOk)
            .andExpect(content().contentType(MediaType.APPLICATION_JSON))
    }
}
