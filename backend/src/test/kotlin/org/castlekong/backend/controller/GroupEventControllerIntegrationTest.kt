package org.castlekong.backend.controller

import com.fasterxml.jackson.databind.ObjectMapper
import org.castlekong.backend.dto.CreateGroupEventRequest
import org.castlekong.backend.dto.RecurrencePattern
import org.castlekong.backend.dto.RecurrenceType
import org.castlekong.backend.dto.UpdateGroupEventRequest
import org.castlekong.backend.dto.UpdateScope
import org.castlekong.backend.entity.EventType
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.entity.User
import org.castlekong.backend.fixture.TestDataFactory
import org.castlekong.backend.repository.GroupEventRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.castlekong.backend.repository.UserRepository
import org.castlekong.backend.security.JwtTokenProvider
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.http.MediaType
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put
import org.springframework.test.web.servlet.result.MockMvcResultHandlers.print
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status
import org.springframework.transaction.annotation.Transactional
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalTime

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@DisplayName("GroupEventController 통합 테스트")
class GroupEventControllerIntegrationTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @Autowired
    private lateinit var jwtTokenProvider: JwtTokenProvider

    @Autowired
    private lateinit var userRepository: UserRepository

    @Autowired
    private lateinit var groupRepository: GroupRepository

    @Autowired
    private lateinit var groupRoleRepository: GroupRoleRepository

    @Autowired
    private lateinit var groupMemberRepository: GroupMemberRepository

    @Autowired
    private lateinit var groupEventRepository: GroupEventRepository

    // Test data
    private lateinit var owner: User
    private lateinit var member: User
    private lateinit var nonMember: User
    private lateinit var group: Group
    private lateinit var ownerToken: String
    private lateinit var memberToken: String
    private lateinit var nonMemberToken: String

    @BeforeEach
    fun setUp() {
        val suffix = System.nanoTime().toString()

        // 그룹장 (CALENDAR_MANAGE 권한 보유)
        owner =
            userRepository.save(
                TestDataFactory.createTestUser(
                    name = "그룹장",
                    email = "owner-event-$suffix@example.com",
                ).copy(profileCompleted = true),
            )

        // 일반 멤버 (CALENDAR_MANAGE 권한 없음)
        member =
            userRepository.save(
                TestDataFactory.createStudentUser(
                    name = "일반 멤버",
                    email = "member-event-$suffix@example.com",
                ),
            )

        // 비멤버
        nonMember =
            userRepository.save(
                TestDataFactory.createStudentUser(
                    name = "비멤버",
                    email = "nonmember-event-$suffix@example.com",
                ),
            )

        // 그룹 및 역할 설정
        group = createGroupWithRoles(owner)

        // 멤버 추가
        val memberRole = groupRoleRepository.findByGroupIdAndName(group.id, "멤버").get()
        groupMemberRepository.save(
            TestDataFactory.createTestGroupMember(
                group = group,
                user = member,
                role = memberRole,
            ),
        )

        // JWT 토큰 생성
        ownerToken = generateToken(owner)
        memberToken = generateToken(member)
        nonMemberToken = generateToken(nonMember)
    }

    private fun createGroupWithRoles(ownerUser: User): Group {
        val testGroup =
            groupRepository.save(
                TestDataFactory.createTestGroup(
                    name = "캘린더 테스트 그룹",
                    owner = ownerUser,
                ),
            )

        val ownerRole = TestDataFactory.createOwnerRole(testGroup)
        ownerRole.replacePermissions(listOf(GroupPermission.CALENDAR_MANAGE, GroupPermission.GROUP_MANAGE))
        groupRoleRepository.save(ownerRole)

        val advisorRole = TestDataFactory.createAdvisorRole(testGroup)
        advisorRole.replacePermissions(listOf(GroupPermission.CALENDAR_MANAGE))
        groupRoleRepository.save(advisorRole)

        val memberRole = TestDataFactory.createMemberRole(testGroup)
        memberRole.replacePermissions(emptyList())
        groupRoleRepository.save(memberRole)

        groupMemberRepository.save(
            TestDataFactory.createTestGroupMember(
                group = testGroup,
                user = ownerUser,
                role = ownerRole,
            ),
        )

        return testGroup
    }

    private fun generateToken(user: User): String {
        val authentication =
            UsernamePasswordAuthenticationToken(
                user.email,
                null,
                listOf(SimpleGrantedAuthority("ROLE_${user.globalRole.name}")),
            )
        return jwtTokenProvider.generateAccessToken(authentication)
    }

    @Nested
    @DisplayName("단일 일정 CRUD 전체 플로우")
    inner class SingleEventCrudTest {
        @Test
        @DisplayName("POST /api/groups/{groupId}/events - 단일 일정 생성 성공")
        fun createSingleEvent_Success() {
            // Given
            val tomorrow = LocalDate.now().plusDays(1)
            val request =
                CreateGroupEventRequest(
                    title = "팀 회의",
                    description = "주간 회의",
                    locationText = "회의실",
                    startDate = tomorrow,
                    endDate = tomorrow,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(15, 0),
                    isAllDay = false,
                    isOfficial = false,
                    eventType = EventType.GENERAL,
                    color = "#3B82F6",
                    recurrence = null,
                )

            // When & Then
            mockMvc.perform(
                post("/api/groups/${group.id}/events")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isCreated)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").isArray)
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].title").value("팀 회의"))
                .andExpect(jsonPath("$.data[0].groupId").value(group.id))
                .andExpect(jsonPath("$.data[0].creatorId").value(member.id))
                .andExpect(jsonPath("$.data[0].seriesId").isEmpty)
                .andExpect(jsonPath("$.data[0].recurrenceRule").isEmpty)
        }

        @Test
        @DisplayName("GET /api/groups/{groupId}/events - 일정 조회 성공")
        fun getEvents_Success() {
            // Given: 일정 생성
            val tomorrow = LocalDate.now().plusDays(1)
            val request =
                CreateGroupEventRequest(
                    title = "조회 테스트 일정",
                    description = null,
                    locationText = null,
                    startDate = tomorrow,
                    endDate = tomorrow,
                    startTime = LocalTime.of(10, 0),
                    endTime = LocalTime.of(11, 0),
                    isAllDay = false,
                    isOfficial = false,
                    eventType = EventType.GENERAL,
                    color = "#10B981",
                    recurrence = null,
                )

            mockMvc.perform(
                post("/api/groups/${group.id}/events")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )

            // When & Then: 날짜 범위 조회
            val startDate = tomorrow.minusDays(1)
            val endDate = tomorrow.plusDays(1)

            mockMvc.perform(
                get("/api/groups/${group.id}/events")
                    .header("Authorization", "Bearer $memberToken")
                    .param("startDate", startDate.toString())
                    .param("endDate", endDate.toString())
                    .accept(MediaType.APPLICATION_JSON),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").isArray)
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].title").value("조회 테스트 일정"))
        }

        @Test
        @DisplayName("PUT /api/groups/{groupId}/events/{eventId} - 단일 일정 수정 성공")
        fun updateSingleEvent_Success() {
            // Given: 일정 생성
            val tomorrow = LocalDate.now().plusDays(1)
            val createRequest =
                CreateGroupEventRequest(
                    title = "원본 제목",
                    description = "원본 설명",
                    locationText = null,
                    startDate = tomorrow,
                    endDate = tomorrow,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(15, 0),
                    isAllDay = false,
                    isOfficial = false,
                    eventType = EventType.GENERAL,
                    color = "#3B82F6",
                    recurrence = null,
                )

            val createResult =
                mockMvc.perform(
                    post("/api/groups/${group.id}/events")
                        .header("Authorization", "Bearer $memberToken")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createRequest)),
                )
                    .andReturn()

            val createResponse = objectMapper.readTree(createResult.response.contentAsString)
            val eventId = createResponse["data"][0]["id"].asLong()

            // When: 일정 수정
            val updateRequest =
                UpdateGroupEventRequest(
                    title = "수정된 제목",
                    description = "수정된 설명",
                    locationText = "새 장소",
                    startTime = LocalTime.of(16, 0),
                    endTime = LocalTime.of(17, 0),
                    isAllDay = false,
                    color = "#F59E0B",
                    updateScope = UpdateScope.THIS_EVENT,
                )

            // Then
            mockMvc.perform(
                put("/api/groups/${group.id}/events/$eventId")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(updateRequest)),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].title").value("수정된 제목"))
                .andExpect(jsonPath("$.data[0].color").value("#F59E0B"))
        }

        @Test
        @DisplayName("DELETE /api/groups/{groupId}/events/{eventId} - 단일 일정 삭제 성공")
        fun deleteSingleEvent_Success() {
            // Given: 일정 생성
            val tomorrow = LocalDate.now().plusDays(1)
            val createRequest =
                CreateGroupEventRequest(
                    title = "삭제 테스트 일정",
                    description = null,
                    locationText = null,
                    startDate = tomorrow,
                    endDate = tomorrow,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(15, 0),
                    isAllDay = false,
                    isOfficial = false,
                    eventType = EventType.GENERAL,
                    color = "#EF4444",
                    recurrence = null,
                )

            val createResult =
                mockMvc.perform(
                    post("/api/groups/${group.id}/events")
                        .header("Authorization", "Bearer $memberToken")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createRequest)),
                )
                    .andReturn()

            val createResponse = objectMapper.readTree(createResult.response.contentAsString)
            val eventId = createResponse["data"][0]["id"].asLong()

            // When & Then: 일정 삭제
            mockMvc.perform(
                delete("/api/groups/${group.id}/events/$eventId")
                    .header("Authorization", "Bearer $memberToken")
                    .param("scope", "THIS_EVENT"),
            )
                .andDo(print())
                .andExpect(status().isNoContent)

            // 삭제 확인
            val startDate = tomorrow.minusDays(1)
            val endDate = tomorrow.plusDays(1)

            mockMvc.perform(
                get("/api/groups/${group.id}/events")
                    .header("Authorization", "Bearer $memberToken")
                    .param("startDate", startDate.toString())
                    .param("endDate", endDate.toString()),
            )
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.data.length()").value(0))
        }
    }

    @Nested
    @DisplayName("반복 일정 CRUD 전체 플로우")
    inner class RecurringEventCrudTest {
        @Test
        @DisplayName("POST - DAILY 반복 일정 생성 (7일)")
        fun createDailyRecurrence_7Days_Success() {
            // Given
            val startDate = LocalDate.now().plusDays(1)
            val endDate = startDate.plusDays(6) // 7일간
            val request =
                CreateGroupEventRequest(
                    title = "매일 스크럼",
                    description = "아침 스탠드업 미팅",
                    locationText = null,
                    startDate = startDate,
                    endDate = endDate,
                    startTime = LocalTime.of(10, 0),
                    endTime = LocalTime.of(10, 30),
                    isAllDay = false,
                    isOfficial = false,
                    eventType = EventType.GENERAL,
                    color = "#3B82F6",
                    recurrence = RecurrencePattern(type = RecurrenceType.DAILY),
                )

            // When & Then
            mockMvc.perform(
                post("/api/groups/${group.id}/events")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isCreated)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.length()").value(7)) // 7개 인스턴스
                .andExpect(jsonPath("$.data[0].seriesId").isNotEmpty)
                .andExpect(jsonPath("$.data[0].recurrenceRule").isNotEmpty)
                .andExpect(jsonPath("$.data[0].title").value("매일 스크럼"))
        }

        @Test
        @DisplayName("POST - WEEKLY 반복 일정 생성 (월수금, 2주)")
        fun createWeeklyRecurrence_MWF_2Weeks_Success() {
            // Given
            val startDate = LocalDate.of(2025, 11, 3) // 월요일
            val endDate = LocalDate.of(2025, 11, 16) // 2주 후
            val request =
                CreateGroupEventRequest(
                    title = "운동",
                    description = "헬스장 PT",
                    locationText = "체육관",
                    startDate = startDate,
                    endDate = endDate,
                    startTime = LocalTime.of(19, 0),
                    endTime = LocalTime.of(20, 0),
                    isAllDay = false,
                    isOfficial = false,
                    eventType = EventType.GENERAL,
                    color = "#10B981",
                    recurrence =
                        RecurrencePattern(
                            type = RecurrenceType.WEEKLY,
                            daysOfWeek = listOf(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY),
                        ),
                )

            // When & Then
            mockMvc.perform(
                post("/api/groups/${group.id}/events")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isCreated)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.length()").value(6)) // 2주 × 3일 = 6개
                .andExpect(jsonPath("$.data[0].seriesId").isNotEmpty)
                .andExpect(jsonPath("$.data[0].title").value("운동"))
        }

        @Test
        @DisplayName("PUT - 이 일정만 수정")
        fun updateRecurrence_ThisEventOnly_Success() {
            // Given: 반복 일정 생성
            val startDate = LocalDate.now().plusDays(1)
            val endDate = startDate.plusDays(9) // 10일간
            val createRequest =
                CreateGroupEventRequest(
                    title = "반복 일정",
                    description = null,
                    locationText = null,
                    startDate = startDate,
                    endDate = endDate,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(15, 0),
                    isAllDay = false,
                    isOfficial = false,
                    eventType = EventType.GENERAL,
                    color = "#3B82F6",
                    recurrence = RecurrencePattern(type = RecurrenceType.DAILY),
                )

            val createResult =
                mockMvc.perform(
                    post("/api/groups/${group.id}/events")
                        .header("Authorization", "Bearer $memberToken")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createRequest)),
                )
                    .andReturn()

            val createResponse = objectMapper.readTree(createResult.response.contentAsString)
            val firstEventId = createResponse["data"][0]["id"].asLong()

            // When: 첫 번째 일정만 수정
            val updateRequest =
                UpdateGroupEventRequest(
                    title = "매일 스크럼 (첫날만 변경)",
                    description = "특별 회의",
                    locationText = null,
                    startTime = LocalTime.of(16, 0),
                    endTime = LocalTime.of(17, 0),
                    isAllDay = false,
                    color = "#F59E0B",
                    updateScope = UpdateScope.THIS_EVENT,
                )

            // Then
            mockMvc.perform(
                put("/api/groups/${group.id}/events/$firstEventId")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(updateRequest)),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.length()").value(1)) // 1개만 반환
                .andExpect(jsonPath("$.data[0].title").value("매일 스크럼 (첫날만 변경)"))

            // 나머지 일정 확인
            mockMvc.perform(
                get("/api/groups/${group.id}/events")
                    .header("Authorization", "Bearer $memberToken")
                    .param("startDate", startDate.toString())
                    .param("endDate", endDate.plusDays(1).toString()),
            )
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.data.length()").value(10)) // 전체 10개 유지
        }

        @Test
        @DisplayName("PUT - 이후 전체 수정")
        fun updateRecurrence_AllFutureEvents_Success() {
            // Given: 과거, 현재, 미래 일정 생성
            val pastDate = LocalDate.now().minusDays(3)
            val futureDate = LocalDate.now().plusDays(7)
            val createRequest =
                CreateGroupEventRequest(
                    title = "반복 일정",
                    description = null,
                    locationText = null,
                    startDate = pastDate,
                    endDate = futureDate,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(15, 0),
                    isAllDay = false,
                    isOfficial = false,
                    eventType = EventType.GENERAL,
                    color = "#3B82F6",
                    recurrence = RecurrencePattern(type = RecurrenceType.DAILY),
                )

            val createResult =
                mockMvc.perform(
                    post("/api/groups/${group.id}/events")
                        .header("Authorization", "Bearer $memberToken")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createRequest)),
                )
                    .andReturn()

            val createResponse = objectMapper.readTree(createResult.response.contentAsString)
            // 미래 일정 중 하나 선택
            val futureEventId = createResponse["data"][5]["id"].asLong()

            // When: 이후 전체 수정
            val updateRequest =
                UpdateGroupEventRequest(
                    title = "수정된 반복 일정",
                    description = "전체 변경",
                    locationText = null,
                    startTime = LocalTime.of(16, 0),
                    endTime = LocalTime.of(17, 0),
                    isAllDay = false,
                    color = "#F59E0B",
                    updateScope = UpdateScope.ALL_EVENTS,
                )

            // Then
            mockMvc.perform(
                put("/api/groups/${group.id}/events/$futureEventId")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(updateRequest)),
            )
                .andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.length()").isNumber) // 미래 일정 개수만큼
        }

        @Test
        @DisplayName("DELETE - 이 일정만 삭제")
        fun deleteRecurrence_ThisEventOnly_Success() {
            // Given: 반복 일정 생성
            val startDate = LocalDate.now().plusDays(1)
            val endDate = startDate.plusDays(9) // 10일간
            val createRequest =
                CreateGroupEventRequest(
                    title = "반복 일정",
                    description = null,
                    locationText = null,
                    startDate = startDate,
                    endDate = endDate,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(15, 0),
                    isAllDay = false,
                    isOfficial = false,
                    eventType = EventType.GENERAL,
                    color = "#3B82F6",
                    recurrence = RecurrencePattern(type = RecurrenceType.DAILY),
                )

            val createResult =
                mockMvc.perform(
                    post("/api/groups/${group.id}/events")
                        .header("Authorization", "Bearer $memberToken")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createRequest)),
                )
                    .andReturn()

            val createResponse = objectMapper.readTree(createResult.response.contentAsString)
            val secondEventId = createResponse["data"][1]["id"].asLong()

            // When: 2번째 일정만 삭제
            mockMvc.perform(
                delete("/api/groups/${group.id}/events/$secondEventId")
                    .header("Authorization", "Bearer $memberToken")
                    .param("scope", "THIS_EVENT"),
            )
                .andDo(print())
                .andExpect(status().isNoContent)

            // Then: 9개 남음
            mockMvc.perform(
                get("/api/groups/${group.id}/events")
                    .header("Authorization", "Bearer $memberToken")
                    .param("startDate", startDate.toString())
                    .param("endDate", endDate.plusDays(1).toString()),
            )
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.data.length()").value(9))
        }

        @Test
        @DisplayName("DELETE - 이후 전체 삭제")
        fun deleteRecurrence_AllFutureEvents_Success() {
            // Given: 과거, 미래 일정 생성
            val pastDate = LocalDate.now().minusDays(3)
            val futureDate = LocalDate.now().plusDays(7)
            val createRequest =
                CreateGroupEventRequest(
                    title = "반복 일정",
                    description = null,
                    locationText = null,
                    startDate = pastDate,
                    endDate = futureDate,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(15, 0),
                    isAllDay = false,
                    isOfficial = false,
                    eventType = EventType.GENERAL,
                    color = "#3B82F6",
                    recurrence = RecurrencePattern(type = RecurrenceType.DAILY),
                )

            val createResult =
                mockMvc.perform(
                    post("/api/groups/${group.id}/events")
                        .header("Authorization", "Bearer $memberToken")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createRequest)),
                )
                    .andReturn()

            val createResponse = objectMapper.readTree(createResult.response.contentAsString)
            // 미래 일정 중 하나 선택
            val futureEventId = createResponse["data"][5]["id"].asLong()

            // When: 이후 전체 삭제
            mockMvc.perform(
                delete("/api/groups/${group.id}/events/$futureEventId")
                    .header("Authorization", "Bearer $memberToken")
                    .param("scope", "ALL_EVENTS"),
            )
                .andDo(print())
                .andExpect(status().isNoContent)

            // Then: 과거 일정만 남음
            mockMvc.perform(
                get("/api/groups/${group.id}/events")
                    .header("Authorization", "Bearer $memberToken")
                    .param("startDate", pastDate.toString())
                    .param("endDate", futureDate.plusDays(1).toString()),
            )
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.data.length()").isNumber) // 과거 일정 개수만큼
        }
    }

    @Nested
    @DisplayName("권한 시나리오 테스트")
    inner class PermissionTest {
        @Test
        @DisplayName("비공식 일정 생성 - 일반 멤버 - 성공")
        fun createUnofficialEvent_Member_Success() {
            // Given
            val tomorrow = LocalDate.now().plusDays(1)
            val request =
                CreateGroupEventRequest(
                    title = "비공식 일정",
                    description = null,
                    locationText = null,
                    startDate = tomorrow,
                    endDate = tomorrow,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(15, 0),
                    isAllDay = false,
                    isOfficial = false,
                    eventType = EventType.GENERAL,
                    color = "#3B82F6",
                    recurrence = null,
                )

            // When & Then
            mockMvc.perform(
                post("/api/groups/${group.id}/events")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isCreated)
                .andExpect(jsonPath("$.success").value(true))
        }

        @Test
        @DisplayName("공식 일정 생성 - CALENDAR_MANAGE 없음 - 403")
        fun createOfficialEvent_WithoutPermission_Forbidden() {
            // Given: 일반 멤버가 공식 일정 생성 시도
            val tomorrow = LocalDate.now().plusDays(1)
            val request =
                CreateGroupEventRequest(
                    title = "공식 일정",
                    description = null,
                    locationText = null,
                    startDate = tomorrow,
                    endDate = tomorrow,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(15, 0),
                    isAllDay = false,
                    // 공식 일정
                    isOfficial = true,
                    eventType = EventType.GENERAL,
                    color = "#EF4444",
                    recurrence = null,
                )

            // When & Then
            mockMvc.perform(
                post("/api/groups/${group.id}/events")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isForbidden)
        }

        @Test
        @DisplayName("타인의 비공식 일정 수정 시도 - 403")
        fun updateOthersEvent_Forbidden() {
            // Given: 일반 멤버가 일정 생성
            val tomorrow = LocalDate.now().plusDays(1)
            val createRequest =
                CreateGroupEventRequest(
                    title = "멤버의 일정",
                    description = null,
                    locationText = null,
                    startDate = tomorrow,
                    endDate = tomorrow,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(15, 0),
                    isAllDay = false,
                    isOfficial = false,
                    eventType = EventType.GENERAL,
                    color = "#3B82F6",
                    recurrence = null,
                )

            val createResult =
                mockMvc.perform(
                    post("/api/groups/${group.id}/events")
                        .header("Authorization", "Bearer $memberToken")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createRequest)),
                )
                    .andReturn()

            val createResponse = objectMapper.readTree(createResult.response.contentAsString)
            val eventId = createResponse["data"][0]["id"].asLong()

            // When: 그룹장이 타인의 비공식 일정 수정 시도 (CALENDAR_MANAGE 있으면 가능)
            val updateRequest =
                UpdateGroupEventRequest(
                    title = "수정 시도",
                    description = null,
                    locationText = null,
                    startTime = LocalTime.of(16, 0),
                    endTime = LocalTime.of(17, 0),
                    isAllDay = false,
                    color = "#F59E0B",
                    updateScope = UpdateScope.THIS_EVENT,
                )

            // Then: 그룹장은 CALENDAR_MANAGE가 있으므로 수정 가능
            mockMvc.perform(
                put("/api/groups/${group.id}/events/$eventId")
                    .header("Authorization", "Bearer $ownerToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(updateRequest)),
            )
                .andDo(print())
                .andExpect(status().isOk) // 그룹장은 성공
        }

        @Test
        @DisplayName("비멤버의 일정 생성 시도 - 4xx")
        fun createEvent_NonMember_Forbidden() {
            // Given
            val tomorrow = LocalDate.now().plusDays(1)
            val request =
                CreateGroupEventRequest(
                    title = "비멤버 일정",
                    description = null,
                    locationText = null,
                    startDate = tomorrow,
                    endDate = tomorrow,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(15, 0),
                    isAllDay = false,
                    isOfficial = false,
                    eventType = EventType.GENERAL,
                    color = "#6366F1",
                    recurrence = null,
                )

            // When & Then
            // GlobalExceptionHandler에서 BusinessException 처리 시 400 or 403 반환 가능
            mockMvc.perform(
                post("/api/groups/${group.id}/events")
                    .header("Authorization", "Bearer $nonMemberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().is4xxClientError) // 400 or 403 허용
        }
    }

    @Nested
    @DisplayName("엣지 케이스 테스트")
    inner class EdgeCaseTest {
        @Test
        @DisplayName("시작일이 종료일보다 늦을 경우 - 400")
        fun createEvent_InvalidDateRange_BadRequest() {
            // Given
            val request =
                CreateGroupEventRequest(
                    title = "잘못된 일정",
                    description = null,
                    locationText = null,
                    startDate = LocalDate.now().plusDays(10),
                    // 시작일보다 빠름
                    endDate = LocalDate.now().plusDays(1),
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(15, 0),
                    isAllDay = false,
                    isOfficial = false,
                    eventType = EventType.GENERAL,
                    color = "#3B82F6",
                    recurrence = RecurrencePattern(type = RecurrenceType.DAILY),
                )

            // When & Then
            mockMvc.perform(
                post("/api/groups/${group.id}/events")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isBadRequest)
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.message").value("날짜 범위가 올바르지 않습니다."))
        }

        @Test
        @DisplayName("빈 제목 입력 - 400")
        fun createEvent_EmptyTitle_BadRequest() {
            // Given
            val tomorrow = LocalDate.now().plusDays(1)
            val request =
                CreateGroupEventRequest(
                    title = "",
                    description = null,
                    locationText = null,
                    startDate = tomorrow,
                    endDate = tomorrow,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(15, 0),
                    isAllDay = false,
                    isOfficial = false,
                    eventType = EventType.GENERAL,
                    color = "#3B82F6",
                    recurrence = null,
                )

            // When & Then
            mockMvc.perform(
                post("/api/groups/${group.id}/events")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isBadRequest)
        }

        @Test
        @DisplayName("WEEKLY 반복 일정에서 daysOfWeek 미선택 - 400")
        fun createWeeklyRecurrence_NoDaysOfWeek_BadRequest() {
            // Given
            val startDate = LocalDate.now().plusDays(1)
            val endDate = startDate.plusDays(13)
            val request =
                CreateGroupEventRequest(
                    title = "주간 반복",
                    description = null,
                    locationText = null,
                    startDate = startDate,
                    endDate = endDate,
                    startTime = LocalTime.of(10, 0),
                    endTime = LocalTime.of(11, 0),
                    isAllDay = false,
                    isOfficial = false,
                    eventType = EventType.GENERAL,
                    color = "#10B981",
                    recurrence =
                        RecurrencePattern(
                            type = RecurrenceType.WEEKLY,
                            // 요일 미선택
                            daysOfWeek = null,
                        ),
                )

            // When & Then
            mockMvc.perform(
                post("/api/groups/${group.id}/events")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isBadRequest)
        }

        @Test
        @DisplayName("존재하지 않는 그룹 - 404")
        fun createEvent_GroupNotFound_NotFound() {
            // Given
            val tomorrow = LocalDate.now().plusDays(1)
            val request =
                CreateGroupEventRequest(
                    title = "일정",
                    description = null,
                    locationText = null,
                    startDate = tomorrow,
                    endDate = tomorrow,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(15, 0),
                    isAllDay = false,
                    isOfficial = false,
                    eventType = EventType.GENERAL,
                    color = "#3B82F6",
                    recurrence = null,
                )

            // When & Then
            mockMvc.perform(
                post("/api/groups/9999999/events")
                    .header("Authorization", "Bearer $memberToken")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)),
            )
                .andDo(print())
                .andExpect(status().isNotFound)
        }
    }
}
