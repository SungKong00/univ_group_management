# 그룹 일정-장소 예약 통합 설계

> **상위 문서**: [그룹 캘린더 개발 계획](group-calendar-development-plan.md) | [장소 캘린더 명세서](place-calendar-specification.md)
> **관련 문서**: [캘린더 시스템](../concepts/calendar-system.md) | [장소 관리](../concepts/calendar-place-management.md)
> **상태**: Phase 2 완료 (2025-10-18), Phase 3 진행 중
> **브랜치**: palce_callendar

## 📋 개요

**목적**: 그룹 일정 생성 시 장소 정보를 3가지 방식으로 설정할 수 있도록 통합
**배경**: 기존 location 필드(텍스트)와 Place 엔티티(실제 장소)를 모두 지원하여 유연성 제공
**범위**: GroupEvent 엔티티 수정 + PlaceReservation 연동 + API 확장

---

## 🎯 핵심 요구사항

### 3가지 장소 설정 모드

| 모드 | locationText | place | PlaceReservation | 사용 사례 |
|------|-------------|-------|------------------|-----------|
| **Mode A (장소 없음)** | null | null | 생성 안 함 | 온라인 회의, 장소 미정 일정 |
| **Mode B (수동 입력)** | "학생회관 2층" | null | 생성 안 함 | 등록되지 않은 장소, 외부 장소 |
| **Mode C (장소 선택)** | null | Place 객체 | 자동 생성 | 등록된 장소 예약 (충돌 검증) |

### 비즈니스 규칙

1. **상호 배타성**: locationText와 place는 동시에 값을 가질 수 없음 (validation 에러)
2. **장소 선택 시 자동 예약**: Mode C 선택 시 PlaceReservation 자동 생성
3. **예약 가능 검증**: 운영 시간 → 차단 시간 → 예약 충돌 3단계 검증
4. **사용 권한 확인**: PlaceUsageGroup APPROVED + 그룹 멤버십
5. **동시성 제어**: 낙관적 락 + 중복 검증 (FCFS)

---

## 💾 데이터 모델 설계

### 1.1. GroupEvent 엔티티 수정

**현재 상태** (group-event-place-integration.md 작성 기준):
```kotlin
@Entity
@Table(name = "group_events")
data class GroupEvent(
    // ... 기존 필드 ...
    @Column(length = 100)
    val location: String? = null, // 기존: 텍스트 장소
    // ...
)
```

**수정 후** (3가지 모드 지원):
```kotlin
@Entity
@Table(name = "group_events")
data class GroupEvent(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "creator_id", nullable = false)
    val creator: User,

    @Column(nullable = false, length = 200)
    val title: String,

    @Column(columnDefinition = "TEXT")
    val description: String? = null,

    // ===== 장소 통합 필드 (수정) =====
    @Column(name = "location_text", length = 100)
    val locationText: String? = null, // Mode B: 수동 입력 장소

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id")
    val place: Place? = null, // Mode C: 실제 장소 선택

    // ===== 기존 필드 =====
    @Column(name = "start_date", nullable = false)
    val startDate: LocalDateTime,

    @Column(name = "end_date", nullable = false)
    val endDate: LocalDateTime,

    @Column(name = "is_all_day", nullable = false)
    val isAllDay: Boolean = false,

    @Column(name = "is_official", nullable = false)
    val isOfficial: Boolean = false,

    @Column(name = "event_type", nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    val eventType: EventType = EventType.GENERAL,

    // 반복 일정 관련
    @Column(name = "series_id", length = 50)
    val seriesId: String? = null,

    @Column(name = "recurrence_rule", columnDefinition = "TEXT")
    val recurrenceRule: String? = null,

    @Column(length = 7, nullable = false)
    val color: String = "#3B82F6",

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),
)
```

### 1.2. PlaceReservation 연관 관계

**기존 PlaceReservation 엔티티** (변경 불필요):
```kotlin
@Entity
@Table(name = "place_reservations")
class PlaceReservation(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "event_id", nullable = false, unique = true)
    var event: GroupEvent, // 1:1 관계

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    var place: Place,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reserved_by", nullable = false)
    var reservedBy: User,

    @Version
    @Column(nullable = false)
    var version: Long = 0, // 낙관적 락

    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now(),
)
```

**연관 관계 정리**:
- GroupEvent ← 1:1 → PlaceReservation ← N:1 → Place
- GroupEvent.place: 참조용 (빠른 조회)
- PlaceReservation: 실제 예약 레코드 (version, reservedBy 등 추가 정보)

### 1.3. DB Migration 계획

