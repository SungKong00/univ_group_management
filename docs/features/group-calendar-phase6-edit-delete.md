# 그룹 캘린더 Phase 6: 일정 수정/삭제 기능 구현

> **작성일**: 2025-10-12
> **선행 작업**: Phase 1-5 (백엔드 API + 생성 기능)
> **소요 시간**: 3시간

---

## 📋 Phase 6 개요

Phase 5에서 일정 생성 기능을 구현한 후, 일정 수정/삭제 기능을 추가했습니다.

### 구현 기능
- ✅ 일정 상세 보기 (BottomSheet)
- ✅ 수정/삭제 옵션 메뉴
- ✅ 반복 일정 선택 다이얼로그 ("이 일정만" / "이후 전체")
- ✅ 일정 수정 (GroupEventFormDialog 재사용)
- ✅ 일정 삭제 (확인 다이얼로그)
- ✅ 권한 체크 (작성자 본인 확인)

---

## ✅ 구현 완료 사항

### 1. 일정 상세 보기 (`_showEventDetail()`)

**UI 형식**: DraggableScrollableSheet (하단에서 올라오는 시트)

**표시 항목**:
- 제목 (+ 공식/비공식 배지, 반복 아이콘)
- 시간 (날짜 범위 + 시간)
- 장소 (있는 경우)
- 설명 (있는 경우)
- 작성자 정보
- 생성/수정 시간

**코드 구조**:
```dart
Future<void> _showEventDetail(GroupEvent event) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        // 상세 정보 표시
        child: ListView(
          children: [
            // 제목 + 배지 + 옵션 버튼
            // 시간 정보
            // 장소, 설명
            // 작성자 정보
            // 생성/수정 시간
          ],
        ),
      ),
    ),
  );
}
```

---

### 2. 옵션 메뉴 (`_showEventActions()`)

**UI 형식**: ModalBottomSheet (하단 메뉴)

**메뉴 항목**:
- "수정" (파란색 아이콘)
- "삭제" (빨간색 아이콘)
- "취소"

**권한 체크**:
```dart
bool _canModifyEvent(GroupEvent event) {
  final currentUser = ref.read(currentUserProvider);
  if (currentUser == null) return false;

  // 공식 일정: CALENDAR_MANAGE 권한 필요 (TODO: 백엔드 연동)
  if (event.isOfficial) {
    return false; // Placeholder
  }

  // 비공식 일정: 작성자 본인만 수정/삭제 가능
  return event.creatorId == currentUser.id;
}
```

---

### 3. 반복 일정 선택 다이얼로그 (`_showUpdateScopeDialog()`)

**UI 형식**: AlertDialog

**선택 옵션**:
- "이 일정만" (`UpdateScope.thisEvent`)
- "이후 모든 반복 일정" (`UpdateScope.allEvents`)
- "취소"

**사용 시점**:
- 반복 일정 수정 시
- 반복 일정 삭제 시

**코드 구조**:
```dart
Future<UpdateScope?> _showUpdateScopeDialog({bool isDelete = false}) async {
  return showDialog<UpdateScope>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(isDelete ? '반복 일정 삭제' : '반복 일정 수정'),
      content: Column(
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(UpdateScope.thisEvent),
            child: const Text('이 일정만'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(UpdateScope.allEvents),
            child: const Text('이후 모든 반복 일정'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('취소'),
        ),
      ],
    ),
  );
}
```

---

### 4. 일정 수정 (`_handleEditEvent()`)

**흐름**:
1. 반복 일정인 경우 → `_showUpdateScopeDialog()` 호출
2. `showGroupEventFormDialog()` 호출 (기존 폼 재사용, `initial` 파라미터로 기존 일정 전달)
3. 사용자가 폼 제출 → API 호출 (`updateEvent()`)
4. Provider 상태 업데이트
5. 성공 메시지 표시

**API 호출**:
```dart
await ref
    .read(groupCalendarProvider(widget.groupId).notifier)
    .updateEvent(
  groupId: widget.groupId,
  eventId: event.id,
  title: result.title,
  description: result.description,
  location: result.location,
  startDate: result.startDate,
  endDate: result.endDate,
  isAllDay: result.isAllDay,
  color: result.color.toHex(),
  updateScope: updateScope ?? UpdateScope.thisEvent,
);
```

**참고**: GroupEventFormDialog는 수정 모드를 지원합니다 (`initial` 파라미터).
- 수정 모드에서는 반복 일정 선택기가 숨겨집니다 (`if (!_isEditing)`).

---

### 5. 일정 삭제 (`_handleDeleteEvent()`)

**흐름**:
1. 반복 일정인 경우 → `_showUpdateScopeDialog(isDelete: true)` 호출
2. 확인 다이얼로그 표시
3. 사용자가 "삭제" 클릭 → API 호출 (`deleteEvent()`)
4. Provider에서 해당 일정 제거
5. 성공 메시지 표시

