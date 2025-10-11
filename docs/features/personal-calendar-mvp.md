# 개인 캘린더 시스템 MVP 기능 명세서

> **버전**: 1.0 (확정)
> **작성일**: 2025-10-12
> **상태**: 개발 준비 완료

---

## 1. 개요 (Overview)

### 1.1. 목적
대학생의 주간 고정 일정(시간표)과 단발성 이벤트(캘린더)를 분리하여 효율적으로 관리하는 개인 일정 관리 시스템

### 1.2. MVP 범위
- ✅ **포함**: 개인 시간표, 개인 캘린더
- ❌ **제외**: 그룹 캘린더, 장소 예약, 학교 강의 연동, 최적 시간 추천

### 1.3. 핵심 원칙
1. **명확한 분리**: 시간표(반복 일정) ≠ 캘린더(단발 이벤트)
2. **독립성**: 시간표와 캘린더는 서로 데이터를 참조하지 않음
3. **단순성**: 복합 표시 기능은 MVP 이후 고도화 단계에서 추가

---

## 2. 시스템 구조

### 2.1. 글로벌 네비게이션
```
[홈] [그룹] [캘린더] [프로필]
              ↑
         여기서 접근
```

### 2.2. 캘린더 메뉴 구조
```
┌─────────────────────────────────────┐
│  [시간표] [캘린더]  ← 탭 전환       │
├─────────────────────────────────────┤
│                                     │
│  [시간표 탭 - 초기 진입 화면]      │
│  - Weekly View (고정)               │
│  - 개인이 추가한 반복 일정 표시     │
│  - [수업 추가] [개인 일정 추가]     │
│                                     │
│  [캘린더 탭]                        │
│  - [일간|주간|월간] 뷰 선택기       │
│  - 단발성 이벤트 표시               │
│  - [이벤트 추가]                    │
│                                     │
└─────────────────────────────────────┘
```

---

## 3. 기능 상세 명세

### 3.1. 시간표 (Timetable)

#### 3.1.1. 특징
- **뷰**: Weekly View 고정 (월~일, 시간대별 그리드)
- **용도**: 매주 반복되는 고정 일정 관리
- **예시**: 수업, 아르바이트, 동아리 정기 회의
- **주간 시작**: 월요일

#### 3.1.2. 데이터 구조
```kotlin
// Backend Entity
@Entity
@Table(name = "personal_schedules")
data class PersonalSchedule(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @Column(nullable = false, length = 100)
    val title: String,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val dayOfWeek: DayOfWeek,  // MONDAY, TUESDAY, ...

    @Column(nullable = false)
    val startTime: LocalTime,

    @Column(nullable = false)
    val endTime: LocalTime,

    @Column(length = 200)
    val location: String? = null,

    @Column(nullable = false, length = 7)
    val color: String = "#3b82f6",  // 기본 파란색

    @Column(nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now()
)
```

```dart
// Frontend Model
class PersonalSchedule {
  final int id;
  final String title;
  final DayOfWeek dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? location;
  final Color color;

  PersonalSchedule({
    required this.id,
    required this.title,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.color,
  });
}

enum DayOfWeek {
  MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY
}
```

#### 3.1.3. CRUD 기능

**[생성] 개인 일정 추가**
- **트리거**: "개인 일정 추가" 버튼 클릭
- **입력 폼**:
  - 제목 (필수, 최대 100자)
  - 요일 (필수, 단일 선택 드롭다운)
  - 시작 시간 (필수, 시간 선택기)
  - 종료 시간 (필수, 시간 선택기)
  - 장소 (선택, 최대 200자)
  - 색상 (필수, 5가지 팔레트 제공)
- **검증**:
  - 시작 시간 < 종료 시간
  - 동일 요일에 시간 겹침 시 **경고 메시지 표시** (저장은 허용)
    - 경고 예시: "⚠️ 해당 시간대에 다른 일정이 있습니다. 계속 진행하시겠습니까?"

**[조회]**
- Weekly View에 요일별로 시간 블록 표시
- 시간 블록 클릭 시 상세 정보 표시 (모달 또는 사이드바)

**[수정]**
- 시간 블록 클릭 → 상세 모달 → "수정" 버튼
- 생성과 동일한 폼 제공

**[삭제]**
- 상세 모달 → "삭제" 버튼
- 확인 다이얼로그 표시: "정말 삭제하시겠습니까?"
- **즉시 삭제** (휴지통 기능 없음)

