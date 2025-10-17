package org.castlekong.backend.service

import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.castlekong.backend.dto.CreateGroupEventRequest
import org.castlekong.backend.dto.RecurrencePattern
import org.castlekong.backend.dto.RecurrenceType
import org.castlekong.backend.dto.UpdateGroupEventRequest
import org.castlekong.backend.dto.UpdateScope
import org.castlekong.backend.entity.EventType
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.fixture.TestDataFactory
import org.castlekong.backend.repository.GroupEventRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.castlekong.backend.repository.UserRepository
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.test.context.ActiveProfiles
import org.springframework.transaction.annotation.Transactional
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime

@SpringBootTest
@ActiveProfiles("test")
@Transactional
@DisplayName("GroupEventService 통합 테스트")
class GroupEventServiceTest {
    @Autowired
    private lateinit var groupEventService: GroupEventService

    @Autowired
    private lateinit var groupEventRepository: GroupEventRepository

    @Autowired
    private lateinit var userRepository: UserRepository

    @Autowired
    private lateinit var groupRepository: GroupRepository

    @Autowired
    private lateinit var groupRoleRepository: GroupRoleRepository

    @Autowired
    private lateinit var groupMemberRepository: GroupMemberRepository

    private lateinit var owner: User
    private lateinit var member: User
    private lateinit var nonMember: User
    private lateinit var group: Group

