# Chip 컴포넌트 (Chip Components)

AppChip, AppInputChip, CompactChip, ExpandableChipSection 커스텀 컴포넌트 구현 가이드입니다.

## 개요

Flutter의 기본 Chip 위젯을 확장하여 프로젝트 디자인 시스템에 맞춘 컴포넌트:
- **AppChip**: 읽기 전용 정보 표시 (태그, 배지)
- **AppInputChip**: 선택 가능한 필터/옵션
- **CompactChip**: 공간 절약형 선택 칩 (멀티셀렉트 필터용)
- **ExpandableChipSection**: 확장 가능한 인라인 칩 섹션 (Step 1 필터 선택용)

## CompactChip (공간 절약형) ⭐ NEW

**파일**: `frontend/lib/presentation/components/chips/compact_chip.dart`

### 특징

- **고정 높이 24px** (기존 AppChip 36px 대비 33% 감소)
- **체크 아이콘 없음** (선택 시 배경색만 변경)
- **완전히 둥근 모양** (borderRadius: 12px)
- **120ms 페이드 애니메이션**
- **접근성 지원** (Semantics, 포커스 링)
- **최소 터치 영역 44x44px** (InkWell)

### 사용 예시

```dart
// MultiSelectPopover 내부에서 사용
CompactChip(
  label: '2학년',
  isSelected: _draftSelection.contains(2),
  onTap: () => _toggleSelection(2),
)
```

### 디자인 스펙

**크기**: height 24px, borderRadius 12px, padding 8px/4px
**타이포**: fontSize 12px, fontWeight w500, lineHeight 1.33
**색상**: 미선택 (neutral100/neutral700), 선택 (brand/white)

## AppChip (읽기 전용)

**파일**: `frontend/lib/presentation/widgets/common/app_chip.dart`

### 사용 예시

```dart
// 기본 정보 칩
AppChip(label: 'AI 학회')

// 삭제 가능한 태그
AppChip(
  label: '그룹장',
  backgroundColor: AppColors.blue50,
  textColor: AppColors.blue700,
  onDeleted: () => removeTag('그룹장'),
)
```

**스타일**: 배경 neutral100, 텍스트 bodyMedium, 패딩 8px, 높이 32px

## AppInputChip (선택 가능)

**파일**: `frontend/lib/presentation/widgets/common/app_input_chip.dart`

### 사용 예시

```dart
// 필터 칩
AppInputChip(
  label: '2학년',
  isSelected: selectedGrades.contains(2),
  onSelected: (selected) {
    if (selected) {
      addGrade(2);
    } else {
      removeGrade(2);
    }
  },
)
```

**선택 상태 스타일**:
- 미선택: neutral100/neutral700 (테두리 neutral300)
- 선택: blue100/blue700 (테두리 blue500)
- 비활성화: neutral50/neutral400

## ExpandableChipSection (확장 가능한 섹션) ⭐ NEW

**파일**: `frontend/lib/presentation/components/chips/expandable_chip_section.dart`

### 특징

- **인라인 칩 표시** (드롭다운 없이 페이지에 직접 표시)
- **제한된 초기 표시** (기본 6개, 커스터마이징 가능)
- **더보기/접기 버튼** (초과 항목이 있을 때만 표시)
- **애니메이션 확장** (AnimatedSize 200ms)
- **제네릭 타입 지원** (역할, 그룹, 학년 등)

### 사용 예시

```dart
// 역할 필터 (6개 초과 시 확장 버튼 표시)
ExpandableChipSection<GroupRole>(
  items: roles,
  selectedItems: selectedRoles,
  itemLabel: (role) => role.name,
  onSelectionChanged: (selected) => updateSelection(selected),
  initialDisplayCount: 6,
)

// 학년 필터 (5개만 초기 표시)
ExpandableChipSection<int>(
  items: [1, 2, 3, 4, 5],
  selectedItems: selectedGrades,
  itemLabel: (grade) => '$grade학년',
  onSelectionChanged: (selected) => updateGrades(selected),
  initialDisplayCount: 5,
)
```

### 디자인 스펙

**레이아웃**: Wrap (반응형 자동 줄바꿈)
**칩 간격**: 8px (AppSpacing.xs)
**더보기 버튼**: 좌측 하단, action 컬러, 16px 아이콘
**애니메이션**: 200ms easeInOut (AnimatedSize)

### 사용 위치

- **Step 1 (MemberFilterPage)**: 역할, 그룹, 학년, 학번 필터 선택
- **기타 필터 페이지**: 인라인 칩 선택이 필요한 모든 곳

## 비교표

| 항목 | AppChip | AppInputChip | CompactChip | ExpandableChipSection |
|------|---------|--------------|-------------|-----------------------|
| 높이 | 32px | 32px | 24px | 24px (칩) |
| 용도 | 읽기 전용 | 선택 가능 | 멀티셀렉트 | 인라인 멀티셀렉트 |
| 체크 아이콘 | ❌ | ✅ | ❌ | ❌ |
| 삭제 버튼 | ✅ (옵션) | ❌ | ❌ | ❌ |
| 애니메이션 | 없음 | 없음 | 120ms 페이드 | 200ms 확장 |
| 확장 기능 | ❌ | ❌ | ❌ | ✅ |
| 레이아웃 | 단일 | 단일 | 단일 | Wrap (다중) |

## 관련 문서

- [MultiSelectPopover](../../ui-ux/components/member-filter-ui-spec.md) - CompactChip 사용 예시
- [디자인 시스템](../../ui-ux/concepts/design-system.md) - 디자인 토큰
- [컴포넌트 구현](components.md) - 전체 컴포넌트 목록
- [멤버 선택 구현](member-selection-implementation.md) - ExpandableChipSection 실제 사용
