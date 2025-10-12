# 그룹 캘린더 개발 계획 (Group Calendar Development Plan)

> **버전**: 1.0
> **작성일**: 2025-10-12
> **상태**: 계획 확정
> **관련 문서**: [캘린더 시스템](../concepts/calendar-system.md) | [설계 결정사항](../concepts/calendar-design-decisions.md) | [장소 관리](../concepts/calendar-place-management.md)

---

## 1. 프로젝트 개요

### 1.1. 목표

개인 캘린더(시간표 + 캘린더) 구현을 기반으로, 그룹 내 멤버들이 함께 사용하는 **그룹 캘린더 시스템**을 구축합니다.

### 1.2. 현재 상태 (2025-10-12 기준)

**완료된 기능:**
- ✅ 개인 시간표 백엔드/프론트엔드 (PersonalSchedule)
- ✅ 개인 캘린더 백엔드/프론트엔드 (PersonalEvent)
- ✅ 캘린더 UI 컴포넌트 (Weekly View, Event Form 등)
- ✅ 권한 시스템 통합 (RBAC)

**미구현 기능:**
- ❌ 그룹 일정 (GroupEvent)
- ❌ 일정 참여자 (EventParticipant)
- ❌ 반복 일정 예외 (EventException)
- ❌ 장소 관리 (Place, PlaceReservation 등)
- ❌ 최적 시간 추천

### 1.3. MVP 범위 (Phase 1 목표)

**포함:**
- 그룹 일반 일정 (GENERAL) 생성/조회/수정/삭제
- 공식/비공식 일정 구분
- 반복 일정 (매일 / 요일 선택) 지원
- 채널 게시글 연동 (간단한 링크 방식)

**제외 (Phase 2 이후):**
- 대상 지정형 일정 (TARGETED)
- 참여 신청형 일정 (RSVP)
- 최적 시간 추천
- 장소 예약
- 반복 일정 예외 처리

---

## 2. 확정된 설계 결정사항

### 2.1. 권한 체계

| 권한 | 설명 | 적용 대상 |
|------|------|----------|
| `CALENDAR_MANAGE` | 캘린더 및 장소 관리 | 공식 일정 생성/수정/삭제, 장소 등록/관리 |
| 그룹 멤버 (`isMember()`) | 기본 권한 | 그룹 캘린더 조회, 비공식 일정 생성 |
| 작성자 본인 | 소유권 | 비공식 일정 수정/삭제 |

### 2.2. 일정 유형

| 유형 | 접근 권한 | 기능 범위 |
|------|----------|----------|
| **공식 일정** | `CALENDAR_MANAGE` 필요 | General/Targeted/RSVP, 장소 예약, 채널 연동 |
| **비공식 일정** | 그룹 멤버 누구나 생성 | General만, 장소 예약, 채널 연동 |

### 2.3. 반복 일정 설계

- **저장 방식**: 명시적 인스턴스 저장 (DD-CAL-002)
- **범위 지정**: 시작일 + 종료일 필수
- **패턴 선택**:
  - 매일 (DAILY): 시작일~종료일 매일 생성
  - 요일 선택 (WEEKLY): 월~일 체크박스로 선택
- **JSON 저장 형식**:
  ```json
  {"type": "DAILY"}
  {"type": "WEEKLY", "daysOfWeek": ["MONDAY", "WEDNESDAY", "FRIDAY"]}
  ```

### 2.4. 기술 스택

**백엔드:**
- Kotlin + Spring Boot 3.2+
- JPA (Hibernate)
- PostgreSQL (프로덕션) / H2 (개발)

**프론트엔드:**
- Flutter 3.16+ (Web)
- Provider (상태 관리)
- dio (HTTP 클라이언트)

---

## 3. Phase 1: MVP 백엔드 개발

### 3.1. 엔티티 생성 (Week 1-2)

**우선순위 1: 핵심 엔티티**

- [x] `GroupEvent` 엔티티 (스키마 설계 완료)
  - 파일 위치: `backend/src/main/kotlin/org/castlekong/backend/entity/GroupEvent.kt`
  - 필드: id, group, creator, title, description, location, startDate, endDate, isAllDay
  - 일정 분류: isOfficial, eventType (GENERAL/TARGETED/RSVP)
  - 반복 패턴: seriesId, recurrenceRule, recurrenceEndDate
  - 채널 연동: linkedChannel, linkedPost
  - 참여 제한: maxParticipants, currentParticipants

**우선순위 2: MVP 제외 (Phase 2)**

- [ ] `EventParticipant` 엔티티 (대상 지정형/참여 신청형 일정용)
- [ ] `EventException` 엔티티 (반복 일정 예외 처리용)
- [ ] `Place` 관련 엔티티 (장소 예약용)

