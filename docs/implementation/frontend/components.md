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

## 관련 문서

- [프론트엔드 아키텍처](architecture.md) - 전체 구조
- [디자인 시스템](../ui-ux/concepts/design-system.md) - UI 가이드라인
- [상태 관리](state-management.md) - Riverpod 패턴
