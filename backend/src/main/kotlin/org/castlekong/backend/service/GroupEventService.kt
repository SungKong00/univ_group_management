package org.castlekong.backend.service

import com.fasterxml.jackson.databind.ObjectMapper
import org.castlekong.backend.dto.CreateGroupEventRequest
import org.castlekong.backend.dto.GroupEventResponse
import org.castlekong.backend.dto.RecurrenceType
import org.castlekong.backend.dto.UpdateGroupEventRequest
import org.castlekong.backend.dto.UpdateScope
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupEvent
import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.GroupEventRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.security.PermissionService
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.util.UUID

@Service
@Transactional
class GroupEventService(
    private val groupEventRepository: GroupEventRepository,
    private val groupRepository: GroupRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val permissionService: PermissionService,
    private val objectMapper: ObjectMapper,
) {
    /**
     * 그룹의 특정 기간 일정 조회
     */
    @Transactional(readOnly = true)
    fun getEventsByDateRange(
        user: User,
        groupId: Long,
        startDate: LocalDate,
        endDate: LocalDate,
    ): List<GroupEventResponse> {
        // 1. 그룹 멤버십 확인
        validateGroupMembership(user, groupId)

        // 2. 날짜 범위 검증
        if (endDate.isBefore(startDate)) {
            throw BusinessException(ErrorCode.INVALID_DATE_RANGE)
        }

        // 3. Repository 조회
        val events =
            groupEventRepository.findByGroupIdAndStartDateBetween(
                groupId,
                startDate.atStartOfDay(),
                endDate.plusDays(1).atStartOfDay(),
            )

        // 4. DTO 변환
        return events.map { it.toResponse() }
    }

    /**
     * 일정 생성 (단일 or 반복)
     */
    fun createEvent(
        user: User,
        groupId: Long,
        request: CreateGroupEventRequest,
    ): List<GroupEventResponse> {
        // 1. 그룹 조회
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 2. 권한 확인
        if (request.isOfficial) {
            // 공식 일정: CALENDAR_MANAGE 권한 필요
            checkCalendarManagePermission(user, groupId)
        } else {
            // 비공식 일정: 그룹 멤버면 생성 가능
            validateGroupMembership(user, groupId)
        }

        // 3. Date/Time 검증
        val startDate = request.startDate ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
        val endDate = request.endDate ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
        val startTime = request.startTime ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
        val endTime = request.endTime ?: throw BusinessException(ErrorCode.INVALID_REQUEST)

        // 4. 날짜 범위 검증
        validateDateRange(startDate, endDate)

        // 5. 반복 일정 검증
        if (request.recurrence != null) {
            validateRecurrenceRequest(request)
        }

        // 6. 종일 이벤트 처리
        val actualStartTime = if (request.isAllDay) LocalTime.MIN else startTime
        val actualEndTime = if (request.isAllDay) LocalTime.of(23, 59, 59) else endTime

        // 7. 시간 검증
        validateTimeRange(actualStartTime, actualEndTime)

        // 8. 반복 일정 여부 확인
        if (request.recurrence == null) {
            // 단일 일정 생성
            val eventStart = startDate.atTime(actualStartTime)
            val eventEnd = startDate.atTime(actualEndTime)
            val event = createSingleEvent(group, user, request, eventStart, eventEnd, null, null)
            val saved = groupEventRepository.save(event)
            return listOf(saved.toResponse())
        } else {
            // 반복 일정 생성 (명시적 인스턴스 저장)
            return createRecurringEvents(group, user, request, actualStartTime, actualEndTime)
        }
    }

    /**
     * 반복 패턴에 따라 여러 인스턴스 생성
     */
    private fun createRecurringEvents(
        group: Group,
        user: User,
        request: CreateGroupEventRequest,
        startTime: LocalTime,
        endTime: LocalTime,
    ): List<GroupEventResponse> {
        val recurrence = request.recurrence!!
        val seriesId = UUID.randomUUID().toString()
        val recurrenceRuleJson = objectMapper.writeValueAsString(recurrence)

        val startDate = request.startDate!!
        val endDate = request.endDate!!

        // 1. 생성할 날짜 목록 계산
        val dates =
            when (recurrence.type) {
                RecurrenceType.DAILY -> {
                    // 매일: startDate부터 endDate까지 모든 날짜
                    generateSequence(startDate) { it.plusDays(1) }
                        .takeWhile { !it.isAfter(endDate) }
                        .toList()
                }
                RecurrenceType.WEEKLY -> {
                    // 요일 선택: startDate부터 endDate까지 해당 요일만
                    val daysOfWeek =
                        recurrence.daysOfWeek
                            ?: throw BusinessException(ErrorCode.INVALID_REQUEST)

                    generateSequence(startDate) { it.plusDays(1) }
                        .takeWhile { !it.isAfter(endDate) }
                        .filter { it.dayOfWeek in daysOfWeek }
                        .toList()
                }
            }

        // 1.1. 빈 인스턴스 체크
        if (dates.isEmpty()) {
            throw BusinessException(ErrorCode.INVALID_REQUEST)
        }

        // 2. 각 날짜마다 GroupEvent 인스턴스 생성
        val events =
            dates.map { date ->
                val eventStart = date.atTime(startTime)
                val eventEnd = date.atTime(endTime)

                createSingleEvent(
                    group = group,
                    creator = user,
                    request = request,
                    eventStart = eventStart,
                    eventEnd = eventEnd,
                    seriesId = seriesId,
                    recurrenceRule = recurrenceRuleJson,
                )
            }

        // 3. Batch Insert
        val saved = groupEventRepository.saveAll(events)
        return saved.map { it.toResponse() }
    }

    /**
     * GroupEvent 엔티티 생성 (재사용 가능한 헬퍼)
     */
    private fun createSingleEvent(
        group: Group,
        creator: User,
        request: CreateGroupEventRequest,
        eventStart: LocalDateTime,
        eventEnd: LocalDateTime,
        seriesId: String?,
        recurrenceRule: String?,
    ): GroupEvent =
        GroupEvent(
            group = group,
            creator = creator,
            title = request.title.trim(),
            description = request.description?.trim(),
            locationText = request.locationText?.trim(),
            // Phase 1: place 연동은 Phase 2에서 구현
            place = null,
            startDate = eventStart,
            endDate = eventEnd,
            isAllDay = request.isAllDay,
            isOfficial = request.isOfficial,
            eventType = request.eventType,
            seriesId = seriesId,
            recurrenceRule = recurrenceRule,
            color = normalizeColor(request.color),
            createdAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now(),
        )

    /**
     * 일정 수정 (이 일정만 vs 반복 전체)
     */
    fun updateEvent(
        user: User,
        groupId: Long,
        eventId: Long,
        request: UpdateGroupEventRequest,
    ): List<GroupEventResponse> {
        // 1. 일정 조회 및 권한 확인
        val existing = getEventWithPermissionCheck(user, groupId, eventId)

        // 2. 시간 검증
        val startTime = request.startTime ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
        val endTime = request.endTime ?: throw BusinessException(ErrorCode.INVALID_REQUEST)

        // 3. 종일 이벤트 처리
        val actualStartTime = if (request.isAllDay) LocalTime.MIN else startTime
        val actualEndTime = if (request.isAllDay) LocalTime.of(23, 59, 59) else endTime

        validateTimeRange(actualStartTime, actualEndTime)

        // 4. 수정 범위에 따라 분기
        return when (request.updateScope) {
            UpdateScope.THIS_EVENT -> {
                // 이 일정만 수정
                val newStart = existing.startDate.toLocalDate().atTime(actualStartTime)
                val newEnd = existing.endDate.toLocalDate().atTime(actualEndTime)

                val updated =
                    existing.copy(
                        title = request.title.trim(),
                        description = request.description?.trim(),
                        locationText = request.locationText?.trim(),
                        // Phase 1: place 연동은 Phase 2에서 구현
                        place = null,
                        startDate = newStart,
                        endDate = newEnd,
                        isAllDay = request.isAllDay,
                        color = normalizeColor(request.color),
                        updatedAt = LocalDateTime.now(),
                    )
                val saved = groupEventRepository.save(updated)
                listOf(saved.toResponse())
            }
            UpdateScope.ALL_EVENTS -> {
                // 반복 전체 수정 (미래 일정만)
                if (existing.seriesId == null) {
                    throw BusinessException(ErrorCode.NOT_RECURRING_EVENT)
                }

                val futureEvents =
                    groupEventRepository.findFutureEventsBySeries(
                        groupId,
                        existing.seriesId,
                        LocalDateTime.now(),
                    )

                val updated =
                    futureEvents.map { event ->
                        val newStart = event.startDate.toLocalDate().atTime(actualStartTime)
                        val newEnd = event.endDate.toLocalDate().atTime(actualEndTime)

                        event.copy(
                            title = request.title.trim(),
                            description = request.description?.trim(),
                            locationText = request.locationText?.trim(),
                            // Phase 1: place 연동은 Phase 2에서 구현
                            place = null,
                            startDate = newStart,
                            endDate = newEnd,
                            isAllDay = request.isAllDay,
                            color = normalizeColor(request.color),
                            updatedAt = LocalDateTime.now(),
                        )
                    }

                val saved = groupEventRepository.saveAll(updated)
                saved.map { it.toResponse() }
            }
        }
    }

    /**
     * 일정 삭제 (이 일정만 vs 반복 전체)
     */
    fun deleteEvent(
        user: User,
        groupId: Long,
        eventId: Long,
        deleteScope: UpdateScope = UpdateScope.THIS_EVENT,
    ) {
        // 1. 일정 조회 및 권한 확인
        val existing = getEventWithPermissionCheck(user, groupId, eventId)

        // 2. 삭제 범위에 따라 분기
        when (deleteScope) {
            UpdateScope.THIS_EVENT -> {
                // 이 일정만 삭제
                groupEventRepository.delete(existing)
            }
            UpdateScope.ALL_EVENTS -> {
                // 반복 전체 삭제 (미래 일정만)
                if (existing.seriesId == null) {
                    throw BusinessException(ErrorCode.NOT_RECURRING_EVENT)
                }

                val futureEvents =
                    groupEventRepository.findFutureEventsBySeries(
                        groupId,
                        existing.seriesId,
                        LocalDateTime.now(),
                    )

                groupEventRepository.deleteAll(futureEvents)
            }
        }
    }

    // ===== 헬퍼 메서드 =====

    /**
     * 그룹 멤버십 확인
     */
    private fun validateGroupMembership(
        user: User,
        groupId: Long,
    ) {
        if (!groupMemberRepository.findByGroupIdAndUserId(groupId, user.id).isPresent) {
            throw BusinessException(ErrorCode.NOT_GROUP_MEMBER)
        }
    }

    /**
     * CALENDAR_MANAGE 권한 확인
     */
    private fun checkCalendarManagePermission(
        user: User,
        groupId: Long,
    ) {
        groupMemberRepository.findByGroupIdAndUserId(groupId, user.id)
            .orElseThrow { BusinessException(ErrorCode.NOT_GROUP_MEMBER) }

        val effectivePermissions =
            permissionService.getEffective(groupId, user.id) { roleName ->
                getSystemRolePermissions(roleName)
            }

        if (!effectivePermissions.contains(GroupPermission.CALENDAR_MANAGE)) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
    }

    /**
     * 시스템 역할별 기본 권한 (캘린더 관련)
     */
    private fun getSystemRolePermissions(roleName: String): Set<GroupPermission> =
        when (roleName) {
            "그룹장" ->
                setOf(
                    GroupPermission.GROUP_MANAGE,
                    GroupPermission.MEMBER_MANAGE,
                    GroupPermission.CHANNEL_MANAGE,
                    GroupPermission.RECRUITMENT_MANAGE,
                    GroupPermission.CALENDAR_MANAGE,
                )
            "교수" ->
                setOf(
                    GroupPermission.CHANNEL_MANAGE,
                    GroupPermission.CALENDAR_MANAGE,
                )
            else -> emptySet()
        }

    /**
     * 일정 조회 + 권한 확인
     */
    private fun getEventWithPermissionCheck(
        user: User,
        groupId: Long,
        eventId: Long,
    ): GroupEvent {
        val event =
            groupEventRepository.findById(eventId)
                .orElseThrow { BusinessException(ErrorCode.EVENT_NOT_FOUND) }

        if (event.group.id != groupId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }

        // 권한 확인
        if (event.isOfficial) {
            // 공식 일정: CALENDAR_MANAGE 필요
            checkCalendarManagePermission(user, groupId)
        } else {
            // 비공식 일정: 작성자 본인 or CALENDAR_MANAGE
            groupMemberRepository.findByGroupIdAndUserId(groupId, user.id)
                .orElseThrow { BusinessException(ErrorCode.NOT_GROUP_MEMBER) }

            val effectivePermissions =
                permissionService.getEffective(groupId, user.id) { roleName ->
                    getSystemRolePermissions(roleName)
                }

            val hasPermission =
                event.creator.id == user.id ||
                    effectivePermissions.contains(GroupPermission.CALENDAR_MANAGE)

            if (!hasPermission) {
                throw BusinessException(ErrorCode.FORBIDDEN)
            }
        }

        return event
    }

    /**
     * 날짜 범위 검증
     */
    private fun validateDateRange(
        startDate: LocalDate,
        endDate: LocalDate,
    ) {
        if (startDate.isAfter(endDate)) {
            throw BusinessException(ErrorCode.INVALID_DATE_RANGE)
        }
    }

    /**
     * 시간 범위 검증
     */
    private fun validateTimeRange(
        start: LocalTime,
        end: LocalTime,
    ) {
        if (!end.isAfter(start)) {
            throw BusinessException(ErrorCode.INVALID_TIME_RANGE)
        }
    }

    /**
     * 반복 일정 요청 검증
     */
    private fun validateRecurrenceRequest(request: CreateGroupEventRequest) {
        val recurrence =
            request.recurrence
                ?: throw BusinessException(ErrorCode.INVALID_REQUEST)

        val startDate =
            request.startDate
                ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
        val endDate =
            request.endDate
                ?: throw BusinessException(ErrorCode.INVALID_REQUEST)

        // 반복 일정의 경우 시작일과 종료일이 동일해야 생성 가능
        // (반복 패턴은 startDate를 기준으로 endDate까지 반복)
        // 예: startDate=11/1, endDate=11/7이면 11/1~11/7 사이에 반복 인스턴스 생성

        // 반복 기간이 365일을 초과하는 경우 제한
        val daysBetween = java.time.temporal.ChronoUnit.DAYS.between(startDate, endDate)
        if (daysBetween > 365) {
            throw BusinessException(ErrorCode.INVALID_REQUEST)
        }

        // WEEKLY 타입일 경우 daysOfWeek 필수
        if (recurrence.type == RecurrenceType.WEEKLY) {
            if (recurrence.daysOfWeek.isNullOrEmpty()) {
                throw BusinessException(ErrorCode.INVALID_REQUEST)
            }
        }
    }

    /**
     * 색상 정규화
     */
    private fun normalizeColor(color: String): String {
        val value = color.trim()
        if (!COLOR_REGEX.matches(value)) {
            throw BusinessException(ErrorCode.INVALID_COLOR)
        }
        return value.uppercase()
    }

    /**
     * DTO 변환
     */
    private fun GroupEvent.toResponse(): GroupEventResponse =
        GroupEventResponse(
            id = id,
            groupId = group.id,
            groupName = group.name,
            creatorId = creator.id,
            creatorName = creator.name,
            title = title,
            description = description,
            locationText = locationText,
            placeId = place?.id,
            placeName = place?.getDisplayName(),
            startDate = startDate,
            endDate = endDate,
            isAllDay = isAllDay,
            isOfficial = isOfficial,
            eventType = eventType,
            seriesId = seriesId,
            recurrenceRule = recurrenceRule,
            color = color,
            createdAt = createdAt,
            updatedAt = updatedAt,
        )

    companion object {
        private val COLOR_REGEX = "^#[0-9A-Fa-f]{6}$".toRegex()
    }
}