**예상 작업 시간**: 1-2일

**기술적 고려사항:**
- `eventType` ENUM: MVP에서는 GENERAL만 사용하지만 확장 대비하여 정의
- `seriesId`: UUID 생성으로 동일 반복 패턴 그룹화
- `recurrenceRule`: JSON 문자열로 저장 (Jackson ObjectMapper 활용)
- Soft delete 고려: `deletedAt` 필드 추가 여부 검토

### 3.2. Repository 계층 (Week 1-2)

**파일 위치**: `backend/src/main/kotlin/org/castlekong/backend/repository/`

```kotlin
interface GroupEventRepository : JpaRepository<GroupEvent, Long> {
    // 기본 조회
    fun findByGroupId(groupId: Long): List<GroupEvent>

    // 날짜 범위 조회
    @Query("""
        SELECT e FROM GroupEvent e
        WHERE e.group.id = :groupId
        AND e.startDate >= :startDate
        AND e.endDate <= :endDate
        ORDER BY e.startDate
    """)
    fun findByGroupIdAndDateRange(
        groupId: Long,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<GroupEvent>

    // 반복 일정 조회
    fun findBySeriesId(seriesId: String): List<GroupEvent>

    // 공식/비공식 필터링
    fun findByGroupIdAndIsOfficial(groupId: Long, isOfficial: Boolean): List<GroupEvent>
}
```

**예상 작업 시간**: 1일

**기술적 고려사항:**
- Fetch Join 최적화: `@EntityGraph`로 N+1 문제 방지
- 인덱스 활용: `(group_id, start_date, end_date)` 복합 인덱스
- 페이징 지원: 추후 확장을 위해 PageRequest 파라미터 고려

### 3.3. Service 계층 (Week 2-3)

**파일 위치**: `backend/src/main/kotlin/org/castlekong/backend/service/GroupEventService.kt`

**핵심 비즈니스 로직:**

```kotlin
@Service
class GroupEventService(
    private val groupEventRepository: GroupEventRepository,
    private val permissionService: PermissionService,
    private val groupMemberRepository: GroupMemberRepository,
) {
    // 일정 생성 (단일 or 반복)
    @Transactional
    fun createEvent(groupId: Long, userId: Long, request: CreateGroupEventRequest): GroupEventDto {
        // 1. 권한 확인
        checkCreatePermission(groupId, userId, request.isOfficial)

        // 2. 반복 일정 여부 확인
        if (request.recurrenceRule != null) {
            // 반복 일정: 명시적 인스턴스 생성
            return createRecurringEvent(groupId, userId, request)
        } else {
            // 단일 일정
            return createSingleEvent(groupId, userId, request)
        }
    }

    // 반복 일정 생성
    private fun createRecurringEvent(...): GroupEventDto {
        val seriesId = UUID.randomUUID().toString()
        val instances = generateInstances(request.startDate, request.recurrenceEndDate, request.recurrenceRule)

        instances.forEach { date ->
            val event = GroupEvent(
                group = group,
                creator = user,
                title = request.title,
                startDate = date.atTime(request.startTime),
                endDate = date.atTime(request.endTime),
                seriesId = seriesId,
                recurrenceRule = objectMapper.writeValueAsString(request.recurrenceRule),
                recurrenceEndDate = request.recurrenceEndDate,
                // ...
            )
            groupEventRepository.save(event)
        }

        return instances.first().toDto()
    }

    // 인스턴스 생성 로직
    private fun generateInstances(startDate: LocalDate, endDate: LocalDate, rule: RecurrenceRule): List<LocalDate> {
        return when (rule.type) {
            RecurrenceType.DAILY -> {
                startDate.datesUntil(endDate.plusDays(1)).toList()
            }
            RecurrenceType.WEEKLY -> {
                val selectedDays = rule.daysOfWeek // [MONDAY, WEDNESDAY, FRIDAY]
                startDate.datesUntil(endDate.plusDays(1))
                    .filter { it.dayOfWeek in selectedDays }
                    .toList()
            }
        }
    }

    // 권한 확인
    private fun checkCreatePermission(groupId: Long, userId: Long, isOfficial: Boolean) {
        if (isOfficial) {
            // 공식 일정: CALENDAR_MANAGE 필요
            if (!permissionService.hasPermission(userId, groupId, GroupPermission.CALENDAR_MANAGE)) {
                throw ForbiddenException("공식 일정 생성 권한이 없습니다.")
            }
        } else {
            // 비공식 일정: 그룹 멤버면 OK
            if (!groupMemberRepository.existsByGroupIdAndUserId(groupId, userId)) {
                throw ForbiddenException("그룹 멤버가 아닙니다.")
            }
        }
    }

    // 일정 수정
    @Transactional
    fun updateEvent(eventId: Long, userId: Long, request: UpdateGroupEventRequest): GroupEventDto {
        val event = groupEventRepository.findById(eventId)
            .orElseThrow { NotFoundException("일정을 찾을 수 없습니다.") }

        checkUpdatePermission(event, userId)

        // 반복 일정 수정 (이 일정만 vs 전체)
        if (request.updateMode == UpdateMode.THIS_ONLY) {
            // 이 일정만 수정
            event.apply {
                title = request.title
                description = request.description
                // ...
            }
        } else if (request.updateMode == UpdateMode.ALL_IN_SERIES) {
            // 반복 전체 수정
            val allEvents = groupEventRepository.findBySeriesId(event.seriesId!!)
            allEvents.forEach { it.apply { /* 동일 필드 업데이트 */ } }
        }

        return event.toDto()
    }

    // 일정 삭제
    @Transactional
    fun deleteEvent(eventId: Long, userId: Long, deleteMode: DeleteMode) {
        val event = groupEventRepository.findById(eventId)
            .orElseThrow { NotFoundException("일정을 찾을 수 없습니다.") }

        checkDeletePermission(event, userId)

        when (deleteMode) {
            DeleteMode.THIS_ONLY -> groupEventRepository.delete(event)
            DeleteMode.ALL_IN_SERIES -> {
                val allEvents = groupEventRepository.findBySeriesId(event.seriesId!!)
                groupEventRepository.deleteAll(allEvents)
            }
        }
    }
}

// DTO 정의
data class CreateGroupEventRequest(
    val title: String,
    val description: String?,
    val location: String?,
    val startDate: LocalDate,
    val startTime: LocalTime,
    val endDate: LocalDate,
    val endTime: LocalTime,
    val isAllDay: Boolean = false,
    val isOfficial: Boolean = false,
    val eventType: EventType = EventType.GENERAL,

    // 반복 일정
    val recurrenceRule: RecurrenceRuleDto?,
    val recurrenceEndDate: LocalDate?,

    // 채널 연동
    val linkedChannelId: Long?
)

data class RecurrenceRuleDto(
    val type: RecurrenceType,
    val daysOfWeek: List<DayOfWeek>? = null
)

enum class RecurrenceType {
    DAILY, WEEKLY
}

enum class UpdateMode {
    THIS_ONLY, ALL_IN_SERIES
}

enum class DeleteMode {
    THIS_ONLY, ALL_IN_SERIES
}
```