**[수업 추가 버튼]**
- 클릭 시 토스트 메시지: "🚧 추후 구현 예정입니다"
- UI는 표시하되 기능 비활성화

---

### 3.2. 캘린더 (Calendar)

#### 3.2.1. 특징
- **뷰**: Daily / Weekly / Monthly 전환 가능
- **용도**: 단발성 이벤트 관리
- **예시**: 병원 예약, 친구 약속, 시험 일정
- **주간 시작**: 월요일 (Weekly View)

#### 3.2.2. 데이터 구조
```kotlin
// Backend Entity
@Entity
@Table(name = "personal_events")
data class PersonalEvent(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @Column(nullable = false, length = 100)
    val title: String,

    @Column(nullable = false)
    val startDateTime: LocalDateTime,

    @Column(nullable = false)
    val endDateTime: LocalDateTime,

    @Column(columnDefinition = "TEXT")
    val description: String? = null,

    @Column(length = 200)
    val location: String? = null,

    @Column(nullable = false)
    val isAllDay: Boolean = false,

    @Column(nullable = false, length = 7)
    val color: String = "#3b82f6",

    @Column(nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now()
)
```

```dart
// Frontend Model
class PersonalEvent {
  final int id;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? description;
  final String? location;
  final bool isAllDay;
  final Color color;

  PersonalEvent({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.description,
    this.location,
    this.isAllDay = false,
    required this.color,
  });
}
```

#### 3.2.3. CRUD 기능

**[생성] 이벤트 추가**
- **트리거**:
  - "이벤트 추가" 버튼 클릭
  - 캘린더의 특정 날짜/시간 클릭 (빠른 생성)
- **입력 폼**:
  - 제목 (필수, 최대 100자)
  - 시작 일시 (필수, 날짜+시간 선택기)
  - 종료 일시 (필수, 날짜+시간 선택기)
  - 종일 여부 (체크박스, 선택 시 시간 선택 비활성화)
  - 설명 (선택, 다중 라인, 최대 2000자)
  - 장소 (선택, 최대 200자)
  - 색상 (필수, 5가지 팔레트 제공)
- **검증**:
  - 시작 일시 < 종료 일시
  - 과거 날짜 입력 가능 (제한 없음)
  - 겹침 경고 없음 (캘린더는 자유롭게 추가)

**[조회]**
- **Daily View**: 하루 일정을 시간별로 표시 (00:00 ~ 24:00)
- **Weekly View**: 주간 일정을 그리드로 표시 (시간표와 유사하되 반복 없음)
- **Monthly View**: 월간 달력에 이벤트 점/바 표시
- 이벤트 클릭 시 상세 정보 표시 (모달)

**[수정]**
- 이벤트 클릭 → 상세 모달 → "수정" 버튼
- 생성과 동일한 폼 제공

**[삭제]**
- 상세 모달 → "삭제" 버튼
- 확인 다이얼로그 표시: "정말 삭제하시겠습니까?"
- **즉시 삭제** (휴지통 기능 없음)

---

## 4. UI/UX 상세

### 4.1. 초기 진입 화면
- **기본 활성 탭**: "시간표"
- **마지막 선택 기억**: 세션 내에서만 유지 (LocalStorage 활용)

### 4.2. 색상 팔레트 (5가지)
```dart
// 공통 색상 팔레트
const List<Color> eventColors = [
  Color(0xFF3B82F6), // Blue (기본)
  Color(0xFFEF4444), // Red
  Color(0xFF10B981), // Green
  Color(0xFFF59E0B), // Amber
  Color(0xFF8B5CF6), // Purple
];
```

### 4.3. Weekly View 디자인 (시간표)
```
          2025년 10월 2주차
┌─────┬────────┬────────┬────────┬────────┬────────┬────────┬────────┐
│시간 │  월(6) │  화(7) │  수(8) │  목(9) │  금(10)│  토(11)│  일(12)│
├─────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
│09:00│ [DB설계]│        │ [DB설계]│        │ [DB설계]│        │        │
│     │ 09:00- │        │ 09:00- │        │ 09:00- │        │        │
│     │ 10:30  │        │ 10:30  │        │ 10:30  │        │        │
│     │ 공학관 │        │ 공학관 │        │ 공학관 │        │        │
├─────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
│11:00│        │ [알바] │        │ [알바] │        │        │        │
│     │        │ 11:00- │        │ 11:00- │        │        │        │
│     │        │ 13:00  │        │ 13:00  │        │        │        │
│     │        │ 카페   │        │ 카페   │        │        │        │
└─────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┘
```
- **시간 단위**: 30분 간격 표시
- **표시 범위**: 06:00 ~ 24:00 (세로 스크롤)
- **블록 스타일**:
  - 배경색: 사용자 지정 색상 (투명도 80%)
  - 테두리: 진한 색상
  - 텍스트: 제목 (볼드) + 시간 + 장소