**확인 다이얼로그**:
```dart
final confirmed = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('일정 삭제'),
    content: Text(
      event.isRecurring && deleteScope == UpdateScope.allEvents
          ? '이후 모든 반복 일정이 삭제됩니다. 계속하시겠습니까?'
          : '이 일정을 삭제하시겠습니까?',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('취소'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(true),
        style: TextButton.styleFrom(foregroundColor: AppColors.error),
        child: const Text('삭제'),
      ),
    ],
  ),
);
```

**API 호출**:
```dart
await ref
    .read(groupCalendarProvider(widget.groupId).notifier)
    .deleteEvent(
  groupId: widget.groupId,
  eventId: event.id,
  deleteScope: deleteScope ?? UpdateScope.thisEvent,
);
```

---

## 🔍 API 연동

### UpdateScope Enum

**백엔드 (Kotlin)**:
```kotlin
enum class UpdateScope(val apiValue: String) {
    THIS_EVENT("THIS_EVENT"),
    ALL_EVENTS("ALL_EVENTS")
}
```

**프론트엔드 (Dart)**:
```dart
enum UpdateScope {
  thisEvent('THIS_EVENT'),
  allEvents('ALL_EVENTS');

  const UpdateScope(this.apiValue);
  final String apiValue;
}
```

### API 엔드포인트

#### 수정
```
PUT /api/groups/{groupId}/events/{eventId}
Request Body:
{
  "title": "수정된 제목",
  "startTime": "14:00:00",  // 시간만 수정 가능
  "endTime": "16:00:00",
  "isAllDay": false,
  "color": "#3B82F6",
  "updateScope": "THIS_EVENT"  // or "ALL_EVENTS"
}

Response: 200 OK
{
  "success": true,
  "data": [ /* 수정된 GroupEvent(s) */ ]
}
```

#### 삭제
```
DELETE /api/groups/{groupId}/events/{eventId}?scope=THIS_EVENT
Response: 204 No Content
```

---

## 📊 테스트 가이드

### 1. 일정 상세 보기 테스트

**시나리오**:
1. 그룹 캘린더 페이지에서 일정 클릭
2. 하단에서 상세 정보 시트가 올라옴
3. 제목, 시간, 장소, 설명, 작성자 정보 확인
4. 반복 일정인 경우 "반복" 아이콘 표시 확인
5. 공식 일정인 경우 "공식" 배지 표시 확인

**기대 결과**:
- 모든 정보가 정확히 표시됨
- 시트를 위/아래로 드래그 가능
- 시트 바깥 영역 터치 시 닫힘

---

### 2. 수정 기능 테스트

**시나리오 A: 단일 일정 수정**
1. 그룹 캘린더 페이지에서 본인이 생성한 일정 클릭
2. 상세 보기에서 "..." 버튼 클릭 → "수정" 선택
3. 제목을 "수정된 회의"로 변경
4. 시간을 15:00 ~ 17:00으로 변경
5. "수정" 버튼 클릭
6. 목록에서 변경 사항 확인

**기대 결과**:
- 수정된 내용이 즉시 반영됨
- "일정이 수정되었습니다" 메시지 표시

**시나리오 B: 반복 일정 수정**
1. 반복 일정 클릭 → "수정" 선택
2. **"이 일정만" / "이후 전체" 선택 다이얼로그 표시**
3. "이 일정만" 선택
4. 제목을 "특별 회의"로 변경
5. "수정" 버튼 클릭
6. 목록에서 해당 일정만 변경 확인

**기대 결과**:
- 선택한 일정만 수정됨
- 다른 반복 일정은 그대로 유지

---

### 3. 삭제 기능 테스트

**시나리오 A: 단일 일정 삭제**
1. 본인이 생성한 일정 클릭 → "삭제" 선택
2. **확인 다이얼로그 표시**: "이 일정을 삭제하시겠습니까?"
3. "삭제" 버튼 클릭
4. 목록에서 일정 사라짐 확인

**기대 결과**:
- 일정이 즉시 삭제됨
- "일정이 삭제되었습니다" 메시지 표시

**시나리오 B: 반복 일정 삭제**
1. 반복 일정 클릭 → "삭제" 선택
2. **"이 일정만" / "이후 전체" 선택 다이얼로그 표시**
3. "이후 모든 반복 일정" 선택
4. **확인 다이얼로그 표시**: "이후 모든 반복 일정이 삭제됩니다..."
5. "삭제" 버튼 클릭
6. 목록에서 모든 반복 일정 사라짐 확인

**기대 결과**:
- 선택한 범위의 일정이 모두 삭제됨

---

### 4. 권한 체크 테스트

**시나리오 A: 타인의 일정**
1. 다른 사용자가 생성한 일정 클릭
2. 상세 보기에서 "..." 버튼이 **표시되지 않음** 확인

**기대 결과**:
- 수정/삭제 옵션이 보이지 않음

**시나리오 B: 본인의 비공식 일정**
1. 본인이 생성한 비공식 일정 클릭
2. 상세 보기에서 "..." 버튼 표시 확인
3. "수정" / "삭제" 옵션 모두 사용 가능

**기대 결과**:
- 모든 수정/삭제 기능 정상 작동

