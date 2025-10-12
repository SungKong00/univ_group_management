# 공식 일정 추가 개발 로드맵 (Official Events Roadmap)

> **버전**: 1.0
> **작성일**: 2025-10-12
> **상태**: 설계 확정
> **관련 문서**: [그룹 캘린더 개발 계획](group-calendar-development-plan.md) | [캘린더 시스템](../concepts/calendar-system.md)

---

## 1. 현재 구현 상태 (Phase 1-6 완료)

### 1.1. 비공식 일정 구현 범위

**✅ 완료된 기능:**

| 기능 | 상태 | 설명 |
|------|------|------|
| **일정 생성** | ✅ | 제목, 설명, 장소, 시간, 색상 지정 |
| **일정 조회** | ✅ | 날짜 범위 필터링, 리스트 뷰 |
| **일정 수정** | ✅ | 단일/반복 전체 선택, 폼 재사용 |
| **일정 삭제** | ✅ | 확인 다이얼로그, 반복 일정 범위 선택 |
| **반복 일정** | ✅ | DAILY (매일), WEEKLY (요일 선택) |
| **권한 체크 (백엔드)** | ✅ | 그룹 멤버 확인, 작성자 본인 확인 |
| **상세 보기** | ✅ | DraggableScrollableSheet UI |
| **옵션 메뉴** | ✅ | 수정/삭제 버튼, 권한 기반 표시 |

**⚠️ 미완성 기능:**

| 기능 | 상태 | 설명 |
|------|------|------|
| **프론트엔드 권한 API 연동** | ⚠️ TODO | `_canModifyEvent()`에 Placeholder 존재 |
| **공식 일정 토글 동작** | ⚠️ TODO | CALENDAR_MANAGE 권한 체크 필요 |

### 1.2. 현재 데이터 모델

#### GroupEvent 엔티티 (이미 구현됨)

```kotlin
@Entity
@Table(name = "group_events")
data class GroupEvent(
    val id: Long,
    val group: Group,
    val creator: User,
    val title: String,
    val description: String?,
    val location: String?,
    val startDate: LocalDateTime,
    val endDate: LocalDateTime,
    val isAllDay: Boolean,

    // 공식/비공식 구분
    val isOfficial: Boolean = false,

    // EventType ENUM (확장 준비 완료)
    @Enumerated(EnumType.STRING)
    val eventType: EventType = EventType.GENERAL,

    // 반복 일정
    val seriesId: String?,
    val recurrenceRule: String?,

    val color: String = "#3B82F6",
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
)

enum class EventType {
    GENERAL,   // 일반 공지형 (현재 사용 중)
    TARGETED,  // 대상 지정형 (Phase 2)
    RSVP,      // 참여 신청형 (Phase 2)
}
```

**핵심 포인트:**
- ✅ `isOfficial` 필드 존재 → 공식/비공식 구분 가능
- ✅ `EventType` ENUM 정의됨 → TARGETED/RSVP 확장 준비 완료
- ❌ 참여자 관리 필드 없음 → Phase 2에서 추가

---

## 2. 공식 일정 확장 로드맵

### 2.1. 전체 Phase 개요

| Phase | 기능 | EventType | 참여자 관리 | 예상 시간 |
|-------|------|----------|-----------|----------|
| **2A** | 공식 일반 일정 | GENERAL | 없음 | 1.5일 |
| **2B** | 대상 지정형 일정 | TARGETED | 관리자가 초대 | 6.5일 |
| **2C** | 참여 신청형 일정 | RSVP | 사용자가 신청 | 3.5일 |
| **합계** | | | | **11.5일** (여유 포함 3주) |

---

## 3. Phase 2A: 공식 일반 일정 (1.5일)

### 3.1. 목표

비공식 일정과 동일한 기능이지만, **CALENDAR_MANAGE 권한**이 있는 사용자만 생성/수정/삭제 가능

### 3.2. 작업 목록

#### 백엔드 (변경 없음) ✅

**이유:**
- `GroupEventService.kt`의 `checkCalendarManagePermission()` 메서드가 이미 완벽하게 구현되어 있음
- API는 공식/비공식 일정을 모두 지원 중
- 추가 작업 불필요

