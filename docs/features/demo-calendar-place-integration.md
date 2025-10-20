# 데모 캘린더 장소 예약 통합 기능 명세서

> **작성일**: 2025-10-20
> **상태**: 설계 중 (Design Phase)
> **관련 문서**:
> - [장소 캘린더 명세](place-calendar-specification.md)
> - [장소 관리 개념](../concepts/calendar-place-management.md)
> - [캘린더 통합 로드맵](calendar-integration-roadmap.md)

---

## 📋 개요

**목적**: 데모 캘린더에서 일정 생성 시 장소 예약 기능을 통합하여, 사용자가 예약 가능한 장소를 시각적으로 확인하고 일정에 장소를 추가할 수 있도록 함

**핵심 가치**:
- 일정 생성과 장소 예약을 하나의 플로우로 통합
- 예약 가능 시간을 시각적으로 명확하게 표시 (회색 음영 처리)
- 여러 장소를 비교하여 최적의 시간 선택 가능

**현재 상태**:
- 데모 캘린더: 그룹 일정 불러오기 기능 구현 완료 (WeeklyScheduleEditor + GroupPickerBottomSheet)
- 장소 시스템: 백엔드 Phase 1 완료, 프론트엔드 Provider/Service 구현 완료

---

## 🎯 기능 요구사항

### 1. 장소 선택 UI

#### 1.1. 장소 추가 버튼 (상단 헤더)

**위치**: 데모 캘린더 상단, 그룹 선택 헤더 옆

**레이아웃**:
```
+-----------------------------------------------------------+
| [주간 네비게이션] [그룹 추가 버튼]  [장소 추가 버튼] 🆕    |
+-----------------------------------------------------------+
| [선택된 그룹들 (칩 형태 표시)]                              |
| [선택된 장소들 (칩 형태 표시)] 🆕                           |
+-----------------------------------------------------------+
```

**버튼 스타일**:
- Primary 버튼 스타일 (보라색 배경)
- 레이블: "장소 추가" 또는 "+" 아이콘
- 크기: Medium (12px 패딩)

**동작**:
- 클릭 시 PlaceSelectorBottomSheet 표시
- 사용자가 접근 가능한 모든 장소 목록 표시 (테스트 단계이므로 권한 체크 생략)

#### 1.2. 장소 선택 바텀시트 (PlaceSelectorBottomSheet)

**구조**: GroupPickerBottomSheet와 유사한 패턴

**헤더**:
- 제목: "장소 선택"
- 닫기 버튼 (X 아이콘)

**본문**:
```dart
// 로딩 상태
CircularProgressIndicator + "장소 목록 불러오는 중..."

// 성공 상태
ListView(
  children: [
    // 건물별 그룹화
    ExpansionTile(
      title: "60주년 기념관",
      children: [
        CheckboxListTile(
          title: "18203 (AISC랩실)",
          subtitle: "수용 인원: 20명",
          value: isSelected,
          onChanged: (value) => togglePlace(placeId),
        ),
        // ... more places
      ],
    ),
    // ... more buildings
  ],
)

// 에러 상태
Column(
  children: [
    Icon(Icons.error_outline, color: AppColors.error),
    Text("장소 목록을 불러올 수 없습니다"),
    Text(errorMessage, style: bodySmall),
    ElevatedButton("다시 시도", onPressed: retry),
  ],
)

// 빈 상태
Column(
  children: [
    Icon(Icons.place, color: AppColors.neutral500),
    Text("사용 가능한 장소가 없습니다"),
  ],
)
```

**하단 버튼**:
- Primary 버튼: "완료" (선택된 장소 확정)
- 장소 개수 표시: "N개 장소 선택됨"

**API 연동**:
- `PlaceService.getPlaces()` 호출
- 현재 그룹 필터링 없이 모든 장소 로드 (테스트 단계)
- 향후: `PlaceUsageGroup.status == APPROVED` 조건 추가

#### 1.3. 선택된 장소 표시 (PlaceSelectionHeader)

**위치**: 그룹 선택 헤더 아래

**구조**:
```dart
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: selectedPlaces.map((place) => Chip(
    avatar: CircleAvatar(
      backgroundColor: placeColor,
      child: Icon(Icons.place, size: 16),
    ),
    label: Text("${place.building} ${place.roomNumber}"),
    deleteIcon: Icon(Icons.close, size: 16),
    onDeleted: () => removePlace(place.id),
  )).toList(),
)
```

**스타일**:
- Chip 배경: `neutral200`
- 아바타 색상: 장소별 고유 색상 (PlaceColors.palette 사용)
- 삭제 아이콘: hover 시 `error` 색상

**동작**:
- X 아이콘 클릭 시 장소 선택 해제
- 장소 칩 클릭 시 해당 장소로 캘린더 스크롤 (향후 구현)

---

### 2. 예약 가능 시간 표시 (회색 음영)

#### 2.1. 단일 장소 선택 시 (1개)

**목표**: 선택한 장소에서 예약이 불가능한 시간을 회색으로 표시

**예약 불가 조건**:
1. **운영시간 외**: PlaceAvailability에 정의되지 않은 시간대
2. **기존 예약**: PlaceReservation이 존재하는 시간대
3. **차단 시간**: PlaceBlockedTime이 설정된 시간대 (유지보수, 긴급, 휴무 등)

**시각적 표현**:
```dart
// WeeklyScheduleEditor의 타임 셀 렌더링
Container(
  decoration: BoxDecoration(
    color: isBlockedTime
      ? AppColors.neutral300.withOpacity(0.5)  // 회색 음영
      : Colors.transparent,
    border: Border.all(color: AppColors.neutral400),
  ),
  child: isBlockedTime
    ? Stack(
        children: [
          // 대각선 패턴 (선택)
          CustomPaint(painter: DiagonalStripePainter()),
          // 툴팁 아이콘
          Align(
            alignment: Alignment.topRight,
            child: Icon(Icons.block, size: 12, color: AppColors.neutral600),
          ),
        ],
      )
    : null,
)
```