- **상단 헤더**: 현재 주차 표시 + 좌우 화살표 (주간 이동)

### 4.4. Monthly View 디자인 (캘린더)
```
           2025년 10월                    [오늘]
┌────┬────┬────┬────┬────┬────┬────┐
│ 일 │ 월 │ 화 │ 수 │ 목 │ 금 │ 토 │
├────┼────┼────┼────┼────┼────┼────┤
│ 29 │ 30 │  1 │  2 │  3 │  4 │  5 │
│    │    │    │    │ •병원│    │    │
│    │    │    │    │14:00│    │    │
├────┼────┼────┼────┼────┼────┼────┤
│  6 │  7 │  8 │  9 │ 10 │ 11 │ 12 │
│    │    │    │    │    │    │ •여행│
│    │    │    │    │    │    │(종일)│
├────┼────┼────┼────┼────┼────┼────┤
│ 13 │ 14 │ 15 │ 16 │ 17 │ 18 │ 19 │
│•미팅│    │•시험│    │    │    │    │
│10:00│    │•과제│    │    │    │    │
│    │    │+1   │    │    │    │    │
└────┴────┴────┴────┴────┴────┴────┘
```
- **이벤트 표시**:
  - 1~2개: 제목 + 시간 표시
  - 3개 이상: 처음 2개 + "+N" 표시
- **종일 이벤트**: "(종일)" 텍스트 표시
- **날짜 클릭**: 해당 날짜의 Day View로 전환
- **상단**: 월 선택 드롭다운 + 좌우 화살표 + "오늘" 버튼

### 4.5. Daily View 디자인 (캘린더)
```
      2025년 10월 3일 (목)              [오늘]

┌─────┬──────────────────────────────┐
│09:00│                              │
├─────┤                              │
│10:00│ [병원 예약]                  │
│     │ 10:00 - 11:00                │
│     │ 📍 서울대병원                 │
├─────┼──────────────────────────────┤
│11:00│                              │
├─────┤                              │
│12:00│                              │
├─────┤                              │
│13:00│                              │
├─────┤                              │
│14:00│ [팀 미팅]                    │
│     │ 14:00 - 16:00                │
│     │ 📍 스터디룸 A                 │
│     │ 메모: 발표 자료 준비         │
├─────┼──────────────────────────────┤
│16:00│                              │
└─────┴──────────────────────────────┘
```
- **시간 단위**: 1시간 간격 (클릭 시 30분 단위 확대)
- **빈 시간대 클릭**: 해당 시간의 이벤트 추가 폼 자동 열림
- **상단**: 날짜 선택기 + 좌우 화살표 + "오늘" 버튼

### 4.6. 버튼 배치
```
[시간표 탭]
┌──────────────────────────────────────────┐
│  2025년 10월 2주차          [수업 추가]  │
│                         [개인 일정 추가] │
├──────────────────────────────────────────┤
│         Weekly View 그리드               │
└──────────────────────────────────────────┘

[캘린더 탭]
┌──────────────────────────────────────────┐
│  [일간|주간|월간]           [이벤트 추가]│
├──────────────────────────────────────────┤
│         선택된 뷰 표시                   │
└──────────────────────────────────────────┘
```

### 4.7. 모바일 반응형
- **태블릿 이상 (>768px)**: 전체 주간 표시
- **모바일 (<768px)**:
  - Weekly View: 하루씩 좌우 스와이프
  - Monthly View: 전체 달력 표시 (스크롤)
  - Daily View: 그대로 표시

---

## 5. API 엔드포인트

### 5.1. 시간표 API
```
GET    /api/timetable
       - 설명: 내 시간표 전체 조회
       - 권한: 인증된 사용자
       - 응답: List<PersonalScheduleDto>

POST   /api/timetable
       - 설명: 개인 일정 추가
       - 권한: 인증된 사용자
       - 요청: PersonalScheduleCreateDto
       - 응답: PersonalScheduleDto

PUT    /api/timetable/{id}
       - 설명: 개인 일정 수정
       - 권한: 작성자 본인
       - 요청: PersonalScheduleUpdateDto
       - 응답: PersonalScheduleDto

DELETE /api/timetable/{id}
       - 설명: 개인 일정 삭제
       - 권한: 작성자 본인
       - 응답: 204 No Content
```