**예상 작업 시간**: 3-4일

**기술적 고려사항:**
- 트랜잭션 범위: 반복 일정 생성 시 배치 INSERT 최적화 (JPA Batch Size 설정)
- 예외 처리: 반복 범위가 너무 길 경우 제한 (예: 최대 365일)
- 채널 연동: Post 자동 생성 로직은 별도 서비스로 분리 (`ChannelIntegrationService`)
- 권한 캐싱: PermissionService 내부에서 Redis 활용하여 반복 체크 최적화

**의존성:**
- `PermissionService.hasPermission(userId, groupId, permission)`
- `GroupMemberRepository.existsByGroupIdAndUserId(groupId, userId)`

### 3.4. Controller 계층 (Week 3)

**파일 위치**: `backend/src/main/kotlin/org/castlekong/backend/controller/GroupEventController.kt`

```kotlin
@RestController
@RequestMapping("/api/groups/{groupId}/events")
class GroupEventController(
    private val groupEventService: GroupEventService,
    private val authService: AuthService,
) {
    // 그룹 캘린더 조회
    @GetMapping
    fun getGroupEvents(
        @PathVariable groupId: Long,
        @RequestParam(required = false) startDate: LocalDate?,
        @RequestParam(required = false) endDate: LocalDate?,
    ): ApiResponse<List<GroupEventDto>> {
        val userId = authService.getCurrentUserId()

        val events = if (startDate != null && endDate != null) {
            groupEventService.getEventsByDateRange(groupId, userId, startDate, endDate)
        } else {
            groupEventService.getAllEvents(groupId, userId)
        }

        return ApiResponse.success(events)
    }

    // 일정 생성
    @PostMapping
    fun createEvent(
        @PathVariable groupId: Long,
        @RequestBody request: CreateGroupEventRequest,
    ): ApiResponse<GroupEventDto> {
        val userId = authService.getCurrentUserId()
        val event = groupEventService.createEvent(groupId, userId, request)
        return ApiResponse.success(event)
    }

    // 일정 수정
    @PutMapping("/{eventId}")
    fun updateEvent(
        @PathVariable groupId: Long,
        @PathVariable eventId: Long,
        @RequestBody request: UpdateGroupEventRequest,
    ): ApiResponse<GroupEventDto> {
        val userId = authService.getCurrentUserId()
        val event = groupEventService.updateEvent(eventId, userId, request)
        return ApiResponse.success(event)
    }

    // 일정 삭제
    @DeleteMapping("/{eventId}")
    fun deleteEvent(
        @PathVariable groupId: Long,
        @PathVariable eventId: Long,
        @RequestParam(defaultValue = "THIS_ONLY") deleteMode: DeleteMode,
    ): ApiResponse<Void> {
        val userId = authService.getCurrentUserId()
        groupEventService.deleteEvent(eventId, userId, deleteMode)
        return ApiResponse.success()
    }
}
```

