# Toss 디자인 시스템 (Design System)

## 개요 (Overview)
프로덕션급 대학 그룹 관리 시스템을 위한 Toss 디자인 철학 기반 디자인 시스템. 4가지 핵심 원칙(단순함, 위계, 여백, 피드백)을 중심으로 구축된 완성된 디자인 토큰 시스템.

## 관련 문서
- [프론트엔드 가이드](../implementation/frontend-guide.md) - 구현 방법
- [컴포넌트 재사용성 가이드](../implementation/component-reusability-guide.md) - 재사용 패턴
- [컴포넌트 가이드](component-guide.md) - 사용 예시
- [레이아웃 가이드](layout-guide.md) - 화면 구성

## Toss 4대 디자인 원칙

### 1. 단순함 (Simplicity)
- 최소한의 입력 요소로 핵심 기능 제공
- 깔끔한 로그인 화면, 불필요한 옵션 제거
- 사용자가 집중해야 할 액션을 명확하게 표시

### 2. 위계 (Hierarchy)
- 명확한 정보 계층: 제목 → 설명 → 버튼 → 안내
- 타이포그래피 스케일을 통한 시각적 위계
- 컬러와 크기로 중요도 구분

### 3. 여백 (Spacing)
- 일관된 spacing 시스템 (8px 기반)
- 적절한 여백으로 가독성 향상
- 반응형 환경에서 유연한 여백 조정

### 4. 피드백 (Feedback)
- 로딩 상태, 에러 처리, 성공 알림
- 부드러운 애니메이션과 전환 효과
- 사용자 행동에 즉각적인 시각적 반응

## 컬러 시스템 (AppColors)

### 브랜드 컬러
```dart
primary:     #5C068C   // 메인 브랜드 컬러 (학교 공식: Pantone 2597 CVC)
brandStrong: #4B0672   // Hover/Active 등 진한 보라(톤 다운)
brandLight:  #F2E8FA   // 톤 컨테이너/칩/강조 배경(연보라 틴트)
```

### 중성 컬러 (Neutral)
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

### 시스템 컬러
```dart
// 액션(행동) — 버튼/링크/선택 상태는 블루로 통일
actionPrimary:  #1D4ED8   // 주요 CTA/링크
actionHover:    #0F3CC9   // Hover/포커스 시
actionTonalBg:  #EAF2FF   // 선택 배경/하이라이트 표면

// 상태(의미 고정)
success:        #10B981   // 성공/활성
warning:        #F59E0B   // 경고
error:          #E63946   // 오류/위험(가독성 좋은 레드)

// 접근성
focusRing:      rgba(92, 6, 140, 0.45)  // 브랜드 보라 Focus Ring(2px 권장)
```

## 타이포그래피 (AppTypography)

### 폰트 패밀리
- **영문/숫자**: Inter (Geometric Sans-serif)
- **한글**: Noto Sans KR (가독성 최적화)

### 타이포그래피 스케일
```dart
displayLarge: 32px/700   // 메인 제목
displayMedium: 28px/700  // 섹션 제목
headlineLarge: 22px/600  // 카드 헤더
titleLarge: 16px/600     // 버튼, 중요 액션
bodyLarge: 16px/400      // 기본 본문
bodyMedium: 14px/400     // 보조 텍스트
labelLarge: 14px/600     // 폼 레이블
```

## 간격 시스템 (AppSpacing)

### 8px 기반 스케일
```dart
xxs: 8px    // 최소 간격
xs: 12px    // 텍스트 간 여백
sm: 16px    // 컴포넌트 내부 여백
md: 24px    // 컴포넌트 간 여백
lg: 32px    // 섹션 간 여백
xl: 48px    // 대형 섹션 구분
```

### 레이아웃 오프셋
```dart
offsetMin: 96px   // 모바일 수직 여백
offsetMax: 120px  // 데스크톱 수직 여백
```

## 모서리 반경 (AppRadius)
```dart
card: 20px     // 카드 컴포넌트
button: 12px   // 버튼 요소
input: 12px    // 입력 필드
```

## 애니메이션 (AppMotion)
```dart
quick: 120ms          // 빠른 상호작용
standard: 160ms       // 표준 전환
easing: easeOutCubic  // 자연스러운 곡선
```

## 컴포넌트 규격 (AppComponents)

### 버튼 시스템
```dart
buttonHeight: 52px           // 터치 최적화 높이
loginCardMaxWidth: 420px     // 로그인 카드 최대 너비
```

### 로고 시스템
```dart
logoSize: 56px       // 브랜드 로고 크기
logoRadius: 16px     // 로고 모서리
logoIconSize: 28px   // 내부 아이콘
```

## 사용 예시

### 기본 사용법
```dart
// 컬러 적용
Container(
  color: AppColors.primary,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.onPrimary),
  ),
)

// 간격 적용
Padding(
  padding: EdgeInsets.all(AppSpacing.md),
  child: Column(
    children: [
      Text('Title'),
      SizedBox(height: AppSpacing.sm),
      Text('Content'),
    ],
  ),
)
```

### 테마 시스템 활용
```dart
// Theme 기반 스타일
Text(
  'Headline',
  style: AppTheme.headlineLargeTheme(context),
)

// 직접 스타일 적용
Text(
  'Body',
  style: AppTheme.bodyLarge,
)
```

## 접근성 최적화

### 포커스 관리
- FocusTraversalGroup으로 키보드 네비게이션
- 2px 두께의 포커스 링 (AppColors.focusRing)
- 명확한 포커스 순서 정의

### 의미적 마크업
- Semantics 위젯으로 스크린 리더 지원
- 버튼과 링크에 semanticsLabel 제공
- 상태 변경 시 적절한 피드백

## 반응형 지원

### 브레이크포인트
```dart
MOBILE: 0-450px
TABLET: 451-800px
DESKTOP: 801-1920px
4K: 1921px+
```

### 적응형 레이아웃
- 768px 기준으로 패딩과 여백 조정
- 카드 최대 너비로 가독성 보장
- 터치와 마우스 인터랙션 모두 고려
