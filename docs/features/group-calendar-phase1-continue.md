# 그룹 캘린더 Phase 1 백엔드 구현 - 계속 작업 가이드

> **작성일**: 2025-10-12
> **현재 진행 상황**: Step 1-3 완료 (엔티티, Repository, DTO)
> **다음 작업**: Step 4-6 (Service, Controller, 테스트)

---

## 📋 현재까지 완료된 작업 (Step 1-3)

### ✅ Step 1: GroupEvent 엔티티
**파일**: `backend/src/main/kotlin/org/castlekong/backend/entity/GroupEvent.kt`

**구현 내용**:
- 14개 필드 구현 완료
- EventType enum (GENERAL, TARGETED, RSVP)
- Group, User와의 ManyToOne 관계
- 반복 일정 필드: `seriesId`, `recurrenceRule` (JSON 저장)

**주요 필드**:
```kotlin
- id, group, creator, title, description, location
- startDate, endDate, isAllDay, isOfficial
- eventType, seriesId, recurrenceRule, color
- createdAt, updatedAt
```

---

### ✅ Step 2: GroupEventRepository
**파일**: `backend/src/main/kotlin/org/castlekong/backend/repository/GroupEventRepository.kt`

**구현된 쿼리 메서드 (6개)**:
1. `findByGroupIdAndStartDateBetween()` - 날짜 범위 조회
2. `findBySeriesId()` - 반복 일정 시리즈 조회
3. `findByGroupIdAndIsOfficial()` - 공식/비공식 필터링
4. `findFutureEventsBySeries()` - 미래 이벤트 조회 (반복 전체 수정/삭제용)
5. `findByCreatorId()` - 작성자별 조회
6. `findByGroupIdAndDate()` - 특정 날짜 일정 조회

---

### ✅ Step 3: DTO 클래스
**파일**: `backend/src/main/kotlin/org/castlekong/backend/dto/GroupEventDto.kt`

**구현된 DTO (5개)**:
1. **GroupEventResponse**: 응답용 DTO (14개 필드)
2. **CreateGroupEventRequest**: 생성 요청 DTO
   - 기본 필드 + `recurrence: RecurrencePattern?`
3. **UpdateGroupEventRequest**: 수정 요청 DTO
   - 기본 필드 + `updateScope: UpdateScope`
4. **RecurrencePattern**: 반복 패턴 (type: DAILY/WEEKLY, daysOfWeek)
5. **UpdateScope**: 수정 범위 (THIS_EVENT/ALL_EVENTS)

---

## 🔄 다음 작업: Step 4 - GroupEventService 구현

### 📍 파일 위치
`backend/src/main/kotlin/org/castlekong/backend/service/GroupEventService.kt`

### 📦 필요한 의존성

```kotlin
@Service
@Transactional
class GroupEventService(
    private val groupEventRepository: GroupEventRepository,
    private val groupRepository: GroupRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val permissionService: PermissionService,
    private val objectMapper: ObjectMapper,  // JSON 직렬화/역직렬화
)
```

**참고 파일**:
- `PersonalEventService.kt` - 기본 CRUD 패턴
- `GroupRoleService.kt` - 권한 체크 패턴
- `ContentService.kt` - @Transactional 사용 예시

---

### 🎯 구현해야 할 메서드 (7개)

#### 1. `getEventsByDateRange()`
**목적**: 그룹의 특정 기간 일정 조회

```kotlin
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
    val events = groupEventRepository.findByGroupIdAndStartDateBetween(
        groupId,
        startDate.atStartOfDay(),
        endDate.plusDays(1).atStartOfDay()
    )

    // 4. DTO 변환
    return events.map { it.toResponse() }
}
```

**참고**: `PersonalEventService.getEvents()` 패턴 동일

---

#### 2. `createEvent()` - 핵심 로직!
**목적**: 일정 생성 (단일 or 반복)

```kotlin
fun createEvent(
    user: User,
    groupId: Long,
    request: CreateGroupEventRequest,
): List<GroupEventResponse> {
    // 1. 그룹 조회
    val group = groupRepository.findById(groupId)
        .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

    // 2. 권한 확인
    if (request.isOfficial) {
        // 공식 일정: CALENDAR_MANAGE 권한 필요
        permissionService.checkPermission(user, groupId, GroupPermission.CALENDAR_MANAGE)
    } else {
        // 비공식 일정: 그룹 멤버면 생성 가능
        validateGroupMembership(user, groupId)
    }

    // 3. 시간 검증
    val start = request.startDate ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
    val end = request.endDate ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
    validateTimeRange(start, end)

    // 4. 반복 일정 여부 확인
    if (request.recurrence == null) {
        // 단일 일정 생성
        val event = createSingleEvent(group, user, request, null, null)
        val saved = groupEventRepository.save(event)
        return listOf(saved.toResponse())
    } else {
        // 반복 일정 생성 (명시적 인스턴스 저장)
        return createRecurringEvents(group, user, request)
    }
}
```