**예상 작업 시간**: 1일

**기술적 고려사항:**
- `@PreAuthorize` 어노테이션은 사용하지 않고, Service 계층에서 권한 체크
- 날짜 파라미터: `@DateTimeFormat(iso = DateTimeFormat.ISO.DATE)` 어노테이션 활용
- 에러 응답: GlobalExceptionHandler에서 통일된 에러 형식 반환

### 3.5. 테스트 작성 (Week 3-4)

**Repository 테스트:**
```kotlin
@DataJpaTest
class GroupEventRepositoryTest {
    @Test
    fun `날짜 범위 조회 테스트`() {
        // given
        val group = createTestGroup()
        val event1 = createEvent(group, startDate = LocalDate.of(2025, 11, 1))
        val event2 = createEvent(group, startDate = LocalDate.of(2025, 11, 15))

        // when
        val result = groupEventRepository.findByGroupIdAndDateRange(
            group.id,
            LocalDateTime.of(2025, 11, 1, 0, 0),
            LocalDateTime.of(2025, 11, 30, 23, 59)
        )

        // then
        assertThat(result).hasSize(2)
        assertThat(result.first().startDate).isEqualTo(event1.startDate)
    }
}
```

**Service 통합 테스트:**
```kotlin
@SpringBootTest
@Transactional
class GroupEventServiceTest {
    @Test
    fun `반복 일정 생성 - 매일 패턴`() {
        // given
        val request = CreateGroupEventRequest(
            title = "매일 회의",
            startDate = LocalDate.of(2025, 11, 1),
            recurrenceEndDate = LocalDate.of(2025, 11, 7),
            recurrenceRule = RecurrenceRuleDto(type = RecurrenceType.DAILY)
        )

        // when
        groupEventService.createEvent(groupId, userId, request)

        // then
        val events = groupEventRepository.findByGroupId(groupId)
        assertThat(events).hasSize(7) // 11/1 ~ 11/7
    }

    @Test
    fun `반복 일정 생성 - 요일 선택 패턴`() {
        // given
        val request = CreateGroupEventRequest(
            title = "월수금 회의",
            startDate = LocalDate.of(2025, 11, 3), // 월요일
            recurrenceEndDate = LocalDate.of(2025, 11, 23),
            recurrenceRule = RecurrenceRuleDto(
                type = RecurrenceType.WEEKLY,
                daysOfWeek = listOf(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY)
            )
        )

        // when
        groupEventService.createEvent(groupId, userId, request)

        // then
        val events = groupEventRepository.findByGroupId(groupId)
        assertThat(events).hasSize(9) // 3주간 월수금
        assertThat(events.map { it.startDate.dayOfWeek }).containsOnly(
            DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY
        )
    }

    @Test
    fun `공식 일정 생성 권한 체크`() {
        // given
        val request = CreateGroupEventRequest(/* ... */, isOfficial = true)

        // when & then
        assertThatThrownBy {
            groupEventService.createEvent(groupId, normalUserId, request)
        }.isInstanceOf(ForbiddenException::class.java)
    }
}
```

**예상 작업 시간**: 2일

---

## 4. Phase 2: 프론트엔드 개발

### 4.1. 모델 클래스 (Week 4)

**파일 위치**: `frontend/lib/core/models/group_calendar_models.dart`

