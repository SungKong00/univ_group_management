package org.castlekong.backend.controller

import com.fasterxml.jackson.databind.ObjectMapper
import com.ninjasquad.springmockk.MockkBean
import io.mockk.every
import org.castlekong.backend.dto.UserResponse
import org.castlekong.backend.security.JwtTokenProvider
import org.castlekong.backend.service.UserService
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.http.MediaType
import org.springframework.security.test.context.support.WithMockUser
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.content
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status
import java.time.LocalDateTime

@WebMvcTest(controllers = [MeController::class])
class MeControllerTest {
    @Autowired lateinit var mockMvc: MockMvc

    @Autowired lateinit var objectMapper: ObjectMapper

    @MockkBean lateinit var userService: UserService

    @MockkBean lateinit var jwtTokenProvider: JwtTokenProvider

    @Test
    @WithMockUser(username = "user@example.com")
    fun getMe_success() {
        val now = LocalDateTime.now()
        val user =
            org.castlekong.backend.entity.User(
                name = "User",
                email = "user@example.com",
                password = "",
            )
        every { userService.findByEmail("user@example.com") } returns user
        every { userService.convertToUserResponse(user) } returns
            UserResponse(
                id = 1L, name = "User", email = "user@example.com", globalRole = "STUDENT",
                isActive = true, nickname = null, profileImageUrl = null, bio = null,
                profileCompleted = false, emailVerified = false,
                createdAt = now, updatedAt = now,
            )

        mockMvc.perform(get("/api/me").accept(MediaType.APPLICATION_JSON))
            .andExpect(status().isOk)
            .andExpect(content().contentType(MediaType.APPLICATION_JSON))
    }
}