---

#### 3. `createRecurringEvents()` - 반복 일정 생성
**목적**: 반복 패턴에 따라 여러 인스턴스 생성

```kotlin
private fun createRecurringEvents(
    group: Group,
    user: User,
    request: CreateGroupEventRequest,
): List<GroupEventResponse> {
    val recurrence = request.recurrence!!
    val seriesId = UUID.randomUUID().toString()
    val recurrenceRuleJson = objectMapper.writeValueAsString(recurrence)

    val start = request.startDate!!
    val end = request.endDate!!

    // 1. 생성할 날짜 목록 계산
    val dates = when (recurrence.type) {
        RecurrenceType.DAILY -> {
            // 매일: startDate부터 endDate까지 모든 날짜
            generateSequence(start.toLocalDate()) { it.plusDays(1) }
                .takeWhile { !it.isAfter(end.toLocalDate()) }
                .toList()
        }
        RecurrenceType.WEEKLY -> {
            // 요일 선택: startDate부터 endDate까지 해당 요일만
            val daysOfWeek = recurrence.daysOfWeek
                ?: throw BusinessException(ErrorCode.INVALID_REQUEST)

            generateSequence(start.toLocalDate()) { it.plusDays(1) }
                .takeWhile { !it.isAfter(end.toLocalDate()) }
                .filter { it.dayOfWeek in daysOfWeek }
                .toList()
        }
    }

    // 2. 각 날짜마다 GroupEvent 인스턴스 생성
    val events = dates.map { date ->
        val eventStart = date.atTime(start.toLocalTime())
        val eventEnd = date.atTime(end.toLocalTime())

        createSingleEvent(
            group = group,
            creator = user,
            request = request.copy(
                startDate = eventStart,
                endDate = eventEnd
            ),
            seriesId = seriesId,
            recurrenceRule = recurrenceRuleJson
        )
    }

    // 3. Batch Insert
    val saved = groupEventRepository.saveAll(events)
    return saved.map { it.toResponse() }
}
```

**주의사항**:
- `startDate`는 반복 시작일, `endDate`는 반복 종료일
- 각 인스턴스의 시작/종료 시간은 원본 시간 유지
- 예: 11/1 14:00-16:00 ~ 11/30 매주 월/수/금 → 13개 인스턴스 생성

---

#### 4. `createSingleEvent()` - 단일 인스턴스 생성
**목적**: GroupEvent 엔티티 생성 (재사용 가능한 헬퍼)

```kotlin
private fun createSingleEvent(
    group: Group,
    creator: User,
    request: CreateGroupEventRequest,
    seriesId: String?,
    recurrenceRule: String?,
): GroupEvent {
    return GroupEvent(
        group = group,
        creator = creator,
        title = request.title.trim(),
        description = request.description?.trim(),
        location = request.location?.trim(),
        startDate = request.startDate!!,
        endDate = request.endDate!!,
        isAllDay = request.isAllDay,
        isOfficial = request.isOfficial,
        eventType = request.eventType,
        seriesId = seriesId,
        recurrenceRule = recurrenceRule,
        color = normalizeColor(request.color),
        createdAt = LocalDateTime.now(),
        updatedAt = LocalDateTime.now(),
    )
}
```

---

#### 5. `updateEvent()` - 일정 수정
**목적**: "이 일정만" vs "반복 전체" 수정

