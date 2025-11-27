# Component Development Plan

> 디자인 시스템 컴포넌트 개발 계획 및 컨벤션 가이드
>
> **목적**: 이 문서만 보고 일관성 있는 컴포넌트 개발이 가능하도록 함

---

## 목차

1. [현재 시스템 개요](#1-현재-시스템-개요)
2. [컴포넌트 개발 컨벤션](#2-컴포넌트-개발-컨벤션)
3. [추가 개발 필요 컴포넌트](#3-추가-개발-필요-컴포넌트)
4. [기존 컴포넌트 개선 사항](#4-기존-컴포넌트-개선-사항)
5. [개발 우선순위 로드맵](#5-개발-우선순위-로드맵)
6. [컴포넌트별 상세 스펙](#6-컴포넌트별-상세-스펙)

---

## 1. 현재 시스템 개요

### 1.1 아키텍처 구조

```
lib/core/
├── theme/
│   ├── extensions/           # ThemeExtension (색상, 타이포, 스페이싱)
│   │   ├── app_color_extension.dart      # 40개 semantic 색상 토큰
│   │   ├── app_typography_extension.dart # 타이포그래피 확장
│   │   └── app_spacing_extension.dart    # 간격 토큰
│   ├── colors/               # 컴포넌트별 색상 팩토리
│   │   ├── button_colors.dart
│   │   ├── card_colors.dart
│   │   └── ...
│   ├── enums.dart            # 중앙화된 Enum 정의
│   ├── responsive_tokens.dart # 반응형 토큰
│   ├── animation_tokens.dart  # 애니메이션 토큰
│   ├── border_tokens.dart     # 테두리 토큰
│   └── component_size_tokens.dart # 컴포넌트 크기 토큰
└── widgets/                  # 재사용 가능한 위젯
    ├── app_button.dart
    ├── app_card.dart
    └── ...
```

### 1.2 현재 구현된 컴포넌트 (39개)

| 카테고리 | 컴포넌트 | 완성도 |
|---------|---------|--------|
| **기본** | AppButton, AppCard, AppInput, AppTabs, AppBackButton | 높음 |
| **카드** | VerticalCard, HorizontalCard, CompactCard, SelectableCard, WideCard | 높음 |
| **그리드** | AdaptiveCardGrid, ResponsiveCardGrid, ResponsiveBuilder | 높음 |
| **상태/액션** | PriorityButton, StatusButton, AssigneeButton, ReactionButton, BillingToggle | 중간 |
| **폼/입력** | CommentInput, IssueDescriptionEditor, IssueTitleEditor | 중간 |
| **레이아웃** | AppSection, PropertiesSidebar, SettingsSidebar, PageBreadcrumb | 중간 |
| **데이터 표시** | PricingCard, CustomerCard, CustomerLogoGrid, AppCarousel, AppDefinitionList | 중간 |

### 1.3 테마 시스템 요약

#### 색상 토큰 (AppColorExtension - 40개)

| 카테고리 | 토큰 | 용도 |
|---------|------|------|
| **Brand** | `brandPrimary`, `brandSecondary`, `brandText` | 브랜드 색상 |
| **Surface** | `surfacePrimary`~`surfaceQuaternary`, `surfaceHover` | 배경 레벨 |
| **Text** | `textPrimary`~`textQuaternary`, `textOnBrand` | 텍스트 계층 |
| **Border** | `borderPrimary`~`borderTertiary`, `borderFocus` | 테두리 |
| **State** | `stateSuccessBg/Text`, `stateWarningBg/Text`, `stateErrorBg/Text`, `stateInfoBg/Text` | 상태 표시 |
| **Overlay** | `overlayScrim`, `overlayLight`, `overlayMedium` | 오버레이 |
| **Interactive** | `linkDefault`, `linkHover`, `selectionBg`, `accentHover` | 인터랙션 |

#### 반응형 브레이크포인트 (5-step)

| 단계 | 범위 | 용도 |
|------|------|------|
| **XS** | < 450px | 작은 폰 (iPhone SE) |
| **SM** | 450-768px | 큰 폰 |
| **MD** | 768-1024px | 태블릿 세로 |
| **LG** | 1024-1440px | 태블릿 가로 / 노트북 |
| **XL** | ≥ 1440px | 데스크톱 |

#### 애니메이션 토큰

| 토큰 | 값 | 용도 |
|------|------|------|
| `durationQuick` | 150ms | 빠른 피드백 (버튼 호버) |
| `durationStandard` | 200ms | 일반 전환 (탭 전환) |
| `durationSmooth` | 250ms | 부드러운 전환 (페이지) |
| `curveDefault` | easeOutCubic | 기본 곡선 |
| `curveSmooth` | easeOut | 부드러운 곡선 |
| `curveSlide` | easeInOut | 슬라이드 |

---

## 2. 컴포넌트 개발 컨벤션

### 2.1 파일 구조

새 컴포넌트 추가 시 다음 파일들을 생성:

```
lib/core/
├── theme/
│   ├── colors/
│   │   └── {component}_colors.dart    # 컴포넌트 색상 팩토리
│   └── enums.dart                     # Enum 추가 (필요시)
└── widgets/
    └── {component}.dart               # 위젯 구현
```

### 2.2 Enum 정의 규칙

**위치**: `lib/core/theme/enums.dart`

```dart
// ========================================================
// {카테고리명}
// ========================================================

/// {Enum 설명}
enum App{Component}{Property} {
  variant1,
  variant2,
  variant3,
}
```

**예시**:
```dart
// 버튼
enum AppButtonVariant { primary, secondary, ghost }
enum AppButtonSize { small, medium, large }

// 배지 (신규)
enum AppBadgeVariant { subtle, prominent }
enum AppBadgeColor { success, warning, error, info, neutral }
```

### 2.3 색상 팩토리 규칙

**위치**: `lib/core/theme/colors/{component}_colors.dart`

**구조**:
```dart
import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// {Component} 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class {Component}Colors {
  /// 배경 색상
  final Color background;

  /// 호버 시 배경
  final Color backgroundHover;

  /// 텍스트 색상
  final Color text;

  /// 테두리 색상
  final Color border;

  const {Component}Colors({
    required this.background,
    required this.backgroundHover,
    required this.text,
    required this.border,
  });

  /// Variant별 팩토리 메서드
  factory {Component}Colors.from(
    AppColorExtension c,
    App{Component}Variant variant,
  ) {
    return switch (variant) {
      App{Component}Variant.variant1 => {Component}Colors(
        background: c.surfaceSecondary,
        backgroundHover: c.surfaceTertiary,
        text: c.textPrimary,
        border: c.borderPrimary,
      ),
      // ... 다른 variants
    };
  }
}
```

### 2.4 위젯 구현 규칙

**위치**: `lib/core/widgets/{component}.dart`

**필수 import**:
```dart
import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_typography_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/{component}_colors.dart';
import '../theme/enums.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';
```

**위젯 구조 템플릿**:
```dart
/// {Component 설명}
///
/// **접근성**: {접근성 관련 설명}
/// **반응형**: {반응형 동작 설명}
class App{Component} extends StatefulWidget {
  // === Required Props ===
  final String label;

  // === Optional Props (with defaults) ===
  final App{Component}Variant variant;
  final App{Component}Size size;
  final VoidCallback? onTap;
  final bool isDisabled;
  final bool isLoading;

  const App{Component}({
    super.key,
    required this.label,
    this.variant = App{Component}Variant.primary,
    this.size = App{Component}Size.medium,
    this.onTap,
    this.isDisabled = false,
    this.isLoading = false,
  });

  @override
  State<App{Component}> createState() => _App{Component}State();
}

class _App{Component}State extends State<App{Component}>
    with SingleTickerProviderStateMixin {
  // === Animation Controller ===
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // === Local State ===
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationTokens.durationQuick,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: AnimationTokens.curveSmooth),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // === Theme Extensions 접근 ===
    final colorExt = context.appColors;
    final typographyExt = context.appTypography;
    final spacingExt = context.appSpacing;

    // === 반응형 토큰 ===
    final width = MediaQuery.sizeOf(context).width;
    final borderRadius = ResponsiveTokens.componentBorderRadius(width);

    // === 색상 팩토리 ===
    final colors = {Component}Colors.from(colorExt, widget.variant);

    // === 위젯 빌드 ===
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          // ... 구현
        ),
      ),
    );
  }
}
```

### 2.5 Props 네이밍 컨벤션

| 패턴 | 예시 | 용도 |
|------|------|------|
| `is{State}` | `isDisabled`, `isLoading`, `isSelected` | boolean 상태 |
| `on{Action}` | `onTap`, `onChanged`, `onDismiss` | 콜백 함수 |
| `{property}` | `label`, `title`, `icon` | 데이터 props |
| `{component}Variant` | `variant`, `style` | 스타일 변형 |
| `{component}Size` | `size` | 크기 변형 |

### 2.6 접근성 규칙

1. **최소 터치 영역**: 44px × 44px (iOS/Android 권장)
2. **키보드 네비게이션**: `Focus` 위젯 사용
3. **스크린 리더**: `Semantics` 위젯으로 레이블 제공
4. **색상 대비**: WCAG 2.1 AA 기준 충족

```dart
// 접근성 래퍼 예시
Semantics(
  label: '${widget.label} 버튼',
  button: true,
  enabled: !widget.isDisabled,
  child: // ... 실제 위젯
)
```

### 2.7 반응형 규칙

1. **MediaQuery.sizeOf() 사용** (성능 최적화)
2. **ResponsiveTokens 활용** (일관된 반응형)
3. **LayoutBuilder** (부모 제약 기반 레이아웃)

```dart
@override
Widget build(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;

  // 반응형 값 계산
  final padding = ResponsiveTokens.cardPadding(width);
  final borderRadius = ResponsiveTokens.componentBorderRadius(width);
  final fontSize = ResponsiveTokens.fontScale(width);

  // 화면 크기 타입 확인
  final screenSize = ResponsiveTokens.getScreenSize(width);

  // ...
}
```

---

## 3. 추가 개발 필요 컴포넌트

### 3.1 Phase 1: 필수 컴포넌트 (높은 우선순위)

| 컴포넌트 | 설명 | 필요 이유 | 상태 |
|---------|------|----------|--------|
| **AppBadge** | 상태/카운트 표시 | 알림 개수, 상태 태그 표시 | ✅ 완료 |
| **AppDialog** | 모달 다이얼로그 | 확인, 경고, 입력 모달 | ✅ 완료 |
| **AppToast** | 토스트 알림 | 성공/에러/정보 피드백 | ✅ 완료 |
| **AppDropdown** | 드롭다운 선택기 | 폼 입력, 필터링 | ✅ 완료 |
| **AppChip** | 태그/필터 칩 | 라벨, 필터 선택 | ✅ 완료 |
| **AppTooltip** | 툴팁 | 아이콘/버튼 설명 | ✅ 완료 |

### 3.2 Phase 2: 권장 컴포넌트

| 컴포넌트 | 설명 | 필요 이유 |
|---------|------|----------|
| **AppDatePicker** | 날짜 선택기 | 날짜 입력 |
| **AppTimePicker** | 시간 선택기 | 시간 입력 |
| **AppSkeleton** | 스켈레톤 로딩 | 로딩 상태 표시 |
| **AppEmptyState** | 빈 상태 | 데이터 없음 표시 |
| **AppErrorState** | 에러 상태 | 에러 발생 표시 |
| **AppAvatar** | 사용자 아바타 | 프로필 이미지 |

### 3.3 Phase 3: 선택 컴포넌트

| 컴포넌트 | 설명 | 필요 이유 |
|---------|------|----------|
| **AppMenu** | 컨텍스트 메뉴 | 우클릭/액션 메뉴 |
| **AppPagination** | 페이지네이션 | 목록 페이지 이동 |
| **AppAccordion** | 아코디언 | 접힘/펼침 콘텐츠 |
| **AppStepper** | 단계 표시기 | 진행 단계 표시 |
| **AppProgressBar** | 진행률 표시 | 진행 상황 표시 |
| **AppDivider** | 구분선 | 콘텐츠 구분 |
| **AppAvatarGroup** | 아바타 그룹 | 다중 사용자 표시 |

---

## 4. 기존 컴포넌트 개선 사항

### 4.1 상태 표준화

모든 인터랙티브 컴포넌트에 다음 상태 추가:

| 상태 | Props | 설명 |
|------|-------|------|
| **Default** | - | 기본 상태 |
| **Hover** | `_isHovered` (internal) | 마우스 오버 |
| **Pressed** | `_isPressed` (internal) | 클릭 중 |
| **Disabled** | `isDisabled` | 비활성화 |
| **Loading** | `isLoading` | 로딩 중 |
| **Focused** | `_isFocused` (internal) | 키보드 포커스 |

### 4.2 카드 컴포넌트 개선

모든 카드에 추가할 props:

```dart
class VerticalCard extends StatefulWidget {
  // 기존 props...

  // 추가 props
  final bool isLoading;        // 스켈레톤 표시
  final bool isEmpty;          // 빈 상태 표시
  final String? errorMessage;  // 에러 상태 표시
  final VoidCallback? onRetry; // 에러 시 재시도
}
```

### 4.3 AppTabs 개선

```dart
class AppTabs extends StatefulWidget {
  // 기존 props...

  // 추가 props
  final bool isScrollable;              // 스크롤 가능 탭
  final Map<int, int>? badgeCounts;     // 탭별 배지 카운트
  final TabBarIndicatorSize indicatorSize; // 인디케이터 크기
}
```

### 4.4 AppButton 개선

```dart
// 현재: variant (primary, secondary, ghost)
// 추가: destructive variant

enum AppButtonVariant {
  primary,
  secondary,
  ghost,
  destructive,  // 추가: 삭제/위험 작업용
}
```

---

## 5. 개발 우선순위 로드맵

### Phase 1: 핵심 피드백 컴포넌트

**목표**: 사용자 피드백을 위한 기본 컴포넌트
**완료도**: ✅ 6/6 (100%)

| 순서 | 컴포넌트 | 예상 난이도 | 의존성 | 상태 |
|------|---------|------------|--------|--------|
| 1 | AppBadge | 낮음 | 없음 | ✅ 완료 |
| 2 | AppToast | 중간 | 없음 | ✅ 완료 |
| 3 | AppTooltip | 중간 | 없음 | ✅ 완료 |
| 4 | AppDialog | 중간 | AppButton | ✅ 완료 |
| 5 | AppChip | 낮음 | 없음 | ✅ 완료 |
| 6 | AppDropdown | 높음 | AppInput | ✅ 완료 |

### Phase 2: 폼/입력 강화

**목표**: 데이터 입력을 위한 컴포넌트

| 순서 | 컴포넌트 | 예상 난이도 | 의존성 |
|------|---------|------------|--------|
| 7 | AppDatePicker | 높음 | AppInput, AppDropdown |
| 8 | AppTimePicker | 높음 | AppInput, AppDropdown |
| 9 | AppSkeleton | 낮음 | 없음 |
| 10 | AppEmptyState | 낮음 | AppButton |
| 11 | AppErrorState | 낮음 | AppButton |
| 12 | AppAvatar | 낮음 | 없음 |

### Phase 3: 고급 UI

**목표**: 복잡한 UI 패턴 지원

| 순서 | 컴포넌트 | 예상 난이도 | 의존성 |
|------|---------|------------|--------|
| 13 | AppMenu | 중간 | 없음 |
| 14 | AppPagination | 중간 | AppButton |
| 15 | AppAccordion | 중간 | 없음 |
| 16 | AppStepper | 중간 | 없음 |
| 17 | AppProgressBar | 낮음 | 없음 |
| 18 | AppAvatarGroup | 낮음 | AppAvatar |

---

## 6. 컴포넌트별 상세 스펙

### 6.1 AppBadge

**목적**: 상태, 카운트, 라벨을 표시하는 작은 UI 요소

**Variants**:
- `subtle`: 배경 없이 텍스트만 (메타 정보)
- `prominent`: 배경 있는 강조 배지

**Colors**:
- `success`: 성공/완료 상태 (초록)
- `warning`: 경고/주의 상태 (주황)
- `error`: 에러/위험 상태 (빨강)
- `info`: 정보/알림 상태 (파랑)
- `neutral`: 일반 상태 (회색)

**Sizes**:
- `small`: 작은 배지 (폰트 10px, 패딩 2px 6px)
- `medium`: 기본 배지 (폰트 12px, 패딩 4px 8px)

**Props**:
```dart
class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;
  final AppBadgeColor color;
  final AppBadgeSize size;
  final int? count;        // 숫자 표시 (99+ 처리)
  final IconData? icon;    // 아이콘 (선택)
}
```

**색상 매핑**:
```dart
factory BadgeColors.from(AppColorExtension c, AppBadgeColor color) {
  return switch (color) {
    AppBadgeColor.success => BadgeColors(
      background: c.stateSuccessBg.withOpacity(0.15),
      text: c.stateSuccessText,
    ),
    AppBadgeColor.warning => BadgeColors(
      background: c.stateWarningBg.withOpacity(0.15),
      text: c.stateWarningText,
    ),
    AppBadgeColor.error => BadgeColors(
      background: c.stateErrorBg.withOpacity(0.15),
      text: c.stateErrorText,
    ),
    AppBadgeColor.info => BadgeColors(
      background: c.stateInfoBg.withOpacity(0.15),
      text: c.stateInfoText,
    ),
    AppBadgeColor.neutral => BadgeColors(
      background: c.surfaceTertiary,
      text: c.textSecondary,
    ),
  };
}
```

---

### 6.2 AppToast

**목적**: 일시적인 피드백 메시지 표시

**Types**:
- `success`: 성공 메시지
- `warning`: 경고 메시지
- `error`: 에러 메시지
- `info`: 정보 메시지

**Positions**:
- `topCenter`: 상단 중앙
- `topRight`: 상단 우측
- `bottomCenter`: 하단 중앙
- `bottomRight`: 하단 우측

**Props**:
```dart
class AppToast {
  final String message;
  final AppToastType type;
  final Duration duration;     // 기본 4초
  final VoidCallback? onDismiss;
  final String? actionLabel;   // 액션 버튼 텍스트
  final VoidCallback? onAction; // 액션 버튼 콜백
}

// 사용법 (전역 함수)
void showAppToast(BuildContext context, {
  required String message,
  AppToastType type = AppToastType.info,
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  VoidCallback? onAction,
});
```

**애니메이션**:
- 진입: 위에서 슬라이드 + 페이드 (250ms)
- 퇴장: 위로 슬라이드 + 페이드 (200ms)

---

### 6.3 AppDialog

**목적**: 모달 다이얼로그

**Types**:
- `alert`: 확인만 있는 알림
- `confirm`: 확인/취소 선택
- `prompt`: 입력 포함 다이얼로그
- `custom`: 커스텀 콘텐츠

**Props**:
```dart
class AppDialog extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? content;          // 커스텀 콘텐츠
  final AppDialogType type;
  final String confirmLabel;      // 기본: "확인"
  final String cancelLabel;       // 기본: "취소"
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDismissible;       // 배경 탭으로 닫기
  final bool isDestructive;       // 삭제 확인 등 위험 액션
}

// 사용법 (전역 함수)
Future<bool?> showAppDialog(BuildContext context, {
  required String title,
  String? description,
  AppDialogType type = AppDialogType.confirm,
  // ...
});
```

**레이아웃**:
```
┌─────────────────────────────────┐
│  Title                      [X] │
├─────────────────────────────────┤
│                                 │
│  Description / Content          │
│                                 │
├─────────────────────────────────┤
│              [Cancel] [Confirm] │
└─────────────────────────────────┘
```

---

### 6.4 AppDropdown

**목적**: 드롭다운 선택기

**Features**:
- 단일 선택
- 검색 가능 옵션
- 그룹화된 옵션
- 커스텀 아이템 렌더링

**Props**:
```dart
class AppDropdown<T> extends StatefulWidget {
  final List<AppDropdownItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? placeholder;
  final String? label;
  final String? helperText;
  final String? errorText;
  final bool isSearchable;
  final bool isDisabled;
  final bool isLoading;
  final Widget Function(AppDropdownItem<T>)? itemBuilder;
}

class AppDropdownItem<T> {
  final T value;
  final String label;
  final String? description;
  final IconData? icon;
  final String? group;    // 그룹 헤더
  final bool isDisabled;
}
```

---

### 6.5 AppChip

**목적**: 태그, 필터, 선택 항목 표시

**Types**:
- `filter`: 필터 선택용 (선택/해제)
- `input`: 입력된 값 표시 (삭제 가능)
- `suggestion`: 추천 항목 (탭으로 선택)

**Props**:
```dart
class AppChip extends StatelessWidget {
  final String label;
  final AppChipType type;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;   // input 타입에서 삭제
  final IconData? leadingIcon;
  final Color? color;             // 커스텀 색상
}
```

---

### 6.6 AppTooltip

**목적**: 호버/탭 시 추가 정보 표시

**Positions**:
- `top`, `bottom`, `left`, `right`
- 자동 위치 조정 (화면 가장자리 감지)

**Props**:
```dart
class AppTooltip extends StatelessWidget {
  final Widget child;
  final String message;
  final AppTooltipPosition preferredPosition;
  final Duration showDelay;       // 기본 500ms
  final Duration hideDelay;       // 기본 0ms
  final bool showOnTap;           // 모바일용 탭 표시
}
```

---

### 6.7 AppSkeleton

**목적**: 로딩 중 플레이스홀더 표시

**Types**:
- `text`: 텍스트 라인
- `circle`: 원형 (아바타)
- `rectangle`: 사각형 (이미지, 카드)
- `card`: 카드 모양

**Props**:
```dart
class AppSkeleton extends StatelessWidget {
  final AppSkeletonType type;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final int lines;               // text 타입용 줄 수
}

// 카드별 프리셋
class AppSkeletonCard {
  static Widget vertical() => // VerticalCard 스켈레톤
  static Widget horizontal() => // HorizontalCard 스켈레톤
  static Widget compact() => // CompactCard 스켈레톤
}
```

**애니메이션**: Shimmer 효과 (좌→우 그라데이션 이동)

---

### 6.8 AppEmptyState

**목적**: 데이터 없음 상태 표시

**Props**:
```dart
class AppEmptyState extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? illustration;    // 커스텀 이미지/아이콘
  final IconData? icon;          // 기본 아이콘
  final String? actionLabel;
  final VoidCallback? onAction;
}
```

**레이아웃**:
```
┌─────────────────────────────────┐
│                                 │
│         [Illustration]          │
│                                 │
│            Title                │
│         Description             │
│                                 │
│          [Action]               │
│                                 │
└─────────────────────────────────┘
```

---

### 6.9 AppAvatar

**목적**: 사용자 프로필 이미지 표시

**Sizes**:
- `xs`: 24px
- `sm`: 32px
- `md`: 40px
- `lg`: 48px
- `xl`: 64px

**Props**:
```dart
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;           // 이미지 없을 때 이니셜
  final AppAvatarSize size;
  final Color? backgroundColor; // 이니셜 배경색
  final bool showOnlineStatus;
  final bool isOnline;
  final VoidCallback? onTap;
}
```

---

## Appendix A: 색상 토큰 Quick Reference

```dart
// 색상 접근
final colors = context.appColors;

// Brand
colors.brandPrimary      // 메인 브랜드 (#5c068c)
colors.brandSecondary    // 보조 브랜드 (#7a0bb8)

// Surface (배경 레벨)
colors.surfacePrimary    // 레벨 0 (#0a0a0b)
colors.surfaceSecondary  // 레벨 1 (#141416)
colors.surfaceTertiary   // 레벨 2 (#1e1e21)
colors.surfaceQuaternary // 레벨 3 (#28282c)

// Text
colors.textPrimary       // 주요 텍스트 (#ffffff)
colors.textSecondary     // 보조 텍스트 (#a1a1aa)
colors.textTertiary      // 3차 텍스트 (#71717a)
colors.textQuaternary    // 비활성 텍스트 (#52525b)

// State
colors.stateSuccessBg    // 성공 배경 (#10b981)
colors.stateWarningBg    // 경고 배경 (#f59e0b)
colors.stateErrorBg      // 에러 배경 (#ef4444)
colors.stateInfoBg       // 정보 배경 (#3b82f6)
```

## Appendix B: 체크리스트

### 새 컴포넌트 개발 시 체크리스트

- [ ] `enums.dart`에 필요한 Enum 추가
- [ ] `colors/{component}_colors.dart` 생성
- [ ] `widgets/{component}.dart` 구현
- [ ] 접근성 고려 (최소 터치 영역 44px, Semantics)
- [ ] 반응형 고려 (ResponsiveTokens 사용)
- [ ] 애니메이션 토큰 사용 (AnimationTokens)
- [ ] 모든 상태 구현 (default, hover, pressed, disabled, loading)
- [ ] 문서/주석 작성
- [ ] Showcase 페이지에 예시 추가

### 기존 컴포넌트 수정 시 체크리스트

- [ ] 기존 API 호환성 유지
- [ ] 새 props는 optional + 기본값 제공
- [ ] 다른 컴포넌트 영향도 확인
- [ ] Showcase 페이지 업데이트

---

*Last Updated: 2025-11-27*
*Version: 1.0.0*