**Flyway Migration 스크립트** (V{N}__add_place_integration_to_group_events.sql):
```sql
-- 1. 기존 location 컬럼 이름 변경
ALTER TABLE group_events RENAME COLUMN location TO location_text;

-- 2. place_id 외래키 추가
ALTER TABLE group_events ADD COLUMN place_id BIGINT;
ALTER TABLE group_events ADD CONSTRAINT fk_group_event_place
    FOREIGN KEY (place_id) REFERENCES places(id);

-- 3. 인덱스 추가 (성능 최적화)
CREATE INDEX idx_group_event_place ON group_events(place_id);
CREATE INDEX idx_group_event_location_type ON group_events(
    location_text IS NOT NULL AS location_type_text,
    place_id IS NOT NULL AS location_type_place
);
```

**마이그레이션 전략**:
1. **기존 데이터 호환성**: 기존 location 값은 locationText로 자동 변환 (이름 변경)
2. **NULL 허용**: locationText, place 모두 nullable → 기존 데이터 영향 없음
3. **점진적 적용**: 기존 일정은 Mode B로 동작, 신규 일정부터 3가지 모드 선택 가능

---

## 🔧 비즈니스 로직 설계

### 2.1. 모드 검증 로직

**GroupEventService.kt - validateLocationFields()**:
```kotlin
private fun validateLocationFields(locationText: String?, placeId: Long?) {
    // 규칙 1: 둘 다 값이 있으면 에러
    if (!locationText.isNullOrBlank() && placeId != null) {
        throw BusinessException(ErrorCode.INVALID_LOCATION_COMBINATION,
            "장소는 텍스트 입력 또는 장소 선택 중 하나만 가능합니다.")
    }

    // 규칙 2: Mode A (둘 다 null) - 허용
    // 규칙 3: Mode B (locationText만) - 허용
    // 규칙 4: Mode C (placeId만) - 허용
}
```

### 2.2. 장소 사용 권한 확인

**GroupEventService.kt - checkPlaceUsagePermission()**:
```kotlin
private fun checkPlaceUsagePermission(groupId: Long, placeId: Long) {
    // 1. PlaceUsageGroup 조회
    val usageGroup = placeUsageGroupRepository
        .findByPlaceIdAndGroupId(placeId, groupId)
        .orElseThrow {
            BusinessException(ErrorCode.PLACE_USAGE_NOT_REQUESTED,
                "이 장소에 대한 사용 신청이 없습니다.")
        }

    // 2. 승인 상태 확인
    if (usageGroup.status != UsageStatus.APPROVED) {
        throw BusinessException(ErrorCode.PLACE_USAGE_NOT_APPROVED,
            "이 장소는 아직 사용 승인이 되지 않았습니다. 상태: ${usageGroup.status}")
    }
}
```

### 2.3. 예약 가능 시간 검증 (3단계)

**PlaceReservationService.kt - validateReservationTime()**:
```kotlin
fun validateReservationTime(
    placeId: Long,
    startDate: LocalDateTime,
    endDate: LocalDateTime
): ReservationValidationResult {

    // Step 1: 운영 시간 확인
    val dayOfWeek = startDate.dayOfWeek
    val availabilities = placeAvailabilityRepository
        .findByPlaceIdAndDayOfWeek(placeId, dayOfWeek)

    if (availabilities.isEmpty()) {
        return ReservationValidationResult.error(
            ErrorCode.PLACE_NOT_OPERATING,
            "해당 요일에는 장소가 운영되지 않습니다."
        )
    }

    val startTime = startDate.toLocalTime()
    val endTime = endDate.toLocalTime()
    val isWithinOperatingHours = availabilities.any {
        startTime >= it.startTime && endTime <= it.endTime
    }

    if (!isWithinOperatingHours) {
        return ReservationValidationResult.error(
            ErrorCode.OUTSIDE_OPERATING_HOURS,
            "운영 시간(${availabilities.first().startTime}-${availabilities.first().endTime}) 외 시간입니다."
        )
    }

    // Step 2: 차단 시간 확인
    val blockedTime = placeBlockedTimeRepository
        .findConflictingBlockedTime(placeId, startDate, endDate)

    if (blockedTime != null) {
        return ReservationValidationResult.error(
            ErrorCode.PLACE_BLOCKED_TIME,
            "해당 시간대는 예약이 불가능합니다. 사유: ${blockedTime.reason ?: "관리자 차단"}"
        )
    }

    // Step 3: 예약 충돌 확인
    val conflictingReservation = placeReservationRepository
        .findConflictingReservation(placeId, startDate, endDate)

    if (conflictingReservation != null) {
        return ReservationValidationResult.error(
            ErrorCode.RESERVATION_CONFLICT,
            "이미 예약된 시간대입니다."
        )
    }

    return ReservationValidationResult.success()
}

data class ReservationValidationResult(
    val isValid: Boolean,
    val errorCode: ErrorCode? = null,
    val message: String? = null
) {
    companion object {
        fun success() = ReservationValidationResult(true)
        fun error(code: ErrorCode, msg: String) =
            ReservationValidationResult(false, code, msg)
    }
}
```

