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

| 컴포넌트 | 설명 | 필요 이유 | 상태 |
|---------|------|----------|--------|
| **AppDatePicker** | 날짜 선택기 | 날짜 입력 | ✅ 완료 |
| **AppTimePicker** | 시간 선택기 | 시간 입력 | ✅ 완료 |
| **AppSkeleton** | 스켈레톤 로딩 | 로딩 상태 표시 | ✅ 완료 |
| **AppEmptyState** | 빈 상태 | 데이터 없음 표시 | ✅ 완료 |
| **AppErrorState** | 에러 상태 | 에러 발생 표시 | ✅ 완료 |
| **AppAvatar** | 사용자 아바타 | 프로필 이미지 | ✅ 완료 |

### 3.3 Phase 3: 선택 컴포넌트

| 컴포넌트 | 설명 | 필요 이유 | 상태 |
|---------|------|----------|--------|
| **AppMenu** | 컨텍스트 메뉴 | 우클릭/액션 메뉴 | ✅ 완료 |
| **AppPagination** | 페이지네이션 | 목록 페이지 이동 | ✅ 완료 |
| **AppAccordion** | 아코디언 | 접힘/펼침 콘텐츠 | ✅ 완료 |
| **AppStepper** | 단계 표시기 | 진행 단계 표시 | ✅ 완료 |
| **AppProgressBar** | 진행률 표시 | 진행 상황 표시 | ✅ 완료 |
| **AppDivider** | 구분선 | 콘텐츠 구분 | ✅ 완료 |
| **AppAvatarGroup** | 아바타 그룹 | 다중 사용자 표시 | (AppAvatar에 포함) |

### 3.4 Phase 4: 네비게이션 & 레이아웃 (완료)

