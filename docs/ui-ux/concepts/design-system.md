# 디자인 시스템 가이드 (Design System Guide)

본 문서는 우리 제품의 디자인 시스템 전체 개요와 관련 문서들의 네비게이션 허브입니다.

## 개요

디자인 시스템은 일관되고 효율적인 사용자 경험을 제공하기 위한 디자인 원칙, 시각적 스타일, 컴포넌트 패턴의 체계적인 모음입니다. 이 시스템은 디자인과 개발 간의 일관성을 보장하며, 제품의 확장성과 유지보수성을 높입니다.

## 디자인 시스템 구성 요소

우리의 디자인 시스템은 세 가지 핵심 레이어로 구성됩니다:

### 1. 디자인 원칙 (Design Principles)
**문서**: [design-principles.md](design-principles.md)

디자인 철학과 사용자 경험의 기본 원칙을 정의합니다:
- 코어 원칙 (Simplicity First, One Thing Per Page, Easy to Answer)
- 레이아웃 및 패턴 규칙
- 타이포그래피 및 라이팅 원칙
- 컬러 및 접근성 지침
- 인터랙션 및 모션 가이드
- 정보 화면 설계 패턴
- 콘텐츠 및 이모지 사용 규칙

### 2. 디자인 토큰 (Design Tokens)
**문서**: [design-tokens.md](design-tokens.md)

디자인 원칙을 구현하기 위한 구체적인 값들을 정의합니다:
- 컬러 시스템 (브랜드, 중성, 시스템 컬러)
- 타이포그래피 스케일
- 간격 시스템
- 모서리 반경
- 애니메이션 타이밍
- 컴포넌트 규격
- 반응형 브레이크포인트

### 3. 반응형 디자인
**문서**: [responsive-design-guide.md](responsive-design-guide.md)

다양한 디바이스와 화면 크기에 대응하는 방법을 정의합니다:
- 브레이크포인트 정의
- 적응형 레이아웃 패턴
- 반응형 컴포넌트 구현

### 4. 컬러 시스템
**문서**: [color-guide.md](color-guide.md)

컬러 팔레트와 사용 지침을 상세히 정의합니다:
- 브랜드 컬러 사용 지침
- 접근성 가이드라인
- 컬러 조합 예시

## 핵심 컴포넌트 가이드

디자인 시스템의 주요 컴포넌트들:

### 버튼 (Button)
-   **Primary:** 보라색 배경 + 흰색 텍스트
-   **Secondary:** 투명 배경 + 보라색 텍스트 + 보라색 윤곽선
-   **크기:** Large (상하 패딩 16/20px), Medium (12/16px), Small (8/12px)

### 카드 (Card)
-   **속성:** 내부 여백 16/24px, 모서리 둥글기 20px, 그림자 elevation-1
-   **구조:** 헤더(아이콘+제목) → 내용 → 행동(Primary 버튼 1개)
-   **ActionCard:** Title + Description 패턴 적용

### 폼 (Form)
-   **구조:** 라벨은 항상 한 줄로, 플레이스홀더는 입력 예시 표시
-   **상태:** 포커스 시 2px 보라색 링, 에러 시 위험 색상 표시

### 드롭다운 (Dropdown)
-   **구조:** 트리거 버튼 + 드롭다운 리스트
-   **계층 표시:** level × 16px 들여쓰기
-   **정렬:** 계층적 정렬 (DFS 기반)

### 헤더 (Header)
-   **원칙:** 명시적 제목 우선 (Explicit Title First)
-   **구조:** 2단 계층 - 제목(Title) + 역할(Role) + 경로(Path)

## 구현 참조

### Flutter/Dart 구현
디자인 토큰은 다음과 같은 Flutter 클래스로 구현됩니다:
- `AppColors`: 컬러 시스템
- `AppTypography`: 타이포그래피 스케일
- `AppSpacing`: 간격 시스템
- `AppRadius`: 모서리 반경
- `AppMotion`: 애니메이션 타이밍
- `AppComponents`: 컴포넌트 규격

### 구현 위치
```
frontend/lib/core/theme/
├── app_colors.dart
├── app_typography.dart
├── app_spacing.dart
├── app_radius.dart
├── app_motion.dart
└── app_components.dart
```

## 사용 가이드

### 1. 새로운 기능 디자인 시
1. [design-principles.md](design-principles.md)에서 핵심 원칙 확인
2. [design-tokens.md](design-tokens.md)에서 사용할 토큰 값 확인
3. [responsive-design-guide.md](responsive-design-guide.md)에서 반응형 규칙 확인

### 2. 컴포넌트 구현 시
1. 디자인 토큰에서 정의된 값 사용
2. 모든 인터랙티브 상태 (default, hover, active, disabled, focus) 구현
3. WCAG AA 접근성 기준 준수

### 3. 컬러 사용 시
1. [color-guide.md](color-guide.md)에서 적절한 컬러 확인
2. Grayscale 70-80% / Brand Color 20-30% 비율 유지
3. WCAG AA 대비 기준 (4.5:1) 준수

## 관련 페이지 문서

디자인 시스템이 적용된 주요 페이지들:
- [워크스페이스 페이지](../pages/workspace-pages.md) - 워크스페이스 콘텐츠 페이지
- [채널 페이지](../pages/channel-pages.md) - 채널 권한 및 생성 플로우
- [모집 페이지](../pages/recruitment-pages.md) - 모집 공고 관련 페이지
- [네비게이션 및 페이지 플로우](../pages/navigation-and-page-flow.md) - 전체 네비게이션 구조

## 업데이트 정책

디자인 시스템 변경 시:
1. 해당 문서 업데이트 (design-principles.md, design-tokens.md 등)
2. 구현 코드 반영 (frontend/lib/core/theme/)
3. 영향받는 페이지 문서 확인 및 업데이트
4. 컨텍스트 추적 시스템에 변경 기록