```dart
class GroupEvent {
  final int id;
  final int groupId;
  final int creatorId;
  final String title;
  final String? description;
  final String? location;
  final DateTime startDate;
  final DateTime endDate;
  final bool isAllDay;
  final bool isOfficial;
  final EventType eventType;

  // 반복 일정
  final String? seriesId;
  final RecurrenceRule? recurrenceRule;
  final DateTime? recurrenceEndDate;

  // 채널 연동
  final int? linkedChannelId;
  final int? linkedPostId;

  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupEvent({/* ... */});

  factory GroupEvent.fromJson(Map<String, dynamic> json) {
    return GroupEvent(
      id: json['id'],
      groupId: json['groupId'],
      creatorId: json['creatorId'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isAllDay: json['isAllDay'],
      isOfficial: json['isOfficial'],
      eventType: EventType.values.firstWhere((e) => e.name == json['eventType']),
      seriesId: json['seriesId'],
      recurrenceRule: json['recurrenceRule'] != null
          ? RecurrenceRule.fromJson(json['recurrenceRule'])
          : null,
      recurrenceEndDate: json['recurrenceEndDate'] != null
          ? DateTime.parse(json['recurrenceEndDate'])
          : null,
      linkedChannelId: json['linkedChannelId'],
      linkedPostId: json['linkedPostId'],
      color: json['color'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {/* ... */}
}

class RecurrenceRule {
  final RecurrenceType type;
  final List<DayOfWeek>? daysOfWeek;

  RecurrenceRule({required this.type, this.daysOfWeek});

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      type: RecurrenceType.values.firstWhere((e) => e.name == json['type']),
      daysOfWeek: json['daysOfWeek'] != null
          ? (json['daysOfWeek'] as List<dynamic>)
              .map((e) => DayOfWeek.values.firstWhere((d) => d.name == e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (daysOfWeek != null) 'daysOfWeek': daysOfWeek!.map((e) => e.name).toList(),
    };
  }
}

enum EventType { GENERAL, TARGETED, RSVP }
enum RecurrenceType { DAILY, WEEKLY }
enum DayOfWeek { MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY }
```

**예상 작업 시간**: 1일

### 4.2. API 서비스 (Week 4)

**파일 위치**: `frontend/lib/core/services/group_calendar_service.dart`

```dart
class GroupCalendarService {
  final Dio _dio;

  GroupCalendarService(this._dio);

  // 그룹 캘린더 조회
  Future<List<GroupEvent>> getGroupEvents(
    int groupId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _dio.get(
      '/api/groups/$groupId/events',
      queryParameters: {
        if (startDate != null) 'startDate': startDate.toIso8601String().split('T')[0],
        if (endDate != null) 'endDate': endDate.toIso8601String().split('T')[0],
      },
    );

    final List<dynamic> data = response.data['data'];
    return data.map((json) => GroupEvent.fromJson(json)).toList();
  }

  // 일정 생성
  Future<GroupEvent> createEvent(int groupId, CreateGroupEventRequest request) async {
    final response = await _dio.post(
      '/api/groups/$groupId/events',
      data: request.toJson(),
    );
    return GroupEvent.fromJson(response.data['data']);
  }

  // 일정 수정
  Future<GroupEvent> updateEvent(int groupId, int eventId, UpdateGroupEventRequest request) async {
    final response = await _dio.put(
      '/api/groups/$groupId/events/$eventId',
      data: request.toJson(),
    );
    return GroupEvent.fromJson(response.data['data']);
  }

  // 일정 삭제
  Future<void> deleteEvent(int groupId, int eventId, {DeleteMode deleteMode = DeleteMode.thisOnly}) async {
    await _dio.delete(
      '/api/groups/$groupId/events/$eventId',
      queryParameters: {'deleteMode': deleteMode.name.toUpperCase()},
    );
  }
}
```

**예상 작업 시간**: 1일

### 4.3. 상태 관리 (Week 5)

**파일 위치**: `frontend/lib/presentation/providers/group_calendar_provider.dart`

```dart
class GroupCalendarProvider extends ChangeNotifier {
  final GroupCalendarService _service;

  List<GroupEvent> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<GroupEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  GroupCalendarProvider(this._service);

  // 그룹 캘린더 로드
  Future<void> loadEvents(int groupId, DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _service.getGroupEvents(
        groupId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _errorMessage = '일정을 불러오는 데 실패했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 일정 생성
  Future<bool> createEvent(int groupId, CreateGroupEventRequest request) async {
    try {
      final newEvent = await _service.createEvent(groupId, request);
      _events.add(newEvent);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '일정 생성에 실패했습니다: $e';
      notifyListeners();
      return false;
    }
  }

  // 일정 삭제
  Future<bool> deleteEvent(int groupId, int eventId, {DeleteMode deleteMode = DeleteMode.thisOnly}) async {
    try {
      await _service.deleteEvent(groupId, eventId, deleteMode: deleteMode);

      if (deleteMode == DeleteMode.allInSeries) {
        final event = _events.firstWhere((e) => e.id == eventId);
        _events.removeWhere((e) => e.seriesId == event.seriesId);
      } else {
        _events.removeWhere((e) => e.id == eventId);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '일정 삭제에 실패했습니다: $e';
      notifyListeners();
      return false;
    }
  }
}
```

**예상 작업 시간**: 1일

### 4.4. UI 컴포넌트 (Week 5-6)

**4.4.1. 그룹 캘린더 페이지**

**파일 위치**: `frontend/lib/presentation/pages/group_calendar/group_calendar_page.dart`