> **참고**: [shadcn/ui](https://ui.shadcn.com/docs/components), [GetWidget](https://www.getwidget.dev/), [Moon Design System](https://moon.io/) 등 주요 UI 라이브러리 분석 결과

| 컴포넌트 | 설명 | 필요 이유 | 상태 |
|---------|------|----------|--------|
| **AppBottomSheet** | 모달/지속 바텀시트 | 모바일 액션 메뉴, 상세 정보 | ✅ 완료 |
| **AppDrawer** | 사이드 드로어 | 네비게이션, 필터 패널 | ✅ 완료 |
| **AppSidebar** | 고정 사이드바 | 대시보드, 관리자 페이지 | ✅ 완료 |
| **AppBreadcrumb** | 브레드크럼 | 페이지 경로 표시 | ✅ 완료 |
| **AppNavbar** | 상단 네비게이션 바 | 웹 헤더 네비게이션 | ✅ 완료 |
| **AppBottomNav** | 하단 네비게이션 바 | 모바일 주요 탭 이동 | ✅ 완료 |
| **AppNavigationRail** | 세로 네비게이션 레일 | 태블릿/데스크톱 좌측 네비 | ✅ 완료 |

### 3.5 Phase 5: 데이터 & 폼 확장 (추가 권장)

| 컴포넌트 | 설명 | 필요 이유 | 우선순위 |
|---------|------|----------|---------|
| **AppDataTable** | 데이터 테이블 | 정렬, 필터, 페이지네이션 | 높음 |
| **AppSearchInput** | 검색 입력 | 검색 자동완성, 히스토리 | 높음 |
| **AppSlider** | 슬라이더 | 범위 선택 (가격, 날짜 등) | 중간 |
| **AppSwitch** | 토글 스위치 | 설정 on/off | 높음 |
| **AppRadioGroup** | 라디오 그룹 | 단일 선택 옵션 | 높음 |
| **AppCheckboxGroup** | 체크박스 그룹 | 다중 선택 옵션 | 높음 |
| **AppTextarea** | 여러 줄 입력 | 긴 텍스트 입력 | 중간 |
| **AppFileUpload** | 파일 업로드 | 이미지, 문서 업로드 | 높음 |
| **AppOtpInput** | OTP 입력 | 인증 코드 입력 | 중간 |
| **AppColorPicker** | 색상 선택기 | 테마, 라벨 색상 | 낮음 |

### 3.6 Phase 6: 고급 피드백 & 오버레이 (추가 권장)

| 컴포넌트 | 설명 | 필요 이유 | 우선순위 |
|---------|------|----------|---------|
| **AppSheet** | 시트 (사이드 패널) | 상세 정보, 편집 패널 | 높음 |
| **AppPopover** | 팝오버 | 컨텍스트 정보, 미니 폼 | 중간 |
| **AppHoverCard** | 호버 카드 | 미리보기, 사용자 정보 | 낮음 |
| **AppAlert** | 알림 배너 | 페이지 상단 경고/안내 | 높음 |
| **AppNotificationBadge** | 알림 배지 | 알림 개수, 상태 표시 | 높음 |
| **AppCommandPalette** | 커맨드 팔레트 | 빠른 검색/명령 (⌘K) | 중간 |
| **AppSpinner** | 스피너 로딩 | 인라인 로딩 표시 | 높음 |
| **AppConfirmDialog** | 확인 다이얼로그 | 위험 작업 재확인 | 중간 |

### 3.7 Phase 7: 특수 컴포넌트 (추가 권장)

| 컴포넌트 | 설명 | 필요 이유 | 우선순위 |
|---------|------|----------|---------|
| **AppImageGallery** | 이미지 갤러리 | 이미지 그리드, 라이트박스 | 중간 |
| **AppRating** | 별점 | 평가, 리뷰 | 낮음 |
| **AppTimeline** | 타임라인 | 활동 내역, 이벤트 기록 | 중간 |
| **AppCalendar** | 캘린더 위젯 | 일정 선택, 이벤트 표시 | 높음 |
| **AppChart** | 차트 | 통계, 분석 시각화 | 중간 |
| **AppKanbanBoard** | 칸반 보드 | 태스크 관리, 드래그&드롭 | 낮음 |
| **AppRichTextEditor** | 리치 텍스트 에디터 | 서식 있는 텍스트 입력 | 중간 |
| **AppCodeBlock** | 코드 블록 | 코드 하이라이팅 | 낮음 |
| **AppCollapsible** | 접이식 컨테이너 | 단일 섹션 접기/펴기 | 중간 |
| **AppResizable** | 리사이즈 패널 | 패널 크기 조절 | 낮음 |

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
**완료도**: ✅ 6/6 (100%)

| 순서 | 컴포넌트 | 예상 난이도 | 의존성 | 상태 |
|------|---------|------------|--------|--------|
| 7 | AppDatePicker | 높음 | AppInput, AppDropdown | ✅ 완료 |
| 8 | AppTimePicker | 높음 | AppInput, AppDropdown | ✅ 완료 |
| 9 | AppSkeleton | 낮음 | 없음 | ✅ 완료 |
| 10 | AppEmptyState | 낮음 | AppButton | ✅ 완료 |
| 11 | AppErrorState | 낮음 | AppButton | ✅ 완료 |
| 12 | AppAvatar | 낮음 | 없음 | ✅ 완료 |

### Phase 3: 고급 UI

**목표**: 복잡한 UI 패턴 지원
**완료도**: ✅ 6/6 (100%)

| 순서 | 컴포넌트 | 예상 난이도 | 의존성 | 상태 |
|------|---------|------------|--------|--------|
| 13 | AppMenu | 중간 | 없음 | ✅ 완료 |
| 14 | AppPagination | 중간 | AppButton | ✅ 완료 |
| 15 | AppAccordion | 중간 | 없음 | ✅ 완료 |
| 16 | AppStepper | 중간 | 없음 | ✅ 완료 |
| 17 | AppProgressBar | 낮음 | 없음 | ✅ 완료 |
| 18 | AppDivider | 낮음 | 없음 | ✅ 완료 |

### Phase 4: 네비게이션 & 레이아웃

**목표**: 앱 구조를 위한 네비게이션 컴포넌트
**완료도**: ✅ 7/7 (100%)

| 순서 | 컴포넌트 | 예상 난이도 | 의존성 | 상태 |
|------|---------|------------|--------|--------|
| 19 | AppBottomSheet | 중간 | 없음 | ✅ 완료 |
| 20 | AppDrawer | 중간 | 없음 | ✅ 완료 |
| 21 | AppSidebar | 높음 | AppButton | ✅ 완료 |
| 22 | AppBottomNav | 중간 | AppBadge | ✅ 완료 |
| 23 | AppBreadcrumb | 낮음 | 없음 | ✅ 완료 |
| 24 | AppNavbar | 중간 | AppButton | ✅ 완료 |
| 25 | AppNavigationRail | 중간 | AppTooltip | ✅ 완료 |

### Phase 5: 데이터 & 폼 확장

**목표**: 복잡한 데이터 입력과 표시
**완료도**: ✅ 10/10 (100%)

| 순서 | 컴포넌트 | 예상 난이도 | 의존성 | 상태 |
|------|---------|------------|--------|--------|
| 26 | AppSwitch | 낮음 | 없음 | ✅ 완료 |
| 27 | AppRadioGroup | 낮음 | 없음 | ✅ 완료 |
| 28 | AppCheckboxGroup | 낮음 | 없음 | ✅ 완료 |
| 29 | AppSearchInput | 중간 | AppInput | ✅ 완료 |
| 30 | AppSlider | 중간 | 없음 | ✅ 완료 |
| 31 | AppTextarea | 낮음 | AppInput | ✅ 완료 |
| 32 | AppFileUpload | 높음 | AppButton | ✅ 완료 |
| 33 | AppOtpInput | 중간 | 없음 | ✅ 완료 |
| 34 | AppDataTable | 높음 | AppPagination, AppCheckbox | ✅ 완료 |
| 35 | AppColorPicker | 중간 | 없음 | ✅ 완료 |

### Phase 6: 고급 피드백 & 오버레이

**목표**: 사용자 피드백과 컨텍스트 정보
**완료도**: ✅ 8/8 (100%)

| 순서 | 컴포넌트 | 예상 난이도 | 의존성 | 상태 |
|------|---------|------------|--------|--------|
| 36 | AppSpinner | 낮음 | 없음 | ✅ 완료 |
| 37 | AppAlert | 낮음 | AppButton | ✅ 완료 |
| 38 | AppNotificationBadge | 낮음 | 없음 | ✅ 완료 |
| 39 | AppSheet | 중간 | 없음 | ✅ 완료 |
| 40 | AppPopover | 중간 | 없음 | ✅ 완료 |
| 41 | AppHoverCard | 중간 | 없음 | ✅ 완료 |
| 42 | AppConfirmDialog | 낮음 | AppDialog | ✅ 완료 |
| 43 | AppCommandPalette | 높음 | AppInput | ✅ 완료 |

### Phase 7: 특수 컴포넌트

**목표**: 도메인 특화 고급 컴포넌트
**완료도**: ✅ 10/10 (100%)

| 순서 | 컴포넌트 | 예상 난이도 | 의존성 | 상태 |
|------|---------|------------|--------|--------|
| 44 | AppCollapsible | 낮음 | 없음 | ✅ 완료 |
| 45 | AppTimeline | 중간 | 없음 | ✅ 완료 |
| 46 | AppCalendar | 높음 | AppDatePicker | ✅ 완료 |
| 47 | AppImageGallery | 중간 | 없음 | ✅ 완료 |
| 48 | AppRating | 낮음 | 없음 | ✅ 완료 |
| 49 | AppChart | 높음 | 없음 | ✅ 완료 |
| 50 | AppRichTextEditor | 높음 | 없음 | ✅ 완료 |
| 51 | AppCodeBlock | 중간 | 없음 | ✅ 완료 |
| 52 | AppKanbanBoard | 높음 | AppCard | ✅ 완료 |
| 53 | AppResizable | 중간 | 없음 | ✅ 완료 |

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

### 6.10 AppBottomSheet (Phase 4)

**목적**: 화면 하단에서 슬라이드 업 되는 패널

**Types**:
- `modal`: 배경 어둡게, 외부 탭으로 닫힘
- `persistent`: 배경과 상호작용 가능, 지속 표시

**Props**:
```dart
class AppBottomSheet extends StatelessWidget {
  final Widget child;
  final AppBottomSheetType type;
  final double? initialHeight;      // 초기 높이 비율 (0.0-1.0)
  final double? minHeight;          // 최소 높이
  final double? maxHeight;          // 최대 높이
  final bool isDraggable;           // 드래그 가능 여부
  final bool showDragHandle;        // 드래그 핸들 표시
  final bool isDismissible;         // 외부 탭으로 닫기
  final VoidCallback? onClose;
}

// 사용법
void showAppBottomSheet(BuildContext context, {
  required Widget child,
  AppBottomSheetType type = AppBottomSheetType.modal,
  // ...
});
```

**레이아웃**:
```
┌─────────────────────────────────┐
│       ───── (drag handle)       │
├─────────────────────────────────┤
│                                 │
│            Content              │
│                                 │
└─────────────────────────────────┘
```

---

### 6.11 AppSwitch (Phase 5)

**목적**: On/Off 토글 스위치

**Sizes**:
- `small`: 작은 스위치 (너비 36px)
- `medium`: 기본 스위치 (너비 48px)
- `large`: 큰 스위치 (너비 60px)

**Props**:
```dart
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final AppSwitchSize size;
  final String? label;
  final String? description;
  final bool isDisabled;
  final bool isLoading;
  final Color? activeColor;
}
```

---

### 6.12 AppRadioGroup (Phase 5)

**목적**: 단일 선택 라디오 버튼 그룹

**Orientations**:
- `vertical`: 세로 배치
- `horizontal`: 가로 배치

**Props**:
```dart
class AppRadioGroup<T> extends StatelessWidget {
  final List<AppRadioItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final AppRadioOrientation orientation;
  final String? label;
  final String? errorText;
  final bool isDisabled;
}

class AppRadioItem<T> {
  final T value;
  final String label;
  final String? description;
  final bool isDisabled;
}
```

---

### 6.13 AppCheckboxGroup (Phase 5)

**목적**: 다중 선택 체크박스 그룹

**Props**:
```dart
class AppCheckboxGroup<T> extends StatelessWidget {
  final List<AppCheckboxItem<T>> items;
  final List<T> values;
  final ValueChanged<List<T>>? onChanged;
  final AppCheckboxOrientation orientation;
  final String? label;
  final String? errorText;
  final bool isDisabled;
  final int? maxSelections;       // 최대 선택 개수
}

class AppCheckboxItem<T> {
  final T value;
  final String label;
  final String? description;
  final bool isDisabled;
}
```

---

### 6.14 AppSearchInput (Phase 5)

**목적**: 검색 전용 입력 필드

**Features**:
- 검색 아이콘
- 클리어 버튼
- 자동완성 드롭다운
- 검색 히스토리

**Props**:
```dart
class AppSearchInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final List<String>? suggestions;
  final List<String>? history;
  final bool showClearButton;
  final bool isLoading;
  final Duration debounce;        // 디바운스 시간 (기본 300ms)
}
```

---

### 6.15 AppDataTable (Phase 5)

**목적**: 정렬, 필터, 페이지네이션을 지원하는 데이터 테이블

**Features**:
- 컬럼 정렬 (오름차순/내림차순)
- 행 선택 (단일/다중)
- 페이지네이션 통합
- 고정 헤더
- 반응형 (모바일에서 카드 뷰)

**Props**:
```dart
class AppDataTable<T> extends StatelessWidget {
  final List<AppTableColumn<T>> columns;
  final List<T> data;
  final bool isSelectable;
  final List<T>? selectedRows;
  final ValueChanged<List<T>>? onSelectionChanged;
  final AppTableColumn<T>? sortColumn;
  final bool sortAscending;
  final ValueChanged<AppTableColumn<T>>? onSort;
  final int? currentPage;
  final int? totalPages;
  final ValueChanged<int>? onPageChanged;
  final bool isLoading;
  final Widget Function(T)? mobileRowBuilder;  // 모바일 카드 뷰
}

class AppTableColumn<T> {
  final String id;
  final String label;
  final double? width;
  final bool isSortable;
  final Widget Function(T) cellBuilder;
}
```

---

### 6.16 AppFileUpload (Phase 5)

**목적**: 파일/이미지 업로드

**Types**:
- `single`: 단일 파일
- `multiple`: 다중 파일
- `dropzone`: 드래그 앤 드롭 영역

**Props**:
```dart
class AppFileUpload extends StatelessWidget {
  final AppFileUploadType type;
  final List<String>? allowedExtensions;
  final int? maxFiles;
  final int? maxFileSize;            // bytes
  final ValueChanged<List<File>>? onFilesSelected;
  final ValueChanged<File>? onFileRemoved;
  final List<File>? selectedFiles;
  final bool isLoading;
  final double? uploadProgress;      // 0.0-1.0
  final String? errorText;
}
```

---

### 6.17 AppAlert (Phase 6)

**목적**: 페이지 상단 알림 배너

**Types**:
- `info`: 정보 안내 (파랑)
- `success`: 성공 메시지 (초록)
- `warning`: 경고 메시지 (주황)
- `error`: 에러 메시지 (빨강)

**Props**:
```dart
class AppAlert extends StatelessWidget {
  final String message;
  final AppAlertType type;
  final String? title;
  final IconData? icon;
  final bool isDismissible;
  final VoidCallback? onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;
}
```

---

### 6.18 AppSheet (Phase 6)

**목적**: 화면 측면에서 슬라이드 인 되는 패널

**Positions**:
- `right`: 우측에서 슬라이드 (기본)
- `left`: 좌측에서 슬라이드

**Sizes**:
- `small`: 너비 320px
- `medium`: 너비 480px
- `large`: 너비 640px
- `full`: 전체 너비

**Props**:
```dart
class AppSheet extends StatelessWidget {
  final Widget child;
  final AppSheetPosition position;
  final AppSheetSize size;
  final String? title;
  final bool showCloseButton;
  final bool isDismissible;
  final VoidCallback? onClose;
}

// 사용법
void showAppSheet(BuildContext context, {
  required Widget child,
  AppSheetPosition position = AppSheetPosition.right,
  // ...
});
```

---

### 6.19 AppCommandPalette (Phase 6)

**목적**: 빠른 검색 및 명령 팔레트 (⌘K / Ctrl+K)

**Features**:
- 퍼지 검색
- 최근 명령 히스토리
- 키보드 네비게이션
- 카테고리 그룹핑

**Props**:
```dart
class AppCommandPalette extends StatelessWidget {
  final List<AppCommand> commands;
  final ValueChanged<AppCommand>? onSelect;
  final String placeholder;
  final List<AppCommand>? recentCommands;
}

class AppCommand {
  final String id;
  final String label;
  final String? description;
  final IconData? icon;
  final String? shortcut;         // 예: "⌘K"
  final String? category;
  final VoidCallback? onExecute;
}

// 사용법
void showAppCommandPalette(BuildContext context, {
  required List<AppCommand> commands,
});
```

---

### 6.20 AppTimeline (Phase 7)

**목적**: 시간순 이벤트/활동 표시

**Orientations**:
- `vertical`: 세로 타임라인 (기본)
- `horizontal`: 가로 타임라인

**Props**:
```dart
class AppTimeline extends StatelessWidget {
  final List<AppTimelineItem> items;
  final AppTimelineOrientation orientation;
  final bool showConnector;
}

class AppTimelineItem {
  final String title;
  final String? description;
  final String? timestamp;
  final IconData? icon;
  final Color? iconColor;
  final Widget? content;
  final AppTimelineItemStatus status;  // completed, active, pending
}
```

---

### 6.21 AppCalendar (Phase 7)

**목적**: 월간/주간 캘린더 위젯

**Views**:
- `month`: 월간 뷰
- `week`: 주간 뷰

**Props**:
```dart
class AppCalendar extends StatelessWidget {
  final DateTime? selectedDate;
  final DateTime? focusedMonth;
  final ValueChanged<DateTime>? onDateSelected;
  final ValueChanged<DateTime>? onMonthChanged;
  final AppCalendarView view;
  final List<DateTime>? markedDates;
  final List<AppCalendarEvent>? events;
  final DateTime? minDate;
  final DateTime? maxDate;
  final List<int>? disabledWeekdays;  // 0=일, 6=토
}

class AppCalendarEvent {
  final String id;
  final String title;
  final DateTime date;
  final Color? color;
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

*Last Updated: 2025-11-29*
*Version: 7.0.0*

## Changelog

### v7.0.0 (2025-11-29)
- **Phase 7 완료** (10/10 컴포넌트)
  - AppChart: 차트 컴포넌트
    - 5가지 차트 타입(line, bar, pie, doughnut, area)
    - 애니메이션, 호버 툴팁, 범례 지원
    - CustomPainter 기반 구현
  - AppRichTextEditor: 리치 텍스트 에디터
    - 12가지 포맷(굵게, 기울임, 밑줄, 취소선, 헤딩 1-3, 목록, 인용구, 코드, 링크)
    - 키보드 단축키(Ctrl+B/I/U) 지원
    - 커스텀 컨트롤러, 포맷 제한 기능
  - AppKanbanBoard: 칸반 보드 컴포넌트
    - 드래그 앤 드롭 카드 이동
    - 라벨, 마감일, 담당자, 댓글/첨부 수 표시
    - 컬럼/카드 추가 버튼 지원
- **쇼케이스 페이지 업데이트**: special_components_page.dart에 새 컴포넌트 추가

### v6.0.0 (2025-11-29)
- **Phase 7 진행** (7/10 컴포넌트)
  - AppCollapsible: 접기/펼치기 컴포넌트
    - 3가지 스타일(plain, bordered, card)
    - 애니메이션 아이콘, 그룹 지원
  - AppTimeline: 타임라인 컴포넌트
    - 세로/가로 방향, 4가지 상태
    - 아이콘/타임스탬프/콘텐츠 지원
  - AppCalendar: 캘린더 컴포넌트
    - 월간 뷰, 이벤트 표시
    - 날짜 선택, 비활성화 지원
  - AppImageGallery: 이미지 갤러리 컴포넌트
    - 그리드/캐러셀 레이아웃
    - 라이트박스 지원, 확대/축소
  - AppRating: 별점 컴포넌트
    - 별/하트/숫자 스타일
    - 0.5 단위 지원, 읽기 전용 모드
  - AppCodeBlock: 코드 블록 컴포넌트
    - 다크/라이트 테마
    - 라인 번호, 복사 기능
  - AppResizable: 리사이즈 컴포넌트
    - 가로/세로 방향
    - 분할 패널(SplitPanel) 지원
- **쇼케이스 페이지 추가**: special_components_page.dart

### v5.0.0 (2025-11-29)
- **Phase 6 완료** (8/8 컴포넌트)
  - AppSpinner: 스피너 로딩 인디케이터
    - 3가지 스타일(circular, dots, pulse), 5가지 크기
    - 색상 커스터마이징, 오버레이 지원
  - AppAlert: 알림 배너 컴포넌트
    - 4가지 타입(info, success, warning, error)
    - 3가지 스타일(filled, outlined, subtle)
    - 닫기/액션 버튼 지원
  - AppNotificationBadge: 알림 배지 컴포넌트
    - 숫자/점 배지, 최대값 설정
    - 6가지 색상, 위치 조정 가능
  - AppSheet: 시트(사이드 패널) 컴포넌트
    - 4가지 위치(left, right, top, bottom)
    - 4가지 크기, 슬라이드 애니메이션
  - AppPopover: 팝오버 컴포넌트
    - 8가지 위치, 오프셋 지원
    - 외부 클릭 닫기, 애니메이션
  - AppHoverCard: 호버 카드 컴포넌트
    - 3가지 크기, 딜레이 설정
    - 호버 유지 지원
  - AppConfirmDialog: 확인 다이얼로그
    - 위험 모드(destructive) 지원
    - 커스텀 아이콘
  - AppCommandPalette: 커맨드 팔레트
    - 퍼지 검색, 카테고리 그룹화
    - 키보드 네비게이션, 단축키 표시

### v4.0.0 (2025-11-29)
- **Phase 5 완료** (10/10 컴포넌트)
  - AppFileUpload: 파일 업로드 컴포넌트
    - 단일/다중 파일 선택, 드래그 앤 드롭 영역
    - 파일 크기/확장자 제한, 업로드 진행률 표시
    - 업로드된 파일 목록 및 삭제 기능
  - AppDataTable: 데이터 테이블 컴포넌트
    - 정렬, 선택(단일/다중), 스트라이프 스타일
    - 밀도 설정(compact/standard/comfortable)
    - 빈 상태/로딩 상태 표시, 가로 스크롤 지원

### v3.9.0 (2025-11-29)
- **Phase 5 진행** (8/10 컴포넌트)
  - AppColorPicker: 색상 선택기
  - 20가지 기본 팔레트 색상
  - HEX 입력 모드 지원
  - 미리보기, 커스텀 팔레트 지원

### v3.8.0 (2025-11-29)
- **Phase 5 진행** (7/10 컴포넌트)
  - AppOtpInput: OTP/인증 코드 입력 필드
  - 4-6자리 코드 입력, 붙여넣기 지원
  - 숫자만 입력, 비밀번호 마스킹 지원
  - 에러/성공 상태 표시

### v3.7.0 (2025-11-29)
- **Phase 5 진행** (6/10 컴포넌트)
  - AppTextarea: 여러 줄 텍스트 입력 필드
  - 자동 높이 조절, 글자 수 표시 지원
  - 라벨/헬퍼/에러 텍스트 지원

### v3.6.0 (2025-11-29)
- **Phase 5 진행** (5/10 컴포넌트)
  - AppSlider: 범위 선택 슬라이더
  - AppRangeSlider: 시작~끝 범위 선택 슬라이더
  - 3가지 크기, 3가지 스타일(standard, marked, stepped)
  - 마크 표시, 툴팁, 값 포맷터 지원

### v3.5.0 (2025-11-29)
- **Phase 5 진행** (4/10 컴포넌트)
  - AppSearchInput: 검색 전용 입력 필드
  - 자동완성 서제스천 기능
  - 검색 히스토리 기능
  - 디바운스 지원
  - 클리어 버튼, 로딩 상태 지원

### v3.4.0 (2025-11-29)
- **Phase 5 진행** (3/10 컴포넌트)
  - AppCheckboxGroup: 다중 선택 체크박스 그룹
  - AppCheckbox: 독립 체크박스 컴포넌트
  - 세로/가로 배치, 3가지 크기 지원
  - 최대 선택 개수 제한 기능
  - 라벨/설명/에러 텍스트 지원

### v3.3.0 (2025-11-29)
- **Phase 5 진행** (2/10 컴포넌트)
  - AppRadioGroup: 단일 선택 라디오 버튼 그룹
  - 세로/가로 배치, 3가지 크기 지원
  - 라벨/설명/에러 텍스트 지원
  - 커스텀 선택 색상 지원

### v3.2.0 (2025-11-29)
- **Phase 5 시작** (1/10 컴포넌트)
  - AppSwitch: On/Off 토글 스위치, 3가지 크기, 라벨/설명 지원
  - AppSwitchGroup: 여러 스위치를 그룹으로 관리
  - 커스텀 활성 색상 지원
- **쇼케이스 페이지 추가**: data_form_components_page.dart

### v3.1.0 (2025-11-28)
- **Phase 4 완료** (7/7 컴포넌트)
  - AppBottomSheet: 모달/지속 바텀시트, 드래그 가능
  - AppDrawer: 좌측/우측 드로어, 중첩 메뉴 지원
  - AppSidebar: 확장 가능 사이드바, 그룹 메뉴 지원
  - AppBottomNav: standard/shifting 스타일, 배지 지원
  - AppBreadcrumb: slash/arrow/chevron/dot 구분자
  - AppNavbar: standard/transparent/sticky 스타일
  - AppNavigationRail: 확장/축소 모드, 배지 지원
- **쇼케이스 페이지 추가**: navigation_components_page.dart

### v3.0.0 (2025-11-28)
- **Phase 4-7 로드맵 추가** (35개 신규 컴포넌트)
  - Phase 4: 네비게이션 & 레이아웃 (7개)
  - Phase 5: 데이터 & 폼 확장 (10개)
  - Phase 6: 고급 피드백 & 오버레이 (8개)
  - Phase 7: 특수 컴포넌트 (10개)
- **상세 스펙 추가**: AppBottomSheet, AppSwitch, AppRadioGroup, AppCheckboxGroup, AppSearchInput, AppDataTable, AppFileUpload, AppAlert, AppSheet, AppCommandPalette, AppTimeline, AppCalendar
- **참고자료**: shadcn/ui, GetWidget, Moon Design System 분석 반영

### v2.1.0 (2025-11-28)
- **Phase 3 완료** (6/6 컴포넌트)
  - AppMenu: 컨텍스트 메뉴, 서브메뉴, 액션 메뉴 지원
  - AppPagination: numbered/simple/compact 스타일
  - AppAccordion: bordered/separated/plain 스타일
  - AppStepper: horizontal/vertical 방향, 상태 표시
  - AppProgressBar: linear/circular/semicircular 스타일
  - AppDivider: solid/dashed/dotted 스타일, 라벨 지원

### v2.0.0 (2025-11-27)
- Phase 1, 2 완료 (12/12 컴포넌트)