#### 프론트엔드 (1.5일)

**1. 권한 API 엔드포인트 추가** (백엔드, 30분)

```kotlin
// GroupController.kt
@GetMapping("/{groupId}/permissions")
fun getMyPermissions(
    @PathVariable groupId: Long,
    authentication: Authentication
): ApiResponse<Set<GroupPermission>> {
    val user = userService.findByEmail(authentication.name)
    val permissions = permissionService.getEffective(groupId, user.id) { roleName ->
        getSystemRolePermissions(roleName)
    }
    return ApiResponse.success(permissions)
}
```

**2. 프론트엔드 권한 서비스 추가** (1시간)

```dart
// frontend/lib/core/services/group_permission_service.dart
class GroupPermissionService {
    final DioClient _dioClient;

    Future<Set<String>> getMyPermissions(int groupId) async {
        final response = await _dioClient.get('/groups/$groupId/permissions');
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
            return (json as List<dynamic>).cast<String>().toSet();
        });
        return apiResponse.data ?? {};
    }
}

// Provider 추가
final groupPermissionsProvider = FutureProvider.family<Set<String>, int>(
    (ref, groupId) async {
        final service = ref.read(groupPermissionServiceProvider);
        return service.getMyPermissions(groupId);
    },
);
```

**3. GroupCalendarPage 권한 체크 개선** (1시간)

```dart
// group_calendar_page.dart
bool _canModifyEvent(GroupEvent event) {
    final currentUser = ref.read(currentUserProvider);
    final permissions = ref.watch(groupPermissionsProvider(widget.groupId));

    if (currentUser == null) return false;

    // Official events: Require CALENDAR_MANAGE permission
    if (event.isOfficial) {
        return permissions.value?.contains('CALENDAR_MANAGE') ?? false;
    }

    // Unofficial events: Creator or CALENDAR_MANAGE
    return event.creatorId == currentUser.id ||
           (permissions.value?.contains('CALENDAR_MANAGE') ?? false);
}

Future<void> _showCreateDialog() async {
    final permissions = await ref.read(groupPermissionsProvider(widget.groupId).future);
    final canCreateOfficial = permissions.contains('CALENDAR_MANAGE');

    if (!mounted) return;

    showDialog(
        context: context,
        builder: (context) => GroupEventFormDialog(
            groupId: widget.groupId,
            canCreateOfficial: canCreateOfficial,  // 권한에 따라 토글 활성화
        ),
    );
}
```

**4. UI 테스트** (30분)

- 권한 있는 사용자: 공식 일정 토글 활성화 확인
- 권한 없는 사용자: 토글 비활성화 확인
- 공식 일정 생성/수정/삭제 권한 체크

### 3.3. 완료 조건

✅ 다음 기능이 모두 동작해야 합니다:
1. CALENDAR_MANAGE 권한 있는 사용자만 공식 일정 토글 활성화
2. 권한 없는 사용자가 공식 일정 생성 시도 시 403 에러
3. 공식 일정 수정/삭제는 CALENDAR_MANAGE 권한 보유자만 가능

---

## 4. Phase 2B: 대상 지정형 일정 (6.5일)

### 4.1. 목표

관리자가 특정 조건에 맞는 멤버들을 선택하여 일정에 초대하고, 참여 여부를 관리

### 4.2. 사용 시나리오

```
관리자: "1학년 오리엔테이션" 일정 생성
└─ 대상 조건: "역할 = 1학년"

백엔드: 조건에 맞는 User 계산
└─ 1학년 멤버 50명 자동 선택

백엔드: EventParticipant 자동 생성
└─ 50개 레코드 생성 (status = PENDING)

알림: 대상자들에게 알림 전송
└─ "새로운 일정에 초대되었습니다"

사용자: 참여 여부 응답
├─ 참여 → status = ACCEPTED
└─ 불참 → status = DECLINED (사유 입력)
```

### 4.3. 데이터 모델 확장

#### EventParticipant 엔티티 (신규 생성)