### 2.4. 반복 일정 + 장소 예약 처리

**GroupEventService.kt - createRecurringEventsWithPlace()**:
```kotlin
@Transactional
fun createRecurringEventsWithPlace(
    request: CreateGroupEventRequest,
    groupId: Long,
    userId: Long
): List<GroupEventResponse> {

    // 1. 장소 선택 시 권한 확인 (Mode C)
    if (request.placeId != null) {
        checkPlaceUsagePermission(groupId, request.placeId)
    }

    // 2. 반복 패턴 파싱
    val recurrenceRule = parseRecurrenceRule(request.recurrence)
    val eventDates = calculateEventDates(
        startDate = request.startDate,
        endDate = request.endDate,
        recurrenceRule = recurrenceRule
    )

    // 3. 장소 선택 시 모든 날짜에 대해 예약 가능 여부 검증 (Mode C)
    if (request.placeId != null) {
        eventDates.forEach { date ->
            val startDateTime = date.atTime(request.startTime)
            val endDateTime = date.atTime(request.endTime)

            val validationResult = placeReservationService
                .validateReservationTime(request.placeId, startDateTime, endDateTime)

            if (!validationResult.isValid) {
                throw BusinessException(
                    validationResult.errorCode!!,
                    "${date}의 예약 불가: ${validationResult.message}"
                )
            }
        }
    }

    // 4. 반복 일정 명시적 인스턴스 생성
    val seriesId = UUID.randomUUID().toString()
    val events = eventDates.map { date ->
        val event = createSingleEvent(request, groupId, userId, seriesId, date)
        val savedEvent = groupEventRepository.save(event)

        // 5. 장소 선택 시 PlaceReservation 자동 생성 (Mode C)
        if (request.placeId != null) {
            createPlaceReservation(savedEvent, request.placeId, userId)
        }

        savedEvent.toResponse()
    }

    return events
}
```

### 2.5. 장소 변경 로직

**GroupEventService.kt - updateEventPlace()**:
```kotlin
@Transactional
fun updateEventPlace(
    eventId: Long,
    newLocationText: String?,
    newPlaceId: Long?,
    userId: Long
): GroupEventResponse {

    // 1. 기존 일정 조회
    val event = groupEventRepository.findById(eventId)
        .orElseThrow { BusinessException(ErrorCode.EVENT_NOT_FOUND) }

    // 2. 모드 검증
    validateLocationFields(newLocationText, newPlaceId)

    // 3. 권한 확인 (작성자 또는 CALENDAR_MANAGE)
    checkEventUpdatePermission(event, userId)

    // 4. 기존 예약 삭제 (Mode C → Mode A/B 전환)
    if (event.place != null) {
        placeReservationRepository.deleteByEventId(eventId)
    }

    // 5. 새 장소 설정
    val updatedEvent = event.copy(
        locationText = newLocationText,
        place = if (newPlaceId != null) {
            placeRepository.findById(newPlaceId)
                .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }
        } else null,
        updatedAt = LocalDateTime.now()
    )

    val savedEvent = groupEventRepository.save(updatedEvent)

    // 6. 새 예약 생성 (Mode A/B → Mode C 전환)
    if (newPlaceId != null) {
        checkPlaceUsagePermission(savedEvent.group.id!!, newPlaceId)

        val validationResult = placeReservationService.validateReservationTime(
            newPlaceId, savedEvent.startDate, savedEvent.endDate
        )

        if (!validationResult.isValid) {
            throw BusinessException(validationResult.errorCode!!, validationResult.message)
        }

        createPlaceReservation(savedEvent, newPlaceId, userId)
    }

    return savedEvent.toResponse()
}
```

---

## 🔌 API 설계

### 3.1. 사용 가능한 장소 조회 API

```
GET /api/groups/{groupId}/available-places
```

**권한**: 그룹 멤버
**설명**: 현재 그룹이 예약 가능한 장소 목록 조회 (APPROVED 상태만)

