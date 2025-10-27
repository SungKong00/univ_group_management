# CompactChip 디자인 명세서

> **작성일**: 2025-10-25
> **목적**: 멤버 필터 UI 개선을 위한 미니멀 칩 컴포넌트 디자인

## 개요

기존 AppChip의 문제점을 해결하고, 사용자 요구사항(미니멀, 컴팩트, 선택 시 사이즈 불변)을 충족하는 새로운 칩 컴포넌트입니다.

---

## 기존 칩 vs CompactChip 비교

### 시각적 비교

```
┌─────────────────────────────────────────────────┐
│ 기존 AppChip (Medium)                           │
├─────────────────────────────────────────────────┤
│                                                 │
│   [ ✓ 그룹장 ]  ← 36px 높이, 체크 아이콘 표시   │
│   ├─ fontSize: 14px                             │
│   ├─ padding: 12px horizontal, 6px vertical     │
│   └─ icon: 16px                                 │
│                                                 │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ CompactChip (새 디자인)                         │
├─────────────────────────────────────────────────┤
│                                                 │
│   [그룹장]  ← 24px 높이, 배경색만 변경          │
│   ├─ fontSize: 12px                             │
│   ├─ padding: 8px horizontal, 4px vertical      │
│   └─ NO icon (체크 표시 없음)                   │
│                                                 │
└─────────────────────────────────────────────────┘
```

### 수치 비교표

| 속성              | 기존 AppChip (Medium) | CompactChip     | 차이     |
|-------------------|----------------------|-----------------|----------|
| 높이              | 36px                 | **24px**        | -33%     |
| 폰트 크기         | 14px                 | **12px**        | -14%     |
| Horizontal Padding| 12px                 | **8px**         | -33%     |
| Vertical Padding  | 6px                  | **4px**         | -33%     |
| 테두리 반경       | 8px (AppRadius.sm)   | **12px**        | +50%     |
| 체크 아이콘       | ✓ (16px)             | **없음**        | N/A      |

**효과**: 공간 절약 33%, 더 둥근 모양, 시각적 간결함 극대화

---

## 디자인 스펙

### 크기 및 형태

```
┌────────────────────────────┐
│                            │
│     [  그 룹 장  ]         │
│     │          │           │
│     │← 8px →   │← 8px →│   │
│     │                      │
│    ↕ 4px                   │
│   ┌─┴─────────────┐        │
│   │   텍스트 영역  │ ← 12px │
│   └───────────────┘        │
│    ↕ 4px                   │
│                            │
│   ←────── 24px ──────→     │
│   (자동 너비: 텍스트 + 16px)│
└────────────────────────────┘
```

**스펙**:
- **고정 높이**: 24px (절대 변하지 않음)
- **자동 너비**: 텍스트 길이 + 16px (좌우 패딩)
- **테두리 반경**: 12px (완전히 둥근 모양)
- **최소 터치 영역**: 44x44px (Material 가이드라인)

### 타이포그래피

```dart
TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w500,  // Medium (기존 w400보다 약간 진하게)
  letterSpacing: 0,
  height: 1.33,  // 16px 라인 높이
)
```

---

## 색상 시스템 (State별)

### 1. 미선택 (Default)

```
┌──────────────────────────────────┐
│                                  │
│   [그룹장] [교수] [멤버]          │
│   │                              │
│   └─ 배경: #F8FAFC (neutral100)  │
│      텍스트: #334155 (neutral700)│
│      테두리: #CBD5E1 (neutral400)│
│                                  │
└──────────────────────────────────┘
```

**색상 코드**:
```dart
backgroundColor: AppColors.neutral100  // #F8FAFC
textColor: AppColors.neutral700        // #334155
borderColor: AppColors.neutral400      // #CBD5E1 (1px)
```

### 2. 선택 (Selected)

```
┌──────────────────────────────────┐
│                                  │
│   [그룹장] [교수] [멤버]          │
│    ^^^^^ (보라색 배경, 흰색 텍스트)│
│   └─ 배경: #5C068C (brand)       │
│      텍스트: #FFFFFF (white)     │
│      테두리: #5C068C (brand)     │
│                                  │
└──────────────────────────────────┘
```

**색상 코드**:
```dart
backgroundColor: AppColors.brand       // #5C068C
textColor: Colors.white                // #FFFFFF
borderColor: AppColors.brand           // #5C068C (1px)
```

**중요**: 체크 아이콘 없음! 배경색만으로 선택 상태 표현

### 3. 호버 (Hover - 데스크톱만)

```
┌──────────────────────────────────┐
│                                  │
│   [그룹장] ← 마우스 올릴 때      │
│    ^^^^^                         │
│   └─ 배경: #EEF2F6 (neutral200) │
│      (미선택 상태에서 약간 진하게)│
│                                  │
└──────────────────────────────────┘
```

**색상 코드**:
```dart
// 미선택 호버
hoverBackgroundColor: AppColors.neutral200  // #EEF2F6

// 선택 호버
hoverBackgroundColor: AppColors.brandStrong  // #4B0672 (약간 진한 보라)
```