### 5.2. 캘린더 API
```
GET    /api/calendar?start={startDate}&end={endDate}
       - 설명: 기간별 이벤트 조회
       - 권한: 인증된 사용자
       - 파라미터:
         - start: LocalDate (예: 2025-10-01)
         - end: LocalDate (예: 2025-10-31)
       - 응답: List<PersonalEventDto>

POST   /api/calendar
       - 설명: 이벤트 추가
       - 권한: 인증된 사용자
       - 요청: PersonalEventCreateDto
       - 응답: PersonalEventDto

PUT    /api/calendar/{id}
       - 설명: 이벤트 수정
       - 권한: 작성자 본인
       - 요청: PersonalEventUpdateDto
       - 응답: PersonalEventDto

DELETE /api/calendar/{id}
       - 설명: 이벤트 삭제
       - 권한: 작성자 본인
       - 응답: 204 No Content
```

### 5.3. DTO 정의
```kotlin
// 시간표 DTO
data class PersonalScheduleDto(
    val id: Long,
    val title: String,
    val dayOfWeek: DayOfWeek,
    val startTime: LocalTime,
    val endTime: LocalTime,
    val location: String?,
    val color: String
)

data class PersonalScheduleCreateDto(
    val title: String,
    val dayOfWeek: DayOfWeek,
    val startTime: LocalTime,
    val endTime: LocalTime,
    val location: String?,
    val color: String
)

data class PersonalScheduleUpdateDto(
    val title: String,
    val dayOfWeek: DayOfWeek,
    val startTime: LocalTime,
    val endTime: LocalTime,
    val location: String?,
    val color: String
)

// 캘린더 DTO
data class PersonalEventDto(
    val id: Long,
    val title: String,
    val startDateTime: LocalDateTime,
    val endDateTime: LocalDateTime,
    val description: String?,
    val location: String?,
    val isAllDay: Boolean,
    val color: String
)

data class PersonalEventCreateDto(
    val title: String,
    val startDateTime: LocalDateTime,
    val endDateTime: LocalDateTime,
    val description: String?,
    val location: String?,
    val isAllDay: Boolean,
    val color: String
)

data class PersonalEventUpdateDto(
    val title: String,
    val startDateTime: LocalDateTime,
    val endDateTime: LocalDateTime,
    val description: String?,
    val location: String?,
    val isAllDay: Boolean,
    val color: String
)
```

---

## 6. 데이터 모델 (ERD)

```
┌──────────────────────────────────────┐
│ users                                │
├──────────────────────────────────────┤
│ id (PK)                              │
│ email                                │
│ ...                                  │
└──────────────────────────────────────┘
         │                    │
         │ 1:N                │ 1:N
         ▼                    ▼
┌─────────────────────┐  ┌─────────────────────┐
│ personal_schedules  │  │ personal_events     │
├─────────────────────┤  ├─────────────────────┤
│ id (PK)             │  │ id (PK)             │
│ user_id (FK)        │  │ user_id (FK)        │
│ title               │  │ title               │
│ day_of_week         │  │ start_date_time     │
│ start_time          │  │ end_date_time       │
│ end_time            │  │ description         │
│ location            │  │ location            │
│ color               │  │ is_all_day          │
│ created_at          │  │ color               │
└─────────────────────┘  │ created_at          │
                         └─────────────────────┘
```

**주의**: 두 엔티티는 서로 참조하지 않음 (독립적)

---

## 7. 비즈니스 로직 상세

### 7.1. 시간 겹침 경고 로직
```kotlin
// PersonalScheduleService.kt
fun checkOverlap(userId: Long, dto: PersonalScheduleCreateDto): Boolean {
    val existingSchedules = repository.findByUserIdAndDayOfWeek(userId, dto.dayOfWeek)

    return existingSchedules.any { schedule ->
        // 새 일정의 시작 시간이 기존 일정 범위 내
        (dto.startTime >= schedule.startTime && dto.startTime < schedule.endTime) ||
        // 새 일정의 종료 시간이 기존 일정 범위 내
        (dto.endTime > schedule.startTime && dto.endTime <= schedule.endTime) ||
        // 새 일정이 기존 일정을 완전히 포함
        (dto.startTime <= schedule.startTime && dto.endTime >= schedule.endTime)
    }
}
```
- 겹침 발견 시 HTTP 200 + `{ "overlap": true, "message": "..." }` 응답
- 프론트엔드에서 경고 다이얼로그 표시 후 사용자 선택에 따라 재요청

