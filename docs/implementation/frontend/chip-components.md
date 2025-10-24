# Chip 컴포넌트 (Chip Components)

AppChip과 AppInputChip 커스텀 컴포넌트 구현 가이드입니다.

## 개요

Flutter의 기본 Chip 위젯을 확장하여 프로젝트 디자인 시스템에 맞춘 컴포넌트:
- **AppChip**: 읽기 전용 정보 표시 (태그, 배지)
- **AppInputChip**: 선택 가능한 필터/옵션

## AppChip (읽기 전용)

**파일**: `frontend/lib/presentation/widgets/common/app_chip.dart`

### 주요 Props

```dart
AppChip({
  required String label,           // 표시 텍스트
  IconData? icon,                  // 선택적 아이콘
  Color? backgroundColor,          // 배경색 (기본: neutral-100)
  Color? textColor,                // 텍스트 색 (기본: neutral-800)
  VoidCallback? onDeleted,         // 삭제 콜백 (× 버튼 표시)
  bool showDeleteIcon = false,     // 삭제 아이콘 강제 표시
})
```

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

// 아이콘 포함
AppChip(
  icon: Icons.star,
  label: '추천',
)
```

### 스타일 기본값

- 배경색: `AppColors.neutral100`
- 텍스트: `AppTypography.bodyMedium`
- 패딩: `AppSpacing.xs` (8px) 수평
- 높이: 32px

## AppInputChip (선택 가능)

**파일**: `frontend/lib/presentation/widgets/common/app_input_chip.dart`

### 주요 Props

```dart
AppInputChip({
  required String label,
  required bool isSelected,        // 선택 상태
  required ValueChanged<bool> onSelected,  // 토글 콜백
  bool isEnabled = true,           // 활성화 여부
  IconData? icon,
})
```

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

// 비활성화 칩
AppInputChip(
  label: '그룹장',
  isSelected: false,
  isEnabled: false,  // 회색 처리
  onSelected: (_) {},
)
```

### 선택 상태 스타일

**미선택**:
- 배경: `AppColors.neutral100`
- 텍스트: `AppColors.neutral700`
- 테두리: `AppColors.neutral300`

**선택**:
- 배경: `AppColors.blue100`
- 텍스트: `AppColors.blue700`
- 테두리: `AppColors.blue500`

**비활성화**:
- 배경: `AppColors.neutral50`
- 텍스트: `AppColors.neutral400`

## 적용 현황

### 1. 멤버 필터 패널
**파일**: `frontend/lib/presentation/pages/member_management/widgets/member_filter_panel.dart:100-150`

역할, 그룹, 학년/학번 필터에 AppInputChip 사용

### 2. 적용된 필터 칩 바
**파일**: `frontend/lib/presentation/pages/group_explore/widgets/group_filter_chip_bar.dart:40-60`

선택된 필터를 AppChip(onDeleted)로 표시

### 3. 그룹 탐색 페이지
**파일**: `frontend/lib/presentation/pages/group_explore/widgets/group_search_bar.dart`

검색 필터에 AppInputChip 적용

## 디자인 토큰 통합

모든 색상, 간격, 타이포그래피는 디자인 시스템에서 가져옴:

```dart
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_spacing.dart';
import 'package:frontend/core/theme/app_typography.dart';
```

## 접근성

- **키보드 네비게이션**: Tab/Enter 지원
- **스크린 리더**: 선택 상태 음성 안내
- **최소 터치 영역**: 44x44px (모바일)

## 관련 문서

- [멤버 필터 고급 기능](member-filter-advanced-features.md) - Phase 2-3 구현
- [디자인 시스템](../../ui-ux/concepts/design-system.md) - 디자인 토큰
- [컴포넌트 구현](components.md) - 전체 컴포넌트 목록