**응답**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "building": "60주년 기념관",
      "roomNumber": "18203",
      "alias": "AISC랩실",
      "capacity": 30,
      "managingGroupName": "AISC 동아리",
      "usageStatus": "APPROVED",
      "description": "AI/SW 전용 랩실"
    }
  ],
  "error": null
}
```

**필터링 쿼리 파라미터** (선택):
- `building`: 건물명 필터
- `capacity`: 최소 수용 인원
- `date`: 특정 날짜 예약 가능 여부 확인

**구현**:
```kotlin
@GetMapping("/groups/{groupId}/available-places")
@PreAuthorize("@security.isMember(#groupId)")
fun getAvailablePlaces(
    @PathVariable groupId: Long,
    @RequestParam(required = false) building: String?,
    @RequestParam(required = false) capacity: Int?,
    @RequestParam(required = false) date: LocalDate?,
    authentication: Authentication
): ResponseEntity<ApiResponse<List<PlaceResponse>>> {
    val places = placeService.findAvailablePlaces(
        groupId, building, capacity, date
    )
    return ResponseEntity.ok(ApiResponse.success(places))
}
```

### 3.2. 일정 생성 API (장소 통합)

```
POST /api/groups/{groupId}/events
```

**권한**:
- 공식 일정 (isOfficial=true): `CALENDAR_MANAGE`
- 비공식 일정: 그룹 멤버

**요청 DTO 수정** (CreateGroupEventRequest):
```kotlin
data class CreateGroupEventRequest(
    @field:NotBlank val title: String,
    val description: String? = null,

    // ===== 장소 통합 (3가지 모드) =====
    val locationText: String? = null, // Mode B: 수동 입력
    val placeId: Long? = null,        // Mode C: 장소 선택

    @field:NotNull val startDate: LocalDate?,
    @field:NotNull val endDate: LocalDate?,
    @field:NotNull val startTime: LocalTime?,
    @field:NotNull val endTime: LocalTime?,
    val isAllDay: Boolean = false,
    val isOfficial: Boolean = false,
    val eventType: EventType = EventType.GENERAL,
    @field:NotBlank val color: String,
    val recurrence: RecurrencePattern? = null,
)
```

**요청 예시 (Mode A - 장소 없음)**:
```json
{
  "title": "온라인 총회",
  "description": "Zoom 링크: https://...",
  "locationText": null,
  "placeId": null,
  "startDate": "2025-11-20",
  "endDate": "2025-11-20",
  "startTime": "14:00:00",
  "endTime": "16:00:00",
  "isAllDay": false,
  "isOfficial": true,
  "color": "#3B82F6"
}
```

**요청 예시 (Mode B - 수동 입력)**:
```json
{
  "title": "외부 세미나",
  "locationText": "서울 역삼동 강남구청",
  "placeId": null,
  "startDate": "2025-11-25",
  "endDate": "2025-11-25",
  "startTime": "10:00:00",
  "endTime": "18:00:00",
  "isAllDay": false,
  "isOfficial": false,
  "color": "#10B981"
}
```

**요청 예시 (Mode C - 장소 선택)**:
```json
{
  "title": "정기 스터디",
  "placeId": 1,
  "locationText": null,
  "startDate": "2025-11-15",
  "endDate": "2025-12-31",
  "startTime": "18:00:00",
  "endTime": "21:00:00",
  "recurrence": {
    "type": "WEEKLY",
    "daysOfWeek": ["MONDAY", "WEDNESDAY"]
  },
  "color": "#F59E0B"
}
```

**응답** (GroupEventResponse):
```json
{
  "success": true,
  "data": {
    "id": 123,
    "groupId": 7,
    "groupName": "AISC 동아리",
    "creatorId": 5,
    "creatorName": "홍길동",
    "title": "정기 스터디",
    "description": null,
    "locationText": null,
    "place": {
      "id": 1,
      "building": "60주년 기념관",
      "roomNumber": "18203",
      "alias": "AISC랩실"
    },
    "placeReservation": {
      "id": 456,
      "reservedBy": "홍길동",
      "createdAt": "2025-10-18T14:30:00"
    },
    "startDate": "2025-11-15T18:00:00",
    "endDate": "2025-11-15T21:00:00",
    "isAllDay": false,
    "isOfficial": false,
    "eventType": "GENERAL",
    "seriesId": "uuid-1234-5678",
    "recurrenceRule": "{\"type\":\"WEEKLY\",\"daysOfWeek\":[\"MONDAY\",\"WEDNESDAY\"]}",
    "color": "#F59E0B",
    "createdAt": "2025-10-18T14:30:00",
    "updatedAt": "2025-10-18T14:30:00"
  },
  "error": null
}
```

**에러 코드**:

| ErrorCode | HTTP | 조건 |
|-----------|------|------|
| INVALID_LOCATION_COMBINATION | 400 | locationText + placeId 동시 입력 |
| PLACE_NOT_FOUND | 404 | placeId가 존재하지 않음 |
| PLACE_USAGE_NOT_APPROVED | 403 | 사용 승인되지 않은 장소 |
| OUTSIDE_OPERATING_HOURS | 400 | 운영 시간 외 |
| PLACE_BLOCKED_TIME | 400 | 차단 시간대 |
| RESERVATION_CONFLICT | 409 | 이미 예약된 시간 |

### 3.3. 일정 수정 API (장소 변경 지원)

```
PATCH /api/groups/{groupId}/events/{eventId}
```

**권한**:
- 공식 일정: `CALENDAR_MANAGE`
- 비공식 일정: 작성자 본인 또는 `CALENDAR_MANAGE`

**요청 DTO** (UpdateGroupEventRequest):
```kotlin
data class UpdateGroupEventRequest(
    @field:NotBlank val title: String,
    val description: String? = null,

    // ===== 장소 변경 =====
    val locationText: String? = null,
    val placeId: Long? = null,

    @field:NotNull val startTime: LocalTime?,
    @field:NotNull val endTime: LocalTime?,
    val isAllDay: Boolean = false,
    @field:NotBlank val color: String,
    val updateScope: UpdateScope = UpdateScope.THIS_EVENT,
)
```

**요청 예시** (Mode C → Mode B 전환):
```json
{
  "title": "정기 스터디 (장소 변경)",
  "locationText": "학생회관 2층",
  "placeId": null,
  "startTime": "18:00:00",
  "endTime": "21:00:00",
  "color": "#F59E0B",
  "updateScope": "THIS_EVENT"
}
```

**장소 변경 플로우**:
1. Mode C → Mode A/B: 기존 PlaceReservation 삭제
2. Mode A/B → Mode C: 예약 가능 여부 검증 → PlaceReservation 생성
3. Mode C → Mode C (다른 장소): 기존 예약 삭제 → 새 예약 생성

---

## 🔐 권한 설계

### 4.1. 장소 조회 권한

**API**: GET /api/groups/{groupId}/available-places
**권한**: 그룹 멤버 (`@PreAuthorize("@security.isMember(#groupId)")`)
**구현**:
```kotlin
@Component("security")
class GroupPermissionEvaluator {
    fun isMember(groupId: Long): Boolean {
        val user = getCurrentUser()
        return groupMemberRepository
            .findByGroupIdAndUserId(groupId, user.id).isPresent
    }
}
```

### 4.2. 장소 예약 권한

**자동 검증 로직** (서비스 레이어):
```kotlin
private fun checkPlaceReservationPermission(groupId: Long, placeId: Long, userId: Long) {
    // 1. 그룹 멤버 확인
    val member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
        .orElseThrow { BusinessException(ErrorCode.NOT_GROUP_MEMBER) }

    // 2. PlaceUsageGroup APPROVED 확인
    checkPlaceUsagePermission(groupId, placeId)

    // 별도 권한 불필요 (멤버십 + APPROVED 상태로 충분)
}
```

### 4.3. 권한 매트릭스

| 작업 | 권한 요구사항 | 비고 |
|------|--------------|------|
| 사용 가능한 장소 조회 | 그룹 멤버 | 모든 멤버 가능 |
| 일정 생성 (Mode A/B) | 그룹 멤버 (비공식) / CALENDAR_MANAGE (공식) | 장소 예약 없음 |
| 일정 생성 (Mode C) | 그룹 멤버 + PlaceUsageGroup APPROVED | 자동 예약 생성 |
| 일정 수정 (장소 변경) | 작성자 또는 CALENDAR_MANAGE | 예약 재검증 |
| 일정 삭제 | 작성자 또는 CALENDAR_MANAGE | 예약 CASCADE 삭제 |

---

## 📅 구현 계획 (Phase별)

### Phase 1: 데이터 모델 구현 (2-3시간)

**작업 내용**:
1. GroupEvent 엔티티 수정 (locationText, place 필드 추가)
2. Flyway Migration 스크립트 작성
3. DTO 클래스 수정 (CreateGroupEventRequest, UpdateGroupEventRequest)
4. Repository 메서드 추가 (findByPlaceId, findByLocationTextContaining)

**결과물**:
- V{N}__add_place_integration_to_group_events.sql
- GroupEvent.kt (수정)
- GroupEventDto.kt (수정)
- GroupEventRepository.kt (메서드 추가)

### Phase 2: 비즈니스 로직 구현 (3-4시간)

**작업 내용**:
1. GroupEventService - validateLocationFields() 구현
2. GroupEventService - checkPlaceUsagePermission() 구현
3. PlaceReservationService - validateReservationTime() 구현 (3단계 검증)
4. GroupEventService - createRecurringEventsWithPlace() 구현
5. GroupEventService - updateEventPlace() 구현 (장소 변경)
6. ErrorCode 추가 (INVALID_LOCATION_COMBINATION, PLACE_USAGE_NOT_APPROVED 등)

**결과물**:
- GroupEventService.kt (메서드 추가)
- PlaceReservationService.kt (검증 로직)
- ErrorCode.kt (에러 코드 추가)

### Phase 3: API 구현 (2-3시간)

**작업 내용**:
1. GroupController - getAvailablePlaces() 엔드포인트
2. GroupEventController - createEvent() 수정 (placeId 처리)
3. GroupEventController - updateEvent() 수정 (장소 변경)
4. ApiResponse 응답 형식 통일
5. @PreAuthorize 권한 어노테이션 적용

**결과물**:
- GroupController.kt (새 엔드포인트)
- GroupEventController.kt (수정)

### Phase 4: 테스트 및 문서화 (2-3시간)

**작업 내용**:
1. 단위 테스트 작성 (validateLocationFields, checkPlaceUsagePermission 등)
2. 통합 테스트 작성 (API 엔드포인트, 동시성 제어)
3. 에러 시나리오 테스트 (권한 부족, 예약 충돌, 차단 시간 등)
4. API 문서 업데이트 (api-reference.md)
5. 프론트엔드 가이드 작성 (이 문서 Section 8)

**결과물**:
- GroupEventServiceTest.kt
- GroupEventControllerIntegrationTest.kt
- PlaceReservationServiceTest.kt
- docs/implementation/api-reference.md (업데이트)

---

## ⚠️ 위험 요소 및 고려사항

### 6.1. 동시성 제어

**문제**: 여러 사용자가 동시에 같은 장소/시간 예약 시도

**해결책**: 낙관적 락 + 트랜잭션 격리
```kotlin
@Transactional
fun createPlaceReservation(...): PlaceReservation {
    // 1. 중복 검증 (비관적 락)
    val conflicts = placeReservationRepository
        .findConflictingReservationForUpdate(placeId, startDate, endDate)

    if (conflicts.isNotEmpty()) {
        throw BusinessException(ErrorCode.RESERVATION_CONFLICT)
    }

    // 2. 예약 생성 (낙관적 락 적용)
    try {
        val reservation = PlaceReservation(...)
        return placeReservationRepository.save(reservation)
    } catch (e: OptimisticLockException) {
        throw BusinessException(ErrorCode.RESERVATION_CONFLICT,
            "다른 사용자가 이미 예약했습니다. 다시 시도해주세요.")
    }
}
```

**Repository 메서드**:
```kotlin
@Query("""
    SELECT pr FROM PlaceReservation pr
    WHERE pr.place.id = :placeId
      AND pr.event.startDate < :endDate
      AND pr.event.endDate > :startDate
    FOR UPDATE
""")
fun findConflictingReservationForUpdate(
    placeId: Long,
    startDate: LocalDateTime,
    endDate: LocalDateTime
): List<PlaceReservation>
```

### 6.2. 반복 일정 충돌 처리

**시나리오**: 반복 일정 생성 시 특정 날짜만 예약 불가

**해결책**: 부분 성공 처리 + EventException 활용
```kotlin
fun createRecurringEventsWithPlace(...): RecurringEventsResult {
    val successEvents = mutableListOf<GroupEvent>()
    val failedDates = mutableListOf<FailedDate>()

    eventDates.forEach { date ->
        try {
            val event = createSingleEventWithReservation(...)
            successEvents.add(event)
        } catch (e: BusinessException) {
            failedDates.add(FailedDate(date, e.errorCode, e.message))
        }
    }

    if (successEvents.isEmpty()) {
        throw BusinessException(ErrorCode.NO_EVENTS_CREATED,
            "모든 날짜에 예약 실패. 다른 시간대를 선택해주세요.")
    }

    return RecurringEventsResult(successEvents, failedDates)
}