**상세 정보 표시** (툴팁 또는 롱프레스):
- 운영시간 외: "운영 시간이 아닙니다 (운영: 09:00-18:00)"
- 기존 예약: "이미 예약되었습니다 (예약자: XX그룹)"
- 차단 시간: "예약 불가 (사유: 장비 유지보수)"

**데이터 로딩**:
```dart
Future<void> _loadPlaceBlockedTimes() async {
  final placeId = selectedPlaceIds.first;
  final weekEnd = _weekStart.add(Duration(days: 6));

  // 1. 운영시간 조회
  final availability = await _placeService.getAvailability(placeId);

  // 2. 예약 조회
  final reservations = await _placeService.getReservations(
    placeId: placeId,
    startDate: _weekStart,
    endDate: weekEnd,
  );

  // 3. 차단 시간 조회
  final blockedTimes = await _placeService.getBlockedTimes(
    placeId: placeId,
    startDate: _weekStart,
    endDate: weekEnd,
  );

  // 4. 회색 시간대 계산
  setState(() {
    _blockedTimeSlots = _calculateBlockedSlots(
      availability,
      reservations,
      blockedTimes,
    );
  });
}

Set<DateTime> _calculateBlockedSlots(
  List<PlaceAvailability> availability,
  List<PlaceReservation> reservations,
  List<PlaceBlockedTime> blockedTimes,
) {
  final blocked = <DateTime>{};

  // 30분 단위로 순회 (00:00 ~ 23:30)
  for (int day = 0; day < 7; day++) {
    final currentDay = _weekStart.add(Duration(days: day));

    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final slot = DateTime(
          currentDay.year,
          currentDay.month,
          currentDay.day,
          hour,
          minute,
        );

        // 조건 1: 운영시간 외
        if (!_isWithinOperatingHours(slot, availability)) {
          blocked.add(slot);
          continue;
        }

        // 조건 2: 기존 예약
        if (_hasReservation(slot, reservations)) {
          blocked.add(slot);
          continue;
        }

        // 조건 3: 차단 시간
        if (_isBlockedTime(slot, blockedTimes)) {
          blocked.add(slot);
          continue;
        }
      }
    }
  }

  return blocked;
}
```

#### 2.2. 다중 장소 선택 시 (2개 이상)

**목표**: 모든 선택된 장소에서 예약 가능한 시간만 활성화 (교집합)

**로직**:
```dart
Set<DateTime> _calculateAvailableSlots(List<int> placeIds) {
  if (placeIds.isEmpty) return {};

  // 첫 번째 장소의 가능한 시간대
  Set<DateTime> available = _getAllTimeSlots();

  // 각 장소의 차단 시간을 계산하여 교집합 구하기
  for (final placeId in placeIds) {
    final blockedForPlace = _blockedTimeSlotsPerPlace[placeId] ?? {};
    available.removeAll(blockedForPlace);
  }

  return available;
}

Set<DateTime> _getAllTimeSlots() {
  final all = <DateTime>{};
  for (int day = 0; day < 7; day++) {
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        all.add(_weekStart.add(Duration(
          days: day,
          hours: hour,
          minutes: minute,
        )));
      }
    }
  }
  return all;
}
```

**시각적 표현**:
- 회색 셀: 어느 한 장소라도 예약 불가인 시간 (장소 개수 표시)
- 흰색 셀: 모든 장소에서 예약 가능한 시간
- 툴팁: "2개 장소 중 1개 예약 불가 (60주년 18203: 기존 예약)"

**성능 최적화**:
- 각 장소의 차단 시간을 개별적으로 캐싱
- 교집합 계산은 메모이제이션 적용
- 장소 선택 변경 시에만 재계산

---

### 3. 일정 생성 및 장소 예약

#### 3.1. 일정 블록 추가 (WeeklyScheduleEditor)

**기존 동작**:
- 사용자가 캘린더에서 시간 블록을 드래그하여 선택
- 제목 입력 다이얼로그 표시
- 개인 일정으로 저장

**새로운 동작** (장소 선택 시):

**Step 1: 시간 블록 선택**
- 회색 셀(차단 시간)에는 블록 생성 불가
- 흰색 셀에만 블록 생성 가능
- 블록 선택 시 검증:
  ```dart
  bool _canCreateEventAtSlot(DateTime startSlot, DateTime endSlot) {
    // 단일 장소: 선택된 시간이 차단 시간에 포함되지 않는지 확인
    if (selectedPlaceIds.length == 1) {
      final placeId = selectedPlaceIds.first;
      return !_overlapsWithBlockedTimes(placeId, startSlot, endSlot);
    }

    // 다중 장소: 모든 장소에서 예약 가능한지 확인
    for (final placeId in selectedPlaceIds) {
      if (_overlapsWithBlockedTimes(placeId, startSlot, endSlot)) {
        return false;
      }
    }
    return true;
  }
  ```

**Step 2: 일정 생성 다이얼로그**

**단일 장소 선택 시**:
```dart
AlertDialog(
  title: Text("일정 생성"),
  content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // 제목 입력
      TextField(
        decoration: InputDecoration(labelText: "제목"),
        controller: _titleController,
      ),
      SizedBox(height: 16),

      // 시간 표시
      ListTile(
        leading: Icon(Icons.schedule),
        title: Text("${formatTime(startTime)} - ${formatTime(endTime)}"),
      ),

      // 장소 선택 (단일 장소는 자동 선택)
      ListTile(
        leading: Icon(Icons.place),
        title: Text("${selectedPlace.building} ${selectedPlace.roomNumber}"),
        subtitle: Text("이 장소로 예약"),
        trailing: Checkbox(
          value: _reservePlace,
          onChanged: (value) => setState(() => _reservePlace = value),
        ),
      ),

      // 선택 해제 옵션
      if (_reservePlace == false)
        Text(
          "장소 없이 일정만 추가됩니다",
          style: AppTypography.bodySmall.copyWith(color: AppColors.neutral600),
        ),
    ],
  ),
  actions: [
    TextButton("취소", onPressed: cancel),
    ElevatedButton("생성", onPressed: createEvent),
  ],
)
```