```kotlin
fun updateEvent(
    user: User,
    groupId: Long,
    eventId: Long,
    request: UpdateGroupEventRequest,
): List<GroupEventResponse> {
    // 1. 일정 조회 및 권한 확인
    val existing = getEventWithPermissionCheck(user, groupId, eventId)

    // 2. 시간 검증
    val start = request.startDate ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
    val end = request.endDate ?: throw BusinessException(ErrorCode.INVALID_REQUEST)
    validateTimeRange(start, end)

    // 3. 수정 범위에 따라 분기
    return when (request.updateScope) {
        UpdateScope.THIS_EVENT -> {
            // 이 일정만 수정
            val updated = existing.copy(
                title = request.title.trim(),
                description = request.description?.trim(),
                location = request.location?.trim(),
                startDate = start,
                endDate = end,
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

            val futureEvents = groupEventRepository.findFutureEventsBySeries(
                groupId,
                existing.seriesId,
                LocalDateTime.now()
            )

            val updated = futureEvents.map { event ->
                event.copy(
                    title = request.title.trim(),
                    description = request.description?.trim(),
                    location = request.location?.trim(),
                    // 시간 차이 유지하면서 업데이트
                    startDate = event.startDate.toLocalDate().atTime(start.toLocalTime()),
                    endDate = event.endDate.toLocalDate().atTime(end.toLocalTime()),
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
```

---

#### 6. `deleteEvent()` - 일정 삭제
**목적**: "이 일정만" vs "반복 전체" 삭제

```kotlin
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

            val futureEvents = groupEventRepository.findFutureEventsBySeries(
                groupId,
                existing.seriesId,
                LocalDateTime.now()
            )

            groupEventRepository.deleteAll(futureEvents)
        }
    }
}
```

---

#### 7. 헬퍼 메서드들

```kotlin
// 그룹 멤버십 확인
private fun validateGroupMembership(user: User, groupId: Long) {
    if (!groupMemberRepository.existsByGroupIdAndUserId(groupId, user.id)) {
        throw BusinessException(ErrorCode.NOT_GROUP_MEMBER)
    }
}

// 일정 조회 + 권한 확인
private fun getEventWithPermissionCheck(
    user: User,
    groupId: Long,
    eventId: Long,
): GroupEvent {
    val event = groupEventRepository.findById(eventId)
        .orElseThrow { BusinessException(ErrorCode.EVENT_NOT_FOUND) }

    if (event.group.id != groupId) {
        throw BusinessException(ErrorCode.FORBIDDEN)
    }

    // 권한 확인
    if (event.isOfficial) {
        // 공식 일정: CALENDAR_MANAGE 필요
        permissionService.checkPermission(user, groupId, GroupPermission.CALENDAR_MANAGE)
    } else {
        // 비공식 일정: 작성자 본인 or CALENDAR_MANAGE
        val hasPermission = event.creator.id == user.id ||
            permissionService.hasPermission(user, groupId, GroupPermission.CALENDAR_MANAGE)

        if (!hasPermission) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
    }

    return event
}

// 시간 범위 검증
private fun validateTimeRange(start: LocalDateTime, end: LocalDateTime) {
    if (!end.isAfter(start)) {
        throw BusinessException(ErrorCode.INVALID_TIME_RANGE)
    }
}

// 색상 정규화
private fun normalizeColor(color: String): String {
    val value = color.trim()
    if (!COLOR_REGEX.matches(value)) {
        throw BusinessException(ErrorCode.INVALID_COLOR)
    }
    return value.uppercase()
}

// DTO 변환
private fun GroupEvent.toResponse(): GroupEventResponse =
    GroupEventResponse(
        id = id,
        groupId = group.id,
        groupName = group.name,
        creatorId = creator.id,
        creatorName = creator.name,
        title = title,
        description = description,
        location = location,
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
```

---

## 🌐 Step 5: GroupEventController 구현

### 📍 파일 위치
`backend/src/main/kotlin/org/castlekong/backend/controller/GroupEventController.kt`

### 📦 구현 내용

