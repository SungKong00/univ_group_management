# 디자인 토큰 (Design Tokens)

본 문서는 디자인 철학을 실제 코드로 구현하기 위한 구체적인 값(토큰)을 정의합니다.

## 개요

디자인 토큰은 색상, 타이포그래피, 간격, 모서리 반경, 애니메이션 등 UI 디자인의 모든 시각적 속성을 정의하는 명명된 값입니다. 이를 통해 디자인과 개발 간의 일관성을 유지하고, 전체 시스템의 스타일을 중앙에서 관리할 수 있습니다.

## 1. 컬러 시스템 (AppColors)

### 1.1. 브랜드 컬러

```dart
primary:     #5C068C   // 메인 브랜드 컬러 (학교 공식: Pantone 2597 CVC)
brandStrong: #4B0672   // Hover/Active 등 진한 보라(톤 다운)
brandLight:  #F2E8FA   // 톤 컨테이너/칩/강조 배경(연보라 틴트)
```

### 1.2. 중성 컬러 (Neutral)

```dart
neutral900: #0F172A   // 제목, 가장 중요한 텍스트
neutral800: #1E293B   // 섹션 타이틀
neutral700: #334155   // 본문 텍스트
neutral600: #64748B   // 보조 텍스트/아이콘
neutral500: #94A3B8   // 서브 아이콘, 비활성 텍스트
neutral400: #CBD5E1   // 얕은 보더/디바이더
neutral300: #E2E8F0   // 카드 보더/섹션 분리
neutral200: #EEF2F6   // 카드/패널 표면 구분
neutral100: #F8FAFC   // 페이지 베이스 배경
```

### 1.3. 시스템 컬러

#### 액션(행동) — 버튼/링크/선택 상태는 블루로 통일

```dart
actionPrimary:  #1D4ED8   // 주요 CTA/링크
actionHover:    #0F3CC9   // Hover/포커스 시
actionTonalBg:  #EAF2FF   // 선택 배경/하이라이트 표면
```

#### 상태(의미 고정)

```dart
success:        #10B981   // 성공/활성
warning:        #F59E0B   // 경고
error:          #E63946   // 오류/위험(가독성 좋은 레드)
```

#### 접근성

```dart
focusRing:      rgba(92, 6, 140, 0.45)  // 브랜드 보라 Focus Ring(2px 권장)
```

## 2. 타이포그래피 (AppTypography)

### 2.1. 폰트 패밀리

- **영문/숫자**: Inter (Geometric Sans-serif)
- **한글**: Noto Sans KR (가독성 최적화)

### 2.2. 타이포그래피 스케일

```dart
displayLarge: 32px/700   // 메인 제목
displayMedium: 28px/700  // 섹션 제목
headlineLarge: 22px/600  // 카드 헤더
titleLarge: 16px/600     // 버튼, 중요 액션
bodyLarge: 16px/400      // 기본 본문
bodyMedium: 14px/400     // 보조 텍스트
labelLarge: 14px/600     // 폼 레이블
```

## 3. 간격 시스템 (AppSpacing)

### 3.1. 8px 기반 스케일

```dart
xxs: 8px    // 최소 간격
xs: 12px    // 텍스트 간 여백
sm: 16px    // 컴포넌트 내부 여백
md: 24px    // 컴포넌트 간 여백
lg: 32px    // 섹션 간 여백
xl: 48px    // 대형 섹션 구분
```

### 3.2. 레이아웃 오프셋

```dart
offsetMin: 96px   // 모바일 수직 여백
offsetMax: 120px  // 데스크톱 수직 여백
```

## 4. 모서리 반경 (AppRadius)

```dart
card: 20px     // 카드 컴포넌트
button: 12px   // 버튼 요소
input: 12px    // 입력 필드
```

## 5. 애니메이션 (AppMotion)

```dart
quick: 120ms          // 빠른 상호작용
standard: 160ms       // 표준 전환
easing: easeOutCubic  // 자연스러운 곡선
```

## 6. 컴포넌트 규격 (AppComponents)

### 6.1. 버튼 시스템

```dart
buttonHeight: 52px           // 터치 최적화 높이
loginCardMaxWidth: 420px     // 로그인 카드 최대 너비
```

### 6.2. 로고 시스템

```dart
logoSize: 56px       // 브랜드 로고 크기
logoRadius: 16px     // 로고 모서리
logoIconSize: 28px   // 내부 아이콘
```

## 7. 반응형 지원 (Responsive)

### 7.1. 브레이크포인트

```dart
MOBILE: 0-450px
TABLET: 451-800px
DESKTOP: 801-1920px
4K: 1921px+
```

## 관련 문서

- [디자인 시스템 가이드](design-system.md) - 전체 디자인 시스템 개요
- [디자인 원칙](design-principles.md) - 디자인 철학 및 패턴
- [반응형 디자인 가이드](responsive-design-guide.md) - 반응형 레이아웃 상세
- [컬러 가이드](color-guide.md) - 컬러 사용 지침