data class RecurringEventsResult(
    val createdEvents: List<GroupEvent>,
    val failedDates: List<FailedDate>
)

data class FailedDate(
    val date: LocalDate,
    val errorCode: ErrorCode,
    val reason: String?
)
```

**프론트엔드 처리**:
- 부분 성공 시 경고 메시지 표시
- 실패한 날짜 목록 표시 (예: "11/20, 11/27은 이미 예약됨")
- 재시도 또는 시간 변경 옵션 제공

### 6.3. 장소 삭제 시 기존 예약 처리

**문제**: Place Soft delete 시 연결된 미래 예약 처리

**정책**:
1. **Soft delete 진행**: deletedAt 설정
2. **신규 예약 차단**: isDeleted() 체크
3. **기존 예약 유지**: GroupEvent는 유지, PlaceReservation도 유지
4. **표시 처리**: 프론트엔드에서 "(삭제된 장소)" 표시

**구현**:
```kotlin
@Transactional
fun softDeletePlace(placeId: Long, userId: Long) {
    val place = placeRepository.findById(placeId)
        .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

    // 권한 확인
    checkCalendarManagePermission(userId, place.managingGroup.id!!)

    // Soft delete
    val deletedPlace = place.copy(deletedAt = LocalDateTime.now())
    placeRepository.save(deletedPlace)

    // 미래 예약 개수 조회
    val futureReservationsCount = placeReservationRepository
        .countFutureReservations(placeId, LocalDateTime.now())

    if (futureReservationsCount > 0) {
        logger.warn("Place $placeId deleted with $futureReservationsCount future reservations")
    }
}
```

---

## 🎨 프론트엔드 가이드 (개요)

### 7.1. UI 모드 선택

**LocationSelector 컴포넌트**:
```dart
enum LocationMode {
  none,   // Mode A
  text,   // Mode B
  place,  // Mode C
}

