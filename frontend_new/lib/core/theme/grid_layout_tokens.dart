import 'package:flutter/material.dart';
import 'responsive_tokens.dart';
import 'enums.dart';
import '../widgets/responsive_builder.dart';

/// 반응형 그리드 레이아웃 설정
///
/// [AdaptiveCardGrid]에 필요한 모든 파라미터를 사전 계산하여 제공합니다.
/// 토큰 레이어를 통해 일관된 그리드 레이아웃을 보장합니다.
@immutable
class GridLayoutConfig {
  /// 그리드 아이템 최소 너비 (카드가 너무 좁아지지 않도록 방지)
  final double minItemWidth;

  /// 그리드 아이템 최대 너비 (카드가 너무 넓어지지 않도록 방지)
  final double maxItemWidth;

  /// 그리드 최대 열 수 (이 값을 초과하여 렌더링되지 않음)
  final int maxColumns;

  /// 열 수 계산에 사용되는 선호 너비
  /// 화면 너비를 이 값으로 나누어 열 수를 결정합니다
  final double preferredItemWidth;

  /// 화면 크기에 따른 종횡비 (null이면 자동 높이)
  final ResponsiveValue<double>? aspectRatio;

  /// 모든 아이템에 aspectRatio를 강제할지 여부
  final bool enforceAspectRatio;

  const GridLayoutConfig({
    required this.minItemWidth,
    required this.maxItemWidth,
    required this.maxColumns,
    required this.preferredItemWidth,
    this.aspectRatio,
    this.enforceAspectRatio = true,
  });

  @override
  String toString() =>
      'GridLayoutConfig(min: $minItemWidth, max: $maxItemWidth, '
      'cols: $maxColumns, preferred: $preferredItemWidth)';
}

/// 그리드 레이아웃 프리셋 토큰 시스템
///
/// **핵심 원칙**: 프리셋 열 수를 가능한 한 유지하되, breakpoint 제한 내에서 적용합니다.
/// 카드 크기는 가용 너비에서 동적으로 계산됩니다.
///
/// ## 설계 원칙
///
/// 1. **열 수 = min(프리셋, breakpoint 최대)**: 프리셋이 화면 한계를 넘으면 자동 조정
/// 2. **일관성**: 6열에서 5열이 보이는 화면 → 5열 프리셋 선택 시 5열 유지
/// 3. **동적 카드 크기**: 카드 크기 = (가용너비 - 간격합) / 열수
///
/// ## Breakpoint별 최대 열 수
///
/// | Breakpoint | 최대 열 수 |
/// |------------|-----------|
/// | XS (<450)  | 3열       |
/// | SM (450-768) | 4열     |
/// | MD (768-1024) | 5열    |
/// | LG/XL (≥1024) | 6열    |
///
/// ## 픽셀 계산 공식
///
/// ```
/// availableWidth = screenWidth - (pagePadding × 2)
/// totalGaps = gap × (columns - 1)
/// cardWidth = (availableWidth - totalGaps) / columns
/// ```
///
/// ## 사용 예시
/// ```dart
/// // 방법 1: fromCardType (권장 - 반응형)
/// AdaptiveCardGrid.fromCardType(
///   cardType: CardVariant.vertical,
///   columns: GridPresetColumns.three,
///   itemCount: items.length,
///   itemBuilder: (context, index) => VerticalCard(...),
/// );
///
/// // 방법 2: Named preset
/// final width = MediaQuery.sizeOf(context).width;
/// AdaptiveCardGrid.fromPreset(
///   config: GridLayoutTokens.pricingCards(width),
///   itemCount: plans.length,
///   itemBuilder: (context, index) => PricingCard(plans[index]),
/// );
/// ```
class GridLayoutTokens {
  GridLayoutTokens._();

  // ═══════════════════════════════════════════════════════════════════════════
  // Breakpoint별 최대 열 수 테이블
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // 각 breakpoint에서 **표시 가능한 최대 열 수**를 정의합니다.
  // 프리셋 열 수가 이보다 크면 이 값으로 제한됩니다.