**다중 장소 선택 시**:
```dart
AlertDialog(
  title: Text("일정 생성"),
  content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // 제목 입력
      TextField(
        decoration: InputDecoration(labelText: "제목"),
        controller: _titleController,
      ),
      SizedBox(height: 16),

      // 시간 표시
      ListTile(
        leading: Icon(Icons.schedule),
        title: Text("${formatTime(startTime)} - ${formatTime(endTime)}"),
      ),

      // 장소 드롭다운 (모두 예약 가능한 장소만)
      DropdownButtonFormField<int?>(
        decoration: InputDecoration(labelText: "장소 선택 (선택사항)"),
        value: _selectedPlaceId,
        items: [
          DropdownMenuItem(value: null, child: Text("장소 없음")),
          ...availablePlaces.map((place) => DropdownMenuItem(
            value: place.id,
            child: Text("${place.building} ${place.roomNumber}"),
          )),
        ],
        onChanged: (value) => setState(() => _selectedPlaceId = value),
      ),

      // 안내 문구
      if (_selectedPlaceId == null)
        Text(
          "장소 없이 일정만 추가됩니다",
          style: AppTypography.bodySmall.copyWith(color: AppColors.neutral600),
        )
      else
        Text(
          "선택한 장소를 예약합니다",
          style: AppTypography.bodySmall.copyWith(color: AppColors.success),
        ),
    ],
  ),
  actions: [
    TextButton("취소", onPressed: cancel),
    ElevatedButton("생성", onPressed: createEvent),
  ],
)
```

**Step 3: 일정 저장 및 예약 생성**

```dart
Future<void> _createEventWithPlace({
  required String title,
  required DateTime startTime,
  required DateTime endTime,
  int? placeId,
}) async {
  try {
    // 1. 개인 일정 생성 (또는 그룹 일정)
    final event = PersonalCalendarEvent(
      title: title,
      startDatetime: startTime,
      endDatetime: endTime,
      // ... other fields
    );

    // 2. 장소 예약 생성 (선택된 경우)
    if (placeId != null) {
      await _placeCalendarProvider.createReservation(
        placeId: placeId,
        request: CreatePlaceReservationRequest(
          eventId: event.id,  // 개인 일정 ID
          startDatetime: startTime,
          endDatetime: endTime,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("일정이 생성되고 장소가 예약되었습니다"),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("일정이 생성되었습니다")),
      );
    }

    // 3. 캘린더 새로고침
    await _refreshCalendar();

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("일정 생성 실패: $e"),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
```

#### 3.2. 회색 블록에 일정 추가 시도 시

**검증 로직**:
```dart
void _onCellTap(DateTime startTime) {
  if (_isBlockedTime(startTime)) {
    _showBlockedTimeDialog(startTime);
    return;
  }

  // 정상 플로우
  _showEventCreationDialog(startTime);
}
```

**에러 다이얼로그**:
```dart
AlertDialog(
  title: Row(
    children: [
      Icon(Icons.warning_amber, color: AppColors.warning),
      SizedBox(width: 8),
      Text("예약 불가"),
    ],
  ),
  content: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("이 시간대는 다음 이유로 예약할 수 없습니다:"),
      SizedBox(height: 8),

      // 차단 이유 표시
      if (isOutsideOperatingHours)
        ListTile(
          leading: Icon(Icons.schedule, color: AppColors.neutral600),
          title: Text("운영 시간 외"),
          subtitle: Text("운영 시간: 09:00-18:00"),
        ),

      if (hasExistingReservation)
        ListTile(
          leading: Icon(Icons.event_busy, color: AppColors.error),
          title: Text("이미 예약됨"),
          subtitle: Text("예약자: ${reservation.groupName}"),
        ),

      if (isBlockedByAdmin)
        ListTile(
          leading: Icon(Icons.block, color: AppColors.warning),
          title: Text("관리자 차단"),
          subtitle: Text("사유: ${blockedTime.reason}"),
        ),
    ],
  ),
  actions: [
    TextButton("확인", onPressed: () => Navigator.pop(context)),
  ],
)
```

---

## 🎨 UI/UX 설계

### 색상 시스템

**장소 색상 팔레트** (PlaceColors.palette):
```dart
const List<Color> palette = [
  Color(0xFF5C068C),  // primary (violet)
  Color(0xFF1E6FFF),  // blue
  Color(0xFF10B981),  // green
  Color(0xFFF59E0B),  // orange
  Color(0xFFE63946),  // red
  Color(0xFF8B5CF6),  // purple
  Color(0xFF06B6D4),  // cyan
  Color(0xFFEC4899),  // pink
];
```

**차단 시간 표시**:
- 배경: `AppColors.neutral300.withOpacity(0.5)`
- 테두리: `AppColors.neutral400`
- 아이콘: `AppColors.neutral600`
- 대각선 패턴: `AppColors.neutral400` (선택사항)

**예약 가능 시간**:
- 배경: `Colors.transparent`
- 테두리: `AppColors.neutral400`
- Hover 시: `AppColors.brandLight` (연보라)

### 상호작용 패턴

**장소 선택 플로우**:
```
1. 사용자가 "장소 추가" 버튼 클릭
   ↓
2. PlaceSelectorBottomSheet 표시 (로딩 → 목록)
   ↓
3. 사용자가 장소 체크박스 선택 (1개 이상)
   ↓
4. "완료" 버튼 클릭
   ↓
5. 바텀시트 닫힘 + 장소 칩 표시
   ↓
6. 각 장소의 예약 현황 로드
   ↓
7. 캘린더에 회색 음영 표시
```