class LocationSelector extends StatefulWidget {
  final LocationMode initialMode;
  final String? initialLocationText;
  final Place? initialPlace;
  final Function(LocationMode mode, String? text, Place? place) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 모드 선택 탭
        SegmentedButton<LocationMode>(
          segments: [
            ButtonSegment(value: LocationMode.none, label: Text('장소 없음')),
            ButtonSegment(value: LocationMode.text, label: Text('직접 입력')),
            ButtonSegment(value: LocationMode.place, label: Text('장소 선택')),
          ],
          selected: {_selectedMode},
          onSelectionChanged: (Set<LocationMode> selected) {
            setState(() => _selectedMode = selected.first);
          },
        ),

        // 모드별 입력 필드
        if (_selectedMode == LocationMode.text)
          TextField(
            decoration: InputDecoration(labelText: '장소명'),
            onChanged: (value) => onChanged(LocationMode.text, value, null),
          ),

        if (_selectedMode == LocationMode.place)
          PlaceSelector(
            groupId: widget.groupId,
            onPlaceSelected: (place) =>
              onChanged(LocationMode.place, null, place),
          ),
      ],
    );
  }
}
```

### 7.2. PlaceSelector 컴포넌트 요구사항

**기능**:
1. 사용 가능한 장소 목록 조회 (GET /api/groups/{groupId}/available-places)
2. 건물별 그룹화 표시
3. 장소별 예약 가능 시간 실시간 표시 (선택된 날짜 기준)
4. 검색 및 필터링 (건물명, 수용 인원)

**API 통합 예시**:
```dart
class PlaceSelector extends StatelessWidget {
  final long groupId;
  final Function(Place) onPlaceSelected;

