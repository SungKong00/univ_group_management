# 컴포넌트 구현 (Components)

## StateView - 범용 상태 관리 위젯

**파일**: presentation/widgets/common/state_view.dart
**구현일**: 2025-10-24

**목적**: AsyncValue의 loading/error/empty/data 상태를 통합 처리

**주요 기능**:
- AsyncValue<T> 자동 상태 처리 (when 메서드 활용)
- 빈 상태 자동 감지 (emptyChecker 함수)
- 커스터마이징 가능한 UI (아이콘, 제목, 설명, 액션 버튼)
- Extension 메서드로 간편한 사용 (buildWith)
- 재시도 기능 (onRetry 콜백)

**사용 예시**:

```dart
// 기본 사용
final usersAsync = ref.watch(usersProvider);

return StateView<List<User>>(
  value: usersAsync,
  emptyChecker: (users) => users.isEmpty,
  emptyIcon: Icons.person_off,
  emptyTitle: '사용자가 없습니다',
  emptyDescription: '아직 등록된 사용자가 없습니다',
  builder: (context, users) => UserList(users: users),
  onRetry: () => ref.refresh(usersProvider),
);

// Extension 사용
return usersAsync.buildWith(
  context: context,
  builder: (users) => UserList(users: users),
  emptyChecker: (users) => users.isEmpty,
  emptyTitle: '사용자가 없습니다',
);
```

**적용 현황**: 9개 파일 (147줄 감소)
- workspace_page.dart
- recruitment_management_page.dart (-83줄)
- member_list_section.dart
- role_management_section.dart (-9줄)
- channel_list_section.dart (-55줄)
- recruitment_application_section.dart
- join_request_section.dart
- channel_management_page.dart
- (more...)

---

## CompactMonthCalendar - 소형 월간 캘린더 위젯

**파일**: presentation/widgets/calendar/compact_month_calendar.dart
**구현일**: 2025-11-02

**목적**: 그룹 홈 대시보드에서 그룹 일정을 월간 뷰로 미리보기

**주요 기능**:
- 작은 크기 (280px 높이) 최적화 월간 캘린더
- 이벤트 표시 (일별 최대 3개 색상 점)
- 월 네비게이션 (이전/다음 월 버튼)
- 날짜 선택 시 전체 캘린더로 이동
- TableCalendar 기반으로 일관된 UX 유지

**구현 특징**:
- **반응형 디자인**: 고정 높이 300px (헤더 포함)
- **이벤트 시각화**: Color 리스트를 받아 일별 5px 원형 점 표시
- **인터랙션**: 날짜 클릭 시 그룹 캘린더 페이지로 이동 (날짜 유지)
- **네비게이션**: 헤더에 "YYYY년 MM월" 표시 + 화살표 버튼

**사용 예시**:

```dart
// 그룹 홈 대시보드에서 사용
CompactMonthCalendar(
  focusedDate: _focusedDate,
  selectedDate: _selectedDate,
  eventColorsByDate: {
    DateTime(2025, 11, 5): [Colors.blue, Colors.purple],
    DateTime(2025, 11, 10): [Colors.green],
  },
  onPageChanged: (newFocusedDate) {
    setState(() => _focusedDate = newFocusedDate);
    _loadEvents();
  },
  onEventDateTap: (date) {
    // Navigate to group calendar with selected date
    navigateToCalendar(date);
  },
  onCalendarTap: () {
    // Navigate to full calendar view
    navigateToCalendar(null);
  },
)
```

**적용 현황**: 1개 파일
- group_home_view.dart (그룹 홈 대시보드)

---

## CalendarNavigator - 날짜 네비게이션 바

**파일**: presentation/widgets/calendar/calendar_navigator.dart
**구현일**: 2025-11-02

**목적**: 캘린더 페이지에서 날짜 이동을 위한 공통 네비게이션 컴포넌트

**주요 기능**:
- 이전/다음 버튼으로 날짜 이동
- 오늘 버튼 (현재 날짜가 아닐 때만 표시)
- 주간/월간 뷰 모두 지원
- 2줄 라벨 (주간 뷰) 또는 1줄 라벨 (월간 뷰)

**사용 예시**:
```dart
// 주간 뷰
CalendarNavigator(
  currentDate: _weekStart,
  isWeekView: true,
  label: '${_weekStart.year}년 ${_weekStart.month}월 ${_weekNo}주차',
  subtitle: DateFormatter.formatWeekLabel(_weekStart),
  onPrevious: () => _changeWeek(-1),
  onNext: () => _changeWeek(1),
  onToday: () => _goToToday(),
)
```

**적용 현황**: calendar/tabs/timetable_tab.dart

---

## CalendarErrorBanner - 에러 배너

**파일**: presentation/widgets/calendar/calendar_error_banner.dart
**구현일**: 2025-11-02

**목적**: 캘린더 로딩 중 에러 표시

**주요 기능**:
- 에러 메시지 표시
- 재시도 버튼 제공
- 일관된 에러 UI

**적용 현황**: calendar/tabs/timetable_tab.dart

---

## ConfirmDialog - 확인 다이얼로그

**파일**: presentation/widgets/dialogs/confirm_dialog.dart
**구현일**: 2025-11-02

**목적**: 사용자 확인이 필요한 작업에 사용하는 범용 다이얼로그

**주요 기능**:
- 일반 확인: PrimaryButton
- 삭제 확인: ErrorButton (isDestructive: true)
- 헬퍼 함수 `showConfirmDialog()` 제공

**사용 예시**:
```dart
final confirmed = await showConfirmDialog(
  context,
  title: '일정 삭제',
  message: '정말 삭제하시겠습니까?',
  confirmLabel: '삭제',
  isDestructive: true,
);
```

---

## 관련 문서

- [프론트엔드 아키텍처](architecture.md) - 전체 구조
- [디자인 시스템](../../ui-ux/concepts/design-system.md) - UI 가이드라인
- [상태 관리](state-management.md) - Riverpod 패턴
