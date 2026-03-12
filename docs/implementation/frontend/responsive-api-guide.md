# 반응형 API 가이드 (5-Step System)

본 문서는 Flutter 앱에서 5단계 반응형 시스템을 구현하기 위한 API 가이드입니다.

## 1. 핵심 개념

### ScreenSize Enum (5-Step System)

```dart
enum ScreenSize {
  xs,   // < 450px (소형 모바일)
  sm,   // 450-768px (대형 모바일)
  md,   // 768-1024px (태블릿 세로)
  lg,   // 1024-1440px (태블릿 가로/노트북)
  xl;   // ≥ 1440px (데스크톱)
}
```

### Breakpoint Constants

```dart
// ResponsiveTokens 클래스
static const double xs = 450.0;    // XS 상단
static const double sm = 768.0;    // SM 상단
static const double md = 1024.0;   // MD 상단
static const double lg = 1440.0;   // LG 상단
static const double xl = 1920.0;   // XL 상단
```

## 2. API 레퍼런스

### 2.1. ResponsiveBuilder - 기본 반응형 위젯

```dart
ResponsiveBuilder(
  builder: (context, screenSize, width) {
    return switch (screenSize) {
      ScreenSize.xs || ScreenSize.sm => _buildMobileLayout(),
      ScreenSize.md => _buildTabletLayout(),
      _ => _buildDesktopLayout(),
    };
  },
)
```

**파라미터:**
- `context`: BuildContext
- `screenSize`: ScreenSize enum (현재 화면 크기)
- `width`: double (실제 화면 너비 px)

### 2.2. ResponsiveValue<T> - 화면별 값 제공

```dart
// 모든 값 지정
final padding = ResponsiveValue<double>(
  xs: 16.0,
  sm: 20.0,
  md: 24.0,
  lg: 28.0,
  xl: 32.0,
).getValue(context);

// 일부만 지정 (폴백 적용)
final padding = ResponsiveValue<double>(
  xs: 16.0,  // sm, md, lg, xl이 xs 값 사용
  lg: 28.0,  // xl은 lg 값 사용
).getValue(context);
```

**폴백 규칙:**
- SM → XS
- MD → SM → XS
- LG → MD → SM → XS
- XL → LG → MD → SM → XS

### 2.3. 조건부 렌더링 - ShowOn/HideOn 컴포넌트

```dart
// 특정 크기에서만 표시
ShowOnXS(child: Text('모바일만'));
ShowOnSM(child: Text('대형 모바일'));
ShowOnMD(child: Text('태블릿'));
ShowOnLG(child: Text('노트북'));
ShowOnXL(child: Text('데스크톱'));

// 여러 크기 조합
ShowOnScreenSize(
  screenSizes: [ScreenSize.xs, ScreenSize.sm],
  child: Text('모바일만'),
)

// 특정 크기에서만 숨김
HideOnXS(child: Text('SM 이상'));
```

### 2.4. ResponsiveTokens - 반응형 값 계산

```dart
// 페이지 패딩
final padding = ResponsiveTokens.pagePadding(width);
// XS: 16px, SM: 20px, MD: 24px, LG: 28px, XL: 32px

// 그리드 컬럼 수
final columns = ResponsiveTokens.columnCount(width);
// XS: 4, SM: 8, MD: 12, LG: 16, XL: 20

// 카드 패딩
final cardPadding = ResponsiveTokens.cardPadding(width);
// XS/SM: 12px, MD/LG: 16px, XL: 20px

// 카드 간격
final cardGap = ResponsiveTokens.cardGap(width);
// XS/SM: 8px, MD: 12px, LG/XL: 16px

// 버튼 높이
final btnHeight = ResponsiveTokens.buttonHeight(width);
// XS/SM: 40px, MD/LG: 44px, XL: 48px

// 화면 크기 판단
final isXS = ResponsiveTokens.isXS(width);
final isSM = ResponsiveTokens.isSM(width);
final isMD = ResponsiveTokens.isMD(width);
final isLG = ResponsiveTokens.isLG(width);
final isXL = ResponsiveTokens.isXL(width);
```

### 2.5. GridLayoutTokens - 카드 그리드 설정

```dart
// Named preset로부터 반응형 그리드
AdaptiveCardGrid.fromPreset(
  config: GridLayoutTokens.pricingCards(width),
  itemCount: items.length,
  itemBuilder: (context, index) => PricingCard(items[index]),
  maxContentWidth: ResponsiveTokens.maxContentWidth,
)

// 카드 타입과 컬럼으로부터 동적 생성 (권장)
AdaptiveCardGrid.fromCardType(
  cardType: CardVariant.vertical,
  columns: GridPresetColumns.three,
  itemCount: items.length,
  itemBuilder: (context, index) => Card(items[index]),
)
```

**Available Presets:**
- `pricingCards(width)` - 3열 가격 카드
- `customerTestimonials(width)` - 2열 고객 추천사
- `featureHighlights(width)` - 4열 기능 카드
- `tagGrid(width)` - 6열 태그
- `customerCards(width)` - 4열 고객 카드

### 2.6. AdaptiveCardGrid - 유연한 카드 그리드

```dart
AdaptiveCardGrid(
  itemCount: 12,
  itemBuilder: (context, index) => MyCard(items[index]),

  // 카드 크기 범위
  minItemWidth: 260,
  maxItemWidth: 380,

  // 선택: 최대 컬럼 수 제한
  maxColumns: 4,

  // 선택: 반응형 간격
  spacing: null, // null이면 ResponsiveTokens.cardGap 자동 사용

  // 선택: 비율 강제
  aspectRatio: ResponsiveValue(
    xs: 1.0,
    sm: 1.1,
    md: 1.2,
    lg: 1.3,
    xl: 1.4,
  ),

  // 선택: 레이아웃 모드
  mode: AdaptiveLayoutMode.grid, // grid, wrap, list

  // 선택: 좋은 폭에서 가로 스크롤
  scrollOnOverflow: true,
)
```