### 7.2. 시간대 처리
- **서버**: 모든 시간을 `Asia/Seoul` 기준으로 저장
- **클라이언트**: 사용자의 로컬 시간대와 무관하게 `Asia/Seoul` 고정
- **이유**: 한국 대학 전용 시스템으로 단순화

### 7.3. 권한 확인
```kotlin
// SecurityService.kt
fun checkOwnership(userId: Long, scheduleId: Long) {
    val schedule = repository.findById(scheduleId)
        .orElseThrow { NotFoundException("일정을 찾을 수 없습니다.") }

    if (schedule.user.id != userId) {
        throw ForbiddenException("본인의 일정만 수정/삭제할 수 있습니다.")
    }
}
```

---

## 8. 에러 처리

### 8.1. 백엔드 에러 코드
```kotlin
// 400 Bad Request
CAL_001: "시작 시간은 종료 시간보다 이전이어야 합니다."
CAL_002: "제목은 1자 이상 100자 이하여야 합니다."
CAL_003: "색상 코드 형식이 올바르지 않습니다. (예: #3b82f6)"
CAL_004: "요일을 선택해주세요."

// 403 Forbidden
CAL_010: "본인의 일정만 수정할 수 있습니다."
CAL_011: "본인의 일정만 삭제할 수 있습니다."

// 404 Not Found
CAL_020: "일정을 찾을 수 없습니다."
CAL_021: "이벤트를 찾을 수 없습니다."
```

### 8.2. 프론트엔드 에러 표시
- **토스트 메시지**: 일반적인 성공/실패 알림
- **다이얼로그**: 중요한 경고 (시간 겹침, 삭제 확인)
- **폼 인라인 에러**: 입력 검증 실패 시 필드 하단에 빨간 텍스트

---

## 9. 향후 확장 계획 (Phase 2+)

### 9.1. 시간표 고도화
- [ ] 학교 강의 연동 (Course/CourseTimetable)
- [ ] 시간표 공유 기능 (URL 생성)
- [ ] 시간표 템플릿 (학기별 저장/복사)
- [ ] 시간표 이미지 내보내기

### 9.2. 캘린더 고도화
- [ ] 그룹 일정 표시 토글 (참여한 그룹 일정 오버레이)
- [ ] 시간표 항목을 캘린더 뷰에 표시 (토글)
- [ ] 반복 이벤트 생성 (매주/매월 패턴)
- [ ] 알림 설정 (푸시 알림, 10분 전 / 1시간 전)
- [ ] iCal 가져오기/내보내기 (.ics 파일)
- [ ] 캘린더 구독 기능 (외부 캘린더 동기화)

### 9.3. 통합 기능
- [ ] 최적 시간 추천 (그룹 일정 생성 시 시간표 분석)
- [ ] 그룹 캘린더 연동 (워크스페이스 내 캘린더 채널)
- [ ] 장소 예약 연동
- [ ] 통계 대시보드 (월별 일정 개수, 바쁜 요일 분석)

### 9.4. UX 개선
- [ ] 드래그 앤 드롭으로 일정 이동/시간 조정
- [ ] 일정 템플릿 (자주 추가하는 일정 저장)
- [ ] 일정 검색 기능
- [ ] 일정 필터링 (색상별, 장소별)
- [ ] 다크 모드 지원

---

## 10. 기술 스택

### 10.1. 백엔드
- **언어**: Kotlin 1.9+
- **프레임워크**: Spring Boot 3.2+
- **데이터베이스**:
  - 개발: H2 (In-Memory)
  - 프로덕션: PostgreSQL 15+
- **ORM**: JPA + Hibernate 6+
- **검증**: Jakarta Validation
- **문서화**: Swagger/OpenAPI 3.0

### 10.2. 프론트엔드
- **언어**: Dart 3.0+
- **프레임워크**: Flutter 3.16+ (Web)
- **상태 관리**: Provider
- **HTTP 클라이언트**: dio
- **캘린더 라이브러리**:
  - `table_calendar` ^3.0.0 (Monthly View)
  - 커스텀 구현 (Weekly/Daily View)
- **날짜/시간**: intl ^0.18.0

### 10.3. 개발 도구
- **백엔드 테스트**: JUnit 5, MockK
- **프론트엔드 테스트**: flutter_test
- **API 테스트**: Postman / REST Client
- **버전 관리**: Git + GitHub Flow

