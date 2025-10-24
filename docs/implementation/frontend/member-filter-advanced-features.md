# 멤버 필터 고급 기능 (Member Filter Advanced Features)

Phase 2-3 멤버 필터링 시스템의 고급 기능 구현 가이드입니다.

## 개요

Phase 1 기본 필터링 위에 추가된 고급 기능:
- AppChip, AppInputChip 커스텀 컴포넌트
- 로컬 필터링 (Dart 기반)
- 멀티 선택 UI (학번 드롭다운)
- 적용된 필터 칩 바 (Applied Filters)

## Phase 2: Chip 컴포넌트 시스템

**구현 파일**:
- `frontend/lib/presentation/widgets/common/app_chip.dart`
- `frontend/lib/presentation/widgets/common/app_input_chip.dart`

### 주요 기능

1. **AppChip**: 읽기 전용 정보 표시
   - 역할 배지, 태그 표시
   - 삭제 가능 (onDeleted 콜백)

2. **AppInputChip**: 선택 가능한 필터
   - 선택/해제 토글
   - isSelected 상태 반영
   - 비활성화 지원

**디자인 토큰 적용**: AppColors, AppSpacing, AppTypography

**상세 문서**: [Chip 컴포넌트](chip-components.md)

## Phase 3: 로컬 필터링

**파일**: `frontend/lib/core/providers/group_explore/local_filtering_provider.dart`

### LocalFilterNotifier 패턴

서버 데이터를 로컬에서 실시간 필터링:

```dart
class LocalFilterNotifier extends StateNotifier<LocalFilterState> {
  final List<Group> _allGroups;  // 서버에서 받은 전체 데이터

  // 필터 조건 변경 시 즉시 재계산
  void updateFilter(FilterCondition condition) {
    final filtered = _allGroups.where((g) => condition.matches(g)).toList();
    state = state.copyWith(filteredGroups: filtered);
  }
}
```

**핵심**: API 호출 없이 클라이언트에서 필터 적용 (검색, 정렬)

## 멀티 선택 UI (학번 드롭다운)

**파일**: `frontend/lib/presentation/pages/member_management/widgets/member_filter_panel.dart`

### 구현 패턴

```dart
DropdownButton<int>(
  hint: Text('학번 선택'),
  items: availableYears.map((year) {
    return DropdownMenuItem(
      value: year,
      child: Row(
        children: [
          Checkbox(value: isSelected(year)),
          Text('${year}학번 (${count}명)'),
        ],
      ),
    );
  }).toList(),
)
```

**특징**:
- 체크박스로 멀티 선택 표현
- 각 학번별 멤버 수 표시
- 선택된 학번은 필터 칩으로 표시

## 적용된 필터 칩 바

**파일**: `frontend/lib/presentation/pages/group_explore/widgets/group_filter_chip_bar.dart`

### UI 구조

```
[역할: 그룹장 ×] [그룹: AI학회 ×] [학년: 2,3학년 ×] [모두 지우기]
```

### 구현 포인트

- Wrap 위젯으로 자동 줄바꿈
- 각 칩에 삭제 아이콘 (×)
- "모두 지우기" 버튼 (필터 reset)

**파일**: `frontend/lib/presentation/pages/member_management/widgets/member_filter_panel.dart:150-180`

## 성능 최적화

### 1. 디바운싱

API 필터링은 300ms 디바운스:

**파일**: `frontend/lib/core/providers/member/member_filter_provider.dart:60-70`

### 2. 로컬 우선 전략

- 검색어: 로컬 필터링
- 역할/그룹: API 필터링 (정확도 우선)

## 통합 예시

**멤버 관리 페이지** (`member_management_page.dart`):
1. 상단: 적용된 필터 칩 바
2. 좌측: 필터 패널 (역할, 그룹, 학년/학번)
3. 우측: 멤버 목록 (필터 적용 결과)

## 관련 문서

- [Phase 1 기본 필터](member-list-implementation.md) - 기본 필터링 구조
- [Chip 컴포넌트](chip-components.md) - AppChip, AppInputChip 상세
- [필터 UI 명세](../../ui-ux/components/member-filter-ui-spec.md) - UI/UX 가이드
- [고급 상태 패턴](advanced-state-patterns.md) - LocalFilterNotifier 패턴