**일정 생성 플로우**:
```
1. 사용자가 캘린더에서 시간 블록 드래그
   ↓
2. 회색 셀 포함 여부 검증
   ├─ 회색 셀 포함 → 에러 다이얼로그 표시
   └─ 모두 흰색 셀 → 일정 생성 다이얼로그
   ↓
3. 제목 입력 + 장소 선택 (드롭다운 또는 자동)
   ↓
4. "생성" 버튼 클릭
   ↓
5. 일정 생성 + 장소 예약 (선택 시)
   ↓
6. 성공 스낵바 표시
   ↓
7. 캘린더 새로고침
```

### 반응형 디자인

**모바일 (< 600px)**:
- 바텀시트 높이: 화면의 80%
- 장소 칩: 1줄에 1-2개 (Wrap 자동 줄바꿈)
- 일정 생성 다이얼로그: Full width

**태블릿/데스크톱 (≥ 600px)**:
- 바텀시트 최대 너비: 500px (중앙 정렬)
- 장소 칩: 1줄에 2-3개
- 일정 생성 다이얼로그: 최대 너비 420px

---

## 🔌 API 연동

### 장소 목록 조회
```dart
GET /api/places
Query Params: (없음 - 모든 장소 반환, 테스트 단계)

Response:
[
  {
    "id": 1,
    "managingGroupId": 5,
    "building": "60주년 기념관",
    "roomNumber": "18203",
    "alias": "AISC랩실",
    "capacity": 20,
    "deletedAt": null
  },
  // ...
]
```

### 장소 운영시간 조회
```dart
GET /api/places/{placeId}/availability

Response:
[
  {
    "id": 1,
    "placeId": 1,
    "dayOfWeek": "MONDAY",
    "startTime": "09:00:00",
    "endTime": "18:00:00"
  },
  // ...
]
```

### 장소 예약 조회
```dart
GET /api/places/{placeId}/reservations?start=2025-10-20&end=2025-10-27

Response:
[
  {
    "id": 1,
    "placeId": 1,
    "groupEventId": 10,
    "groupName": "AISC",
    "title": "정기 회의",
    "startDatetime": "2025-10-21T14:00:00",
    "endDatetime": "2025-10-21T16:00:00"
  },
  // ...
]
```

### 장소 차단시간 조회
```dart
GET /api/places/{placeId}/blocked-times?start=2025-10-20&end=2025-10-27

Response:
[
  {
    "id": 1,
    "placeId": 1,
    "startDatetime": "2025-10-22T00:00:00",
    "endDatetime": "2025-10-22T23:59:59",
    "blockType": "HOLIDAY",
    "reason": "개교기념일"
  },
  // ...
]
```

### 다중 장소 캘린더 조회 (최적화)
```dart
GET /api/places/calendar?placeIds=1,2,3&start=2025-10-20&end=2025-10-27

Response:
{
  "1": {  // Place ID
    "reservations": [...],
    "blockedTimes": [...],
    "availability": [...]
  },
  "2": { ... },
  "3": { ... }
}
```

### 장소 예약 생성
```dart
POST /api/places/{placeId}/reservations

Request Body:
{
  "eventId": 123,  // 개인 일정 ID 또는 그룹 일정 ID
  "startDatetime": "2025-10-21T14:00:00",
  "endDatetime": "2025-10-21T16:00:00"
}

Response:
{
  "id": 1,
  "placeId": 1,
  "eventId": 123,
  "startDatetime": "2025-10-21T14:00:00",
  "endDatetime": "2025-10-21T16:00:00",
  "createdAt": "2025-10-20T10:00:00"
}
```

---

## ⚠️ 예외 처리

### 1. 네트워크 에러

**시나리오**: 백엔드 서버 접속 불가

**처리**:
- 바텀시트에 에러 상태 표시
- 에러 메시지: "장소 목록을 불러올 수 없습니다"
- "다시 시도" 버튼 제공
- 스낵바: "네트워크 연결을 확인하세요"

**코드**:
```dart
try {
  final places = await _placeService.getPlaces();
  setState(() => _places = places);
} catch (e) {
  setState(() => _error = e.toString());
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("장소 목록 로드 실패: $e"),
      action: SnackBarAction(label: "재시도", onPressed: _retry),
    ),
  );
}
```

### 2. 예약 충돌 (409 Conflict)

**시나리오**: 다른 사용자가 동시에 같은 시간대 예약

**처리**:
- 낙관적 락 실패 → 409 CONFLICT 응답
- 에러 다이얼로그: "이미 다른 사용자가 예약했습니다"
- 캘린더 자동 새로고침
- 사용자에게 다른 시간 선택 유도

**코드**:
```dart
try {
  await _placeCalendarProvider.createReservation(
    placeId: placeId,
    request: request,
  );
} on DioException catch (e) {
  if (e.response?.statusCode == 409) {
    _showConflictDialog();
    _refreshCalendar();
  } else {
    _showErrorSnackbar(e.toString());
  }
}
```

### 3. 운영시간 외 예약 시도 (400 Bad Request)

**시나리오**: 프론트엔드 검증 통과했지만 백엔드에서 거부

**처리**:
- 400 BAD_REQUEST 응답
- 에러 메시지: "운영 시간이 아닙니다"
- 캘린더 데이터 재로드 (동기화)

### 4. 빈 장소 목록

**시나리오**: 사용자가 접근 가능한 장소가 없음

**처리**:
- 바텀시트에 빈 상태 표시
- 아이콘: `Icons.place` (회색)
- 메시지: "사용 가능한 장소가 없습니다"
- 안내: "그룹 관리자에게 장소 사용 권한을 요청하세요"

### 5. 타임아웃

**시나리오**: API 응답 지연 (10초 이상)