```dart
class GroupCalendarPage extends StatefulWidget {
  final int groupId;

  GroupCalendarPage({required this.groupId});

  @override
  _GroupCalendarPageState createState() => _GroupCalendarPageState();
}

class _GroupCalendarPageState extends State<GroupCalendarPage> {
  DateTime _selectedDate = DateTime.now();
  CalendarView _currentView = CalendarView.month;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    final provider = Provider.of<GroupCalendarProvider>(context, listen: false);
    final startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    provider.loadEvents(widget.groupId, startDate, endDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('그룹 캘린더'),
        actions: [
          IconButton(
            icon: Icon(Icons.view_day),
            onPressed: () => setState(() => _currentView = CalendarView.day),
          ),
          IconButton(
            icon: Icon(Icons.view_week),
            onPressed: () => setState(() => _currentView = CalendarView.week),
          ),
          IconButton(
            icon: Icon(Icons.calendar_month),
            onPressed: () => setState(() => _currentView = CalendarView.month),
          ),
        ],
      ),
      body: Consumer<GroupCalendarProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }

          switch (_currentView) {
            case CalendarView.day:
              return DayView(events: provider.events, selectedDate: _selectedDate);
            case CalendarView.week:
              return WeekView(events: provider.events, selectedDate: _selectedDate);
            case CalendarView.month:
              return MonthView(events: provider.events, selectedDate: _selectedDate);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showCreateEventDialog(),
      ),
    );
  }

  void _showCreateEventDialog() {
    showDialog(
      context: context,
      builder: (context) => GroupEventFormDialog(groupId: widget.groupId),
    );
  }
}

enum CalendarView { day, week, month }
```

**4.4.2. 일정 생성 폼**

**파일 위치**: `frontend/lib/presentation/pages/group_calendar/widgets/group_event_form_dialog.dart`

```dart
class GroupEventFormDialog extends StatefulWidget {
  final int groupId;
  final GroupEvent? event; // 수정 시

  GroupEventFormDialog({required this.groupId, this.event});

  @override
  _GroupEventFormDialogState createState() => _GroupEventFormDialogState();
}

class _GroupEventFormDialogState extends State<GroupEventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: 0);

  bool _isOfficial = false;
  bool _isRecurring = false;
  RecurrenceType? _recurrenceType;
  List<DayOfWeek> _selectedDays = [];
  DateTime? _recurrenceEndDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.event == null ? '일정 생성' : '일정 수정'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 제목
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: '제목 *'),
                validator: (value) => value?.isEmpty ?? true ? '제목을 입력하세요' : null,
              ),
              SizedBox(height: 16),

              // 설명
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: '설명'),
                maxLines: 3,
              ),
              SizedBox(height: 16),

              // 시작 날짜/시간
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: '시작일 *'),
                        child: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (time != null) setState(() => _startTime = time);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: '시작 시간'),
                        child: Text(_startTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // 종료 날짜/시간
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) setState(() => _endDate = date);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: '종료일 *'),
                        child: Text(DateFormat('yyyy-MM-dd').format(_endDate)),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (time != null) setState(() => _endTime = time);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: '종료 시간'),
                        child: Text(_endTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // 공식 일정 여부
              SwitchListTile(
                title: Text('공식 일정'),
                subtitle: Text('CALENDAR_MANAGE 권한 필요'),
                value: _isOfficial,
                onChanged: (value) => setState(() => _isOfficial = value),
              ),

              // 반복 일정 여부
              SwitchListTile(
                title: Text('반복 일정'),
                value: _isRecurring,
                onChanged: (value) => setState(() {
                  _isRecurring = value;
                  if (!value) {
                    _recurrenceType = null;
                    _selectedDays = [];
                    _recurrenceEndDate = null;
                  }
                }),
              ),

              // 반복 패턴 선택
              if (_isRecurring) ...[
                DropdownButtonFormField<RecurrenceType>(
                  decoration: InputDecoration(labelText: '반복 패턴'),
                  value: _recurrenceType,
                  items: [
                    DropdownMenuItem(value: RecurrenceType.DAILY, child: Text('매일')),
                    DropdownMenuItem(value: RecurrenceType.WEEKLY, child: Text('요일 선택')),
                  ],
                  onChanged: (value) => setState(() => _recurrenceType = value),
                ),

                if (_recurrenceType == RecurrenceType.WEEKLY) ...[
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: DayOfWeek.values.map((day) {
                      return FilterChip(
                        label: Text(_getDayLabel(day)),
                        selected: _selectedDays.contains(day),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDays.add(day);
                            } else {
                              _selectedDays.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],

                SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _recurrenceEndDate ?? _endDate.add(Duration(days: 30)),
                      firstDate: _endDate,
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) setState(() => _recurrenceEndDate = date);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: '반복 종료일 *'),
                    child: Text(
                      _recurrenceEndDate != null
                          ? DateFormat('yyyy-MM-dd').format(_recurrenceEndDate!)
                          : '날짜 선택',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text('취소'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: Text(widget.event == null ? '생성' : '수정'),
          onPressed: _submit,
        ),
      ],
    );
  }

  String _getDayLabel(DayOfWeek day) {
    const labels = {
      DayOfWeek.MONDAY: '월',
      DayOfWeek.TUESDAY: '화',
      DayOfWeek.WEDNESDAY: '수',
      DayOfWeek.THURSDAY: '목',
      DayOfWeek.FRIDAY: '금',
      DayOfWeek.SATURDAY: '토',
      DayOfWeek.SUNDAY: '일',
    };
    return labels[day]!;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isRecurring && _recurrenceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('반복 패턴을 선택하세요')),
      );
      return;
    }

    if (_isRecurring && _recurrenceType == RecurrenceType.WEEKLY && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('요일을 하나 이상 선택하세요')),
      );
      return;
    }

    if (_isRecurring && _recurrenceEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('반복 종료일을 선택하세요')),
      );
      return;
    }

    final request = CreateGroupEventRequest(
      title: _titleController.text,
      description: _descriptionController.text,
      location: _locationController.text,
      startDate: _startDate,
      startTime: _startTime,
      endDate: _endDate,
      endTime: _endTime,
      isOfficial: _isOfficial,
      recurrenceRule: _isRecurring
          ? RecurrenceRuleDto(
              type: _recurrenceType!,
              daysOfWeek: _recurrenceType == RecurrenceType.WEEKLY ? _selectedDays : null,
            )
          : null,
      recurrenceEndDate: _recurrenceEndDate,
    );

    final provider = Provider.of<GroupCalendarProvider>(context, listen: false);
    final success = await provider.createEvent(widget.groupId, request);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일정이 생성되었습니다')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? '일정 생성에 실패했습니다')),
      );
    }
  }
}
```