### 2.7. CardDesignTokens - 카드 크기 계산

```dart
// 화면별 카드 최소/최대 너비
final sizes = CardDesignTokens.getCardWidths('vertical', width);
// { 'min': 260, 'max': 380, 'preferred': 340 }

// 메타 스타일
final metaStyle = CardDesignTokens.getMetaStyle(context);

// 서브타이틀 스타일
final titleStyle = CardDesignTokens.getSubtitleStyle(context);
```

## 3. 사용 패턴

### 패턴 1: 간단한 조건부 레이아웃

```dart
ResponsiveBuilder(
  builder: (context, screenSize, width) {
    return screenSize == ScreenSize.xs || screenSize == ScreenSize.sm
        ? Column(children: [...])  // 모바일
        : Row(children: [...]);     // 데스크톱
  },
)
```

### 패턴 2: 반응형 값 조합

```dart
final padding = ResponsiveTokens.pagePadding(width);
final columns = ResponsiveTokens.columnCount(width);
final gap = ResponsiveTokens.cardGap(width);

// 페이지 패딩 + 그리드 레이아웃
Padding(
  padding: EdgeInsets.all(padding),
  child: GridView.count(
    crossAxisCount: columns,
    mainAxisSpacing: gap,
    crossAxisSpacing: gap,
    children: [...],
  ),
)
```

### 패턴 3: 복잡한 반응형 카드 그리드

```dart
ResponsiveBuilder(
  builder: (context, screenSize, width) {
    return AdaptiveCardGrid.fromCardType(
      cardType: CardVariant.vertical,
      columns: screenSize == ScreenSize.xl
          ? GridPresetColumns.four
          : screenSize == ScreenSize.lg
          ? GridPresetColumns.three
          : GridPresetColumns.two,
      itemCount: cards.length,
      itemBuilder: (context, index) => ProductCard(cards[index]),
    );
  },
)
```

### 패턴 4: 모바일/데스크톱 다른 구조

```dart
ResponsiveBuilder(
  builder: (context, screenSize, width) {
    if (screenSize.isCompact) {
      // XS/SM/MD: 전체 화면 뷰
      return Column(children: [
        HeaderSection(),
        ContentView(),
      ]);
    } else {
      // LG/XL: 분할 뷰
      return Row(children: [
        Expanded(flex: 2, child: ContentView()),
        Expanded(flex: 1, child: SidebarView()),
      ]);
    }
  },
)
```

## 4. Deprecated API (2025-11-23 이후)

### Deprecated Constants
```dart
@Deprecated('Use ScreenSize.xs instead')
static const double mobile = 450.0;

@Deprecated('Use ScreenSize.lg instead')
static const double desktop = 1440.0;
```

### Deprecated Methods
```dart
@Deprecated('Use isXS() instead')
static bool isMobile(double width) => isXS(width);

@Deprecated('Use isLG() or isXL() instead')
static bool isDesktop(double width) => isLG(width) || isXL(width);
```

### Deprecated Components
```dart
@Deprecated('Use ShowOnXS instead')
class ShowOnMobile extends ShowOnXS { ... }

@Deprecated('Use ShowOnLG or ShowOnXL instead')
class ShowOnDesktop extends StatelessWidget { ... }
```

**Migration Guide:**
- `isMobile()` → `isXS(width)`
- `isTablet()` → `isSM(width) || isMD(width)`
- `isDesktop()` → `isLG(width) || isXL(width)`
- `ShowOnMobile` → `ShowOnXS`
- `ShowOnTablet` → `ShowOnSM` 또는 `ShowOnMD`
- `ShowOnDesktop` → `ShowOnLG` 또는 `ShowOnXL`

## 5. Best Practices

1. **항상 width를 전달하기**: ResponsiveTokens 호출 시 width 파라미터는 필수
   ```dart
   ✅ ResponsiveTokens.cardGap(width)
   ❌ ResponsiveTokens.cardGap()  // 컴파일 에러
   ```

2. **LayoutBuilder와 조합하기**: 실제 사용 가능한 너비 계산
   ```dart
   LayoutBuilder(
     builder: (context, constraints) {
       final itemWidth = constraints.maxWidth;
       // ...
     },
   )
   ```

3. **MediaQuery.sizeOf() 사용**: 성능 최적화
   ```dart
   ✅ final width = MediaQuery.sizeOf(context).width;
   ❌ final width = MediaQuery.of(context).size.width; // 더 느림
   ```

4. **Switch 표현식 사용**: 깔끔한 조건부 레이아웃
   ```dart
   return switch (screenSize) {
     ScreenSize.xs || ScreenSize.sm => _buildMobile(),
     ScreenSize.md => _buildTablet(),
     _ => _buildDesktop(),
   };
   ```

5. **GridLayoutTokens 활용**: 일관된 그리드 설정
   ```dart
   // 하드코딩 피하기
   ❌ minWidth = screenSize == xs ? 260 : 280;
   ✅ minWidth = GridLayoutTokens.forCardType(type, columns, width: width).minItemWidth;
   ```

## 6. 관련 문서

- [반응형 UI 가이드](../ui-ux/concepts/responsive-design-guide.md)
- [디자인 토큰](../ui-ux/concepts/design-tokens.md)
- [디자인 시스템](./design-system.md)