**처리**:
- Dio 타임아웃 설정: 10초
- 타임아웃 발생 시 에러 상태로 전환
- 재시도 버튼 제공

---

## 📊 성능 고려사항

### 1. 데이터 로딩 최적화

**문제**: 여러 장소 선택 시 API 호출 증가

**해결책**:
```dart
// Bad: 각 장소마다 개별 API 호출
for (final placeId in selectedPlaceIds) {
  await _placeService.getReservations(placeId, start, end);
  await _placeService.getBlockedTimes(placeId, start, end);
  await _placeService.getAvailability(placeId);
}

// Good: 단일 API로 모든 장소 데이터 조회
final calendarData = await _placeService.getPlaceCalendar(
  placeIds: selectedPlaceIds,
  startDate: start,
  endDate: end,
);
// Response: { placeId: { reservations, blockedTimes, availability } }
```

### 2. 캐싱 전략

**장소 목록 캐싱**:
```dart
class PlaceListCache {
  static List<Place>? _cachedPlaces;
  static DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 5);

  static Future<List<Place>> getPlaces(PlaceService service) async {
    final now = DateTime.now();

    if (_cachedPlaces != null &&
        _cacheTimestamp != null &&
        now.difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedPlaces!;
    }

    _cachedPlaces = await service.getPlaces();
    _cacheTimestamp = now;
    return _cachedPlaces!;
  }

  static void invalidate() {
    _cachedPlaces = null;
    _cacheTimestamp = null;
  }
}
```

**예약 데이터 캐싱** (주간 단위):
```dart
final _reservationCache = <String, List<PlaceReservation>>{};

String _getCacheKey(List<int> placeIds, DateTime week) {
  final weekKey = '${week.year}-W${week.weekOfYear}';
  return '${placeIds.join(',')}_$weekKey';
}

Future<List<PlaceReservation>> _loadReservationsWithCache() async {
  final cacheKey = _getCacheKey(selectedPlaceIds, _weekStart);

  if (_reservationCache.containsKey(cacheKey)) {
    return _reservationCache[cacheKey]!;
  }

  final reservations = await _placeService.getPlaceCalendar(...);
  _reservationCache[cacheKey] = reservations;
  return reservations;
}
```

### 3. 렌더링 최적화

**회색 셀 계산 메모이제이션**:
```dart
class BlockedSlotsCalculator {
  final _cache = <String, Set<DateTime>>{};

  Set<DateTime> calculate({
    required int placeId,
    required List<PlaceAvailability> availability,
    required List<PlaceReservation> reservations,
    required List<PlaceBlockedTime> blockedTimes,
  }) {
    final cacheKey = '$placeId-${availability.hashCode}-${reservations.hashCode}-${blockedTimes.hashCode}';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final blocked = _calculateBlockedSlotsInternal(...);
    _cache[cacheKey] = blocked;
    return blocked;
  }
}
```

### 4. 교집합 계산 최적화

**다중 장소 예약 가능 시간 계산**:
```dart
// Bad: O(n * m * k) - 모든 셀마다 모든 장소 검사
for (final slot in allSlots) {
  bool available = true;
  for (final placeId in placeIds) {
    if (_isBlocked(placeId, slot)) {
      available = false;
      break;
    }
  }
  if (available) result.add(slot);
}

// Good: O(n + m) - 차단 시간 집합 먼저 계산 후 교집합
final allSlots = _getAllTimeSlots();
Set<DateTime> available = Set.from(allSlots);

for (final placeId in placeIds) {
  final blocked = _blockedSlotsCache[placeId] ?? {};
  available = available.difference(blocked);
}
return available;
```

---

## 🧪 테스트 시나리오

### 1. 단일 장소 선택 테스트

**시나리오 1.1: 정상 플로우**
```
Given: 사용자가 "60주년 18203" 장소 선택
When: 월요일 14:00-16:00 시간 블록 생성
Then:
  - 일정 생성 다이얼로그 표시
  - 장소 자동 선택 (체크박스 체크됨)
  - "생성" 클릭 시 일정 + 예약 생성
  - 성공 스낵바 표시
```

**시나리오 1.2: 운영시간 외**
```
Given: "60주년 18203" 운영시간 09:00-18:00
When: 사용자가 월요일 20:00-21:00 클릭
Then:
  - 회색 셀 표시
  - 클릭 시 "운영 시간 외" 에러 다이얼로그
```

**시나리오 1.3: 기존 예약**
```
Given: "60주년 18203" 월요일 14:00-16:00 예약 존재
When: 사용자가 해당 시간 블록 클릭
Then:
  - 회색 셀 표시
  - 클릭 시 "이미 예약됨 (예약자: AISC)" 다이얼로그
```

**시나리오 1.4: 장소 없이 일정만 생성**
```
Given: "60주년 18203" 선택
When: 월요일 14:00-16:00 블록 생성
  And: 장소 체크박스 해제
  And: "생성" 클릭
Then:
  - 일정만 생성 (예약 없음)
  - "일정이 생성되었습니다" 스낵바
```

### 2. 다중 장소 선택 테스트

**시나리오 2.1: 2개 장소 모두 예약 가능**
```
Given: "60주년 18203", "창의관 201" 선택
When: 월요일 14:00-16:00 블록 생성 (모두 예약 가능)
Then:
  - 일정 생성 다이얼로그 표시
  - 드롭다운에 2개 장소 표시
  - 장소 선택 후 "생성" → 예약 생성
```

**시나리오 2.2: 한 장소만 예약 가능**
```
Given: "60주년 18203" (예약 가능), "창의관 201" (기존 예약)
When: 월요일 14:00-16:00 블록 생성 시도
Then:
  - 해당 시간 회색으로 표시
  - 클릭 시 "2개 장소 중 1개 예약 불가" 에러
```

**시나리오 2.3: 모든 장소 예약 불가**
```
Given: 3개 장소 선택, 모두 월요일 14:00-16:00 예약됨
When: 해당 시간 블록 클릭
Then:
  - 회색 셀 표시
  - "모든 장소가 예약 불가" 에러 다이얼로그
```

