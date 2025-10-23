# 반응형 디자인 (Responsive Design)

## 브레이크포인트 시스템

### 정의

**파일**: lib/core/constants/breakpoints.dart

```dart
ResponsiveBreakpoints.builder(
  breakpoints: [
    const Breakpoint(start: 0, end: 450, name: MOBILE),
    const Breakpoint(start: 451, end: 800, name: TABLET),
    const Breakpoint(start: 801, end: 1920, name: DESKTOP),
    const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
  ],
)
```

### 각 레벨별 특성

- **모바일** (0-450px): 1열, 가득 찬 너비, 최소한의 패딩 (8px)
- **태블릿** (451-800px): 2열, 중간 패딩 (16px), 터치 친화적
- **데스크톱** (801-1920px): 3열+, 넓은 패딩 (32px), 마우스 최적화
- **4K** (1921px+): 고정 최대 너비, 중앙 정렬

## 적응형 레이아웃

### 조건부 스타일 적용

```dart
// 화면 크기 감지
final size = MediaQuery.of(context).size;
final isWide = size.width > 768;

// 패딩 동적 조정
final horizontalPadding = isWide ? AppSpacing.spacing32 : AppSpacing.spacing16;
final verticalPadding = isWide ? AppSpacing.spacing120 : AppSpacing.spacing96;

// 열 개수 동적 조정
final crossAxisCount = isWide ? 3 : 1;
```

### 실전 패턴

```dart
Column(
  children: [
    // 상단: 모든 크기에서 일정
    Header(),

    // 중간: 반응형
    if (isWide)
      Sidebar()    // 데스크톱: 옆에 표시
    else
      TabBar(),    // 모바일: 탭으로 표시

    // 하단: 모든 크기에서 일정
    Footer(),
  ],
)
```

## 상단바 높이 최적화

**모바일 공간 효율성 개선**:

- 상단바 높이: **48px** (데스크톱 64px → 25% 감소)
- 타이포그래피: headlineMedium (20px) → titleLarge (16px)
- 아이콘 크기: 24px → 20px
- 사용자 아바타: 32×32px → 24×24px
- 간격 최적화: 8px → 4px, 6px → 4px

**영향받는 컴포넌트**:
- TopNavigation (상단바 메인)
- BreadcrumbWidget (경로 표시)
- WorkspaceHeader (워크스페이스 헤더)
- GroupDropdown (그룹 드롭다운)

## 웹 vs 모바일 레이아웃

### 웹 버전 (Desktop)

- 2열 레이아웃: 사이드바 + 메인 콘텐츠
- 사이드바: 고정 너비 (280px)
- 댓글: 우측 패널에 사이드바로 표시

### 모바일 버전 (Mobile/Tablet)

- 1열 레이아웃: 풀스크린
- 탭 네비게이션: 하단 또는 상단
- 댓글: 모달이나 별도 페이지로 표시

## 체크리스트

새로운 레이아웃 추가 시: 모바일/태블릿/데스크톱/4K 테스트, 텍스트 가독성(14px 이상), 터치 대상(48x48px 이상), 이미지 스케일링 확인
