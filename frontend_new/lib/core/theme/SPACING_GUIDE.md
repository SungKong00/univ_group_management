# Spacing 사용 가이드

## 📋 요약: 언제 뭘 쓸 것인가?

| 상황 | 사용 | 예시 |
|------|------|------|
| **컴포넌트 내부 간격** (고정) | `context.appSpacing` | 버튼 padding, 아이콘 사이 간격 |
| **구성 요소 간 간격** (고정) | `context.appSpacing` | 입력필드-라벨, 리스트 항목 간격 |
| **화면 크기별 다른 간격** | `ResponsiveTokens` | 페이지 padding, 섹션 vertical gap |
| **다크 모드 전환** (Dark spacing 필요 시) | `AppSpacingExtension` | 향후 다크모드 spacing 별도 정의 |

---

## 🎯 AppSpacingExtension 사용법

### 기본 4dp 그리드 시스템 (고정값, 반응형 아님)

```dart
import 'package:flutter/material.dart';
import '../theme/extensions/app_spacing_extension.dart';

// context.appSpacing으로 접근 가능
final spacing = context.appSpacing;

// 크기별 간격 (4dp 단위)
spacing.xs      // 4px  - 최소 간격
spacing.small   // 8px  - 작은 간격
spacing.medium  // 12px - 중간-작은 간격
spacing.large   // 16px - 기본 간격 ⭐ 가장 많이 사용
spacing.xl      // 24px - 중간-큰 간격
spacing.xxl     // 32px - 큰 간격
spacing.xxxl    // 48px - 매우 큰 간격
spacing.huge    // 64px - 섹션 간격
spacing.massive // 96px - 초대형 간격

// 특수 용도
spacing.formLabelGap      // 6px  - 폼 레이블-입력필드 간격
spacing.formHelperGap     // 4px  - Helper 텍스트 간격
spacing.componentIconGap  // 8px  - 컴포넌트 내 아이콘 간격
spacing.minTapSize        // 44px - 최소 터치 영역
```

### 📍 사용 패턴

#### ❌ Before (하드코딩)
```dart
const SizedBox(height: 16)
const SizedBox(height: 12)
EdgeInsets.symmetric(horizontal: 16, vertical: 12)
```

#### ✅ After (AppSpacingExtension)
```dart
SizedBox(height: context.appSpacing.large)        // 16px
SizedBox(height: context.appSpacing.medium)       // 12px
EdgeInsets.symmetric(
  horizontal: context.appSpacing.large,   // 16px
  vertical: context.appSpacing.medium,    // 12px
)
```

---

## 🔄 ResponsiveTokens 사용법

### 화면 크기에 따라 다른 간격 (반응형)

```dart
import '../theme/responsive_tokens.dart';

final width = MediaQuery.sizeOf(context).width;

// 화면 너비에 따라 자동으로 값이 달라짐
ResponsiveTokens.pagePadding(width)          // 모바일: 16, 태블릿: 24, 데스크톱: 32
ResponsiveTokens.sectionVerticalGap(width)   // 모바일: 32, 태블릿: 48, 데스크톱: 64
ResponsiveTokens.sectionMaxWidth(width)      // 기기별 최대 섹션 너비
```

### 📍 사용 패턴

#### ❌ Before (하드코딩된 반응형)
```dart
// 반응형이지만 값이 정의되지 않음 → 버그
SizedBox(height: 16)  // 모든 화면에서 16px → 큰 화면에서는 너무 좁음
```

#### ✅ After (ResponsiveTokens)
```dart
// 화면 크기별로 자동 적용
final width = MediaQuery.sizeOf(context).width;
SizedBox(height: ResponsiveTokens.sectionVerticalGap(width))
// 모바일 375px: 32px
// 태블릿 768px: 48px
// 데스크톱 1440px: 64px
```

---

## 📊 적용 기준 (의사결정 트리)

```
간격을 정할 때:

1. 화면 크기별로 달라져야 하나?
   └─ YES → ResponsiveTokens.xxx(width) 사용
   └─ NO → 다음 단계로

2. 고정값으로 충분한가?
   └─ YES → context.appSpacing.xxx 사용
   └─ NO → 다른 방법 검토 (조건부 로직 등)

3. 수평/수직 방향은 일관되나?
   └─ YES → EdgeInsets.symmetric() 사용
   └─ NO → EdgeInsets.only() 사용
```

---

## 🎨 컴포넌트별 권장 간격

### AppButton
- 내부 padding: `context.appSpacing.large` (16px)
- 좌우 내부 padding: `context.appSpacing.large` * 1.5 = 24px
- 아이콘-텍스트 간격: `context.appSpacing.small` (8px)

### AppInput
- 상하 padding: `context.appSpacing.medium` (12px)
- 좌우 padding: `context.appSpacing.large` (16px)
- 라벨-입력필드: `context.appSpacing.formLabelGap` (6px)
- Helper 텍스트: `context.appSpacing.formHelperGap` (4px)

### AppCard
- 내부 padding: `context.appSpacing.large` (16px)
- 내부 요소 간격: `context.appSpacing.medium` (12px)

### AppSection (페이지 섹션)
- 수직 gap: `ResponsiveTokens.sectionVerticalGap(width)` (반응형)
- 제목-콘텐츠 gap: `ResponsiveTokens.sectionContentGap` (고정값)
- 수평 padding: `ResponsiveTokens.pagePadding(width)` (반응형)

---

## 🚫 금지 사항

```dart
// ❌ 절대 금지: 매직 넘버
const SizedBox(height: 16)
EdgeInsets.all(12)
SizedBox(width: 8)

// ✅ 허용: AppSpacingExtension
SizedBox(height: context.appSpacing.large)
EdgeInsets.all(context.appSpacing.medium)
SizedBox(width: context.appSpacing.small)
```

---

## 📝 변경이력

- **2025-11-22**: 초기 작성, AppSpacingExtension vs ResponsiveTokens 명확화