  Future<List<Place>> _fetchAvailablePlaces() async {
    final response = await apiClient.get(
      '/api/groups/$groupId/available-places',
      queryParameters: {
        'date': selectedDate.toIso8601String(),
      },
    );

    if (response.data['success']) {
      return (response.data['data'] as List)
        .map((json) => Place.fromJson(json))
        .toList();
    }

    throw Exception(response.data['error']['message']);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Place>>(
      future: _fetchAvailablePlaces(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final place = snapshot.data![index];
              return ListTile(
                title: Text('${place.building} ${place.roomNumber}'),
                subtitle: Text(place.alias ?? ''),
                trailing: Icon(Icons.chevron_right),
                onTap: () => onPlaceSelected(place),
              );
            },
          );
        }

        return CircularProgressIndicator();
      },
    );
  }
}
```

### 7.3. 일정 생성 API 통합

**CreateEventScreen.dart**:
```dart
Future<void> _createEvent() async {
  // 1. 모드별 요청 데이터 구성
  final requestData = {
    'title': _titleController.text,
    'description': _descriptionController.text,
    'startDate': _startDate.toIso8601String(),
    'endDate': _endDate.toIso8601String(),
    'startTime': _startTime.format24Hour(),
    'endTime': _endTime.format24Hour(),
    'isAllDay': _isAllDay,
    'isOfficial': _isOfficial,
    'color': _selectedColor.toHex(),
  };

  // 2. 장소 정보 추가 (모드별)
  switch (_locationMode) {
    case LocationMode.none:
      // locationText, placeId 모두 null (생략)
      break;
    case LocationMode.text:
      requestData['locationText'] = _locationTextController.text;
      break;
    case LocationMode.place:
      requestData['placeId'] = _selectedPlace.id;
      break;
  }

  // 3. 반복 일정 정보 추가 (선택 사항)
  if (_isRecurring) {
    requestData['recurrence'] = {
      'type': _recurrenceType.name,
      'daysOfWeek': _selectedDaysOfWeek.map((d) => d.name).toList(),
    };
  }

  // 4. API 호출
  try {
    final response = await apiClient.post(
      '/api/groups/$groupId/events',
      data: requestData,
    );

    if (response.data['success']) {
      showSuccessSnackbar('일정이 생성되었습니다.');
      Navigator.pop(context, true);
    }
  } on DioException catch (e) {
    final errorCode = e.response?.data['error']['code'];
    final errorMessage = e.response?.data['error']['message'];

    // 5. 에러별 처리
    switch (errorCode) {
      case 'INVALID_LOCATION_COMBINATION':
        showErrorDialog('장소는 텍스트 입력 또는 선택 중 하나만 가능합니다.');
        break;
      case 'PLACE_USAGE_NOT_APPROVED':
        showErrorDialog('이 장소는 아직 사용 승인이 되지 않았습니다.');
        break;
      case 'RESERVATION_CONFLICT':
        showErrorDialog('이미 예약된 시간대입니다. 다른 시간을 선택해주세요.');
        break;
      default:
        showErrorDialog(errorMessage ?? '일정 생성 실패');
    }
  }
}
```

### 7.4. 에러 핸들링 가이드

**에러 코드별 사용자 메시지**:

| ErrorCode | 사용자 메시지 | 액션 |
|-----------|--------------|------|
| INVALID_LOCATION_COMBINATION | "장소는 텍스트 입력 또는 선택 중 하나만 가능합니다." | 모드 재선택 유도 |
| PLACE_NOT_FOUND | "선택한 장소를 찾을 수 없습니다." | 장소 목록 새로고침 |
| PLACE_USAGE_NOT_APPROVED | "이 장소는 아직 사용 승인이 되지 않았습니다. 관리자에게 문의하세요." | 다른 장소 선택 유도 |
| OUTSIDE_OPERATING_HOURS | "운영 시간 외입니다. 운영 시간: 09:00-18:00" | 시간 조정 유도 |
| PLACE_BLOCKED_TIME | "해당 시간대는 예약이 불가능합니다. (사유: 유지보수)" | 다른 시간 선택 |
| RESERVATION_CONFLICT | "이미 예약된 시간대입니다. 다른 시간을 선택해주세요." | 시간 조정 또는 다른 장소 선택 |

---

## 📊 설계 결정사항

### DD-CAL-009: 장소 연동 방식 (3가지 모드 병행 지원)

**결정일**: 2025-10-18
**상태**: 확정

**배경**:
- 기존 GroupEvent.location 필드 (텍스트)와 새로운 Place 엔티티 (실제 장소)를 통합 필요
- 유연성 vs 제약 트레이드오프

**선택지**:
1. **Option A (채택)**: 3가지 모드 병행 지원
   - 장점: 최대 유연성, 기존 데이터 호환성, 점진적 마이그레이션
   - 단점: 복잡도 증가, validation 로직 필요
2. Option B: Place 엔티티만 사용 (강제)
   - 장점: 데이터 일관성, 장소 통계 정확성
   - 단점: 외부 장소 입력 불가, 사용자 불편
3. Option C: locationText만 사용 (Place 미연동)
   - 장점: 단순함
   - 단점: 예약 시스템 구축 불가

**근거**:
- 실제 사용 사례: 내부 장소 (예약 필요) + 외부 장소 (텍스트만) + 온라인 (장소 없음)
- 기존 데이터 마이그레이션 부담 최소화
- Phase별 점진적 도입 가능

**영향**:
- GroupEvent 엔티티에 locationText, place 2개 필드 추가
- CreateGroupEventRequest DTO 수정
- 프론트엔드 UI 모드 선택 기능 필요

---

## 📚 관련 문서

### 백엔드 구현
- [백엔드 가이드](../implementation/backend-guide.md)
- [API 참조](../implementation/api-reference.md)
- [데이터베이스 참조](../implementation/database-reference.md)

### 도메인 개념
- [캘린더 시스템](../concepts/calendar-system.md)
- [장소 관리](../concepts/calendar-place-management.md)
- [캘린더 설계 결정사항](../concepts/calendar-design-decisions.md)
- [권한 시스템](../concepts/permission-system.md)

### 기능 명세서
- [그룹 캘린더 개발 계획](group-calendar-development-plan.md)
- [장소 캘린더 명세서](place-calendar-specification.md)

---

## 📌 다음 단계

### 우선순위 1: Phase 1 구현 (데이터 모델)
- [ ] GroupEvent 엔티티 수정
- [ ] Flyway Migration 스크립트 작성
- [ ] DTO 클래스 수정
- [ ] Repository 메서드 추가

### 우선순위 2: Phase 2 구현 (비즈니스 로직) ✅ 완료 (2025-10-18)
- [x] 모드 검증 로직 구현 (validateLocationFields)
- [x] 장소 사용 권한 확인 로직 (hasReservationPermission)
- [x] 예약 가능 시간 3단계 검증 (validateReservation)
- [x] 반복 일정 + 장소 예약 통합 (createRecurringEventsWithPlace)
- [x] ValidationResult 유틸리티 클래스 추가

### 우선순위 3: Phase 3 구현 (API)
- [ ] GET /api/groups/{groupId}/available-places 구현
- [ ] POST /api/groups/{groupId}/events 수정 (placeId 처리)
- [ ] PATCH /api/groups/{groupId}/events/{eventId} 수정 (장소 변경)

### 우선순위 4: Phase 4 테스트 및 문서화
- [ ] 단위 테스트 작성
- [ ] 통합 테스트 작성
- [ ] API 문서 업데이트
- [ ] 프론트엔드 가이드 작성

---

**작성일**: 2025-10-18
**작성자**: Backend Architect Agent
**검토 필요**: 데이터 모델 설계, 동시성 제어 전략
