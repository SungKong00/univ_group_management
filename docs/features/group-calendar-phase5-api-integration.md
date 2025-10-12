# 그룹 캘린더 Phase 5: API 연동 수정 완료

> **작성일**: 2025-10-12
> **선행 작업**: Phase 1-4 (백엔드 API 구조 변경)
> **소요 시간**: 1시간

---

## 📋 Phase 5 개요

Phase 1-4에서 백엔드 API 구조가 변경되어 프론트엔드 API 호출이 실패하는 문제를 수정했습니다.

### 문제점
- **백엔드 (Phase 1-4)**: `startDate: LocalDate`, `endDate: LocalDate`, `startTime: LocalTime`, `endTime: LocalTime` (4개 필드)
- **프론트엔드 (기존)**: `startDate: DateTime`, `endDate: DateTime` (2개 필드만 ISO8601 전송)
- **결과**: 400 Bad Request 에러 발생 → "캘린더 준비 중" 메시지 표시

---

## ✅ 수정 완료 사항

### 1. API Service 수정 (`group_calendar_service.dart`)

**변경 내용**:
```dart
// BEFORE
'startDate': startDate.toIso8601String(),
'endDate': endDate.toIso8601String(),

// AFTER
'startDate': _dateFormatter.format(startDate),  // yyyy-MM-dd
'endDate': _dateFormatter.format(endDate),      // yyyy-MM-dd
'startTime': _formatTime(startDate),             // HH:mm:ss
'endTime': _formatTime(endDate),                 // HH:mm:ss
```

**적용 메서드**:
- `createEvent()`: 4개 필드로 분리하여 전송
- `updateEvent()`: startTime/endTime만 전송 (날짜는 수정 불가)

**헬퍼 메서드 추가**:
```dart
String _formatTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}:'
      '${dateTime.second.toString().padLeft(2, '0')}';
}
```

---

### 2. UI Form 로직 수정 (`group_event_form_dialog.dart`)

**변경 내용**:
- **단일 일정 검증**: 종료 시간이 시작 시간보다 이후인지 확인
- **반복 일정 검증**: 종료 날짜가 시작 날짜 이후인지 확인
- **반복 일정 지원**: startDate ~ endDate 범위를 반복 기간으로 사용

**수정된 로직**:
```dart
// 단일 일정: 시간 검증
if (_recurrence == null) {
  if (!_endDateTime.isAfter(_startDateTime)) {
    // 에러 메시지 표시
  }
}

// 반복 일정: 날짜 검증
if (_recurrence != null) {
  final startDateOnly = _normalizeDateTime(_startDateTime);
  final endDateOnly = _normalizeDateTime(_endDateTime);
  if (endDateOnly.isBefore(startDateOnly)) {
    // 에러 메시지 표시
  }
}

// DateTime 그대로 전달 (Service에서 분리)
startDate: _startDateTime,
endDate: _endDateTime,
```

---

## 🔍 API 구조 정리

### CreateGroupEventRequest (백엔드)
```kotlin
data class CreateGroupEventRequest(
    val startDate: LocalDate,      // 반복 시작 날짜 (yyyy-MM-dd)
    val endDate: LocalDate,        // 반복 종료 날짜 (yyyy-MM-dd)
    val startTime: LocalTime,      // 이벤트 시작 시간 (HH:mm:ss)
    val endTime: LocalTime,        // 이벤트 종료 시간 (HH:mm:ss)
    val isAllDay: Boolean,
    val recurrence: RecurrencePattern?,
    // ...
)
```

### UpdateGroupEventRequest (백엔드)
```kotlin
data class UpdateGroupEventRequest(
    // 날짜는 수정 불가 (반복 일정의 날짜는 변경하지 않음)
    val startTime: LocalTime,      // 시간만 수정 가능
    val endTime: LocalTime,
    // ...
)
```

### 프론트엔드 전송 형식 (JSON)
```json
{
  "startDate": "2025-11-01",
  "endDate": "2025-11-30",
  "startTime": "14:00:00",
  "endTime": "16:00:00",
  "isAllDay": false,
  "recurrence": {
    "type": "WEEKLY",
    "daysOfWeek": ["MONDAY", "WEDNESDAY", "FRIDAY"]
  }
}
```

---

## 🎯 단일 일정 vs 반복 일정