```kotlin
@RestController
@RequestMapping("/api/groups/{groupId}/events")
class GroupEventController(
    private val groupEventService: GroupEventService,
) {
    /**
     * GET /api/groups/{groupId}/events?startDate={date}&endDate={date}
     * 그룹 캘린더 일정 목록 조회
     */
    @GetMapping
    fun getEvents(
        @AuthenticationPrincipal user: User,
        @PathVariable groupId: Long,
        @RequestParam startDate: LocalDate,
        @RequestParam endDate: LocalDate,
    ): ApiResponse<List<GroupEventResponse>> {
        val events = groupEventService.getEventsByDateRange(user, groupId, startDate, endDate)
        return ApiResponse.success(events)
    }

    /**
     * POST /api/groups/{groupId}/events
     * 그룹 일정 생성 (단일 or 반복)
     */
    @PostMapping
    fun createEvent(
        @AuthenticationPrincipal user: User,
        @PathVariable groupId: Long,
        @Valid @RequestBody request: CreateGroupEventRequest,
    ): ApiResponse<List<GroupEventResponse>> {
        val events = groupEventService.createEvent(user, groupId, request)
        return ApiResponse.success(events)
    }

    /**
     * PUT /api/groups/{groupId}/events/{eventId}
     * 그룹 일정 수정 (이 일정만 or 반복 전체)
     */
    @PutMapping("/{eventId}")
    fun updateEvent(
        @AuthenticationPrincipal user: User,
        @PathVariable groupId: Long,
        @PathVariable eventId: Long,
        @Valid @RequestBody request: UpdateGroupEventRequest,
    ): ApiResponse<List<GroupEventResponse>> {
        val events = groupEventService.updateEvent(user, groupId, eventId, request)
        return ApiResponse.success(events)
    }

    /**
     * DELETE /api/groups/{groupId}/events/{eventId}?scope={THIS_EVENT|ALL_EVENTS}
     * 그룹 일정 삭제
     */
    @DeleteMapping("/{eventId}")
    fun deleteEvent(
        @AuthenticationPrincipal user: User,
        @PathVariable groupId: Long,
        @PathVariable eventId: Long,
        @RequestParam(defaultValue = "THIS_EVENT") scope: UpdateScope,
    ): ApiResponse<Unit> {
        groupEventService.deleteEvent(user, groupId, eventId, scope)
        return ApiResponse.success(Unit)
    }
}
```

**참고 파일**: `PersonalCalendarController.kt`, `ContentController.kt`

---

## 🧪 Step 6: 통합 테스트 작성

### 📍 파일 위치
`backend/src/test/kotlin/org/castlekong/backend/service/GroupEventServiceTest.kt`

### 🎯 테스트 시나리오 (10개)

```kotlin
@SpringBootTest
@Transactional
class GroupEventServiceTest {
    @Autowired
    private lateinit var groupEventService: GroupEventService

    @Autowired
    private lateinit var groupEventRepository: GroupEventRepository

    // ... 기타 Repository 주입

    @Test
    fun `단일 일정 생성 - 성공`() {
        // Given: 그룹 멤버가 비공식 일정 생성 요청
        // When: createEvent() 호출
        // Then: 1개 일정 생성 확인
    }

    @Test
    fun `반복 일정 생성 - DAILY - 성공`() {
        // Given: 11/1 ~ 11/30, 매일 반복
        // When: createEvent() 호출
        // Then: 30개 인스턴스 생성, 동일 seriesId 확인
    }

    @Test
    fun `반복 일정 생성 - WEEKLY - 성공`() {
        // Given: 11/1 ~ 11/30, 월/수/금 반복
        // When: createEvent() 호출
        // Then: 13개 인스턴스 생성 확인
    }

    @Test
    fun `공식 일정 생성 - CALENDAR_MANAGE 권한 없음 - 실패`() {
        // Given: 일반 멤버가 공식 일정 생성 시도
        // When: createEvent() 호출
        // Then: BusinessException(FORBIDDEN) 발생
    }

    @Test
    fun `비공식 일정 생성 - 그룹 멤버 아님 - 실패`() {
        // Given: 그룹 비멤버가 일정 생성 시도
        // When: createEvent() 호출
        // Then: BusinessException(NOT_GROUP_MEMBER) 발생
    }

    @Test
    fun `이 일정만 수정 - 성공`() {
        // Given: 반복 일정 중 1개만 수정
        // When: updateEvent(updateScope = THIS_EVENT)
        // Then: 해당 일정만 수정, 나머지는 원본 유지
    }

    @Test
    fun `반복 전체 수정 - 미래 일정만 수정 - 성공`() {
        // Given: 반복 일정 (과거 3개, 미래 7개)
        // When: updateEvent(updateScope = ALL_EVENTS)
        // Then: 미래 7개만 수정, 과거 3개는 원본 유지
    }

    @Test
    fun `이 일정만 삭제 - 성공`() {
        // Given: 반복 일정 중 1개만 삭제
        // When: deleteEvent(deleteScope = THIS_EVENT)
        // Then: 해당 일정만 삭제, 나머지는 유지
    }

    @Test
    fun `반복 전체 삭제 - 미래 일정만 삭제 - 성공`() {
        // Given: 반복 일정 (과거 3개, 미래 7개)
        // When: deleteEvent(deleteScope = ALL_EVENTS)
        // Then: 미래 7개만 삭제, 과거 3개는 유지
    }

    @Test
    fun `날짜 범위 조회 - 성공`() {
        // Given: 11/1 ~ 11/30 범위에 15개 일정
        // When: getEventsByDateRange(11/1, 11/30)
        // Then: 15개 일정 반환
    }
}
```