### 4. 비활성화 (Disabled)

```
┌──────────────────────────────────┐
│                                  │
│   [그룹장] ← 회색 처리           │
│    ^^^^^                         │
│   └─ 배경: #F1F5F9 (disabledBg) │
│      텍스트: #94A3B8 (disabled)  │
│                                  │
└──────────────────────────────────┘
```

**색상 코드**:
```dart
backgroundColor: AppColors.disabledBgLight
textColor: AppColors.disabledTextLight
```

---

## 상태 전환 애니메이션

### 선택/해제 애니메이션

```
미선택 → 선택:
[그룹장] → [그룹장]
(회색)     (보라색)
  └─────────┘
   120ms fade
```

**스펙**:
```dart
Duration: 120ms (AppDuration.quick)
Curve: Curves.easeOutCubic
Property: backgroundColor, textColor (동시 변경)
```

**중요**: 사이즈는 절대 변하지 않음!

---

## 접근성 (Accessibility)

### 1. 키보드 네비게이션

```
Tab: 다음 칩으로 포커스 이동
Shift+Tab: 이전 칩으로 포커스 이동
Enter / Space: 선택/해제 토글
```

### 2. 포커스 링

```
┌──────────────────────────────────┐
│                                  │
│   ┌─────────────┐                │
│   │  [그룹장]   │ ← 보라색 링    │
│   └─────────────┘                │
│   (포커스 시 표시)                │
│                                  │
└──────────────────────────────────┘
```

**스펙**:
```dart
focusColor: AppColors.focusRing  // rgba(92, 6, 140, 0.45)
focusWidth: 2px
focusOffset: 2px
```

### 3. Semantics (스크린 리더)

```dart
Semantics(
  button: true,
  label: '그룹장',
  selected: true,  // 또는 false
  enabled: true,
  onTap: () => toggleSelection(),
)
```

**스크린 리더 읽기**:
- "그룹장, 버튼, 선택됨" (선택 시)
- "그룹장, 버튼, 선택 안됨" (미선택 시)

### 4. 최소 터치 영역

```
┌─────────────────────────────────┐
│     ┌───────────────────┐       │
│     │                   │       │
│     │    [그룹장]       │ ← 44px│
│     │    (24px)         │       │
│     │                   │       │
│     └───────────────────┘       │
│         (최소 44px)             │
└─────────────────────────────────┘
```

**구현**:
```dart
InkWell(
  // 실제 시각적 크기: 24px
  child: Container(height: 24, ...),

  // 터치 영역 확장 (Material 가이드라인)
  // iOS/Android에서 최소 44x44px 보장
)
```

---

## 레이아웃 패턴

### 1. Wrap 레이아웃 (자동 줄바꿈)

```
┌─────────────────────────────────────────────────┐
│                                                 │
│  [그룹장] [교수] [멤버] [조교] [게스트]         │
│  [신입생] [졸업생] [휴학생]                     │
│   │      │                                      │
│   │      └─ runSpacing: 12px (AppSpacing.xs)   │
│   └─ spacing: 12px (AppSpacing.xs)             │
│                                                 │
└─────────────────────────────────────────────────┘
```

**코드**:
```dart
Wrap(
  spacing: AppSpacing.xs,        // 12px (좌우 간격)
  runSpacing: AppSpacing.xs,     // 12px (상하 간격)
  children: [
    CompactChip(label: '그룹장', ...),
    CompactChip(label: '교수', ...),
    // ...
  ],
)
```

### 2. Row 레이아웃 (한 줄 배치)

```
┌─────────────────────────────────┐
│                                 │
│  [1학년] [2학년] [3학년] [4학년]│
│   │     │                       │
│   │     └─ spacing: 12px        │
│   └─ MainAxisSize.min           │
│                                 │
└─────────────────────────────────┘
```

**코드**:
```dart
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    CompactChip(label: '1학년', ...),
    const SizedBox(width: AppSpacing.xs),
    CompactChip(label: '2학년', ...),
    // ...
  ],
)
```

---

## 실제 사용 예시

### 1. MultiSelectPopover 내부

```
┌─────────────────────────────────────────┐
│ 역할 선택 (2)                    [×]    │
├─────────────────────────────────────────┤
│                                         │
│  [그룹장] [교수] [멤버]                  │
│   ^^^^^          ^^^^^                  │
│  (선택)         (선택)                  │
│                                         │
│  ← CompactChip 높이: 24px               │
│  ← 칩 간격: 12px                        │
│  ← 선택 시에도 사이즈 불변!             │
│                                         │
└─────────────────────────────────────────┘
```

### 2. 멤버 필터 패널

```
┌─────────────────────────────────────────┐
│ 역할                                    │
│ ─────────────────────────────────────── │
│ [역할 (2) ▼]  ← MultiSelectPopover     │
│                                         │
│ 그룹                                    │
│ ─────────────────────────────────────── │
│ [그룹: 전체 ▼]                          │
│                                         │
│ 학년                                    │
│ ─────────────────────────────────────── │
│ [학년: 전체 ▼]                          │
│                                         │
└─────────────────────────────────────────┘
```

