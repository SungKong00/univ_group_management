# Chip 컴포넌트 (Chip Components)

AppChip, AppInputChip, CompactChip 커스텀 컴포넌트 구현 가이드입니다.

## 개요

Flutter의 기본 Chip 위젯을 확장하여 프로젝트 디자인 시스템에 맞춘 컴포넌트:
- **AppChip**: 읽기 전용 정보 표시 (태그, 배지)
- **AppInputChip**: 선택 가능한 필터/옵션
- **CompactChip**: 공간 절약형 선택 칩 (멀티셀렉트 필터용)

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

## 비교표

| 항목 | AppChip | AppInputChip | CompactChip |
|------|---------|--------------|-------------|
| 높이 | 32px | 32px | 24px |
| 용도 | 읽기 전용 | 선택 가능 | 멀티셀렉트 |
| 체크 아이콘 | ❌ | ✅ | ❌ |
| 삭제 버튼 | ✅ (옵션) | ❌ | ❌ |
| 애니메이션 | 없음 | 없음 | 120ms 페이드 |

## 관련 문서

- [MultiSelectPopover](../../ui-ux/components/member-filter-ui-spec.md) - CompactChip 사용 예시
- [디자인 시스템](../../ui-ux/concepts/design-system.md) - 디자인 토큰
- [컴포넌트 구현](components.md) - 전체 컴포넌트 목록