### 3. 에러 처리 테스트

**시나리오 3.1: 네트워크 에러**
```
Given: 백엔드 서버 중지
When: "장소 추가" 버튼 클릭
Then:
  - 바텀시트에 로딩 표시
  - 10초 후 타임아웃
  - 에러 상태 표시 + "다시 시도" 버튼
```

**시나리오 3.2: 동시 예약 충돌**
```
Given: 사용자 A, B가 동시에 같은 시간 예약 시도
When: A가 먼저 "생성" 클릭 → 성공
  And: B가 "생성" 클릭 → 409 Conflict
Then:
  - B에게 "이미 예약됨" 에러 다이얼로그
  - 캘린더 자동 새로고침
```

### 4. 성능 테스트

**시나리오 4.1: 다중 장소 로딩 성능**
```
Given: 10개 장소 선택
When: 주간 데이터 로드
Then:
  - 단일 API 호출로 모든 데이터 조회
  - 로딩 시간 < 2초
  - 회색 셀 계산 시간 < 500ms
```

**시나리오 4.2: 캐시 동작 확인**
```
Given: 장소 목록 로드 완료
When: 바텀시트 닫고 다시 열기
Then:
  - 캐시된 데이터 즉시 표시 (로딩 없음)
  - 5분 후 재로드 시 새로운 API 호출
```

---

## 📝 논의 필요 사항

### 1. UI/UX 패턴

#### 1.1. 회색 셀 시각적 표현

**옵션 A: 단순 회색 배경**
- 장점: 심플하고 직관적
- 단점: 차단 이유 구분 어려움

**옵션 B: 아이콘 + 회색 배경**
- 장점: 차단 이유를 아이콘으로 구분 가능 (⏰ 운영시간, 🚫 예약됨, 🔧 유지보수)
- 단점: 작은 셀에 아이콘 표시 어려움

**옵션 C: 대각선 패턴 + 회색 배경**
- 장점: 시각적으로 명확함
- 단점: 성능 오버헤드 (CustomPaint)

**질문**:
- 어떤 방식이 사용자에게 가장 직관적일까요?
- 차단 이유를 구분할 필요가 있을까요? (툴팁으로 충분한가?)

#### 1.2. 다중 장소 선택 시 드롭다운 위치

**옵션 A: 일정 생성 다이얼로그 내부**
- 장점: 모든 정보가 한 곳에
- 단점: 다이얼로그가 복잡해짐

**옵션 B: 별도 스텝 (2단계 플로우)**
- Step 1: 시간 블록 선택 → 장소 선택 바텀시트
- Step 2: 제목 입력 다이얼로그
- 장점: 각 스텝이 단순함 (One Thing Per Page)
- 단점: 플로우가 길어짐

**질문**:
- 사용자 경험상 어느 것이 더 자연스러울까요?

#### 1.3. 장소 없이 일정만 생성 옵션

**현재 설계**: 체크박스 또는 "장소 없음" 드롭다운 항목

**대안**:
- 장소 선택을 아예 별도 버튼으로 분리 ("+ 장소 추가" 버튼)
- 장점: 명확한 의도 구분
- 단점: UI 복잡도 증가

**질문**:
- 대부분의 사용자가 장소를 예약할까요, 아니면 선택사항일까요?
- 기본값을 어떻게 설정해야 할까요?

### 2. 데이터 동기화

#### 2.1. 실시간 업데이트

**현재 설계**: 사용자가 주간 전환 시에만 데이터 새로고침

**대안**:
- WebSocket 또는 Polling으로 실시간 예약 현황 동기화
- 장점: 다른 사용자의 예약을 즉시 반영
- 단점: 백엔드 복잡도 증가, 프론트엔드 성능 영향

**질문**:
- 실시간 동기화가 필수일까요?
- 예약 충돌이 얼마나 자주 발생할까요?

#### 2.2. 낙관적 업데이트 vs 비관적 업데이트

**낙관적 업데이트** (현재 설계):
- 사용자 액션 즉시 UI 반영
- 백엔드 응답 후 롤백 (실패 시)
- 장점: 빠른 UX
- 단점: 충돌 시 혼란

**비관적 업데이트**:
- 백엔드 응답 대기 후 UI 반영
- 장점: 정확성
- 단점: 느린 UX

**질문**:
- 예약 생성 시 어떤 방식이 적절할까요?

### 3. 에러 처리 상세 수준

#### 3.1. 회색 셀 클릭 시 에러 메시지 상세도

**간단한 메시지**:
- "이 시간은 예약할 수 없습니다"
- 장점: 간결함
- 단점: 사용자가 이유를 모름

**상세한 메시지**:
- "이 시간은 다음 이유로 예약할 수 없습니다: 운영시간 외 (운영: 09:00-18:00)"
- 장점: 사용자가 대안 찾기 쉬움
- 단점: 메시지가 길어짐

**질문**:
- 어느 정도 수준의 정보가 적절할까요?
- 모든 차단 이유를 나열해야 할까요? (운영시간 외 + 기존 예약이 동시에 있는 경우)

#### 3.2. 예약 충돌 시 대안 제시

**기본 처리**: "이미 예약되었습니다" 에러만 표시

**대안 제시**:
- "이미 예약되었습니다. 다음 시간은 예약 가능합니다: 16:00-18:00"
- 또는 "가장 가까운 예약 가능 시간으로 이동" 버튼

**질문**:
- 대안을 자동으로 제시하는 것이 도움이 될까요?
- 어떤 방식으로 제시해야 할까요?

### 4. 성능 최적화 우선순위

#### 4.1. 초기 로딩 vs 인터랙션 성능

**초기 로딩 최적화**:
- 장소 목록, 예약 데이터를 미리 로드
- 장점: 사용자가 빠르게 시작
- 단점: 초기 번들 크기 증가