```kotlin
@Entity
@Table(
    name = "event_participants",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["event_id", "user_id"])
    ]
)
data class EventParticipant(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    // 어떤 일정인지
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "event_id", nullable = false)
    val event: GroupEvent,

    // 누가 참여하는지
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    // 참여 상태
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    val status: ParticipationStatus,

    // 불참 사유 (선택)
    @Column(length = 500)
    val declineReason: String? = null,

    @CreatedDate
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),
)

enum class ParticipationStatus {
    PENDING,   // 초대됨 (응답 대기)
    ACCEPTED,  // 참여 확정
    DECLINED,  // 불참
}
```

### 4.4. 작업 목록

#### 백엔드 (5.5일)

**1. EventParticipant 엔티티 및 Repository** (1일)

```kotlin
// backend/src/main/kotlin/org/castlekong/backend/entity/EventParticipant.kt
// backend/src/main/kotlin/org/castlekong/backend/repository/EventParticipantRepository.kt

interface EventParticipantRepository : JpaRepository<EventParticipant, Long> {
    fun findByEventId(eventId: Long): List<EventParticipant>
    fun findByEventIdAndUserId(eventId: Long, userId: Long): EventParticipant?
    fun existsByEventIdAndUserId(eventId: Long, userId: Long): Boolean
    fun countByEventIdAndStatus(eventId: Long, status: ParticipationStatus): Int
}
```

**2. EventParticipantService** (2일)

```kotlin
// backend/src/main/kotlin/org/castlekong/backend/service/EventParticipantService.kt

@Service
class EventParticipantService(
    private val participantRepository: EventParticipantRepository,
    private val groupMemberRepository: GroupMemberRepository,
) {
    // 참여자 초대 (TARGETED 일정용)
    @Transactional
    fun inviteParticipants(eventId: Long, userIds: List<Long>): List<EventParticipant> {
        val event = eventRepository.getReferenceById(eventId)

        return userIds.map { userId ->
            EventParticipant(
                event = event,
                user = userRepository.getReferenceById(userId),
                status = ParticipationStatus.PENDING
            )
        }.let { participantRepository.saveAll(it) }
    }

    // 참여 상태 업데이트
    @Transactional
    fun updateParticipationStatus(
        participantId: Long,
        userId: Long,
        status: ParticipationStatus,
        declineReason: String? = null
    ): EventParticipant {
        val participant = participantRepository.findById(participantId)
            .orElseThrow { NotFoundException("참여자 정보를 찾을 수 없습니다.") }

        // 권한 체크: 본인만 상태 변경 가능
        require(participant.user.id == userId) {
            "본인의 참여 상태만 변경할 수 있습니다."
        }

        return participant.copy(
            status = status,
            declineReason = if (status == ParticipationStatus.DECLINED) declineReason else null
        ).also { participantRepository.save(it) }
    }

    // 참여자 목록 조회
    fun getParticipants(eventId: Long): List<EventParticipantDto> {
        return participantRepository.findByEventId(eventId)
            .map { it.toDto() }
    }
}
```

**3. GroupEventService 확장** (1일)

```kotlin
// GroupEventService.kt 수정

fun createEvent(groupId: Long, userId: Long, request: CreateGroupEventRequest): GroupEventDto {
    // ... 기존 코드 (일정 생성)

    // TARGETED 일정 처리
    if (request.eventType == EventType.TARGETED && request.targetConditions != null) {
        val targetUsers = calculateTargetUsers(groupId, request.targetConditions)
        eventParticipantService.inviteParticipants(savedEvent.id!!, targetUsers.map { it.id })
    }

    return savedEvent.toDto()
}

// 대상자 계산 로직
private fun calculateTargetUsers(groupId: Long, conditions: TargetConditions): List<User> {
    val members = groupMemberRepository.findByGroupId(groupId)

    return members.filter { member ->
        when (conditions.filterType) {
            FilterType.BY_ROLE -> member.role.name in conditions.roleNames
            FilterType.BY_GRADE -> member.user.grade in conditions.grades
            FilterType.MANUAL -> member.user.id in conditions.userIds
        }
    }.map { it.user }
}
```

**4. API 추가** (0.5일)

