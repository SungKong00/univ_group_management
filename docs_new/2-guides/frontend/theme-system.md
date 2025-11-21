# Theme System (테마 시스템)

**AI Agent Guide**: 구조와 결정 가이드 중심
**최종 업데이트**: 2025-11-21

## 개요

디자인 토큰을 Flutter ThemeExtension으로 구현한 시스템. Material 3와 통합.

**목적**: 타입 안전한 색상/간격/타이포그래피 접근, 컴포넌트별 의미론적 색상 팔레트

---

## 아키텍처 (3-Layer)

### Layer 1: ThemeExtension
**위치**: `lib/core/theme/extensions/`

- **AppColorExtension**: 전역 색상 → `context.appColors.{property}`
- **AppSpacingExtension**: 간격 → `context.appSpacing.{size}`
- **AppTypographyExtension**: 폰트 → `context.appTypography.{property}`

### Layer 2: Component Color Aliases
**위치**: `lib/core/theme/colors/`
**패턴**: Factory 메서드로 variant별 팔레트 생성

기존: ButtonColors, InputColors, CardColors, TabColors, CarouselColors, PricingCardColors, CustomerCardColors

### Layer 3: Material 3
- **TextTheme**: `Theme.of(context).textTheme.bodyMedium!`
- **ColorScheme**: Material 3 표준

---

## 결정 가이드 및 사용 패턴

### 직접 토큰 사용 (Layer 1)
**조건**: 단순 UI, 변형 없음
**예시**: AppDefinitionList, AppGradientOverlay, BillingToggle
**코드**: `colorExt = context.appColors` → `colorExt.surfaceSecondary`

### Component Alias 사용 (Layer 2)
**조건**: 여러 변형, 상태별 색상
**예시**: AppButton, AppInput, AppCard, PricingCard
**코드**: `ButtonColors.primary(colorExt)` → `buttonColors.background`

### 새 Alias 생성
**위치**: `lib/core/theme/colors/{component}_colors.dart`
**패턴**: Factory(AppColorExtension) → 컴포넌트별 색상 속성 반환

---

## 파일 구조

```
lib/core/theme/
├── extensions/          # Layer 1
│   ├── app_color_extension.dart
│   ├── app_spacing_extension.dart
│   └── app_typography_extension.dart
├── colors/              # Layer 2
│   ├── button_colors.dart
│   └── {component}_colors.dart
└── app_theme.dart       # ThemeData 통합
```

---

## 마이그레이션 (ColorTokens → ThemeExtension)

**변경 사항**:
- `ColorTokens.X` → `context.appColors.X`
- `TypographyTokens.Y` → `Theme.of(context).textTheme.Y!`
- Material 3 TextTheme 필수 사용

**참조**: 실제 마이그레이션 예시는 기존 위젯 참고
- AppButton, AppInput, AppCard (Component Alias 사용)
- AppTabs, AppCarousel, AppDefinitionList (직접 토큰 사용)
- PricingCard (tier별 factory 사용)

---

## 관련 문서

- [Design Tokens](../../1-concepts/design/design-tokens.md)
- [Color System](../../1-concepts/design/color-system.md)