**인터랙션 성능 최적화**:
- 필요할 때만 데이터 로드 (Lazy Loading)
- 장점: 초기 로딩 빠름
- 단점: 클릭 시 대기 시간

**질문**:
- 어느 것을 우선해야 할까요?
- 테스트 단계에서는 데이터 규모가 작지만, 실사용 시 확장성을 고려해야 할까요?

#### 4.2. 캐싱 전략

**현재 설계**: 메모리 캐싱 (5분)

**대안**:
- LocalStorage/IndexedDB 영구 캐싱
- 장점: 페이지 새로고침 후에도 유지
- 단점: 동기화 복잡도 증가

**질문**:
- 영구 캐싱이 필요할까요?
- 캐시 무효화 전략은? (장소 정보 변경 시)

---

## 💡 개선 의견 제안

### 1. 사용자 경험 개선

#### 1.1. 스마트 시간 제안 (Smart Time Suggestion)

**현재 설계**: 사용자가 직접 시간 선택

**개선안**:
```dart
// 예약 가능한 다음 시간 자동 제안
class SmartTimeSuggester {
  DateTime? suggestNextAvailableSlot({
    required List<int> placeIds,
    required DateTime preferredStart,
    required Duration duration,
  }) {
    // 선호 시간부터 순회하며 첫 번째 가능한 슬롯 찾기
    for (int hour = preferredStart.hour; hour < 24; hour++) {
      final start = DateTime(
        preferredStart.year,
        preferredStart.month,
        preferredStart.day,
        hour,
        0,
      );
      final end = start.add(duration);

      if (_isAvailable(placeIds, start, end)) {
        return start;
      }
    }
    return null;
  }
}

// UI에서 사용
if (_isBlockedTime(selectedTime)) {
  final suggested = _suggester.suggestNextAvailableSlot(
    placeIds: selectedPlaceIds,
    preferredStart: selectedTime,
    duration: Duration(hours: 1),
  );

  if (suggested != null) {
    _showSuggestionDialog(
      "선택한 시간은 예약 불가합니다.\n"
      "${formatTime(suggested)}부터 예약 가능합니다.",
      onAccept: () => _createEventAt(suggested),
    );
  }
}
```

**효과**:
- 사용자가 여러 번 시도하지 않아도 됨
- 빠른 예약 완료
- 긍정적 사용자 경험 (문제 + 해결책 동시 제공)

#### 1.2. 예약 가능 시간 하이라이트 (Available Time Highlight)

**현재 설계**: 회색(불가) / 흰색(가능)

**개선안**:
- 장소 선택 시 예약 가능한 시간을 연한 초록색으로 하이라이트
- 회색(불가) / 흰색(일반) / 초록(추천)
- 추천 기준: 연속된 2시간 이상 예약 가능

**코드**:
```dart
Color _getCellColor(DateTime slot) {
  if (_isBlockedTime(slot)) {
    return AppColors.neutral300.withOpacity(0.5);  // 회색
  }

  if (selectedPlaceIds.isEmpty) {
    return Colors.transparent;  // 흰색
  }

  // 연속된 예약 가능 시간 (2시간 이상) 체크
  if (_isContinuousAvailable(slot, duration: Duration(hours: 2))) {
    return AppColors.success.withOpacity(0.1);  // 연한 초록
  }

  return Colors.transparent;
}
```

**효과**:
- 사용자가 최적의 시간을 빠르게 찾음
- 긴 회의/세미나 일정에 유용

#### 1.3. 장소 필터링 및 검색 (Place Filtering & Search)

**현재 설계**: 모든 장소 나열

**개선안**:
```dart
// PlaceSelectorBottomSheet에 검색 및 필터 추가
TextField(
  decoration: InputDecoration(
    prefixIcon: Icon(Icons.search),
    hintText: "장소 검색 (건물, 방번호, 별칭)",
  ),
  onChanged: (query) => _filterPlaces(query),
)

Row(
  children: [
    FilterChip(
      label: Text("즐겨찾기"),
      selected: _showFavoritesOnly,
      onSelected: (value) => setState(() => _showFavoritesOnly = value),
    ),
    FilterChip(
      label: Text("예약 가능"),
      selected: _showAvailableOnly,
      onSelected: (value) => setState(() => _showAvailableOnly = value),
    ),
  ],
)
```

**효과**:
- 장소가 많을 때 빠른 찾기
- 즐겨찾기 기능으로 자주 쓰는 장소 관리

### 2. 기술적 최적화

#### 2.1. 가상 스크롤링 (Virtual Scrolling)

**현재 설계**: 모든 셀을 한 번에 렌더링

**문제점**:
- 1주일 = 7일 × 48개(30분 단위) = 336개 셀
- 10개 장소 × 336개 셀 = 3,360개 위젯
- 성능 저하 가능

**개선안**:
```dart
// ListView.builder로 가상 스크롤링
ListView.builder(
  itemCount: 7,  // 7일
  itemBuilder: (context, dayIndex) {
    return Column(
      children: _buildTimeSlotsForDay(dayIndex),
    );
  },
)

// 보이는 영역만 렌더링
class VirtualizedCalendar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _updateVisibleRange(notification.metrics);
        return true;
      },
      child: ListView.builder(
        itemCount: _visibleDays.length,
        itemBuilder: (context, index) {
          return _buildDay(_visibleDays[index]);
        },
      ),
    );
  }
}
```

**효과**:
- 메모리 사용량 감소
- 초기 렌더링 속도 향상
- 부드러운 스크롤

#### 2.2. Debounce 및 Throttle

**현재 설계**: 장소 선택 변경 시 즉시 API 호출

**문제점**:
- 사용자가 여러 장소를 빠르게 선택/해제 → 과도한 API 호출