**예상 작업 시간**: 3-4일 (캘린더 뷰 포함)

**기술적 고려사항:**
- 기존 개인 캘린더 컴포넌트 재사용: `TimetableWeeklyView` 등
- 공식/비공식 일정 시각적 구분: 배경색, 아이콘 등
- 반복 일정 표시: 시리즈 아이콘 추가

---

## 5. Phase 3: 통합 및 테스트

### 5.1. API 연동 테스트 (Week 6)

**테스트 시나리오:**

1. **기본 CRUD**
   - [ ] 일정 생성 (단일)
   - [ ] 일정 조회 (날짜 범위)
   - [ ] 일정 수정 (단일)
   - [ ] 일정 삭제 (단일)

2. **반복 일정**
   - [ ] 매일 반복 생성 (7일)
   - [ ] 요일 선택 반복 생성 (월수금, 3주)
   - [ ] 반복 전체 수정
   - [ ] 반복 전체 삭제

3. **권한 시나리오**
   - [ ] 공식 일정 생성 (CALENDAR_MANAGE 없음 → 403)
   - [ ] 비공식 일정 생성 (그룹 멤버 → 200)
   - [ ] 타인의 비공식 일정 수정 (권한 없음 → 403)
   - [ ] CALENDAR_MANAGE 보유자의 비공식 일정 수정 → 200

4. **엣지 케이스**
   - [ ] 시작일 > 종료일 → 400
   - [ ] 반복 범위 365일 초과 → 400
   - [ ] 존재하지 않는 그룹 → 404
   - [ ] 존재하지 않는 일정 → 404

**예상 작업 시간**: 2일

### 5.2. E2E 테스트 (Week 6)

**테스트 플로우:**

1. **일반 사용자 시나리오**
   - 그룹 선택 → 워크스페이스 진입
   - 사이드바에서 "캘린더" 메뉴 클릭
   - 그룹 캘린더 페이지 진입
   - 비공식 일정 생성 (단일)
   - 본인 일정 수정/삭제
   - 타인의 공식 일정 조회 (수정/삭제 버튼 비활성화 확인)

2. **관리자 시나리오**
   - 공식 일정 생성 (반복)
   - 반복 일정 중 하나 수정 ("이 일정만" 선택)
   - 반복 전체 삭제

**예상 작업 시간**: 1일

### 5.3. 성능 최적화 (Week 7)

**최적화 항목:**

1. **백엔드**
   - [ ] JPA N+1 문제 해결: `@EntityGraph` 적용
   - [ ] 반복 일정 Batch Insert: `spring.jpa.properties.hibernate.jdbc.batch_size=20`
   - [ ] 권한 캐싱: Redis 캐시 적용 (`@Cacheable`)