```kotlin
// EventParticipantController.kt (신규)

@RestController
@RequestMapping("/api/groups/{groupId}/events/{eventId}/participants")
class EventParticipantController(
    private val participantService: EventParticipantService,
    private val authService: AuthService,
) {
    // 참여자 목록 조회
    @GetMapping
    fun getParticipants(
        @PathVariable groupId: Long,
        @PathVariable eventId: Long,
    ): ApiResponse<List<EventParticipantDto>> {
        val participants = participantService.getParticipants(eventId)
        return ApiResponse.success(participants)
    }

    // 참여 상태 업데이트
    @PutMapping("/{participantId}")
    fun updateParticipationStatus(
        @PathVariable groupId: Long,
        @PathVariable eventId: Long,
        @PathVariable participantId: Long,
        @RequestBody request: UpdateParticipationRequest,
    ): ApiResponse<EventParticipantDto> {
        val userId = authService.getCurrentUserId()
        val participant = participantService.updateParticipationStatus(
            participantId, userId, request.status, request.declineReason
        )
        return ApiResponse.success(participant)
    }
}
```

**5. 테스트 작성** (1일)

- 대상자 계산 로직 테스트
- 참여자 초대 테스트
- 참여 상태 업데이트 테스트
- 권한 체크 테스트

#### 프론트엔드 (2.5일)

**1. 대상 조건 선택 UI** (1일)

```dart
// frontend/lib/presentation/pages/workspace/calendar/widgets/target_condition_selector.dart

class TargetConditionSelector extends StatefulWidget {
    // 역할별 필터
    // 학년별 필터
    // 수동 선택 (멤버 리스트)
}
```

**2. 참여자 목록 UI** (1일)

```dart
// frontend/lib/presentation/pages/workspace/calendar/widgets/participant_list.dart

class ParticipantList extends StatelessWidget {
    // 참여 상태 표시 (PENDING/ACCEPTED/DECLINED)
    // 참여/불참 버튼
    // 불참 사유 입력
}
```

**3. 통합 테스트** (0.5일)

### 4.5. 완료 조건

✅ 다음 기능이 모두 동작해야 합니다:
1. TARGETED 일정 생성 시 대상자 자동 선택
2. 대상자에게 EventParticipant 자동 생성 (status=PENDING)
3. 사용자가 참여/불참 응답 가능
4. 참여자 목록 UI에서 상태 확인 가능

---

## 5. Phase 2C: 참여 신청형 일정 (3.5일)

### 5.1. 목표

사용자가 직접 참여 신청하는 선착순 일정 (정원 제한)

### 5.2. 사용 시나리오

```
관리자: "스터디 모집" 일정 생성
└─ 정원: 10명

사용자 A: "참여 신청" 버튼 클릭
└─ currentParticipants: 0 → 1

사용자 B: "참여 신청" 버튼 클릭
└─ currentParticipants: 1 → 2

...

사용자 K (11번째): "참여 신청" 시도
└─ 400 에러: "정원이 마감되었습니다"
```

### 5.3. 데이터 모델 확장

#### GroupEvent 엔티티 확장

```kotlin
@Entity
data class GroupEvent(
    // ... 기존 필드

    // RSVP용 필드 추가
    @Column(name = "max_participants")
    val maxParticipants: Int? = null,  // 정원

    @Column(name = "current_participants", nullable = false)
    var currentParticipants: Int = 0,  // 현재 신청자 수

    // 동시성 제어 (중요!)
    @Version
    var version: Long = 0,
)
```

### 5.4. 작업 목록

#### 백엔드 (2.5일)

**1. GroupEvent 엔티티 마이그레이션** (0.5일)

```sql
ALTER TABLE group_events ADD COLUMN max_participants INT;
ALTER TABLE group_events ADD COLUMN current_participants INT NOT NULL DEFAULT 0;
ALTER TABLE group_events ADD COLUMN version BIGINT NOT NULL DEFAULT 0;
```

**2. RSVP 로직 추가** (1일)