**개선안**:
```dart
// Debounce: 마지막 변경 후 300ms 대기
Timer? _debounceTimer;

void _onPlaceSelectionChanged() {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 300), () {
    _loadReservationsForSelectedPlaces();
  });
}

// Throttle: 최대 1초에 1번만 호출
DateTime? _lastApiCall;

Future<void> _throttledLoadReservations() async {
  final now = DateTime.now();
  if (_lastApiCall != null &&
      now.difference(_lastApiCall!) < Duration(seconds: 1)) {
    return;
  }

  _lastApiCall = now;
  await _loadReservationsForSelectedPlaces();
}
```

**효과**:
- 불필요한 API 호출 감소
- 서버 부하 감소
- 배터리 절약 (모바일)

#### 2.3. 백그라운드 프리로드 (Background Preloading)

**현재 설계**: 사용자가 주간 전환 시 데이터 로드

**개선안**:
```dart
// 다음 주/이전 주 데이터 미리 로드
void _preloadAdjacentWeeks() {
  final nextWeek = _weekStart.add(Duration(days: 7));
  final prevWeek = _weekStart.subtract(Duration(days: 7));

  // 백그라운드에서 조용히 로드 (에러 무시)
  _loadReservationsForWeek(nextWeek, silent: true);
  _loadReservationsForWeek(prevWeek, silent: true);
}

// 주간 전환 시 즉시 표시
void _onWeekChanged(DateTime newWeek) {
  final cached = _weekCache[newWeek];
  if (cached != null) {
    setState(() => _reservations = cached);
  } else {
    _loadReservationsForWeek(newWeek);
  }
}
```

**효과**:
- 주간 전환 시 즉시 표시 (로딩 없음)
- 부드러운 사용자 경험

### 3. 접근성 개선

#### 3.1. 키보드 네비게이션

**개선안**:
- 화살표 키로 시간 블록 이동
- Enter 키로 일정 생성 다이얼로그 열기
- Tab 키로 장소 선택 순회
- Esc 키로 다이얼로그 닫기

```dart
Focus(
  onKey: (node, event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _moveToNextSlot();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _showEventCreationDialog();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  },
  child: CalendarGrid(...),
)
```

#### 3.2. 스크린 리더 지원

**개선안**:
- Semantics 위젯으로 의미 전달
- 회색 셀: "예약 불가, 이유: 운영시간 외"
- 예약 블록: "AISC 정기회의, 14시부터 16시까지"

```dart
Semantics(
  label: isBlockedTime
    ? "예약 불가, ${_getBlockedReason()}"
    : "예약 가능, ${formatTime(slot)}",
  button: !isBlockedTime,
  enabled: !isBlockedTime,
  onTap: isBlockedTime ? null : _onCellTap,
  child: Container(...),
)
```

#### 3.3. 색상 대비 검증

**개선안**:
- 회색 셀과 흰색 셀의 명도 대비 4.5:1 이상 확보
- 텍스트 색상 자동 조정 (배경이 어두우면 흰색, 밝으면 검은색)

```dart
Color _getTextColorForBackground(Color background) {
  final luminance = background.computeLuminance();
  return luminance > 0.5 ? Colors.black : Colors.white;
}
```

### 4. 향후 확장 가능성

#### 4.1. 반복 일정 지원

**현재 설계**: 단일 일정만 생성

**향후 확장**:
- "매주 반복" 옵션 추가
- 반복 종료일 설정
- 반복 예약 생성 (여러 주간)

#### 4.2. 그룹 일정과의 통합

**현재 설계**: 개인 일정 또는 테스트용

**향후 확장**:
- 그룹 일정 생성 시 장소 선택
- 그룹 캘린더 페이지에서도 동일한 장소 예약 기능
- PlaceReservation ↔ GroupEvent 연동

#### 4.3. 알림 및 리마인더

**향후 확장**:
- 예약 1시간 전 푸시 알림
- 예약 취소 시 관련자에게 알림
- 장소 차단 시 예약자에게 알림

---

## 📚 참조 문서

### 개념 문서
- [장소 관리 개념](../concepts/calendar-place-management.md)
- [캘린더 시스템](../concepts/calendar-system.md)
- [권한 시스템](../concepts/permission-system.md)

### 구현 가이드
- [장소 캘린더 명세](place-calendar-specification.md)
- [프론트엔드 가이드](../implementation/frontend-guide.md)
- [디자인 시스템](../ui-ux/concepts/design-system.md)

### 관련 코드
- `frontend/lib/presentation/pages/demo_calendar/demo_calendar_page.dart`
- `frontend/lib/presentation/providers/place_calendar_provider.dart`
- `frontend/lib/core/services/place_service.dart`
- `frontend/lib/presentation/widgets/weekly_calendar/weekly_schedule_editor.dart`

---

## 📅 다음 단계

### Phase 1: 기본 구현 (8-10시간)
1. PlaceSelectorBottomSheet 구현 (2h)
2. PlaceSelectionHeader 구현 (1h)
3. 회색 셀 표시 로직 구현 (3h)
4. 일정 생성 다이얼로그 수정 (2h)
5. API 연동 및 테스트 (2h)

### Phase 2: 개선 및 최적화 (4-6시간)
1. 캐싱 전략 구현 (2h)
2. 성능 최적화 (1h)
3. 에러 처리 강화 (1h)
4. UI/UX 폴리시 (2h)

### Phase 3: 확장 기능 (선택, 6-8시간)
1. 스마트 시간 제안 (2h)
2. 장소 필터링 및 검색 (2h)
3. 접근성 개선 (2h)
4. 백그라운드 프리로드 (2h)

**총 예상 시간**: 18-24시간 (Phase 1-2 필수, Phase 3 선택)

---

**작성자**: Frontend Development Agent
**검토 필요**: UI/UX 패턴, 성능 최적화 우선순위, 에러 처리 상세도
**다음 액션**: 사용자와 논의 사항 검토 후 Phase 1 구현 착수