2. **프론트엔드**
   - [ ] 캘린더 렌더링 최적화: `ListView.builder` 활용
   - [ ] 이미지 로딩 최적화: `cached_network_image` 적용
   - [ ] 상태 관리 최적화: Selector 활용하여 불필요한 리빌드 방지

**예상 작업 시간**: 2일

---

## 6. 예상 일정 및 리소스

### 6.1. 전체 일정 (7주)

| 주차 | Phase | 작업 내용 | 예상 시간 |
|-----|-------|----------|----------|
| Week 1 | 백엔드 | 엔티티 생성, Repository | 3일 |
| Week 2 | 백엔드 | Service 계층 (반복 일정 로직) | 4일 |
| Week 3 | 백엔드 | Controller, 테스트 작성 | 4일 |
| Week 4 | 프론트엔드 | 모델, API 서비스, 상태 관리 | 3일 |
| Week 5 | 프론트엔드 | UI 컴포넌트 (캘린더 페이지) | 4일 |
| Week 6 | 통합/테스트 | API 연동, E2E 테스트 | 3일 |
| Week 7 | 최적화 | 성능 최적화, 버그 수정 | 2일 |

**총 예상 시간**: 23일 (약 4.5주, 여유 포함 7주)

### 6.2. 필요 리소스

- **백엔드 개발자**: 1명 (Kotlin/Spring Boot 경험)
- **프론트엔드 개발자**: 1명 (Flutter/Dart 경험)
- **QA**: 0.5명 (테스트 작성 지원)

### 6.3. 리스크 및 대응 방안

| 리스크 | 발생 가능성 | 영향도 | 대응 방안 |
|-------|----------|-------|----------|
| 반복 일정 로직 복잡도 | 중 | 높음 | 초기 설계 검증, 단위 테스트 철저히 |
| 권한 체크 누락 | 중 | 높음 | Service 계층에서 일관된 체크 패턴 적용 |
| 프론트 렌더링 성능 | 낮 | 중 | ListView.builder + Pagination 적용 |
| 일정 변경 시 충돌 | 낮 | 중 | 낙관적 락 적용 (Phase 2 이후) |

---

## 7. Phase 2 이후 확장 계획

### 7.1. Phase 2: 고급 일정 기능 (Week 8-10)

- [ ] 대상 지정형 일정 (TARGETED)
  - EventParticipant 엔티티 구현
  - 참여 상태 관리 (PENDING/ACCEPTED/DECLINED)
  - 불참 사유 수집
- [ ] 참여 신청형 일정 (RSVP)
  - 선착순 참여 신청
  - 정원 관리 (max_participants)
- [ ] 반복 일정 예외 처리
  - EventException 엔티티 구현
  - "이 일정만 수정" UI

### 7.2. Phase 3: 장소 관리 (Week 11-13)

- [ ] 장소 등록 (Place)
- [ ] 장소 사용 그룹 승인 (PlaceUsageGroup)
- [ ] 장소 예약 (PlaceReservation)
- [ ] 예약 가능 시간 조회 API
- [ ] 장소 캘린더 UI

### 7.3. Phase 4: 최적 시간 추천 (Week 14-15)

- [ ] 시간표 분석 로직
- [ ] 그룹 일정 충돌 분석
- [ ] 가능 인원 최대화 알고리즘
- [ ] 추천 결과 시각화 UI

### 7.4. Phase 5: 개인 캘린더 통합 (Week 16)

- [ ] 개인 캘린더에 그룹 일정 표시
- [ ] 참여한 일정만 필터링
- [ ] 시간표 + 개인 일정 + 그룹 일정 통합 뷰

---

## 8. 관련 문서

### 개념 문서
- [캘린더 시스템](../concepts/calendar-system.md) - 전체 시스템 개요
- [설계 결정사항](../concepts/calendar-design-decisions.md) - 아키텍처 결정
- [장소 관리](../concepts/calendar-place-management.md) - 장소 예약 권한

### 구현 가이드
- [개인 캘린더 MVP](personal-calendar-mvp.md) - 기존 구현 참조
- [백엔드 가이드](../implementation/backend-guide.md) - 3레이어 아키텍처
- [프론트엔드 가이드](../implementation/frontend-guide.md) - Flutter 구조
- [API 참조](../implementation/api-reference.md) - REST API 규칙
- [데이터베이스 참조](../implementation/database-reference.md) - 캘린더 스키마

### 기타
- [권한 시스템](../concepts/permission-system.md) - RBAC 통합
- [테스트 전략](../workflows/testing-strategy.md) - 테스트 작성 가이드

---

**다음 단계**: Phase 1 백엔드 개발 착수 (Week 1)
