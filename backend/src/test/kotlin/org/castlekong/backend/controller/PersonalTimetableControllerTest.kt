package org.castlekong.backend.controller

import com.fasterxml.jackson.databind.ObjectMapper
import org.castlekong.backend.dto.CreatePersonalScheduleRequest
import org.castlekong.backend.dto.UpdatePersonalScheduleRequest
import org.castlekong.backend.entity.PersonalSchedule
import org.castlekong.backend.entity.User
import org.castlekong.backend.fixture.TestDataFactory
import org.castlekong.backend.repository.PersonalScheduleRepository
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
import java.time.DayOfWeek
import java.time.LocalTime

@SpringBootTest
@AutoConfigureMockMvc
class PersonalTimetableControllerTest {
    @Autowired
    lateinit var mockMvc: MockMvc

    @Autowired
    lateinit var objectMapper: ObjectMapper

    @Autowired
    lateinit var userRepository: UserRepository

    @Autowired
    lateinit var personalScheduleRepository: PersonalScheduleRepository

    @Autowired
    lateinit var jwtTokenProvider: JwtTokenProvider

    private lateinit var owner: User
    private lateinit var anotherUser: User
    private lateinit var ownerToken: String
    private lateinit var anotherToken: String

    @BeforeEach
    fun setUp() {
        personalScheduleRepository.deleteAll()
        owner =
            userRepository.save(
                User(
                    name = "Owner",
                    email = TestDataFactory.uniqueEmail("timetable-owner"),
                    password = "password",
                    profileCompleted = true,
                ),
            )
        anotherUser =
            userRepository.save(
                User(
                    name = "Another",
                    email = TestDataFactory.uniqueEmail("timetable-another"),
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
    fun `should list schedules ordered by day and time`() {
        personalScheduleRepository.save(
            PersonalSchedule(
                user = owner,
                title = "오후 알바",
                dayOfWeek = DayOfWeek.FRIDAY,
                startTime = LocalTime.of(15, 0),
                endTime = LocalTime.of(18, 0),
                color = "#EF4444",
            ),
        )
        personalScheduleRepository.save(
            PersonalSchedule(
                user = owner,
                title = "오전 수업",
                dayOfWeek = DayOfWeek.MONDAY,
                startTime = LocalTime.of(9, 0),
                endTime = LocalTime.of(11, 0),
                color = "#3B82F6",
            ),
        )

        mockMvc
            .perform(
                get("/api/timetable")
                    .header("Authorization", "Bearer $ownerToken"),
            )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.data.length()").value(2))
            .andExpect(jsonPath("$.data[0].dayOfWeek").value("MONDAY"))
            .andExpect(jsonPath("$.data[0].title").value("오전 수업"))
            .andExpect(jsonPath("$.data[1].dayOfWeek").value("FRIDAY"))
    }

    @Test
    fun `should create personal schedule`() {
        val request =
            CreatePersonalScheduleRequest(
                title = "자료구조",
                dayOfWeek = DayOfWeek.TUESDAY,
                startTime = LocalTime.of(10, 0),
                endTime = LocalTime.of(12, 0),
                location = "공학관 301",
                color = "#3B82F6",
            )

        mockMvc
            .perform(
                post("/api/timetable")
                    .header("Authorization", "Bearer $ownerToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
            .andExpect(status().isCreated)
            .andExpect(jsonPath("$.data.title").value("자료구조"))
            .andExpect(jsonPath("$.data.dayOfWeek").value("TUESDAY"))

        val schedules = personalScheduleRepository.findAll()
        assertEquals(1, schedules.size)
        assertEquals(owner.id, schedules.first().user.id)
    }

    @Test
    fun `should forbid update by another user`() {
        val schedule =
            personalScheduleRepository.save(
                PersonalSchedule(
                    user = owner,
                    title = "운동",
                    dayOfWeek = DayOfWeek.WEDNESDAY,
                    startTime = LocalTime.of(7, 0),
                    endTime = LocalTime.of(8, 0),
                    color = "#10B981",
                ),
            )

        val updateRequest =
            UpdatePersonalScheduleRequest(
                title = "운동 연기",
                dayOfWeek = DayOfWeek.WEDNESDAY,
                startTime = LocalTime.of(8, 0),
                endTime = LocalTime.of(9, 0),
                location = null,
                color = "#10B981",
            )

        mockMvc
            .perform(
                put("/api/timetable/{id}", schedule.id)
                    .header("Authorization", "Bearer $anotherToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(updateRequest)),
            )
            .andExpect(status().isForbidden)
    }

    @Test
    fun `should delete schedule`() {
        val schedule =
            personalScheduleRepository.save(
                PersonalSchedule(
                    user = owner,
                    title = "삭제 수업",
                    dayOfWeek = DayOfWeek.THURSDAY,
                    startTime = LocalTime.of(13, 0),
                    endTime = LocalTime.of(14, 0),
                    color = "#8B5CF6",
                ),
            )

        mockMvc
            .perform(
                delete("/api/timetable/{id}", schedule.id)
                    .header("Authorization", "Bearer $ownerToken"),
            )
            .andExpect(status().isNoContent)

        assertEquals(0, personalScheduleRepository.count())
    }

    @Test
    fun `should reject invalid time`() {
        val request =
            CreatePersonalScheduleRequest(
                title = "잘못된 시간",
                dayOfWeek = DayOfWeek.MONDAY,
                startTime = LocalTime.of(15, 0),
                endTime = LocalTime.of(14, 0),
                location = null,
                color = "#3B82F6",
            )

        mockMvc
            .perform(
                post("/api/timetable")
                    .header("Authorization", "Bearer $ownerToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
            .andExpect(status().isBadRequest)
    }
}
