# 디자인 시스템 (Design System)

## 디자인 철학

**Toss 4대 원칙**:

1. **단순함**: 불필요한 요소 제거, 명확한 시각적 계층
2. **위계**: 중요도에 따른 강조 (색상, 크기, 두께)
3. **여백**: 충분한 공간으로 호흡감 있는 UI
4. **피드백**: 사용자 액션에 대한 즉각적 반응

## 디자인 토큰 시스템

**파일**: lib/core/theme/theme.dart

**색상**: Primary (0xFF4080FF) + Semantic (success, error, warning)

**간격**: spacing4 (미니), spacing8 (기본), spacing16 (섹션), spacing32 (큰 여백)

**타이포그래피**: headlineMedium (20px), titleLarge (16px), bodyMedium (14px), bodySmall (12px)

## 버튼 스타일

**4가지 기본 버튼**:

1. **Primary**: 주요 액션 (파란색 배경)
2. **Tonal**: 보조 액션 (옅은 배경)
3. **Outlined**: 취소/무효 (테두리만)
4. **Google**: OAuth 로그인 (SVG 아이콘)

각 버튼 상태:
- 활성 (enabled)
- 비활성 (disabled)
- 로딩 (loading)
- 포커스 (focused)

## 재사용성 원칙

### DRY (Don't Repeat Yourself)

**동일한 코드를 두 번 작성하지 말 것**
- 3곳 이상에서 사용되는 UI는 컴포넌트로 분리
- 디자인 토큰(색상, 간격, 타이포그래피) 활용
- 헬퍼 함수로 복잡한 로직 캡슐화

### 4단계 재사용 전략

1. **하드코딩** (85줄): 모든 스타일을 한 곳에 작성
2. **디자인 토큰화** (60줄): theme.dart로 스타일 분리
3. **컴포넌트화** (35줄): 위젯으로 캡슐화
4. **완전한 재사용** (3줄): 헬퍼 + 독립 위젯

**실전 예시**: 로그아웃 다이얼로그를 85줄에서 3줄로 축소 (96% 감소)

## 접근성 최적화

### 포커스 관리

- 키보드 네비게이션 완전 지원
- 포커스 링 시각화 (Focus border)
- Tab 키로 모든 인터랙티브 요소 접근 가능

### 의미론적 구조 (Semantics)

- 스크린 리더 호환성
- 역할 명시 (button, link, heading 등)
- 상태 설명 (disabled, selected, expanded)

### 색상 대비

- WCAG AA 기준 준수 (4.5:1 이상)
- 흑백 모드 자동 대응
- 색상만으로 정보 전달하지 않음

## 반응형 적응

모바일/태블릿/데스크톱 기준 스타일 조정:

```dart
final isMobile = MediaQuery.of(context).size.width < 768;
final padding = isMobile ? spacing16 : spacing32;
```

자세한 가이드: [responsive-design.md](responsive-design.md)