### 단일 일정
- `startDate == endDate` (같은 날짜)
- `recurrence == null`
- 예시: 2025-11-15 14:00 ~ 16:00 (2시간 회의)
  - startDate: "2025-11-15"
  - endDate: "2025-11-15"
  - startTime: "14:00:00"
  - endTime: "16:00:00"

### 반복 일정
- `startDate != endDate` (날짜 범위)
- `recurrence != null`
- 예시: 11/1 ~ 11/30 매주 월/수/금 14:00 ~ 16:00
  - startDate: "2025-11-01"
  - endDate: "2025-11-30"
  - startTime: "14:00:00"
  - endTime: "16:00:00"
  - recurrence: { type: "WEEKLY", daysOfWeek: ["MONDAY", "WEDNESDAY", "FRIDAY"] }

---

## 📊 테스트 가이드

### 1. 단일 일정 생성 테스트
1. 그룹 캘린더 페이지 이동
2. "+" 버튼 클릭
3. 제목: "팀 회의"
4. 시작 날짜: 2025-11-15 (날짜 picker)
5. 종료 날짜: 2025-11-15 (같은 날짜)
6. 시작 시간: 14:00 (시간 picker)
7. 종료 시간: 16:00 (시간 picker)
8. "추가" 클릭
9. **기대 결과**: 일정 1개 생성, 목록에 표시

### 2. 반복 일정 생성 테스트
1. 그룹 캘린더 페이지 이동
2. "+" 버튼 클릭
3. 제목: "정기 스터디"
4. 시작 날짜: 2025-11-01
5. 종료 날짜: 2025-11-30
6. 시작 시간: 14:00
7. 종료 시간: 16:00
8. "반복 일정" 스위치 ON
9. "매주" 선택, 월/수/금 체크
10. "추가" 클릭
11. **기대 결과**: 13개 일정 생성 (11월 중 월/수/금), 목록에 표시

### 3. API 호출 검증
브라우저 개발자 도구 → Network 탭:
```
POST /api/groups/1/events
Request Payload:
{
  "title": "정기 스터디",
  "startDate": "2025-11-01",
  "endDate": "2025-11-30",
  "startTime": "14:00:00",
  "endTime": "16:00:00",
  "isAllDay": false,
  "color": "#3B82F6",
  "eventType": "GENERAL",
  "recurrence": {
    "type": "WEEKLY",
    "daysOfWeek": ["MONDAY", "WEDNESDAY", "FRIDAY"]
  }
}

Response: 200 OK
{
  "success": true,
  "data": [ /* 13개 GroupEvent */ ]
}
```

---

## 🐛 해결된 문제

### 문제 1: "캘린더 준비 중" 메시지
- **원인**: API 요청 형식 불일치 → 400 Bad Request
- **해결**: 4개 필드로 분리하여 전송
- **상태**: ✅ 해결됨

### 문제 2: 반복 일정 날짜 범위 혼동
- **원인**: UI에서 startDate/endDate를 시간 범위로 잘못 사용
- **해결**: startDate/endDate는 반복 날짜 범위, startTime/endTime은 이벤트 duration으로 명확히 구분
- **상태**: ✅ 해결됨

### 문제 3: 종일 이벤트 endDate 계산 오류
- **원인**: `_allDayEnd(_startDateTime)` 사용 → 23:59:59로 계산
- **해결**: DateTime 그대로 전달, Service 레이어에서 분리
- **상태**: ✅ 해결됨

---

## 📝 다음 단계

### Phase 6: E2E 테스트 (예정)
- [ ] 단일 일정 CRUD 테스트
- [ ] 반복 일정 생성/수정/삭제 테스트
- [ ] 권한 기반 일정 생성 테스트 (일반 멤버 vs 그룹장)
- [ ] 네트워크 에러 처리 테스트
- [ ] 성능 테스트 (대량 일정 조회)

### 추가 개선 사항 (선택)
- [ ] 일정 상세 페이지 구현
- [ ] 캘린더 뷰 (월간/주간) 구현
- [ ] 반복 일정 "이 일정만 수정" vs "전체 수정" UI
- [ ] 일정 알림 기능
- [ ] 개인 캘린더 통합 뷰

---

**작성자**: Claude Code
**최종 수정**: 2025-10-12