### 3. 적용된 필터 칩 바 (Applied Filters)

```
┌─────────────────────────────────────────────────┐
│ 적용된 필터                                     │
├─────────────────────────────────────────────────┤
│                                                 │
│  [역할: 그룹장 ×] [그룹: AI학회 ×] [모두 지우기]│
│   ^^^^^^^^^^^^^    ^^^^^^^^^^^^^                │
│  (CompactChip)    (CompactChip)                 │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 디자인 토큰 매핑

### 색상 토큰

```dart
// CompactChip 색상
const CompactChipColors = {
  // 미선택
  defaultBackground: AppColors.neutral100,   // #F8FAFC
  defaultText: AppColors.neutral700,         // #334155
  defaultBorder: AppColors.neutral400,       // #CBD5E1

  // 선택
  selectedBackground: AppColors.brand,       // #5C068C
  selectedText: Colors.white,                // #FFFFFF
  selectedBorder: AppColors.brand,           // #5C068C

  // 호버
  hoverBackground: AppColors.neutral200,     // #EEF2F6
  hoverSelectedBackground: AppColors.brandStrong, // #4B0672

  // 비활성화
  disabledBackground: AppColors.disabledBgLight,
  disabledText: AppColors.disabledTextLight,

  // 포커스
  focusRing: AppColors.focusRing,  // rgba(92, 6, 140, 0.45)
};
```

### 크기 토큰

```dart
// CompactChip 크기
const CompactChipSizes = {
  height: 24.0,
  borderRadius: 12.0,
  borderWidth: 1.0,

  // 패딩
  horizontalPadding: 8.0,
  verticalPadding: 4.0,

  // 타이포그래피
  fontSize: 12.0,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.0,
  lineHeight: 1.33,  // 16px

  // 간격
  spacing: AppSpacing.xs,  // 12px

  // 애니메이션
  animationDuration: 120,  // ms
};
```

---

## 구현 시 주의사항

### 1. 사이즈 불변 보장

❌ **잘못된 구현**:
```dart
// 선택 시 아이콘 추가 → 사이즈 변화 발생!
Row(
  children: [
    if (selected) Icon(Icons.check, size: 14),
    Text(label),
  ],
)
```

✅ **올바른 구현**:
```dart
// 배경색만 변경 → 사이즈 불변!
Container(
  height: 24,  // 고정 높이
  decoration: BoxDecoration(
    color: selected ? AppColors.brand : AppColors.neutral100,
  ),
  child: Text(label),  // 아이콘 없음
)
```

### 2. 터치 영역 보장

❌ **잘못된 구현**:
```dart
// 시각적 크기만 24px → 터치하기 어려움
GestureDetector(
  onTap: onTap,
  child: Container(height: 24, ...),
)
```

✅ **올바른 구현**:
```dart
// InkWell이 자동으로 44x44 터치 영역 보장
InkWell(
  onTap: onTap,
  child: Container(height: 24, ...),
)
```

### 3. 테두리 렌더링

❌ **잘못된 구현**:
```dart
// BoxDecoration.border와 shape.side 중복 → 2px 테두리
Container(
  decoration: BoxDecoration(
    border: Border.all(color: color),
  ),
)
```

✅ **올바른 구현**:
```dart
// BoxDecoration.border만 사용
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: selected ? AppColors.brand : AppColors.neutral400,
      width: 1,
    ),
  ),
)
```

---

## 비교: CompactChip vs AppChip vs FilterChip

| 특성              | CompactChip         | AppChip (Medium)    | FilterChip (Material) |
|-------------------|---------------------|---------------------|-----------------------|
| 높이              | 24px                | 36px                | 32px                  |
| 체크 아이콘       | 없음 (배경색만)     | 있음 (optional)     | 있음 (기본)           |
| 사이즈 불변       | ✅ 보장             | ❌ 아이콘 추가 시 변화 | ❌ 체크마크 추가 시 변화 |
| 커스터마이징      | 완전 커스텀         | 높은 커스텀         | 제한적                |
| 디자인 일관성     | ✅ 디자인 시스템    | ✅ 디자인 시스템    | ❌ Material 기본      |
| 미니멀 디자인     | ✅ 매우 간결        | 보통                | 보통                  |

---

## 다음 단계

1. **CompactChip 구현**: 이 스펙 기반으로 위젯 개발
2. **MultiSelectPopover 통합**: CompactChip을 팝오버에 적용
3. **테스트**: 다양한 화면 크기 및 상태에서 검증
4. **문서 업데이트**: chip-components.md에 CompactChip 추가

---

## 참고 자료

- **디자인 시스템**: [docs/ui-ux/concepts/design-system.md](docs/ui-ux/concepts/design-system.md)
- **디자인 토큰**: [docs/ui-ux/concepts/design-tokens.md](docs/ui-ux/concepts/design-tokens.md)
- **기존 Chip 문서**: [docs/implementation/frontend/chip-components.md](docs/implementation/frontend/chip-components.md)
- **Material 가이드라인**: [Material Design - Chips](https://m3.material.io/components/chips/overview)
