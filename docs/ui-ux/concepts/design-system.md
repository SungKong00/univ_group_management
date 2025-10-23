# 디자인 시스템 (Design System)

디자인 시스템 전체 개요와 관련 문서들의 네비게이션 허브입니다.

## 개요

디자인 시스템은 일관되고 효율적인 사용자 경험을 제공하기 위한 디자인 원칙, 시각적 스타일, 컴포넌트 패턴의 체계적인 모음입니다. 디자인과 개발 간의 일관성을 보장하며, 제품의 확장성과 유지보수성을 높입니다.

## 구성 요소

디자인 시스템은 네 가지 핵심 레이어로 구성됩니다:

### 1. 디자인 원칙 (Design Principles)
**문서**: [design-principles.md](design-principles.md)

디자인 철학과 사용자 경험의 기본 원칙:
- 코어 원칙: Simplicity First, One Thing Per Page, Easy to Answer
- 레이아웃 및 패턴 규칙
- 타이포그래피 및 라이팅 원칙
- 컬러 및 접근성 지침
- 인터랙션 및 모션 가이드
- 정보 화면 설계 패턴

### 2. 디자인 토큰 (Design Tokens)
**문서**: [design-tokens.md](design-tokens.md)

디자인 원칙을 구현하기 위한 구체적인 값:
- 컬러 시스템 (브랜드, 중성, 시스템)
- 타이포그래피 스케일
- 간격 시스템 (8px 기반)
- 모서리 반경, 애니메이션
- 컴포넌트 규격
- 반응형 브레이크포인트

### 3. 컬러 시스템
**문서**: [color-guide.md](color-guide.md)

컬러 팔레트와 사용 지침:
- 브랜드 컬러 사용 지침
- 접근성 가이드라인 (WCAG AA)
- 컬러 조합 예시

### 4. 반응형 디자인
**문서**: [responsive-design-guide.md](responsive-design-guide.md)

다양한 디바이스 대응 방법:
- 브레이크포인트 정의 (Mobile/Tablet/Desktop)
- 적응형 레이아웃 패턴
- 반응형 컴포넌트 구현

## 주요 컴포넌트

### 버튼 (Button)
- **Primary**: 보라색 배경 + 흰색 텍스트
- **Secondary**: 투명 배경 + 보라색 윤곽선
- **크기**: Large (52px), Medium (40px), Small (32px)

### 카드 (Card)
- **패딩**: 16px (모바일), 24px (데스크톱)
- **모서리**: 20px
- **그림자**: elevation-1
- **구조**: 헤더 → 내용 → 행동 (Primary 버튼 1개)

### 입력 필드 (Input)
- **높이**: 40px
- **상태**: 포커스 링 2px (보라색)
- **구조**: 라벨 + 플레이스홀더

### 헤더 (Header)
- **원칙**: 명시적 제목 우선
- **구조**: 제목(Title) + 역할(Role) + 경로(Path)

## 사용 가이드

### 새로운 기능 디자인
1. [디자인 원칙](design-principles.md) - 핵심 원칙
2. [디자인 토큰](design-tokens.md) - 토큰 값
3. [반응형 가이드](responsive-design-guide.md) - 반응형 규칙

### 컴포넌트 구현
- 디자인 토큰 값 사용
- 모든 상태 구현 (default, hover, active, disabled, focus)
- WCAG AA 접근성 기준 (4.5:1 대비)

## 관련 문서

### 페이지 구현
- [워크스페이스 페이지](../pages/workspace-pages.md) - 워크스페이스 전체 구조
- [채널 페이지](../pages/channel-pages.md) - 채널 권한 플로우
- [모집 페이지](../pages/recruitment-pages.md) - 모집 시스템
- [네비게이션](../pages/navigation-and-page-flow.md) - 네비게이션 구조

### 구현 가이드
- [프론트엔드 디자인 시스템](../../implementation/frontend/design-system.md) - Flutter 구현
