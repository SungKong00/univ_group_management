package org.castlekong.backend.controller

import com.fasterxml.jackson.databind.ObjectMapper
import org.castlekong.backend.dto.CreatePersonalEventRequest
import org.castlekong.backend.dto.UpdatePersonalEventRequest
import org.castlekong.backend.entity.PersonalEvent
import org.castlekong.backend.entity.User
import org.castlekong.backend.fixture.TestDataFactory
import org.castlekong.backend.repository.PersonalEventRepository
import org.castlekong.backend.repository.UserRepository
import org.castlekong.backend.security.JwtTokenProvider
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status
import java.time.LocalDate
import java.time.LocalDateTime

@SpringBootTest
@AutoConfigureMockMvc
class PersonalCalendarControllerTest {
    @Autowired
    lateinit var mockMvc: MockMvc

    @Autowired
    lateinit var objectMapper: ObjectMapper

    @Autowired
    lateinit var userRepository: UserRepository

    @Autowired
    lateinit var personalEventRepository: PersonalEventRepository

    @Autowired
    lateinit var jwtTokenProvider: JwtTokenProvider

    private lateinit var owner: User
    private lateinit var anotherUser: User
    private lateinit var ownerToken: String
    private lateinit var anotherToken: String

    @BeforeEach
    fun setUp() {
        personalEventRepository.deleteAll()
        owner =
            userRepository.save(
                User(
                    name = "Calendar Owner",
                    email = TestDataFactory.uniqueEmail("calendar-owner"),
                    password = "password",
                    profileCompleted = true,
                ),
            )
        anotherUser =
            userRepository.save(
                User(
                    name = "Another User",
                    email = TestDataFactory.uniqueEmail("calendar-another"),
                    password = "password",
                    profileCompleted = true,
                ),
            )
        ownerToken = generateToken(owner)
        anotherToken = generateToken(anotherUser)
    }

    private fun generateToken(user: User): String {
        val authentication =
            org.springframework.security.authentication.UsernamePasswordAuthenticationToken(
                user.email,
                null,
                listOf(org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_${user.globalRole.name}")),
            )
        return jwtTokenProvider.generateAccessToken(authentication)
    }

    @Test
    fun `should create personal event`() {
        val request =
            CreatePersonalEventRequest(
                title = "스터디",
                description = "알고리즘 스터디",
                location = "도서관",
                startDateTime = LocalDateTime.of(2025, 10, 20, 18, 0),
                endDateTime = LocalDateTime.of(2025, 10, 20, 20, 0),
                isAllDay = false,
                color = "#3B82F6",
            )

        mockMvc
            .perform(
                post("/api/calendar")
                    .header("Authorization", "Bearer $ownerToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
            .andExpect(status().isCreated)
            .andExpect(jsonPath("$.data.title").value("스터디"))
            .andExpect(jsonPath("$.data.location").value("도서관"))

        val events = personalEventRepository.findAll()
        assertEquals(1, events.size)
        assertEquals(owner.id, events.first().user.id)
    }

    @Test
    fun `should return events within requested range`() {
        val insideEvent =
            personalEventRepository.save(
                PersonalEvent(
                    user = owner,
                    title = "중간고사",
                    startDateTime = LocalDateTime.of(2025, 10, 10, 9, 0),
                    endDateTime = LocalDateTime.of(2025, 10, 10, 11, 0),
                    color = "#EF4444",
                ),
            )
        // Event outside range should be excluded
        personalEventRepository.save(
            PersonalEvent(
                user = owner,
                title = "방학 여행",
                startDateTime = LocalDateTime.of(2025, 12, 1, 9, 0),
                endDateTime = LocalDateTime.of(2025, 12, 5, 18, 0),
                color = "#10B981",
            ),
        )

        mockMvc
            .perform(
                get("/api/calendar")
                    .header("Authorization", "Bearer $ownerToken")
                    .param("start", LocalDate.of(2025, 10, 1).toString())
                    .param("end", LocalDate.of(2025, 10, 31).toString()),
            )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.data.length()").value(1))
            .andExpect(jsonPath("$.data[0].id").value(insideEvent.id))
    }

    @Test
    fun `should prevent updating event owned by another user`() {
        val event =
            personalEventRepository.save(
                PersonalEvent(
                    user = owner,
                    title = "모임",
                    startDateTime = LocalDateTime.of(2025, 8, 1, 14, 0),
                    endDateTime = LocalDateTime.of(2025, 8, 1, 16, 0),
                    color = "#8B5CF6",
                ),
            )

        val updateRequest =
            UpdatePersonalEventRequest(
                title = "모임 변경",
                description = null,
                location = null,
                startDateTime = LocalDateTime.of(2025, 8, 1, 15, 0),
                endDateTime = LocalDateTime.of(2025, 8, 1, 17, 0),
                isAllDay = false,
                color = "#8B5CF6",
            )

        mockMvc
            .perform(
                put("/api/calendar/{id}", event.id)
                    .header("Authorization", "Bearer $anotherToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(updateRequest)),
            )
            .andExpect(status().isForbidden)
    }

    @Test
    fun `should delete personal event`() {
        val event =
            personalEventRepository.save(
                PersonalEvent(
                    user = owner,
                    title = "삭제 대상",
                    startDateTime = LocalDateTime.of(2025, 7, 15, 10, 0),
                    endDateTime = LocalDateTime.of(2025, 7, 15, 11, 0),
                    color = "#3B82F6",
                ),
            )

        mockMvc
            .perform(
                delete("/api/calendar/{id}", event.id)
                    .header("Authorization", "Bearer $ownerToken"),
            )
            .andExpect(status().isNoContent)

        assertEquals(0, personalEventRepository.count())
    }
}