```kotlin
// EventParticipantService.kt 확장

@Transactional
fun applyToEvent(eventId: Long, userId: Long): EventParticipant {
    val event = eventRepository.findById(eventId)
        .orElseThrow { NotFoundException("일정을 찾을 수 없습니다.") }

    // RSVP 일정만 신청 가능
    require(event.eventType == EventType.RSVP) {
        "참여 신청형 일정이 아닙니다."
    }

    // 중복 신청 방지
    if (participantRepository.existsByEventIdAndUserId(eventId, userId)) {
        throw BadRequestException("이미 신청했습니다.")
    }

    // 정원 체크 (동시성 제어 - @Version)
    if (event.currentParticipants >= event.maxParticipants!!) {
        throw BadRequestException("정원이 마감되었습니다.")
    }

    // 참여자 생성 + 정원 증가
    val participant = EventParticipant(
        event = event,
        user = userRepository.getReferenceById(userId),
        status = ParticipationStatus.ACCEPTED  // RSVP는 즉시 승인
    )

    event.currentParticipants++  // 여기서 @Version이 자동 증가

    return participantRepository.save(participant)
}
```

**3. 동시성 제어 테스트** (1일)

```kotlin
@Test
fun `RSVP 정원 마감 시 동시 신청 테스트`() {
    // given: 정원 10명인 일정 생성
    val event = createRsvpEvent(maxParticipants = 10)

    // when: 11명이 동시에 신청
    val results = (1..11).map { userId ->
        CompletableFuture.supplyAsync {
            try {
                participantService.applyToEvent(event.id, userId)
                "SUCCESS"
            } catch (e: Exception) {
                "FAIL"
            }
        }
    }.map { it.join() }

    // then: 10명 성공, 1명 실패
    assertThat(results.count { it == "SUCCESS" }).isEqualTo(10)
    assertThat(results.count { it == "FAIL" }).isEqualTo(1)

    // 정원 확인
    val reloaded = eventRepository.findById(event.id).get()
    assertThat(reloaded.currentParticipants).isEqualTo(10)
}
```

#### 프론트엔드 (1.5일)

**1. 정원 입력 UI** (0.5일)

```dart
// group_event_form_dialog.dart 수정

if (_isOfficial && _eventType == EventType.rsvp)
    TextFormField(
        controller: _maxParticipantsController,
        decoration: InputDecoration(labelText: '정원 *'),
        keyboardType: TextInputType.number,
        validator: (value) {
            if (value == null || value.isEmpty) return '정원을 입력하세요';
            final num = int.tryParse(value);
            if (num == null || num <= 0) return '1 이상의 숫자를 입력하세요';
            return null;
        },
    ),
```

**2. 참여 신청 버튼** (0.5일)

```dart
// group_calendar_page.dart 수정

ElevatedButton.icon(
    icon: Icon(Icons.person_add),
    label: Text('참여 신청'),
    onPressed: event.currentParticipants < event.maxParticipants!
        ? () => _applyToEvent(event)
        : null,  // 정원 마감 시 비활성화
)
```

**3. 실시간 정원 표시** (0.5일)

```dart
// participant_list.dart

LinearProgressIndicator(
    value: event.currentParticipants / event.maxParticipants!,
)
Text('${event.currentParticipants} / ${event.maxParticipants}명 신청 완료')
```

### 5.5. 완료 조건

✅ 다음 기능이 모두 동작해야 합니다:
1. RSVP 일정 생성 시 정원 입력
2. 사용자가 참여 신청 버튼 클릭
3. 정원 내 신청 시 즉시 승인 (ACCEPTED)
4. 정원 초과 신청 시 400 에러
5. 동시 신청 시 동시성 제어 정상 작동

---

## 6. 동시성 제어 전략

### 6.1. 문제 상황

**Race Condition 시나리오:**

```
시간 T1: 사용자 A가 currentParticipants = 9 읽음
시간 T2: 사용자 B가 currentParticipants = 9 읽음 (동시에)
시간 T3: 사용자 A가 currentParticipants = 10으로 업데이트
시간 T4: 사용자 B가 currentParticipants = 10으로 업데이트

결과: 11명 신청됨! (정원 10명 초과)
```

### 6.2. 해결: 낙관적 락 (@Version)

**JPA @Version 어노테이션:**

```kotlin
@Entity
data class GroupEvent(
    // ... 기존 필드

    @Version
    var version: Long = 0,  // JPA가 자동 관리
)
```

**동작 방식:**

