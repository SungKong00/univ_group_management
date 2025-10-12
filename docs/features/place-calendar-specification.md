# 장소 캘린더 개발 명세서

## 📋 개요

**목적**: 대학 내 장소(강의실, 동아리방 등)의 예약 및 관리 시스템
**관련 문서**: [장소 관리 개념](../concepts/calendar-place-management.md), [캘린더 시스템](../concepts/calendar-system.md)
**상태**: Phase 1 백엔드 구현 완료, Phase 2 프론트엔드 대기

---

## ✅ Phase 1 완료 사항 (2025-10-13)

### 백엔드 구현 완료
- **엔티티 (4개)**: Place, PlaceAvailability, PlaceBlockedTime, PlaceUsageGroup
- **레포지토리 (4개)**: 최적화된 JPQL 쿼리 포함
- **서비스 (3개)**: PlaceService, PlaceUsageGroupService, PlaceBlockedTimeService
- **컨트롤러 (1개)**: PlaceController (REST API 엔드포인트)
- **DTO 클래스**: Jakarta Validation 포함
- **ErrorCode**: 장소 관련 에러 코드 추가

### 다음 단계
- **Phase 2**: 프론트엔드 기본 구현 (장소 목록, 등록, 운영 시간 설정)
- **Phase 3**: 사용 그룹 관리 UI
- **Phase 4**: 예약 시스템 구현
- **Phase 5**: 차단 시간 관리

## 🎯 핵심 기능

### 장소 관리 (관리 주체)
- 장소 등록 (건물-방 번호, 별칭)
- 운영 시간 설정 (요일별, 여러 시간대 가능)
- 예외 날짜 설정 (특정 날짜 예약 불가)
- 사용 그룹 승인/거절
- 관리 주체 이전
- 모든 예약 조회 및 강제 취소

### 장소 사용 (사용 그룹)
- 장소 사용 신청 (그룹 관리자만)
- 장소 예약 (그룹 일정 생성 시)
- 예약 현황 조회
- 자신의 예약 취소

### 공개 기능
- 장소 목록 조회 (건물별 트리 구조)
- 장소별 예약 현황 조회 (월/주/일간 뷰)
- 예약 가능 시간 확인

## 🎨 UI/UX 설계

### 1. 장소 목록 화면
- **구조**: 건물별 트리 구조
```
60주년 기념관
  ├─ 18203 (AISC랩실)
  └─ 18204
창의관
  ├─ 201
  └─ 202
```
- **기능**: 검색, 필터 (건물, 수용 인원, 사용 가능 여부)

### 2. 장소 캘린더 뷰
- **형식**: 월간/주간/일간 뷰 모두 지원
- **표시**: 예약된 시간 블록 (그룹명 표시)
- **색상**: 회색=운영 시간 외, 빨강=예약됨, 초록=예약 가능

### 3. 장소 선택 UI
- **방식**: 바텀시트
- **기능**: 검색 + 승인된 장소 필터링
- **예약 가능 여부**: 실시간 표시

## 💾 데이터 모델

### Place (장소)
```kotlin
id: UUID
managingGroupId: UUID  // 관리 주체 그룹
building: String       // 건물명
roomNumber: String     // 방 번호
alias: String?         // 별칭 (선택)
capacity: Int?         // 수용 인원 (정보성)
deletedAt: Timestamp?  // Soft delete
```

### PlaceAvailability (운영 시간)
```kotlin
id: UUID
placeId: UUID
dayOfWeek: DayOfWeek   // 요일
startTime: LocalTime   // 시작 시간
endTime: LocalTime     // 종료 시간
```
- **제외 시간 지원**: 여러 시간대 허용 (예: 09:00-12:00, 14:00-18:00)

### PlaceBlockedTime (예약 차단 시간)
```kotlin
id: UUID
placeId: UUID
startDatetime: LocalDateTime  // 차단 시작 일시
endDatetime: LocalDateTime    // 차단 종료 일시
blockType: BlockType          // 차단 유형
reason: String?               // 차단 사유 (선택)
```
- **BlockType**: MAINTENANCE (유지보수), EMERGENCY (긴급), HOLIDAY (휴일), OTHER (기타)
- **운영 시간과의 관계**: PlaceAvailability로 정의된 운영 시간 내에서 추가 차단
- **사용 예**: 특정 날짜/시간대의 유지보수, 긴급 상황, 휴일 등

### PlaceUsageGroup (사용 그룹)
```kotlin
id: UUID
placeId: UUID
groupId: UUID
status: Enum(PENDING, APPROVED, REJECTED)
```