**시나리오 C: 공식 일정 (TODO: CALENDAR_MANAGE 권한 체크)**
- 현재는 Placeholder로 항상 false 반환
- 추후 백엔드 권한 API 연동 필요

---

## 🐛 알려진 이슈 및 제한사항

### 1. 권한 체크 미완성
**문제**:
- 공식 일정 수정/삭제 시 CALENDAR_MANAGE 권한 체크가 프론트엔드에서 구현되지 않음
- 현재는 Placeholder로 항상 false 반환

**해결 방안**:
```dart
bool _canModifyEvent(GroupEvent event) {
  final currentUser = ref.read(currentUserProvider);
  if (currentUser == null) return false;

  if (event.isOfficial) {
    // TODO: Check if user has CALENDAR_MANAGE permission for this group
    // 방법 1: UserInfo 모델에 permissions 필드 추가
    // 방법 2: 별도 API 호출 (GET /api/groups/{groupId}/my-permissions)
    return false; // Placeholder
  }

  return event.creatorId == currentUser.id;
}
```

**우선순위**: 중간 (비공식 일정 수정/삭제는 정상 작동)

---

### 2. 반복 일정 "이전 일정" 수정/삭제 불가
**문제**:
- 현재 구현은 "이후 전체" (`UpdateScope.allEvents`)만 지원
- 과거 일정은 수정/삭제되지 않음

**백엔드 로직**:
```kotlin
// GroupEventService.kt (추정)
if (updateScope == UpdateScope.ALL_EVENTS) {
  val allEvents = groupEventRepository.findBySeriesId(event.seriesId!!)
  allEvents.filter { it.startDate.isAfter(LocalDate.now()) }  // 이후 일정만
      .forEach { /* 수정/삭제 */ }
}
```

**해결 방안**:
- 백엔드에서 `ALL_IN_SERIES` 옵션 추가 (과거 포함)
- 프론트엔드에서 "과거 포함" 체크박스 추가

**우선순위**: 낮음 (대부분의 사용 사례는 "이후 전체"로 충분)

---

### 3. 수정 모드에서 반복 패턴 변경 불가
**문제**:
- `GroupEventFormDialog`는 수정 모드에서 반복 일정 선택기를 숨김
- 반복 패턴 변경이 불가능

**이유**:
- 반복 패턴 변경은 복잡한 로직 필요 (일정 재생성 등)
- MVP 범위에서는 제외

**해결 방안**:
- 일정 삭제 후 새로 생성하도록 안내

**우선순위**: 낮음

---

## 📝 다음 단계

### Phase 7: 캘린더 뷰 개선 (예정)
- [ ] 월간 캘린더 뷰 (table-calendar 패키지 활용)
- [ ] 주간 캘린더 뷰 (WeekView 컴포넌트)
- [ ] 일간 캘린더 뷰 (DayView 컴포넌트)
- [ ] 탭 전환 (월/주/일)

### Phase 8: 권한 시스템 통합
- [ ] 프론트엔드 권한 API 연동
- [ ] CALENDAR_MANAGE 권한 체크
- [ ] 공식 일정 수정/삭제 권한 확인

### Phase 9: 고급 기능
- [ ] 일정 검색 기능
- [ ] 일정 필터링 (공식/비공식, 작성자별)
- [ ] 일정 알림 (Push Notification)
- [ ] 개인 캘린더 통합 뷰

---

## 📦 변경 파일 목록

### 수정된 파일
1. `frontend/lib/presentation/pages/workspace/calendar/group_calendar_page.dart`
   - `_showEventDetail()` 구현
   - `_showEventActions()` 구현
   - `_handleEditEvent()` 구현
   - `_handleDeleteEvent()` 구현
   - `_showUpdateScopeDialog()` 구현
   - `_canModifyEvent()` 헬퍼 함수 추가
   - `_buildDetailRow()` 헬퍼 함수 추가
   - `_formatDateTime()` 헬퍼 함수 추가

### 추가된 Import
```dart
import '../../../../core/models/calendar/group_event.dart';
import '../../../../core/models/calendar/update_scope.dart';
import '../../../providers/auth_provider.dart';
```

### 의존성
- `currentUserProvider` (AuthProvider)
- `groupCalendarProvider` (GroupCalendarProvider)
- `GroupCalendarService` (updateEvent, deleteEvent 메서드)
- `UpdateScope` enum

---

## 🎉 완료 조건 체크리스트

- ✅ 일정 클릭 → 상세 보기 표시
- ✅ 상세 보기에서 "수정" 클릭 → 수정 폼 표시 → 수정 완료
- ✅ 반복 일정 수정 시 "이 일정만" / "이후 전체" 선택 가능
- ✅ 상세 보기에서 "삭제" 클릭 → 확인 다이얼로그 → 삭제 완료
- ✅ 반복 일정 삭제 시 "이 일정만" / "이후 전체" 선택 가능
- ✅ 권한 없는 사용자는 수정/삭제 버튼 비활성화 (본인의 비공식 일정만 허용)

---

**작성자**: Claude Code
**최종 수정**: 2025-10-12