  /// Breakpoint별 최대 열 수
  ///
  /// 실제 열 수 = min(프리셋 열 수, breakpoint 최대 열 수)
  ///
  /// 예: GridPresetColumns.five를 지정하고 화면이 SM이면
  /// - SM 최대 = 4열
  /// - 프리셋 = 5열
  /// - 결과 = min(5, 4) = 4열
  static const Map<ScreenSize, int> _maxColumnsByBreakpoint = {
    ScreenSize.xs: 3, // XS: 최대 3열
    ScreenSize.sm: 4, // SM: 최대 4열
    ScreenSize.md: 5, // MD: 최대 5열
    ScreenSize.lg: 6, // LG: 최대 6열
    ScreenSize.xl: 6, // XL: 최대 6열
  };

  /// 프리셋 열 수를 정수로 변환
  static int _presetToInt(GridPresetColumns columns) {
    return switch (columns) {
      GridPresetColumns.one => 1,
      GridPresetColumns.two => 2,
      GridPresetColumns.three => 3,
      GridPresetColumns.four => 4,
      GridPresetColumns.five => 5,
      GridPresetColumns.six => 6,
    };
  }

  /// Breakpoint별 최소 열 수 (너무 좁은 화면에서 강제 적용)
  static const Map<ScreenSize, int> _minColumnsByBreakpoint = {
    ScreenSize.xs: 1, // XS: 최소 1열
    ScreenSize.sm: 1, // SM: 최소 1열
    ScreenSize.md: 1, // MD: 최소 1열
    ScreenSize.lg: 1, // LG: 최소 1열
    ScreenSize.xl: 1, // XL: 최소 1열
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API: 범용 프리셋
  // ═══════════════════════════════════════════════════════════════════════════

  /// 카드 타입과 열 수에 따른 최적화된 그리드 설정을 반환합니다.
  ///
  /// **핵심 원칙**: 프리셋에서 지정한 열 수를 **강제 적용**합니다.
  /// 카드 크기는 가용 너비에서 동적으로 계산됩니다.
  ///
  /// [cardType] - 카드 종류 (vertical, horizontal, compact 등)
  /// [columns] - 의도한 열 수 프리셋
  /// [width] - 현재 화면 너비 (px)
  ///
  /// ## 예시
  /// ```dart
  /// final width = MediaQuery.sizeOf(context).width;
  ///
  /// // 세로 카드 3열 - 화면 크기에 따라 자동 조정
  /// final config = GridLayoutTokens.forCardType(
  ///   CardVariant.vertical,
  ///   GridPresetColumns.three,
  ///   width: width,
  /// );
  /// // XS: 1열, SM: 2열, MD+: 3열
  /// ```
  static GridLayoutConfig forCardType(
    CardVariant cardType,
    GridPresetColumns columns, {
    required double width,
  }) {
    final screenSize = ResponsiveTokens.getScreenSize(width);

    // 프리셋 열 수
    final presetColumns = _presetToInt(columns);

    // breakpoint 제한 적용: min(프리셋, breakpoint 최대)
    // 이렇게 하면 6열 프리셋에서 5열이 보이는 화면에서
    // 5열 프리셋으로 바꿔도 5열이 유지됨
    final maxColumns = _maxColumnsByBreakpoint[screenSize]!;
    final minColumns = _minColumnsByBreakpoint[screenSize]!;
    final actualColumns = presetColumns.clamp(minColumns, maxColumns);

    // 가용 너비 계산
    final gap = ResponsiveTokens.cardGap(width);
    final padding = ResponsiveTokens.pagePadding(width);
    final availableWidth = width - (padding * 2);
    final totalGaps = gap * (actualColumns - 1);

    // 카드 너비 동적 계산 (가용 너비를 열 수로 나눔)
    final cardWidth = (availableWidth - totalGaps) / actualColumns;

    // 최대 너비만 제한 (카드가 너무 넓어지지 않도록)
    // 최소 너비는 제한하지 않음 - 열 수가 우선
    final maxWidth = _getMaxWidthForCard(cardType);

    // 종횡비 및 강제 여부
    final aspectRatio = _getAspectRatioForCard(cardType);
    final enforceAspectRatio = _shouldEnforceAspectRatio(cardType);

    return GridLayoutConfig(
      minItemWidth: 0, // 열 수 우선 - 최소 너비 제한 없음
      maxItemWidth: maxWidth,
      maxColumns: actualColumns,
      preferredItemWidth: cardWidth,
      aspectRatio: aspectRatio,
      enforceAspectRatio: enforceAspectRatio,
    );
  }

  /// 카드 타입별 최대 너비 (8px 그리드)
  static double _getMaxWidthForCard(CardVariant cardType) {
    return switch (cardType) {
      CardVariant.vertical => 480, // 60×8 - 세로 카드 최대
      CardVariant.horizontal => 720, // 90×8 - 가로 카드 최대
      CardVariant.compact => 200, // 25×8 - 콤팩트 카드 최대
      CardVariant.selectable => 600, // 75×8 - 선택 카드 최대
      CardVariant.wide => 1600, // 200×8 - 와이드 카드 최대
    };
  }

  /// 화면 너비와 카드 타입으로 적절한 열 수를 자동 계산합니다.
  ///
  /// [cardType] - 카드 종류
  /// [width] - 화면 너비
  /// [preferredColumns] - 원하는 열 수 (null이면 자동 계산)
  ///
  /// 반환값: 해당 화면에서 렌더링될 실제 열 수
  static int calculateColumns(
    CardVariant cardType,
    double width, {
    GridPresetColumns? preferredColumns,
  }) {
    final screenSize = ResponsiveTokens.getScreenSize(width);

    if (preferredColumns != null) {
      final presetColumns = _presetToInt(preferredColumns);
      final maxColumns = _maxColumnsByBreakpoint[screenSize]!;
      final minColumns = _minColumnsByBreakpoint[screenSize]!;
      return presetColumns.clamp(minColumns, maxColumns);
    }

    // 자동 계산: 카드 타입에 따른 기본 열 수
    return switch (cardType) {
      CardVariant.vertical => switch (screenSize) {
        ScreenSize.xs => 1,
        ScreenSize.sm => 2,
        _ => 3,
      },
      CardVariant.horizontal => switch (screenSize) {
        ScreenSize.xs => 1,
        _ => 2,
      },
      CardVariant.compact => switch (screenSize) {
        ScreenSize.xs => 3,
        ScreenSize.sm => 4,
        ScreenSize.md => 5,
        _ => 6,
      },
      CardVariant.selectable => switch (screenSize) {
        ScreenSize.xs => 1,
        _ => 2,
      },
      CardVariant.wide => 1,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API: Named Presets (자주 사용하는 조합)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 가격 카드 3열 레이아웃
  ///
  /// 가격 비교 섹션용으로 최적화된 프리셋입니다.
  /// 세로 카드를 3열로 배치하며, 가격 선택이 용이한 간격으로 조정됩니다.
  ///
  /// | Breakpoint | 열 수 |
  /// |------------|-------|
  /// | XS (<450)  | 1열   |
  /// | SM (450-768) | 2열 |
  /// | MD+ (≥768) | 3열   |
  static GridLayoutConfig pricingCards(double width) =>
      forCardType(CardVariant.vertical, GridPresetColumns.three, width: width);

  /// 고객 추천사 2열 레이아웃
  ///
  /// 가로 카드를 2열로 배치합니다.
  /// 이미지와 텍스트가 나란히 배치되는 레이아웃에 최적화되어 있습니다.
  ///
  /// | Breakpoint | 열 수 |
  /// |------------|-------|
  /// | XS (<450)  | 1열   |
  /// | SM+ (≥450) | 2열   |
  static GridLayoutConfig customerTestimonials(double width) =>
      forCardType(CardVariant.horizontal, GridPresetColumns.two, width: width);

  /// 기능 하이라이트 4열 레이아웃
  ///
  /// 콤팩트 카드를 4열로 배치합니다.
  /// 아이콘 기반 기능 그리드에 최적화되어 있습니다.
  ///
  /// | Breakpoint | 열 수 |
  /// |------------|-------|
  /// | XS (<450)  | 2열   |
  /// | SM (450-768) | 2열 |
  /// | MD (768-1024) | 3열 |
  /// | LG+ (≥1024) | 4열  |
  static GridLayoutConfig featureHighlights(double width) =>
      forCardType(CardVariant.compact, GridPresetColumns.four, width: width);

  /// 태그/배지 그리드 6열 레이아웃
  ///
  /// 콤팩트 카드를 6열로 배치합니다.
  /// 태그, 배지, 필터 등 작은 아이템의 밀도 높은 그리드에 최적화되어 있습니다.
  ///
  /// | Breakpoint | 열 수 |
  /// |------------|-------|
  /// | XS (<450)  | 3열   |
  /// | SM (450-768) | 4열 |
  /// | MD (768-1024) | 5열 |
  /// | LG+ (≥1024) | 6열  |
  static GridLayoutConfig tagGrid(double width) =>
      forCardType(CardVariant.compact, GridPresetColumns.six, width: width);

  /// 고객 카드 4열 레이아웃
  ///
  /// 세로 카드를 4열로 배치합니다.
  /// 고객 로고, 팀 멤버 등 4개 항목 그리드에 최적화되어 있습니다.
  ///
  /// | Breakpoint | 열 수 |
  /// |------------|-------|
  /// | XS (<450)  | 2열   |
  /// | SM (450-768) | 2열 |
  /// | MD (768-1024) | 3열 |
  /// | LG+ (≥1024) | 4열  |
  static GridLayoutConfig customerCards(double width) =>
      forCardType(CardVariant.vertical, GridPresetColumns.four, width: width);

  // ═══════════════════════════════════════════════════════════════════════════
  // Debug Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// 현재 화면에서의 그리드 레이아웃 정보를 문자열로 반환 (디버깅용)
  static String debugInfo(
    CardVariant cardType,
    GridPresetColumns columns,
    double width,
  ) {
    final config = forCardType(cardType, columns, width: width);
    final screenSize = ResponsiveTokens.getScreenSize(width);
    final gap = ResponsiveTokens.cardGap(width);
    final padding = ResponsiveTokens.pagePadding(width);
    final availableWidth = width - (padding * 2);

    return '''
GridLayout Debug:
  Screen: ${width.toStringAsFixed(0)}px (${screenSize.name.toUpperCase()})
  Padding: ${padding}px × 2 = ${padding * 2}px
  Available: ${availableWidth.toStringAsFixed(0)}px
  Gap: ${gap}px
  Columns: ${config.maxColumns}
  Card Width: ${config.preferredItemWidth.toStringAsFixed(0)}px (min: ${config.minItemWidth}, max: ${config.maxItemWidth})
''';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Private Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  static ResponsiveValue<double>? _getAspectRatioForCard(CardVariant cardType) {
    return switch (cardType) {
      CardVariant.vertical => const ResponsiveValue<double>(xs: 3 / 4),
      CardVariant.horizontal => const ResponsiveValue<double>(xs: 4 / 3),
      CardVariant.compact => null, // 자동 높이
      CardVariant.selectable => const ResponsiveValue<double>(
        xs: 3 / 1,
        md: 4 / 1,
        lg: 5 / 1,
      ),
      CardVariant.wide => null, // 고정 높이는 카드 자체에서 관리
    };
  }

  static bool _shouldEnforceAspectRatio(CardVariant cardType) {
    return switch (cardType) {
      CardVariant.compact => false,
      CardVariant.wide => false,
      _ => true,
    };
  }
}