```
시간 T1: 사용자 A가 version=1 읽음
시간 T2: 사용자 B가 version=1 읽음
시간 T3: 사용자 A가 업데이트 성공 → version=2
시간 T4: 사용자 B가 업데이트 시도 → OptimisticLockException 발생
         (version=1로 업데이트하려 했지만, 이미 version=2로 변경됨)

결과: 사용자 B는 재시도 필요 → 최신 version=2 읽음 → "정원 마감" 에러
```

**예외 처리:**

```kotlin
try {
    participantService.applyToEvent(eventId, userId)
} catch (e: OptimisticLockException) {
    // 재시도 로직 (최대 3번)
    // 또는 사용자에게 "다시 시도해주세요" 메시지 표시
}
```

---

## 7. 예상 개발 일정 및 리소스

### 7.1. Phase별 일정

| Phase | 기능 | 백엔드 | 프론트엔드 | QA | 총 예상 |
|-------|------|--------|----------|----|----|
| **2A** | 공식 일반 일정 | 0일 (완료) | 1일 | 0.5일 | **1.5일** |
| **2B** | 대상 지정형 일정 | 5.5일 | 2.5일 | 1일 | **9일** → 6.5일 (병렬) |
| **2C** | 참여 신청형 일정 | 2.5일 | 1.5일 | 0.5일 | **4.5일** → 3.5일 (병렬) |
| **합계** | | **8일** | **5일** | **2일** | **11.5일** (순차) |

**여유 포함**: 약 **3주** (15일)

**병렬 작업 고려:**
- 백엔드와 프론트엔드 일부 작업 병렬 가능
- 실제 캘린더 시간: **2-2.5주** 예상

### 7.2. 필요 리소스

- **백엔드 개발자**: 1명 (Kotlin/Spring Boot)
- **프론트엔드 개발자**: 1명 (Flutter/Dart)
- **QA**: 0.5명 (테스트 작성 지원)

---

## 8. 리스크 및 대응 방안

### 8.1. 리스크 분석

| 리스크 | 발생 가능성 | 영향도 | 대응 방안 |
|-------|----------|-------|----------|
| **권한 API 연동 복잡도** | 낮음 | 중간 | 백엔드 API 이미 완성, 프론트엔드 작업만 필요 |
| **EventType별 UI 복잡도** | 중간 | 중간 | 조건부 렌더링으로 단일 폼 유지, 코드 중복 방지 |
| **참여자 관리 데이터 무결성** | 중간 | 높음 | 트랜잭션 범위 명확히 정의, 통합 테스트 철저히 |
| **RSVP 동시성 이슈** | 높음 | 높음 | ✅ @Version (낙관적 락) 적용, 재시도 로직 구현 |
| **기존 비공식 일정 영향** | 낮음 | 높음 | 백엔드 변경 없음, 프론트엔드 권한 체크만 추가 |
| **대상자 계산 로직 성능** | 중간 | 중간 | 인덱스 최적화, 캐싱 고려 (그룹 멤버 수 > 1000명) |

### 8.2. 대응 전략

#### 동시성 이슈 (RSVP)

**문제:** 정원 마감 시 여러 사용자가 동시에 신청할 수 있음

**해결:**
1. **@Version 낙관적 락** 적용 (구현 간단, 충돌 시 재시도)
2. **재시도 로직** (최대 3번)
3. **사용자 피드백**: "다시 시도해주세요" 메시지

#### 데이터 무결성

**문제:** EventParticipant와 GroupEvent 간 정합성

**해결:**
1. **트랜잭션 범위 명확히**: `@Transactional` 적용
2. **외래키 제약조건**: CASCADE 옵션 설정
3. **통합 테스트**: 참여자 생성 → 일정 삭제 시 자동 삭제 확인

#### UI 복잡도

**문제:** EventType별로 UI가 달라질 수 있음

**해결:**
1. **단일 폼 유지**: 조건부 렌더링으로 필드 추가
2. **컴포넌트 분리**: TargetConditionSelector, ParticipantList 등
3. **추상화 최소화**: YAGNI 원칙 준수

---

## 9. 테스트 전략

### 9.1. 단위 테스트