---

## 11. 개발 우선순위 및 일정

### Phase 1: 시간표 백엔드 (Week 1)
- [x] `PersonalSchedule` 엔티티 생성
- [x] Repository, Service, Controller 구현
- [x] 시간 겹침 체크 로직
- [x] 권한 확인 로직
- [x] API 통합 테스트 작성

### Phase 2: 시간표 프론트엔드 (Week 2)
- [ ] Weekly View UI 구현
- [ ] 개인 일정 추가/수정/삭제 폼
- [ ] 시간 겹침 경고 다이얼로그
- [ ] "수업 추가" 버튼 (비활성화)
- [ ] 색상 팔레트 UI

### Phase 3: 캘린더 백엔드 (Week 3)
- [ ] `PersonalEvent` 엔티티 생성
- [ ] Repository, Service, Controller 구현
- [ ] 기간별 조회 로직
- [ ] API 통합 테스트 작성

### Phase 4: 캘린더 프론트엔드 (Week 4-5)
- [ ] Monthly View UI (`table_calendar`)
- [ ] Daily View UI (커스텀)
- [ ] Weekly View UI (커스텀)
- [ ] 이벤트 추가/수정/삭제 폼
- [ ] 뷰 전환 토글
- [ ] 종일 이벤트 표시

### Phase 5: 통합 및 테스트 (Week 6)
- [ ] 글로벌 네비게이션 "캘린더" 메뉴 추가
- [ ] 탭 전환 로직 구현
- [ ] 반응형 레이아웃 테스트
- [ ] 엣지 케이스 처리
- [ ] E2E 테스트
- [ ] 성능 최적화

---

## 12. 테스트 시나리오

### 12.1. 시간표 테스트
- [ ] 개인 일정 추가 (정상)
- [ ] 시간 겹침 경고 발생 (정상)
- [ ] 시작 시간 > 종료 시간 (실패)
- [ ] 다른 사용자의 일정 수정 (403)
- [ ] 존재하지 않는 일정 삭제 (404)
- [ ] 월요일~일요일 모든 요일에 일정 추가
- [ ] 새벽 시간(00:00~06:00) 일정 추가

### 12.2. 캘린더 테스트
- [ ] 이벤트 추가 (정상)
- [ ] 종일 이벤트 추가 (정상)
- [ ] 과거 날짜 이벤트 추가 (정상)
- [ ] 다중 날짜 이벤트 (시작일 ≠ 종료일)
- [ ] 기간별 조회 (1개월, 1주일)
- [ ] Monthly View에서 3개 이상 이벤트 표시
- [ ] Daily View에서 빈 시간 클릭 → 이벤트 추가

### 12.3. 통합 테스트
- [ ] 시간표 탭 ↔ 캘린더 탭 전환
- [ ] 마지막 선택 탭 기억
- [ ] 모바일 반응형 (주간 뷰 스와이프)
- [ ] 로그아웃 후 재로그인 시 데이터 유지
- [ ] 동시 요청 처리 (낙관적 락)

---

## 13. 확정 결정사항 요약

| 항목 | 결정 내용 |
|------|-----------|
| **시간대** | `Asia/Seoul` 고정 (단순화) |
| **시간 겹침** | 경고 메시지 표시 후 저장 허용 |
| **색상 선택** | 5가지 사전 정의 팔레트 제공 |
| **주간 시작** | 월요일 |
| **모바일 반응형** | 주간 뷰 하루씩 스와이프 |
| **삭제 복구** | 즉시 삭제 (휴지통 없음) |
| **초기 진입** | "시간표" 탭 활성화 |
| **그룹 일정** | MVP 제외, Phase 2 추가 |
| **학교 강의 연동** | MVP 제외, Phase 2 추가 |

---

## 14. 관련 문서

- [캘린더 시스템 개념](../concepts/calendar-system.md) - 전체 시스템 개요
- [캘린더 설계 결정사항](../concepts/calendar-design-decisions.md) - 아키텍처 결정
- [백엔드 개발 가이드](../implementation/backend-guide.md) - 3레이어 아키텍처
- [프론트엔드 개발 가이드](../implementation/frontend-guide.md) - Flutter 구조
- [API 참조](../implementation/api-reference.md) - REST API 규칙
- [데이터베이스 참조](../implementation/database-reference.md) - 스키마 상세

---

**문서 확정 완료** ✅
다음 단계: Phase 1 백엔드 개발 시작