**참고 파일**: `ContentServiceTest.kt`, `GroupRoleServiceTest.kt`

---

## 🚨 주의사항 및 체크리스트

### ⚠️ 개발 시 주의사항

1. **JSON 직렬화/역직렬화**
   - `ObjectMapper`를 사용하여 `RecurrencePattern` ↔ JSON 변환
   - `recurrenceRule` 필드는 TEXT 타입 (최대 65,535자)

2. **Batch Insert 최적화**
   - `saveAll()` 사용 시 JPA는 기본적으로 개별 INSERT 실행
   - `spring.jpa.properties.hibernate.jdbc.batch_size=30` 설정 권장

3. **권한 체크 순서**
   - 먼저 그룹 멤버십 확인
   - 그 다음 공식/비공식에 따른 권한 확인
   - PermissionService.checkPermission()은 권한 없으면 예외 발생

4. **날짜 계산**
   - `LocalDate` vs `LocalDateTime` 구분 명확히
   - 반복 일정 생성 시 시간은 원본 유지

5. **트랜잭션 관리**
   - Service 클래스에 `@Transactional` 필수
   - 조회 메서드는 `@Transactional(readOnly = true)`

---

### ✅ 완료 체크리스트

#### Step 4: GroupEventService
- [ ] 의존성 주입 (5개)
- [ ] getEventsByDateRange() 구현
- [ ] createEvent() 구현
- [ ] createRecurringEvents() 구현
- [ ] createSingleEvent() 구현
- [ ] updateEvent() 구현
- [ ] deleteEvent() 구현
- [ ] 7개 헬퍼 메서드 구현

#### Step 5: GroupEventController
- [ ] 4개 엔드포인트 구현
- [ ] @AuthenticationPrincipal 사용
- [ ] @Valid 검증 적용
- [ ] ApiResponse 래퍼 사용

#### Step 6: 통합 테스트
- [ ] 10개 테스트 시나리오 작성
- [ ] 권한 시나리오 커버
- [ ] 반복 일정 시나리오 커버
- [ ] 예외 케이스 테스트

---

## 📚 참고 파일 위치

### 기존 구현 참고
- **PersonalEventService.kt**: 기본 CRUD 패턴
  - 위치: `backend/src/main/kotlin/org/castlekong/backend/service/`
  - 참고: 시간 검증, 색상 정규화, DTO 변환

- **GroupRoleService.kt**: 권한 체크 패턴
  - 위치: `backend/src/main/kotlin/org/castlekong/backend/service/`
  - 참고: PermissionService 사용법

- **ContentService.kt**: @Transactional 사용
  - 위치: `backend/src/main/kotlin/org/castlekong/backend/service/`
  - 참고: 복잡한 비즈니스 로직 구조

### 완료된 파일
- **GroupEvent.kt**: 엔티티
- **GroupEventRepository.kt**: Repository
- **GroupEventDto.kt**: DTO 클래스

### 설계 문서
- **docs/concepts/calendar-system.md**: 전체 시스템 개념
- **docs/concepts/calendar-design-decisions.md**: DD-CAL-001 ~ DD-CAL-008
- **docs/implementation/database-reference.md**: 데이터베이스 스키마
- **docs/features/group-calendar-development-plan.md**: 전체 개발 계획

---

## 🎯 다음 작업 시작 명령어

```bash
# 1. 이 문서를 읽고 컨텍스트 확인
cat docs/features/group-calendar-phase1-continue.md

# 2. 기존 완료 파일 확인
ls -la backend/src/main/kotlin/org/castlekong/backend/entity/GroupEvent.kt
ls -la backend/src/main/kotlin/org/castlekong/backend/repository/GroupEventRepository.kt
ls -la backend/src/main/kotlin/org/castlekong/backend/dto/GroupEventDto.kt

# 3. Step 4부터 시작
# "Step 4 GroupEventService 구현해줘" 요청
```

---

## 📝 예상 작업 시간

- **Step 4 (Service)**: 2-3시간 (가장 복잡)
- **Step 5 (Controller)**: 30분
- **Step 6 (테스트)**: 1-2시간

**총 예상 시간**: 4-6시간

---

**작성자**: Claude Code
**최종 수정**: 2025-10-12