**백엔드:**
- `EventParticipantService.inviteParticipants()` - 대상자 초대
- `EventParticipantService.applyToEvent()` - RSVP 신청
- `calculateTargetUsers()` - 대상자 계산 로직
- 권한 체크 시나리오 (공식/비공식/EventType별)

**프론트엔드:**
- `EventPermissionHelper.canModify()` - 권한 체크
- 폼 유효성 검증 (정원 입력 등)

### 9.2. 통합 테스트

**시나리오:**

1. **TARGETED 일정 생성 → 참여자 자동 생성**
   ```kotlin
   @Test
   fun `대상 지정형 일정 생성 시 참여자 자동 생성`() {
       // given: 1학년 멤버 10명 존재
       // when: "1학년만" 조건으로 TARGETED 일정 생성
       // then: EventParticipant 10개 생성 확인
   }
   ```

2. **RSVP 정원 초과 시 실패**
   ```kotlin
   @Test
   fun `RSVP 정원 초과 시 신청 실패`() {
       // given: 정원 10명인 RSVP 일정 생성
       // when: 10명 신청 → 성공
       // when: 11번째 사용자 신청 → BadRequestException
   }
   ```

3. **낙관적 락 충돌 시나리오**
   ```kotlin
   @Test
   fun `동시 신청 시 낙관적 락 동작 확인`() {
       // given: 정원 10명, 현재 9명 신청
       // when: 2명이 동시에 신청
       // then: 1명 성공, 1명 OptimisticLockException
   }
   ```

### 9.3. E2E 테스트

**시나리오:**

1. **관리자 → TARGETED 일정 생성**
   - 대상 조건 선택 (1학년만)
   - 일정 생성 클릭
   - 참여자 목록 확인 (1학년 멤버만)

2. **멤버 → 참여 여부 응답**
   - 초대된 일정 확인
   - "참여" 버튼 클릭 → status = ACCEPTED
   - 다시 접속 → 상태 유지 확인

3. **RSVP 선착순 신청**
   - 일정 목록에서 RSVP 일정 확인
   - "참여 신청" 버튼 클릭
   - 정원 표시 업데이트 (7/10명)
   - 정원 마감 시 버튼 비활성화

---

## 10. 다음 단계 (Immediate Actions)

### 10.1. 우선순위 1: 비공식 일정 검증 (30분)

**목적:** Phase 6 완료 후 현재 비공식 일정 동작 확인

**작업:**
1. 브라우저에서 수동 테스트
   - 비공식 일정 생성 → 조회
   - 본인 일정 수정 → 삭제
   - 타인 일정 수정 시도 → 권한 없음 확인

2. 반복 일정 테스트
   - DAILY 반복 생성 → 목록 확인
   - WEEKLY 반복 생성 → 목록 확인
   - "이 일정만" 수정 → 반복 전체 수정 비교

### 10.2. 우선순위 2: 권한 API 연동 (Phase 2A 시작) (3시간)

**작업 목록:**
1. 백엔드 권한 API 추가 (30분)
2. 프론트엔드 권한 서비스 추가 (1시간)
3. GroupCalendarPage 권한 체크 개선 (1시간)
4. 통합 테스트 (30분)

### 10.3. 우선순위 3: E2E 테스트 (확장 범위) (3-4시간)

**작업 목록:**
1. 단일/반복 일정 CRUD 전체 플로우
2. 권한 시나리오 테스트
3. 엣지 케이스 검증

---

## 11. 관련 문서

### 개념 문서
- [캘린더 시스템](../concepts/calendar-system.md) - 전체 시스템 개요
- [권한 시스템](../concepts/permission-system.md) - RBAC 통합

### 구현 가이드
- [그룹 캘린더 개발 계획](group-calendar-development-plan.md) - 전체 개발 계획
- [백엔드 가이드](../implementation/backend-guide.md) - 3레이어 아키텍처
- [프론트엔드 가이드](../implementation/frontend-guide.md) - Flutter 구조

### 기타
- [Phase 6 완료 보고](group-calendar-phase6-edit-delete.md) - 일정 수정/삭제 구현
- [테스트 전략](../workflows/testing-strategy.md) - 테스트 작성 가이드

---

**다음 단계:** 우선순위 1 (비공식 일정 검증) 또는 우선순위 2 (권한 API 연동) 선택