    @BeforeEach
    fun setUp() {
        val suffix = System.nanoTime().toString()

        owner =
            userRepository.save(
                TestDataFactory.createTestUser(
                    name = "그룹장",
                    email = "owner-event+$suffix@example.com",
                ).copy(profileCompleted = true),
            )

        member =
            userRepository.save(
                TestDataFactory.createStudentUser(
                    name = "일반 멤버",
                    email = "member-event+$suffix@example.com",
                ),
            )

        nonMember =
            userRepository.save(
                TestDataFactory.createStudentUser(
                    name = "비멤버",
                    email = "nonmember-event+$suffix@example.com",
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
    }

    @Test
    @DisplayName("단일 일정 생성 - 성공")
    fun createEvent_SingleEvent_Success() {
        // Given
        val tomorrow = LocalDate.now().plusDays(1)
        val request =
            CreateGroupEventRequest(
                title = "단일 일정",
                description = "단일 일정 설명",
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

        // When
        val results = groupEventService.createEvent(member, group.id, request)

        // Then
        assertThat(results).hasSize(1)
        val event = results[0]
        assertThat(event.title).isEqualTo("단일 일정")
        assertThat(event.groupId).isEqualTo(group.id)
        assertThat(event.creatorId).isEqualTo(member.id)
        assertThat(event.seriesId).isNull()
        assertThat(event.recurrenceRule).isNull()
        // duration 검증
        assertThat(event.endDate).isAfter(event.startDate)
    }

    @Test
    @DisplayName("반복 일정 생성 - DAILY - 성공")
    fun createEvent_RecurringDaily_Success() {
        // Given: 11/1 ~ 11/30, 매일 반복, 14:00-15:00
        val request =
            CreateGroupEventRequest(
                title = "매일 반복 일정",
                description = "매일 14:00-15:00",
                locationText = null,
                startDate = LocalDate.of(2025, 11, 1),
                endDate = LocalDate.of(2025, 11, 30),
                startTime = LocalTime.of(14, 0),
                endTime = LocalTime.of(15, 0),
                isAllDay = false,
                isOfficial = false,
                eventType = EventType.GENERAL,
                color = "#10B981",
                recurrence = RecurrencePattern(type = RecurrenceType.DAILY),
            )

        // When
        val results = groupEventService.createEvent(member, group.id, request)

        // Then: 30개 인스턴스 생성
        assertThat(results).hasSize(30)
        assertThat(results.map { it.seriesId }.toSet()).hasSize(1) // 동일한 seriesId
        assertThat(results.all { it.title == "매일 반복 일정" }).isTrue()
        // duration 검증: 모든 인스턴스가 duration > 0
        assertThat(results.all { it.endDate.isAfter(it.startDate) }).isTrue()

        // DB에서도 확인
        val seriesId = results[0].seriesId!!
        val saved = groupEventRepository.findBySeriesId(seriesId)
        assertThat(saved).hasSize(30)
    }

    @Test
    @DisplayName("반복 일정 생성 - WEEKLY - 성공")
    fun createEvent_RecurringWeekly_Success() {
        // Given: 11/1 ~ 11/30, 월/수/금 반복, 10:00-11:00
        val request =
            CreateGroupEventRequest(
                title = "주간 반복 일정",
                description = "월수금 10:00-11:00",
                locationText = "강의실",
                startDate = LocalDate.of(2025, 11, 1),
                endDate = LocalDate.of(2025, 11, 30),
                startTime = LocalTime.of(10, 0),
                endTime = LocalTime.of(11, 0),
                isAllDay = false,
                isOfficial = false,
                eventType = EventType.GENERAL,
                color = "#F59E0B",
                recurrence =
                    RecurrencePattern(
                        type = RecurrenceType.WEEKLY,
                        daysOfWeek = listOf(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY),
                    ),
            )

        // When
        val results = groupEventService.createEvent(member, group.id, request)

        // Then: 11월 월수금은 12개 (11/1은 토요일이므로 제외)
        assertThat(results).hasSize(12)
        assertThat(results.map { it.seriesId }.toSet()).hasSize(1)
        // duration 검증: 모든 인스턴스가 duration > 0
        assertThat(results.all { it.endDate.isAfter(it.startDate) }).isTrue()

        // 모든 일정이 월/수/금인지 확인
        val daysOfWeek = results.map { it.startDate.dayOfWeek }.toSet()
        assertThat(daysOfWeek).containsExactlyInAnyOrder(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY)
    }

    @Test
    @DisplayName("공식 일정 생성 - CALENDAR_MANAGE 권한 없음 - 실패")
    fun createEvent_OfficialWithoutPermission_ThrowsForbidden() {
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
            )

        // When & Then
        assertThatThrownBy { groupEventService.createEvent(member, group.id, request) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.FORBIDDEN)
    }

    @Test
    @DisplayName("비공식 일정 생성 - 그룹 멤버 아님 - 실패")
    fun createEvent_NotMember_ThrowsNotGroupMember() {
        // Given: 그룹 비멤버가 일정 생성 시도
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
            )

        // When & Then
        assertThatThrownBy { groupEventService.createEvent(nonMember, group.id, request) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.NOT_GROUP_MEMBER)
    }

    @Test
    @DisplayName("이 일정만 수정 - 성공")
    fun updateEvent_ThisEventOnly_Success() {
        // Given: 반복 일정 생성
        val createRequest =
            CreateGroupEventRequest(
                title = "원본 제목",
                description = "원본 설명",
                locationText = null,
                startDate = LocalDate.of(2025, 11, 1),
                endDate = LocalDate.of(2025, 11, 10),
                startTime = LocalTime.of(14, 0),
                endTime = LocalTime.of(15, 0),
                isAllDay = false,
                isOfficial = false,
                eventType = EventType.GENERAL,
                color = "#3B82F6",
                recurrence = RecurrencePattern(type = RecurrenceType.DAILY),
            )

        val created = groupEventService.createEvent(member, group.id, createRequest)
        // 6번째 일정만 수정
        val targetEvent = created[5]

        // When: 이 일정만 수정
        val updateRequest =
            UpdateGroupEventRequest(
                title = "수정된 제목",
                description = "수정된 설명",
                locationText = "새 장소",
                startTime = LocalTime.of(16, 0),
                endTime = LocalTime.of(17, 0),
                isAllDay = false,
                color = "#10B981",
                updateScope = UpdateScope.THIS_EVENT,
            )

        val updated = groupEventService.updateEvent(member, group.id, targetEvent.id, updateRequest)

        // Then: 해당 일정만 수정, 나머지는 원본 유지
        assertThat(updated).hasSize(1)
        assertThat(updated[0].title).isEqualTo("수정된 제목")
        assertThat(updated[0].color).isEqualTo("#10B981")

        // 나머지 일정 확인
        val seriesId = targetEvent.seriesId!!
        val allEvents = groupEventRepository.findBySeriesId(seriesId)
        val unchangedCount = allEvents.count { it.title == "원본 제목" }
        // 10개 중 9개는 원본 유지
        assertThat(unchangedCount).isEqualTo(9)
    }

    @Test
    @DisplayName("반복 전체 수정 - 미래 일정만 수정 - 성공")
    fun updateEvent_AllFutureEvents_Success() {
        // Given: 과거, 현재, 미래 일정 생성
        val now = LocalDateTime.now()
        val pastDate = now.minusDays(3).toLocalDate()
        val futureDate = now.plusDays(7).toLocalDate()

        val createRequest =
            CreateGroupEventRequest(
                title = "반복 일정",
                description = "설명",
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

        val created = groupEventService.createEvent(member, group.id, createRequest)
        val futureEvent = created.find { it.startDate.isAfter(now) }!!

        // When: 반복 전체 수정
        val updateRequest =
            UpdateGroupEventRequest(
                title = "수정된 반복 일정",
                description = "수정된 설명",
                locationText = null,
                startTime = LocalTime.of(16, 0),
                endTime = LocalTime.of(17, 0),
                isAllDay = false,
                color = "#F59E0B",
                updateScope = UpdateScope.ALL_EVENTS,
            )

        val updated = groupEventService.updateEvent(member, group.id, futureEvent.id, updateRequest)

        // Then: 미래 일정만 수정
        val futureCount = updated.size
        assertThat(futureCount).isGreaterThan(0)
        assertThat(updated.all { it.title == "수정된 반복 일정" }).isTrue()

        // 과거 일정은 원본 유지
        val seriesId = futureEvent.seriesId!!
        val pastEvents = groupEventRepository.findBySeriesId(seriesId).filter { it.startDate.isBefore(now) }
        assertThat(pastEvents.all { it.title == "반복 일정" }).isTrue()
    }

    @Test
    @DisplayName("이 일정만 삭제 - 성공")
    fun deleteEvent_ThisEventOnly_Success() {
        // Given: 반복 일정 생성
        val createRequest =
            CreateGroupEventRequest(
                title = "반복 일정",
                description = null,
                locationText = null,
                startDate = LocalDate.of(2025, 11, 1),
                endDate = LocalDate.of(2025, 11, 10),
                startTime = LocalTime.of(14, 0),
                endTime = LocalTime.of(15, 0),
                isAllDay = false,
                isOfficial = false,
                eventType = EventType.GENERAL,
                color = "#3B82F6",
                recurrence = RecurrencePattern(type = RecurrenceType.DAILY),
            )

        val created = groupEventService.createEvent(member, group.id, createRequest)
        // 4번째 일정만 삭제
        val targetEvent = created[3]

        // When: 이 일정만 삭제
        groupEventService.deleteEvent(member, group.id, targetEvent.id, UpdateScope.THIS_EVENT)

        // Then: 해당 일정만 삭제, 나머지는 유지
        val remaining = groupEventRepository.findBySeriesId(targetEvent.seriesId!!)
        // 10개 중 1개 삭제
        assertThat(remaining).hasSize(9)
        assertThat(remaining.none { it.id == targetEvent.id }).isTrue()
    }

    @Test
    @DisplayName("반복 전체 삭제 - 미래 일정만 삭제 - 성공")
    fun deleteEvent_AllFutureEvents_Success() {
        // Given: 과거, 미래 일정 생성
        val now = LocalDateTime.now()
        val pastDate = now.minusDays(3).toLocalDate()
        val futureDate = now.plusDays(7).toLocalDate()

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

        val created = groupEventService.createEvent(member, group.id, createRequest)
        val futureEvent = created.find { it.startDate.isAfter(now) }!!

        // When: 반복 전체 삭제
        groupEventService.deleteEvent(member, group.id, futureEvent.id, UpdateScope.ALL_EVENTS)

        // Then: 미래 일정만 삭제, 과거는 유지
        val remaining = groupEventRepository.findBySeriesId(futureEvent.seriesId!!)
        assertThat(remaining.all { it.startDate.isBefore(now) }).isTrue()
    }

    @Test
    @DisplayName("날짜 범위 조회 - 성공")
    fun getEventsByDateRange_Success() {
        // Given: 11/1 ~ 11/15 범위에 15개 일정
        val createRequest =
            CreateGroupEventRequest(
                title = "조회 테스트 일정",
                description = null,
                locationText = null,
                startDate = LocalDate.of(2025, 11, 1),
                endDate = LocalDate.of(2025, 11, 15),
                startTime = LocalTime.of(10, 0),
                endTime = LocalTime.of(11, 0),
                isAllDay = false,
                isOfficial = false,
                eventType = EventType.GENERAL,
                color = "#3B82F6",
                recurrence = RecurrencePattern(type = RecurrenceType.DAILY),
            )

        groupEventService.createEvent(member, group.id, createRequest)

        // When: 11/1 ~ 11/30 범위 조회
        val results =
            groupEventService.getEventsByDateRange(
                member,
                group.id,
                LocalDate.of(2025, 11, 1),
                LocalDate.of(2025, 11, 30),
            )

        // Then: 15개 일정 반환
        assertThat(results).hasSize(15)
        assertThat(results.all { it.title == "조회 테스트 일정" }).isTrue()
    }

    // Helper methods

    private fun createGroupWithRoles(owner: User): Group {
        val group =
            groupRepository.save(
                TestDataFactory.createTestGroup(
                    name = "일정 테스트 그룹",
                    owner = owner,
                ),
            )

        val ownerRole = TestDataFactory.createOwnerRole(group)
        ownerRole.replacePermissions(listOf(GroupPermission.CALENDAR_MANAGE, GroupPermission.GROUP_MANAGE))
        groupRoleRepository.save(ownerRole)

        val advisorRole = TestDataFactory.createAdvisorRole(group)
        advisorRole.replacePermissions(listOf(GroupPermission.CALENDAR_MANAGE))
        groupRoleRepository.save(advisorRole)

        val memberRole = TestDataFactory.createMemberRole(group)
        // 일반 멤버는 캘린더 권한 없음
        memberRole.replacePermissions(emptyList())
        groupRoleRepository.save(memberRole)

        groupMemberRepository.save(
            TestDataFactory.createTestGroupMember(
                group = group,
                user = owner,
                role = ownerRole,
            ),
        )

        return group
    }
}