### PlaceReservation (예약)
```kotlin
id: UUID
placeId: UUID
groupEventId: UUID  // 1:1 관계
version: Long       // 낙관적 락
```

## 🔌 API 명세

### 장소 관리 API
- `POST /api/places` - 장소 등록 (CALENDAR_MANAGE)
- `GET /api/places` - 장소 목록 조회 (공개)
- `GET /api/places/{id}` - 장소 상세 조회 (공개)
- `PATCH /api/places/{id}` - 장소 정보 수정 (관리 주체)
- `DELETE /api/places/{id}` - 장소 삭제 (Soft delete, 관리 주체)

### 운영 시간 API
- `POST /api/places/{id}/availability` - 운영 시간 추가
- `DELETE /api/places/{id}/availability/{availId}` - 운영 시간 삭제

### 차단 시간 API
- `POST /api/places/{id}/blocked-times` - 차단 시간 추가 (관리 주체)
- `GET /api/places/{id}/blocked-times` - 차단 시간 조회
- `DELETE /api/places/{id}/blocked-times/{blockedId}` - 차단 시간 삭제 (관리 주체)

### 사용 그룹 API
- `POST /api/places/{id}/usage-requests` - 사용 신청 (그룹 관리자)
- `PATCH /api/places/{id}/usage-groups/{groupId}` - 승인/거절 (관리 주체)

### 예약 API
- `POST /api/places/{id}/reservations` - 예약 생성 (GroupEvent 생성 시)
- `GET /api/places/{id}/reservations` - 예약 현황 조회
- `DELETE /api/reservations/{id}` - 예약 취소

### 예약 가능 시간 API
- `GET /api/places/{id}/calendar?start=2025-11-01&end=2025-11-30` - 캘린더 데이터
  - 응답: 예약된 시간대 + 운영 시간 정보

## 📋 비즈니스 로직 정책

### 장소 삭제
- **방식**: Soft delete (`deletedAt` 설정)
- **효과**: 신규 예약만 차단, 기존 예약/데이터 유지
- **복구**: `deletedAt = NULL`로 복구 가능

### 사용 그룹 승인 취소
- **처리**: 승인 상태 변경 + 해당 그룹의 미래 예약 자동 삭제
- **알림**: 경고 메시지 필수 ("X개 예약이 취소됩니다")

### 예약-일정 연결
- **PlaceReservation 삭제 시**: GroupEvent 유지 (장소만 해제)
- **GroupEvent 삭제 시**: PlaceReservation도 CASCADE 삭제

### 장소 별칭
- **입력**: 선택 입력
- **표시**: 별칭 있으면 "별칭 (방 번호)", 없으면 "건물-방 번호"

### 예약 충돌 방지
- **동시성 제어**: 낙관적 락 (`@Version`)
- **우선순위**: FCFS (먼저 요청한 그룹 선점)
- **검증**: PlaceReservation 생성 시 시간대 중복 쿼리

### 예약 취소 알림
- **MVP**: 알림 없음 (로그만 기록)
- **향후**: 알림 시스템 구축 후 푸시/이메일 발송

## 🔐 권한 및 접근 제어

### 권한 요구사항
- **장소 등록/수정**: `CALENDAR_MANAGE` (그룹 관리자)
- **사용 신청**: `CALENDAR_MANAGE` (그룹 관리자)
- **장소 예약**: PlaceUsageGroup APPROVED + 그룹 멤버십

### 접근 제어
- **관리 주체 확인**: `place.managingGroupId == currentUserGroupId`
- **사용 그룹 확인**: `PlaceUsageGroup.status == APPROVED`
- **예약 취소**: 본인 그룹 예약 또는 관리 주체

## ⚠️ 예외 처리

### 예약 생성 실패
- **시간 충돌**: `409 CONFLICT` - "이미 예약된 시간대입니다"
- **운영 시간 외**: `400 BAD_REQUEST` - "운영 시간이 아닙니다"
- **차단 시간**: `400 BAD_REQUEST` - "해당 시간대는 예약이 불가능합니다 (사유: {reason})"
- **승인되지 않은 그룹**: `403 FORBIDDEN` - "장소 사용 권한이 없습니다"

### 장소 삭제 실패
- **미래 예약 존재**: Soft delete 진행 (에러 아님)

### 사용 그룹 승인 취소
- **미래 예약 존재**: 경고 후 진행 (사용자 확인 필요)

## 참조
- [캘린더 시스템](../concepts/calendar-system.md)
- [장소 관리 개념](../concepts/calendar-place-management.md)
- [권한 시스템](../concepts/permission-system.md)
- [그룹 캘린더 개발 계획](group-calendar-development-plan.md)
