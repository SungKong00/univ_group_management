# 디자인 토큰 (Design Tokens)

디자인 철학을 실제 코드로 구현하기 위한 구체적인 값(토큰)을 정의합니다.

## 개요

디자인 토큰은 색상, 타이포그래피, 간격, 모서리 반경, 애니메이션 등 UI의 모든 시각적 속성을 정의하는 명명된 값입니다. 이를 통해 디자인과 개발 간의 일관성을 유지하고, 전체 시스템의 스타일을 중앙에서 관리할 수 있습니다.

## 1. 컬러 시스템

### 브랜드 컬러
- **primary**: `#5C068C` - 메인 브랜드 컬러
- **brandStrong**: `#4B0672` - Hover/Active 진한 보라
- **brandLight**: `#F2E8FA` - 배경/칩 연보라

### 중성 컬러 (Neutral)
- **neutral900**: `#0F172A` - 제목
- **neutral700**: `#334155` - 본문
- **neutral600**: `#64748B` - 보조 텍스트
- **neutral400**: `#CBD5E1` - 보더
- **neutral200**: `#EEF2F6` - 카드 표면
- **neutral100**: `#F8FAFC` - 배경

### 시스템 컬러
- **actionPrimary**: `#1D4ED8` - CTA/링크 (블루)
- **actionHover**: `#0F3CC9` - Hover 상태
- **success**: `#10B981` - 성공/활성 (녹색)
- **warning**: `#F59E0B` - 경고 (주황)
- **error**: `#E63946` - 오류/위험 (빨강)
- **focusRing**: `rgba(92, 6, 140, 0.45)` - 포커스 링

자세한 컬러 사용 지침: [컬러 가이드](color-guide.md)

## 2. 타이포그래피

**폰트**: Inter (영문/숫자), Noto Sans KR (한글)

- **displayLarge**: 32px/700 - 메인 제목
- **displayMedium**: 28px/700 - 섹션 제목
- **headlineLarge**: 22px/600 - 카드 헤더
- **titleLarge**: 16px/600 - 버튼
- **bodyLarge**: 16px/400 - 본문
- **bodyMedium**: 14px/400 - 보조

## 3. 간격 시스템 (8px 기반)

- **xxs**: 8px - 최소 간격
- **xs**: 12px - 텍스트 간 여백
- **sm**: 16px - 컴포넌트 내부 여백
- **md**: 24px - 컴포넌트 간 여백
- **lg**: 32px - 섹션 간 여백
- **xl**: 48px - 대형 섹션 구분

### 레이아웃 오프셋
- **offsetMin**: 96px - 모바일 수직 여백
- **offsetMax**: 120px - 데스크톱 수직 여백

## 4. 모서리 반경

- **card**: 20px - 카드 컴포넌트
- **button**: 12px - 버튼 요소
- **input**: 12px - 입력 필드

## 5. 애니메이션

- **quick**: 120ms - 빠른 상호작용
- **standard**: 160ms - 표준 전환
- **easing**: easeOutCubic - 자연스러운 곡선

## 6. 컴포넌트 규격

### 버튼 시스템
- **buttonHeight**: 52px - 터치 최적화 높이
- **loginCardMaxWidth**: 420px - 로그인 카드 최대 너비

### 로고 시스템
- **logoSize**: 56px - 브랜드 로고 크기
- **logoRadius**: 16px - 로고 모서리
- **logoIconSize**: 28px - 내부 아이콘

## 7. 반응형 브레이크포인트

- **MOBILE**: 0-450px
- **TABLET**: 451-800px
- **DESKTOP**: 801-1920px
- **4K**: 1921px+

자세한 반응형 패턴: [반응형 가이드](responsive-design-guide.md)

## Flutter 구현

`frontend/lib/core/theme/` 디렉토리의 토큰 클래스 사용
- 상세 구현: [프론트엔드 디자인 시스템](../../implementation/frontend/design-system.md)

## 관련 문서

- [디자인 시스템](design-system.md) - 전체 개요
- [디자인 원칙](design-principles.md) - 디자인 철학
- [컬러 가이드](color-guide.md) - 컬러 상세
- [반응형 가이드](responsive-design-guide.md) - 반응형
