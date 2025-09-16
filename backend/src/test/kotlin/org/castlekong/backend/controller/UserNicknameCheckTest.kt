package org.castlekong.backend.controller

import com.fasterxml.jackson.databind.ObjectMapper
import com.ninjasquad.springmockk.MockkBean
import io.mockk.every
import org.castlekong.backend.security.JwtTokenProvider
import org.castlekong.backend.service.UserService
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.http.MediaType
import org.springframework.security.test.context.support.WithMockUser
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status

@WebMvcTest(controllers = [UserController::class])
@org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc(addFilters = false)
class UserNicknameCheckTest {
    @Autowired lateinit var mockMvc: MockMvc

    @Autowired lateinit var objectMapper: ObjectMapper

    @MockkBean lateinit var userService: UserService

    @MockkBean lateinit var emailVerificationService: org.castlekong.backend.service.EmailVerificationService

    @MockkBean lateinit var jwtTokenProvider: JwtTokenProvider

    @Test
    @WithMockUser
    fun nickname_available() {
        every { userService.nicknameExists("newNick") } returns false

        mockMvc.perform(
            get("/api/users/nickname-check").param("nickname", "newNick")
                .accept(MediaType.APPLICATION_JSON),
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.data.available").value(true))
    }
}
