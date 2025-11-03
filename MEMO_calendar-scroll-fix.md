# Calendar Scroll Structure Fix Memo

**Date**: 2025-11-03
**Feature**: Personal Calendar Month View Scroll Behavior
**Status**: Implemented

## Problem

개인 캘린더 월간 뷰에서 화면이 좁을 때(< 1024px) 하단 오버플로우 발생:
- 월간 캘린더 그리드와 일간 이벤트 리스트가 세로 배치(Column)
- 이벤트 리스트가 `Expanded`로 설정되어 있어 스크롤 불가
- 콘텐츠가 화면을 초과하면 픽셀 오버플로우 에러 발생

## Solution

### 변경 파일
- `frontend/lib/presentation/pages/calendar/widgets/calendar_month_with_sidebar.dart`

### 변경 내용

**Before (Narrow Screen Layout):**
```dart
return Column(
  children: [
    calendarWidget,
    const SizedBox(height: AppSpacing.sm),
    Expanded(child: eventListWidget), // ❌ 스크롤 불가
  ],
);
```

**After (Narrow Screen Layout):**
```dart
return SingleChildScrollView(  // ✅ 전체 스크롤 가능
  child: Column(
    children: [
      calendarWidget,
      const SizedBox(height: AppSpacing.sm),
      SizedBox(
        height: 400,  // ✅ 고정 높이 지정
        child: eventListWidget,
      ),
    ],
  ),
);
```

### 핵심 변경사항

1. **SingleChildScrollView 추가**: 전체 Column을 감싸서 월간 뷰 + 일간 뷰를 통째로 스크롤 가능하도록 변경
2. **Expanded → SizedBox**: 이벤트 리스트에 고정 높이(400px) 지정
3. **Wide Screen 유지**: 1024px 이상에서는 기존 Row 레이아웃 유지

## Technical Details

### Layout Hierarchy
```
CalendarPage (Scaffold)
└─ AppBar
   └─ TabBar (시간표, 캘린더) ← Fixed
└─ TabBarView
   └─ CalendarTab
      └─ Column
         ├─ _CalendarHeader (Fixed)
         ├─ Error/Loading Indicators (Fixed)
         └─ Expanded ← Takes remaining space
            └─ CalendarMonthWithSidebar
               └─ LayoutBuilder
                  ├─ [Wide ≥1024px] Row (No change)
                  └─ [Narrow <1024px] SingleChildScrollView ← NEW
                     └─ Column
                        ├─ Calendar Grid
                        └─ SizedBox(height: 400)
                           └─ Event List
```

### Design Decisions

1. **400px 고정 높이 선택 이유**:
   - 평균적으로 4-5개의 이벤트 카드 표시 가능 (각 카드 100px)
   - 너무 크면 스크롤 필요성 감소, 너무 작으면 답답함
   - 향후 반응형 로직으로 개선 가능 (constraints.maxHeight 기반)

2. **Wide Screen은 변경 없음**:
   - Row 레이아웃에서는 각 컬럼이 Expanded로 공간 분할
   - 이미 스크롤 가능한 구조이므로 수정 불필요

3. **TabBar는 고정 유지**:
   - 사용자 요청대로 시간표/캘린더 탭은 상단 고정
   - 탭 아래 콘텐츠만 스크롤

## Testing Checklist

- [ ] Narrow screen (< 1024px)에서 스크롤 동작 확인
- [ ] Wide screen (≥ 1024px)에서 기존 레이아웃 유지 확인
- [ ] 이벤트가 많을 때(5개 이상) 스크롤 가능 여부 확인
- [ ] 이벤트가 없을 때 UI 정상 표시 확인
- [ ] 브라우저 콘솔에서 오버플로우 에러 없는지 확인
- [ ] 다크모드에서도 정상 동작 확인

## Future Improvements

1. **반응형 높이 계산**:
   ```dart
   final eventListHeight = hasFiniteHeight
     ? (constraints.maxHeight * 0.4).clamp(300.0, 500.0)
     : 400.0;
   ```

2. **CustomScrollView 전환**:
   - 성능 최적화를 위해 Sliver 기반 스크롤 고려
   - 특히 이벤트가 많을 때 유용

3. **스크롤 위치 복원**:
   - 탭 전환 후 돌아왔을 때 스크롤 위치 유지
   - `PageStorageKey` 활용

## Related Files

- `calendar_page.dart`: 전체 캘린더 페이지 (TabBar 구조)
- `calendar_tab.dart`: 캘린더 탭 (월/주/일 뷰 전환)
- `calendar_month_with_sidebar.dart`: 월간 뷰 컴포넌트 (수정됨)

## References

- [Row/Column Layout Checklist](docs/implementation/row-column-layout-checklist.md)
- [Personal Calendar System](docs/concepts/personal-calendar-system.md)
- [Responsive Design Guide](docs/implementation/frontend/responsive-design.md)
