# 장소 시간 관리 시스템 재설계 제안

> **작성일**: 2025-10-19
> **상태**: 설계 검토 중
> **관련 문서**: [장소 캘린더 명세서](place-calendar-specification.md), [장소 관리 개념](../concepts/calendar-place-management.md)

## 📋 목차
1. [현재 시스템 분석](#1-현재-시스템-분석)
2. [변경 요청사항](#2-변경-요청사항)
3. [새로운 데이터 모델 설계](#3-새로운-데이터-모델-설계)
4. [API 설계](#4-api-설계)
5. [비즈니스 로직](#5-비즈니스-로직)
6. [마이그레이션 전략](#6-마이그레이션-전략)
7. [구현 로드맵](#7-구현-로드맵)
8. [의논 사항](#8-의논-사항)

---

## 1. 현재 시스템 분석

### 1.1. 현재 데이터 모델

#### PlaceAvailability (운영 시간)
```kotlin
@Entity
@Table(name = "place_availabilities")
class PlaceAvailability(
    var id: Long = 0,
    var place: Place,
    var dayOfWeek: DayOfWeek,     // 요일
    var startTime: LocalTime,      // 시작 시간
    var endTime: LocalTime,        // 종료 시간
    var displayOrder: Int = 0      // 표시 순서
)
```

**현재 방식**: 요일별로 여러 시간대를 설정 가능
- 예: 월요일 09:00-12:00, 월요일 14:00-18:00 (2개 레코드)

#### PlaceBlockedTime (차단 시간)
```kotlin
@Entity
@Table(name = "place_blocked_times")
class PlaceBlockedTime(
    var id: Long = 0,
    var place: Place,
    var startDatetime: LocalDateTime,  // 차단 시작 일시
    var endDatetime: LocalDateTime,    // 차단 종료 일시
    var blockType: BlockType,          // 차단 유형
    var reason: String? = null
)
```

**현재 방식**: 특정 날짜/시간대를 예약 불가능하게 차단
- PlaceAvailability가 정의하는 운영 시간 내에서 추가 차단

### 1.2. 현재 시스템의 제약사항

#### 문제점 1: 복잡한 운영 시간 설정
- 여러 시간대를 설정하려면 각각 별도의 레코드 생성 필요
- UI에서 관리하기 복잡함 (레코드 추가/삭제 반복)

#### 문제점 2: 주간 정책 부재
- "점심시간은 매주 12:00-13:00 예약 불가"와 같은 반복 정책을 표현하기 어려움
- 매주 반복되는 휴게시간을 일일이 PlaceBlockedTime으로 등록해야 함

#### 문제점 3: 임시 휴무 관리의 불명확성
- PlaceBlockedTime이 "일시적 차단"과 "정기적 차단" 두 가지 용도로 사용됨
- 특정 날짜의 전체 휴무를 표현하기 위해 시간 범위를 00:00-23:59로 설정해야 함

---

## 2. 변경 요청사항

### 2.1. 운영시간 설정 (주간 기반 정책)
- **단일 시간대**: 각 요일당 하나의 운영시간 (시작시간 - 종료시간)
- **주간 반복**: 매주 자동 반복되는 기본 정책
- **UI**: 다이얼로그로 간편 설정 (향후 주간뷰 시각화)

### 2.2. 금지시간 설정 (주간 기반 정책, 복수 가능)
- **복수 시간대**: 점심시간, 휴게시간 등 여러 개 추가 가능
- **주간 반복**: 매주 자동 반복되는 기본 정책
- **UI**: 다이얼로그로 간편 설정 (향후 주간뷰 시각화)

### 2.3. 임시 휴무 설정 (월간 기반)
- **특정 날짜**: 특정 날짜에만 적용되는 휴무
- **UI**: 월간뷰를 통해 추가

### 2.4. 설계 목표
1. **운영시간**: 장소의 기본 운영 범위 정의
2. **금지시간**: 운영시간 내에서 예약 불가능한 시간대 (매주 반복)
3. **임시 휴무**: 특정 날짜의 예외 처리

---

## 3. 새로운 데이터 모델 설계

### 3.1. PlaceOperatingHours (운영시간) - 신규

```kotlin
/**
 * PlaceOperatingHours (장소 운영시간)
 *
 * 장소의 기본 운영시간을 요일별로 정의
 * - 각 요일당 하나의 시간대만 허용 (단순화)
 * - 운영시간 외에는 예약 불가
 * - 매주 반복되는 기본 정책
 */
@Entity
@Table(
    name = "place_operating_hours",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["place_id", "day_of_week"])
    ],
    indexes = [
        Index(name = "idx_operating_place", columnList = "place_id"),
        Index(name = "idx_operating_day", columnList = "place_id, day_of_week")
    ]
)
class PlaceOperatingHours(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    var place: Place,

    @Enumerated(EnumType.STRING)
    @Column(name = "day_of_week", nullable = false, length = 10)
    var dayOfWeek: DayOfWeek,

    @Column(name = "start_time", nullable = false)
    var startTime: LocalTime,

    @Column(name = "end_time", nullable = false)
    var endTime: LocalTime,

    @Column(name = "is_closed", nullable = false)
    var isClosed: Boolean = false,  // 해당 요일 휴무 여부

    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now()
) {
    /**
     * 주어진 시간이 운영시간 내에 있는지 확인
     */
    fun contains(time: LocalTime): Boolean {
        if (isClosed) return false
        return !time.isBefore(startTime) && !time.isAfter(endTime)
    }

    /**
     * 주어진 시간 범위가 운영시간 내에 완전히 포함되는지 확인
     */
    fun fullyContains(start: LocalTime, end: LocalTime): Boolean {
        if (isClosed) return false
        return !start.isBefore(startTime) && !end.isAfter(endTime)
    }

    override fun equals(other: Any?) = other is PlaceOperatingHours && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
```

**DB 스키마**:
```sql
CREATE TABLE place_operating_hours (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    place_id BIGINT NOT NULL,
    day_of_week ENUM('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_closed BOOLEAN DEFAULT false,  -- 해당 요일 휴무
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_operating_hours (place_id, day_of_week),
    FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE
);

CREATE INDEX idx_operating_place ON place_operating_hours(place_id);
CREATE INDEX idx_operating_day ON place_operating_hours(place_id, day_of_week);
```

### 3.2. PlaceRestrictedTime (금지시간) - PlaceBlockedTime 대체

```kotlin
/**
 * PlaceRestrictedTime (장소 금지시간)
 *
 * 운영시간 내에서 예약 불가능한 시간대 정의
 * - 매주 반복되는 주간 정책 (점심시간, 휴게시간 등)
 * - 여러 개 설정 가능
 */
@Entity
@Table(
    name = "place_restricted_times",
    indexes = [
        Index(name = "idx_restricted_place", columnList = "place_id"),
        Index(name = "idx_restricted_day", columnList = "place_id, day_of_week")
    ]
)
class PlaceRestrictedTime(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    var place: Place,

    @Enumerated(EnumType.STRING)
    @Column(name = "day_of_week", nullable = false, length = 10)
    var dayOfWeek: DayOfWeek,

    @Column(name = "start_time", nullable = false)
    var startTime: LocalTime,

    @Column(name = "end_time", nullable = false)
    var endTime: LocalTime,

    @Column(name = "reason", length = 100)
    var reason: String? = null,  // 예: "점심시간", "시설 휴게시간"

    @Column(name = "display_order", nullable = false)
    var displayOrder: Int = 0,

    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now()
) {
    /**
     * 주어진 시간과 겹치는지 확인
     */
    fun overlapsWith(start: LocalTime, end: LocalTime): Boolean {
        return !(end.isBefore(startTime) || start.isAfter(endTime))
    }

    override fun equals(other: Any?) = other is PlaceRestrictedTime && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
```

**DB 스키마**:
```sql
CREATE TABLE place_restricted_times (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    place_id BIGINT NOT NULL,
    day_of_week ENUM('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    reason VARCHAR(100),  -- 예: "점심시간", "시설 휴게시간"
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE
);

CREATE INDEX idx_restricted_place ON place_restricted_times(place_id);
CREATE INDEX idx_restricted_day ON place_restricted_times(place_id, day_of_week);
```

### 3.3. PlaceClosure (임시 휴무) - 신규

```kotlin
/**
 * PlaceClosure (장소 임시 휴무)
 *
 * 특정 날짜의 임시 휴무 관리
 * - 전일 휴무 또는 부분 시간 휴무 지원
 * - 월간뷰를 통해 관리
 */
@Entity
@Table(
    name = "place_closures",
    indexes = [
        Index(name = "idx_closure_place", columnList = "place_id"),
        Index(name = "idx_closure_date", columnList = "place_id, closure_date")
    ]
)
class PlaceClosure(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    var place: Place,

    @Column(name = "closure_date", nullable = false)
    var closureDate: LocalDate,

    @Column(name = "is_full_day", nullable = false)
    var isFullDay: Boolean = true,  // 전일 휴무 여부

    // 부분 시간 휴무인 경우 (isFullDay = false)
    @Column(name = "start_time")
    var startTime: LocalTime? = null,

    @Column(name = "end_time")
    var endTime: LocalTime? = null,

    @Column(name = "reason", length = 200)
    var reason: String? = null,  // 휴무 사유

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    var createdBy: User,

    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalDateTime = LocalDateTime.now()
) {
    /**
     * 주어진 날짜와 시간이 휴무에 해당하는지 확인
     */
    fun isClosedAt(date: LocalDate, time: LocalTime): Boolean {
        if (closureDate != date) return false
        if (isFullDay) return true

        // 부분 시간 휴무 확인
        return startTime != null && endTime != null &&
               !time.isBefore(startTime) && !time.isAfter(endTime)
    }

    /**
     * 주어진 날짜와 시간 범위가 휴무와 겹치는지 확인
     */
    fun overlapsWithTimeRange(date: LocalDate, start: LocalTime, end: LocalTime): Boolean {
        if (closureDate != date) return false
        if (isFullDay) return true

        // 부분 시간 휴무와의 겹침 확인
        return startTime != null && endTime != null &&
               !(end.isBefore(startTime) || start.isAfter(endTime))
    }

    override fun equals(other: Any?) = other is PlaceClosure && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
```

**DB 스키마**:
```sql
CREATE TABLE place_closures (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    place_id BIGINT NOT NULL,
    closure_date DATE NOT NULL,
    is_full_day BOOLEAN DEFAULT true,
    start_time TIME,             -- 부분 시간 휴무 시작
    end_time TIME,               -- 부분 시간 휴무 종료
    reason VARCHAR(200),         -- 휴무 사유
    created_by BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE INDEX idx_closure_place ON place_closures(place_id);
CREATE INDEX idx_closure_date ON place_closures(place_id, closure_date);
```

### 3.4. 엔티티 관계 다이어그램

```
Place [1:N] PlaceOperatingHours    (요일별 운영시간, 각 요일당 1개)
Place [1:N] PlaceRestrictedTime    (요일별 금지시간, 복수 가능)
Place [1:N] PlaceClosure            (날짜별 임시 휴무)

PlaceOperatingHours: 기본 운영 범위 정의
PlaceRestrictedTime: 운영시간 내 예약 불가 시간대 (주간 반복)
PlaceClosure: 특정 날짜의 예외 처리
```

---

## 4. API 설계

### 4.1. 운영시간 API

#### 4.1.1. 운영시간 조회
```http
GET /api/places/{placeId}/operating-hours
```

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "dayOfWeek": "MONDAY",
      "startTime": "09:00",
      "endTime": "18:00",
      "isClosed": false
    },
    {
      "id": 2,
      "dayOfWeek": "TUESDAY",
      "startTime": "09:00",
      "endTime": "18:00",
      "isClosed": false
    },
    {
      "id": 3,
      "dayOfWeek": "SATURDAY",
      "isClosed": true
    }
  ]
}
```

#### 4.1.2. 운영시간 설정 (전체 교체)
```http
PUT /api/places/{placeId}/operating-hours
Authorization: Bearer {token}
```

**Request**:
```json
{
  "operatingHours": [
    {
      "dayOfWeek": "MONDAY",
      "startTime": "09:00",
      "endTime": "18:00",
      "isClosed": false
    },
    {
      "dayOfWeek": "TUESDAY",
      "startTime": "09:00",
      "endTime": "18:00",
      "isClosed": false
    },
    {
      "dayOfWeek": "SATURDAY",
      "isClosed": true
    }
  ]
}
```

**권한**: `CALENDAR_MANAGE` + 관리 주체 확인

#### 4.1.3. 특정 요일 운영시간 수정
```http
PATCH /api/places/{placeId}/operating-hours/{dayOfWeek}
Authorization: Bearer {token}
```

**Request**:
```json
{
  "startTime": "10:00",
  "endTime": "17:00",
  "isClosed": false
}
```

### 4.2. 금지시간 API

#### 4.2.1. 금지시간 조회
```http
GET /api/places/{placeId}/restricted-times
```

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "dayOfWeek": "MONDAY",
      "startTime": "12:00",
      "endTime": "13:00",
      "reason": "점심시간",
      "displayOrder": 0
    },
    {
      "id": 2,
      "dayOfWeek": "MONDAY",
      "startTime": "15:00",
      "endTime": "15:30",
      "reason": "휴게시간",
      "displayOrder": 1
    }
  ]
}
```

#### 4.2.2. 금지시간 추가
```http
POST /api/places/{placeId}/restricted-times
Authorization: Bearer {token}
```

**Request**:
```json
{
  "dayOfWeek": "MONDAY",
  "startTime": "12:00",
  "endTime": "13:00",
  "reason": "점심시간"
}
```

**권한**: `CALENDAR_MANAGE` + 관리 주체 확인

#### 4.2.3. 금지시간 수정
```http
PATCH /api/places/{placeId}/restricted-times/{restrictedTimeId}
Authorization: Bearer {token}
```

#### 4.2.4. 금지시간 삭제
```http
DELETE /api/places/{placeId}/restricted-times/{restrictedTimeId}
Authorization: Bearer {token}
```

### 4.3. 임시 휴무 API

#### 4.3.1. 임시 휴무 조회 (날짜 범위)
```http
GET /api/places/{placeId}/closures?from=2025-11-01&to=2025-11-30
```

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "closureDate": "2025-11-15",
      "isFullDay": true,
      "reason": "시설 점검"
    },
    {
      "id": 2,
      "closureDate": "2025-11-20",
      "isFullDay": false,
      "startTime": "14:00",
      "endTime": "17:00",
      "reason": "긴급 공사"
    }
  ]
}
```

#### 4.3.2. 임시 휴무 추가
```http
POST /api/places/{placeId}/closures
Authorization: Bearer {token}
```

**Request** (전일 휴무):
```json
{
  "closureDate": "2025-11-15",
  "isFullDay": true,
  "reason": "시설 점검"
}
```

**Request** (부분 시간 휴무):
```json
{
  "closureDate": "2025-11-20",
  "isFullDay": false,
  "startTime": "14:00",
  "endTime": "17:00",
  "reason": "긴급 공사"
}
```

**권한**: `CALENDAR_MANAGE` + 관리 주체 확인

#### 4.3.3. 임시 휴무 삭제
```http
DELETE /api/places/{placeId}/closures/{closureId}
Authorization: Bearer {token}
```

### 4.4. 예약 가능 시간 계산 API

#### 4.4.1. 특정 날짜의 예약 가능 시간 조회
```http
GET /api/places/{placeId}/available-times?date=2025-11-15
```

**Response**:
```json
{
  "success": true,
  "data": {
    "date": "2025-11-15",
    "dayOfWeek": "FRIDAY",
    "isClosed": false,
    "operatingHours": {
      "startTime": "09:00",
      "endTime": "18:00"
    },
    "restrictedTimes": [
      {
        "startTime": "12:00",
        "endTime": "13:00",
        "reason": "점심시간"
      }
    ],
    "closures": [],
    "existingReservations": [
      {
        "startTime": "10:00",
        "endTime": "11:30",
        "groupName": "AI/SC 학회"
      }
    ],
    "availableSlots": [
      {
        "startTime": "09:00",
        "endTime": "10:00"
      },
      {
        "startTime": "11:30",
        "endTime": "12:00"
      },
      {
        "startTime": "13:00",
        "endTime": "18:00"
      }
    ]
  }
}
```

**계산 로직**:
1. 운영시간 확인
2. 금지시간 제외
3. 임시 휴무 확인
4. 기존 예약 제외
5. 남은 시간대를 연속된 슬롯으로 반환

---

## 5. 비즈니스 로직

### 5.1. 예약 가능 여부 검증 알고리즘

```kotlin
/**
 * 특정 날짜/시간에 예약이 가능한지 검증
 */
fun isReservable(
    placeId: Long,
    date: LocalDate,
    startTime: LocalTime,
    endTime: LocalTime
): Boolean {
    // 1. 운영시간 확인
    val operatingHours = findOperatingHoursByDayOfWeek(placeId, date.dayOfWeek)
    if (operatingHours == null || operatingHours.isClosed) {
        return false  // 해당 요일 휴무
    }
    if (!operatingHours.fullyContains(startTime, endTime)) {
        return false  // 운영시간 외
    }

    // 2. 금지시간 확인
    val restrictedTimes = findRestrictedTimesByDayOfWeek(placeId, date.dayOfWeek)
    for (restricted in restrictedTimes) {
        if (restricted.overlapsWith(startTime, endTime)) {
            return false  // 금지시간과 겹침
        }
    }

    // 3. 임시 휴무 확인
    val closure = findClosureByDate(placeId, date)
    if (closure != null && closure.overlapsWithTimeRange(date, startTime, endTime)) {
        return false  // 임시 휴무
    }

    // 4. 기존 예약 충돌 확인
    val hasConflict = hasReservationConflict(placeId, date, startTime, endTime)
    if (hasConflict) {
        return false  // 다른 예약과 충돌
    }

    return true  // 예약 가능
}
```

### 5.2. 우선순위 처리

**검증 순서** (위에서 아래로):
1. **운영시간** (PlaceOperatingHours)
   - 가장 먼저 확인
   - 운영시간 외면 즉시 불가
2. **금지시간** (PlaceRestrictedTime)
   - 운영시간 내에서 추가 제약
3. **임시 휴무** (PlaceClosure)
   - 특정 날짜의 예외 처리
4. **기존 예약** (PlaceReservation)
   - 최종 충돌 확인

**우선순위 규칙**:
```
임시 휴무 > 금지시간 > 운영시간
```

### 5.3. 예약 생성 시 검증 로직

```kotlin
@Transactional
fun createReservation(request: CreateReservationRequest): PlaceReservationDto {
    val place = placeRepository.findById(request.placeId)
        .orElseThrow { BusinessException(ErrorCode.PLACE_NOT_FOUND) }

    val date = request.startDatetime.toLocalDate()
    val startTime = request.startDatetime.toLocalTime()
    val endTime = request.endDatetime.toLocalTime()

    // 1. 예약 가능 여부 검증
    if (!isReservable(place.id, date, startTime, endTime)) {
        throw BusinessException(ErrorCode.RESERVATION_NOT_AVAILABLE)
    }

    // 2. 예약 생성 (낙관적 락)
    try {
        val reservation = PlaceReservation(...)
        return placeReservationRepository.save(reservation).toDto()
    } catch (e: OptimisticLockException) {
        throw BusinessException(ErrorCode.RESERVATION_CONFLICT)
    }
}
```

### 5.4. 운영시간 변경 시 기존 예약 처리

**시나리오**: 운영시간을 09:00-18:00에서 10:00-17:00로 변경

**옵션 1**: 기존 예약 유지 (권장)
- 운영시간 변경은 미래 예약에만 영향
- 기존 예약은 변경 전 정책 기준으로 유지

**옵션 2**: 기존 예약 자동 취소 (선택)
- 운영시간 외로 벗어난 예약 자동 취소
- 경고 메시지 필수: "X개 예약이 취소됩니다"

**구현 방향**: 옵션 1 (기존 예약 유지)
- 사용자 혼란 방지
- 운영시간 변경 전에 관리자가 수동으로 예약 조정 유도

---

## 6. 마이그레이션 전략

### 6.1. 기존 데이터 변환

#### PlaceAvailability → PlaceOperatingHours

**문제**: 기존 시스템은 같은 요일에 여러 시간대 허용
**해결**: 첫 번째 시간대만 운영시간으로 변환, 나머지는 무시

```sql
-- 1. 각 요일의 첫 번째 시간대만 추출 (display_order 기준)
INSERT INTO place_operating_hours (place_id, day_of_week, start_time, end_time, created_at, updated_at)
SELECT
    pa.place_id,
    pa.day_of_week,
    pa.start_time,
    pa.end_time,
    NOW(),
    NOW()
FROM place_availabilities pa
INNER JOIN (
    SELECT place_id, day_of_week, MIN(display_order) as min_order
    FROM place_availabilities
    GROUP BY place_id, day_of_week
) first_slot
ON pa.place_id = first_slot.place_id
   AND pa.day_of_week = first_slot.day_of_week
   AND pa.display_order = first_slot.min_order;

-- 2. 나머지 시간대는 금지시간으로 전환할지 확인 필요 (수동 검토)
-- 예: 월요일 09:00-12:00, 14:00-18:00 → 12:00-14:00을 금지시간으로?
```

#### PlaceBlockedTime → PlaceRestrictedTime + PlaceClosure

**분류 기준**:
- 매주 반복되는 패턴 → PlaceRestrictedTime
- 특정 날짜만 적용 → PlaceClosure

```sql
-- 방법 1: 모든 차단 시간을 임시 휴무로 변환 (안전)
INSERT INTO place_closures (place_id, closure_date, is_full_day, start_time, end_time, reason, created_by, created_at)
SELECT
    pbt.place_id,
    DATE(pbt.start_datetime),
    CASE
        WHEN TIME(pbt.start_datetime) = '00:00:00' AND TIME(pbt.end_datetime) = '23:59:59'
        THEN true
        ELSE false
    END as is_full_day,
    CASE
        WHEN TIME(pbt.start_datetime) != '00:00:00'
        THEN TIME(pbt.start_datetime)
        ELSE NULL
    END as start_time,
    CASE
        WHEN TIME(pbt.end_datetime) != '23:59:59'
        THEN TIME(pbt.end_datetime)
        ELSE NULL
    END as end_time,
    pbt.reason,
    pbt.created_by,
    NOW()
FROM place_blocked_times pbt;

-- 방법 2: 패턴 분석 후 반복 패턴을 금지시간으로 (복잡, 수동 작업 필요)
```

### 6.2. 마이그레이션 스크립트

```sql
-- V6__redesign_place_time_management.sql

-- 1. 새 테이블 생성
CREATE TABLE place_operating_hours (...);
CREATE TABLE place_restricted_times (...);
CREATE TABLE place_closures (...);

-- 2. 데이터 마이그레이션
-- (위의 변환 쿼리 실행)

-- 3. 기존 테이블 백업 (안전)
RENAME TABLE place_availabilities TO place_availabilities_backup;
RENAME TABLE place_blocked_times TO place_blocked_times_backup;

-- 4. 검증 후 백업 테이블 삭제 (추후)
-- DROP TABLE place_availabilities_backup;
-- DROP TABLE place_blocked_times_backup;
```

### 6.3. 롤백 계획

1. **백업 테이블 유지**: 마이그레이션 후 일정 기간 백업 테이블 보존
2. **검증 기간**: 2주간 프로덕션에서 동작 확인
3. **롤백 스크립트**: 필요 시 백업 테이블에서 복구

---

## 7. 구현 로드맵

### Phase 1: 백엔드 기본 구조 (4-6시간)

#### 1.1. 엔티티 및 레포지토리
- [ ] PlaceOperatingHours 엔티티 생성
- [ ] PlaceRestrictedTime 엔티티 생성
- [ ] PlaceClosure 엔티티 생성
- [ ] 각 엔티티의 Repository 인터페이스 작성
- [ ] 커스텀 쿼리 메서드 구현

#### 1.2. 마이그레이션 스크립트
- [ ] V6__redesign_place_time_management.sql 작성
- [ ] 데이터 변환 쿼리 작성
- [ ] 테스트 데이터로 검증

### Phase 2: 서비스 레이어 (4-6시간)

#### 2.1. 새 서비스 클래스
- [ ] PlaceOperatingHoursService
  - 운영시간 조회/설정/수정
- [ ] PlaceRestrictedTimeService
  - 금지시간 CRUD
- [ ] PlaceClosureService
  - 임시 휴무 CRUD

#### 2.2. 예약 가능 시간 계산
- [ ] isReservable() 메서드 구현
- [ ] getAvailableSlots() 메서드 구현
- [ ] PlaceReservationService 업데이트

### Phase 3: 컨트롤러 및 API (3-4시간)

#### 3.1. REST API 엔드포인트
- [ ] 운영시간 API (조회/설정/수정)
- [ ] 금지시간 API (CRUD)
- [ ] 임시 휴무 API (CRUD)
- [ ] 예약 가능 시간 조회 API

#### 3.2. DTO 클래스
- [ ] Request/Response DTO 작성
- [ ] Jakarta Validation 적용

### Phase 4: 테스트 (4-6시간)

#### 4.1. 단위 테스트
- [ ] 엔티티 메서드 테스트
- [ ] 서비스 로직 테스트
- [ ] 예약 가능 여부 검증 알고리즘 테스트

#### 4.2. 통합 테스트
- [ ] API 엔드포인트 테스트
- [ ] 권한 검증 테스트
- [ ] 마이그레이션 테스트

### Phase 5: 프론트엔드 (8-12시간)

#### 5.1. 운영시간 설정 UI
- [ ] 요일별 시간 설정 다이얼로그
- [ ] 휴무일 설정 체크박스
- [ ] 저장/취소 액션

#### 5.2. 금지시간 관리 UI
- [ ] 금지시간 목록 표시
- [ ] 추가/수정/삭제 다이얼로그
- [ ] 요일별 필터링

#### 5.3. 임시 휴무 관리 UI
- [ ] 월간 캘린더 뷰
- [ ] 휴무 날짜 클릭 → 추가 다이얼로그
- [ ] 전일/부분 휴무 선택

#### 5.4. 예약 가능 시간 표시
- [ ] 예약 가능 슬롯 시각화
- [ ] 운영시간/금지시간/휴무 표시
- [ ] 기존 예약 표시

### Phase 6: 문서화 및 배포 (2-3시간)

- [ ] API 문서 업데이트
- [ ] 데이터베이스 참조 문서 업데이트
- [ ] 사용자 가이드 작성
- [ ] 마이그레이션 가이드 작성

**총 예상 시간**: 25-37시간 (3-5일)

---

## 8. 의논 사항

### 8.1. 운영시간 단순화

**질문**: 각 요일당 하나의 운영시간만 허용하는 것이 적절한가?

**현재 제안**:
- 월요일: 09:00-18:00 (단일 시간대)

**대안**:
- 월요일: 09:00-12:00, 14:00-18:00 (복수 시간대)

**의견**:
- 단순화된 방식이 대부분의 사용 사례를 커버할 것으로 예상
- 점심시간은 "금지시간"으로 처리하면 충분
- 복수 시간대가 필요한 특수한 경우는 추후 확장 고려

**결정 필요**: 단순화된 방식으로 진행할지, 복수 시간대를 지원할지?

### 8.2. 금지시간과 운영시간의 관계

**질문**: 금지시간이 운영시간 밖에 설정되면 어떻게 처리할지?

**시나리오**:
- 운영시간: 09:00-18:00
- 금지시간: 19:00-20:00 (운영시간 외)

**옵션**:
1. **허용** - 금지시간이 운영시간 외에도 설정 가능 (향후 운영시간 변경 대비)
2. **차단** - 검증 단계에서 에러 발생

**권장**: 옵션 1 (허용)
- 운영시간 변경 시 금지시간을 다시 설정할 필요 없음
- 예약 가능 여부 계산 시 운영시간을 먼저 확인하므로 문제 없음

**결정 필요**: 어떤 옵션으로 할지?

### 8.3. 임시 휴무의 부분 시간 지원

**질문**: 임시 휴무가 전일 휴무와 부분 시간 휴무를 모두 지원해야 하는가?

**현재 제안**:
- 전일 휴무: `isFullDay = true`
- 부분 시간 휴무: `isFullDay = false`, startTime/endTime 설정

**대안**:
- 전일 휴무만 지원 (단순화)
- 부분 시간은 PlaceRestrictedTime으로 처리

**의견**:
- 긴급 상황 (예: 오후만 긴급 공사)을 대비하여 부분 시간 지원 필요
- UI/UX 복잡도는 약간 증가하지만, 유연성 확보

**결정 필요**: 부분 시간 휴무를 지원할지?

### 8.4. 기존 예약 처리

**질문**: 운영시간 변경 시 기존 예약을 어떻게 처리할지?

**시나리오**:
- 기존 운영시간: 09:00-18:00
- 기존 예약: 11월 20일 17:00-18:00
- 변경 후 운영시간: 09:00-17:00

**옵션**:
1. **기존 예약 유지** (권장)
   - 운영시간 변경은 미래 예약에만 영향
   - 이미 확정된 예약은 보호
2. **자동 취소**
   - 운영시간 외 예약 자동 취소
   - 경고 메시지 표시

**권장**: 옵션 1 (기존 예약 유지)
- 사용자 혼란 방지
- 관리자가 수동으로 조정 가능

**결정 필요**: 어떤 정책으로 할지?

### 8.5. 마이그레이션 전략

**질문**: 기존 PlaceAvailability의 복수 시간대를 어떻게 처리할지?

**시나리오**:
- 기존 데이터: 월요일 09:00-12:00, 월요일 14:00-18:00

**옵션**:
1. **첫 번째 시간대만 변환** (단순)
   - 09:00-12:00만 운영시간으로 변환
   - 14:00-18:00은 무시 (데이터 손실)
2. **병합** (복잡)
   - 09:00-18:00로 병합
   - 12:00-14:00을 금지시간으로 추가
3. **수동 검토** (안전)
   - 마이그레이션 전에 모든 장소의 시간대 패턴 분석
   - 케이스별로 수동 변환

**권장**: 옵션 3 (수동 검토)
- 데이터 무결성 보장
- 각 장소의 의도를 정확히 반영

**결정 필요**: 어떤 방식으로 마이그레이션할지?

### 8.6. UI/UX 구현 우선순위

**질문**: 어떤 UI를 먼저 구현할지?

**우선순위 제안**:
1. **운영시간 설정** (필수)
   - 다이얼로그 방식
   - 요일별 시간 설정
2. **금지시간 관리** (중요)
   - 목록 + CRUD
3. **임시 휴무 관리** (선택)
   - 월간 캘린더 뷰
4. **주간뷰 시각화** (향후)
   - 운영시간 + 금지시간 통합 표시

**결정 필요**: 위 순서로 진행할지, 다른 우선순위가 있는지?

---

## 9. 구현 완료 현황

### ✅ 완료된 작업

#### Phase 1: 백엔드 기본 구조 (완료)
- [x] PlaceOperatingHours, PlaceRestrictedTime, PlaceClosure 엔티티 생성
- [x] 마이그레이션 스크립트 V6__redesign_place_time_management.sql 작성
- [x] 3개 Repository 인터페이스 구현

#### Phase 2: 서비스 레이어 (완료)
- [x] PlaceOperatingHoursService 구현
- [x] PlaceRestrictedTimeService 구현
- [x] PlaceClosureService 구현
- [x] PlaceReservationService 업데이트 (isReservable, getAvailableSlots)

#### Phase 3: REST API (완료)
- [x] 운영시간 API (GET, PUT, PATCH)
- [x] 금지시간 API (GET, POST, PATCH, DELETE)
- [x] 임시 휴무 API (GET, POST/전일, POST/부분, DELETE)
- [x] 예약 가능 시간 조회 API (GET)
- [x] DTO 클래스 및 유효성 검사 적용

#### Phase 4: 프론트엔드 UI (완료)
- [x] Core 모델 및 Repository 구현
- [x] Riverpod Provider 14개 작성
- [x] PlaceAdminSettingsPage 메인 페이지
- [x] 운영시간 설정 다이얼로그 + 표시 위젯
- [x] 금지시간 관리 (목록, 추가, 수정, 삭제)
- [x] 임시 휴무 관리 (월간 캘린더, 전일/부분 휴무)
- [x] 예약 가능 시간 표시 위젯

### 생성된 파일 목록

#### 백엔드 (12개 파일)
**엔티티**:
- `backend/src/main/kotlin/org/castlekong/backend/entity/PlaceOperatingHours.kt`
- `backend/src/main/kotlin/org/castlekong/backend/entity/PlaceRestrictedTime.kt`
- `backend/src/main/kotlin/org/castlekong/backend/entity/PlaceClosure.kt`

**Repository**:
- `backend/src/main/kotlin/org/castlekong/backend/repository/PlaceOperatingHoursRepository.kt`
- `backend/src/main/kotlin/org/castlekong/backend/repository/PlaceRestrictedTimeRepository.kt`
- `backend/src/main/kotlin/org/castlekong/backend/repository/PlaceClosureRepository.kt`

**Service**:
- `backend/src/main/kotlin/org/castlekong/backend/service/PlaceOperatingHoursService.kt`
- `backend/src/main/kotlin/org/castlekong/backend/service/PlaceRestrictedTimeService.kt`
- `backend/src/main/kotlin/org/castlekong/backend/service/PlaceClosureService.kt`

**API**:
- `backend/src/main/kotlin/org/castlekong/backend/dto/PlaceTimeManagementDto.kt`
- `backend/src/main/kotlin/org/castlekong/backend/controller/PlaceTimeManagementController.kt`

**마이그레이션**:
- `backend/src/main/resources/db/migration/V6__redesign_place_time_management.sql`

#### 프론트엔드 (8개 파일)
**Core**:
- `frontend/lib/core/models/place_time_models.dart`
- `frontend/lib/core/repositories/place_time_repository.dart`
- `frontend/lib/core/providers/place_time_providers.dart`

**Features**:
- `frontend/lib/features/place_admin/presentation/pages/place_admin_settings_page.dart`
- `frontend/lib/features/place_admin/presentation/widgets/place_operating_hours_dialog.dart`
- `frontend/lib/features/place_admin/presentation/widgets/restricted_time_widgets.dart`
- `frontend/lib/features/place_admin/presentation/widgets/place_closure_widgets.dart`
- `frontend/lib/features/place_admin/presentation/widgets/available_times_widget.dart`

### 주요 API 엔드포인트

| 메서드 | 엔드포인트 | 설명 | 권한 |
|--------|----------|------|------|
| GET | `/api/places/{placeId}/operating-hours` | 운영시간 조회 | 공개 |
| PUT | `/api/places/{placeId}/operating-hours` | 운영시간 전체 설정 | CALENDAR_MANAGE |
| PATCH | `/api/places/{placeId}/operating-hours/{dayOfWeek}` | 특정 요일 수정 | CALENDAR_MANAGE |
| GET | `/api/places/{placeId}/restricted-times` | 금지시간 조회 | 공개 |
| POST | `/api/places/{placeId}/restricted-times` | 금지시간 추가 | CALENDAR_MANAGE |
| PATCH | `/api/places/{placeId}/restricted-times/{id}` | 금지시간 수정 | CALENDAR_MANAGE |
| DELETE | `/api/places/{placeId}/restricted-times/{id}` | 금지시간 삭제 | CALENDAR_MANAGE |
| GET | `/api/places/{placeId}/closures?from=&to=` | 임시 휴무 조회 | 공개 |
| POST | `/api/places/{placeId}/closures/full-day` | 전일 휴무 추가 | CALENDAR_MANAGE |
| POST | `/api/places/{placeId}/closures/partial` | 부분 시간 휴무 추가 | CALENDAR_MANAGE |
| DELETE | `/api/places/{placeId}/closures/{id}` | 임시 휴무 삭제 | CALENDAR_MANAGE |
| GET | `/api/places/{placeId}/available-times?date=` | 예약 가능 시간 조회 | 공개 |

---

## 10. 다음 단계

### 즉시 실행 항목
1. 마이그레이션 실행 확인 (`./gradlew bootRun`)
2. 새 테이블 생성 검증
3. API 엔드포인트 테스트 (Postman/cURL)
4. 프론트엔드 UI 통합 테스트

### 향후 개선사항
- **알림 시스템**: 운영시간 변경/임시 휴무 추가 시 예약자에게 알림
- **주간뷰 시각화**: 운영시간 + 금지시간 통합 표시 (향후 Phase)
- **기존 예약 영향 경고**: 운영시간 변경 시 경고 메시지 (향후 구현)
- **이력 관리**: 운영시간 변경 이력 저장 (향후 선택)
- **통계**: 휴무일 통계, 금지시간 활용도 등 (향후 선택)

---

## 관련 문서
- [장소 캘린더 명세서](place-calendar-specification.md)
- [장소 관리 개념](../concepts/calendar-place-management.md)
- [데이터베이스 참조](../implementation/database-reference.md)
- [백엔드 개발 가이드](../implementation/backend-guide.md)
- [프론트엔드 개발 가이드](../implementation/frontend-guide.md)
