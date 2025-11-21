import 'package:flutter/material.dart';
import 'responsive_tokens.dart';
import 'card_design_tokens.dart';
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
}

/// 그리드 레이아웃 프리셋 토큰 시스템
///
/// 카드 타입과 열 수 조합에 따라 최적화된 그리드 설정을 제공합니다.
/// [CardDesignTokens]의 카드별 너비 제약과 [ResponsiveTokens]의 간격 규칙을
/// 통합하여 단일 진실 공급원을 보장합니다.
///
/// 사용 예시:
/// ```dart
/// // 방법 1: Named preset 사용
/// AdaptiveCardGrid.fromPreset(
///   config: GridLayoutTokens.pricingCards,
///   itemCount: plans.length,
///   itemBuilder: (context, index) => PricingCard(plans[index]),
/// );
///
/// // 방법 2: 커스텀 프리셋
/// final config = GridLayoutTokens.forCardType(
///   CardVariant.vertical,
///   columns: GridPresetColumns.three,
/// );
/// AdaptiveCardGrid.fromPreset(config: config, ...);
/// ```
class GridLayoutTokens {
  GridLayoutTokens._();

  // ═══════════════════════════════════════════════════════════════════════════
  // 열 수별 선호 너비 (1440px 기반 계산)
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // 계산식: (1440px - gaps) / columns
  // - 1열: Full width (무한대)
  // - 2열: 640px (1440px - 16px gap) / 2 = 712px → 640으로 조정
  // - 3열: 480px (1440px - 32px gap) / 3 = 469px → 480으로 조정
  // - 4열: 360px (1440px - 48px gap) / 4 = 348px → 360으로 조정
  // - 5열: 280px (1440px - 64px gap) / 5 = 275px → 280으로 조정
  // - 6열: 224px (1440px - 80px gap) / 6 = 227px → 224로 조정

  static const Map<GridPresetColumns, double> _preferredWidths = {
    GridPresetColumns.one: double.infinity,
    GridPresetColumns.two: 640,
    GridPresetColumns.three: 480,
    GridPresetColumns.four: 360,
    GridPresetColumns.five: 280,
    GridPresetColumns.six: 224,
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API: 범용 프리셋
  // ═══════════════════════════════════════════════════════════════════════════

  /// 카드 타입과 열 수에 따른 최적화된 그리드 설정을 반환합니다.
  ///
  /// [CardDesignTokens.cardWidths]에서 카드 타입별 min/max 너비를 가져오고,
  /// 열 수 프리셋과 결합하여 완전한 그리드 설정을 생성합니다.
  ///
  /// 예시:
  /// ```dart
  /// // 세로 카드 3열
  /// final config = GridLayoutTokens.forCardType(
  ///   CardVariant.vertical,
  ///   columns: GridPresetColumns.three,
  /// );
  ///
  /// // 가로 카드 2열
  /// final config = GridLayoutTokens.forCardType(
  ///   CardVariant.horizontal,
  ///   columns: GridPresetColumns.two,
  /// );
  /// ```
  static GridLayoutConfig forCardType(
    CardVariant cardType,
    GridPresetColumns columns,
  ) {
    final cardWidths = CardDesignTokens.cardWidths[_cardTypeToKey(cardType)]!;
    final aspectRatio = _getAspectRatioForCard(cardType);
    final enforceAspectRatio = _shouldEnforceAspectRatio(cardType);

    return GridLayoutConfig(
      minItemWidth: cardWidths['min']!,
      maxItemWidth: cardWidths['max']!,
      maxColumns: columns.index + 1, // enum index: 0=one → 1 column
      preferredItemWidth: _preferredWidths[columns]!,
      aspectRatio: aspectRatio,
      enforceAspectRatio: enforceAspectRatio,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API: Named Presets (자주 사용하는 조합)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 가격 카드 3열 레이아웃
  ///
  /// 가격 비교 섹션용으로 최적화된 프리셋입니다.
  /// 세로 카드를 3열로 배치하며, 가격 선택이 용이한 간격으로 조정됩니다.
  ///
  /// 사용 예시 (showcase):
  /// ```dart
  /// // Pricing 섹션 (3개 가격 플랜)
  /// AdaptiveCardGrid.fromPreset(
  ///   config: GridLayoutTokens.pricingCards,
  ///   itemCount: pricingPlans.length,
  ///   itemBuilder: (context, index) => PricingCard(plan: pricingPlans[index]),
  ///   maxContentWidth: ResponsiveTokens.maxContentWidth,
  /// );
  /// ```
  static GridLayoutConfig get pricingCards =>
      forCardType(CardVariant.vertical, GridPresetColumns.three);

  /// 고객 추천사 2열 레이아웃
  ///
  /// 가로 카드를 2열로 배치합니다.
  /// 이미지와 텍스트가 나란히 배치되는 레이아웃에 최적화되어 있습니다.
  ///
  /// 사용 예시 (showcase):
  /// ```dart
  /// // Horizontal Cards 섹션 (추천사 또는 증언)
  /// AdaptiveCardGrid.fromPreset(
  ///   config: GridLayoutTokens.customerTestimonials,
  ///   itemCount: testimonials.length,
  ///   itemBuilder: (context, index) => HorizontalCard(...),
  ///   maxContentWidth: ResponsiveTokens.maxContentWidth,
  /// );
  /// ```
  static GridLayoutConfig get customerTestimonials =>
      forCardType(CardVariant.horizontal, GridPresetColumns.two);

  /// 기능 하이라이트 4열 레이아웃
  ///
  /// 콤팩트 카드를 4열로 배치합니다.
  /// 아이콘 기반 기능 그리드에 최적화되어 있습니다.
  ///
  /// 사용 예시 (showcase):
  /// ```dart
  /// // Compact Cards 섹션 - 기능 목록
  /// AdaptiveCardGrid.fromPreset(
  ///   config: GridLayoutTokens.featureHighlights,
  ///   itemCount: features.length,
  ///   itemBuilder: (context, index) => CompactCard(...),
  ///   maxContentWidth: ResponsiveTokens.maxContentWidth,
  /// );
  /// ```
  static GridLayoutConfig get featureHighlights =>
      forCardType(CardVariant.compact, GridPresetColumns.four);

  /// 태그/배지 그리드 6열 레이아웃
  ///
  /// 콤팩트 카드를 6열로 배치합니다.
  /// 태그, 배지, 필터 등 작은 아이템의 밀도 높은 그리드에 최적화되어 있습니다.
  /// aspectRatio 강제가 비활성화되어 자동 높이를 지원합니다.
  ///
  /// 사용 예시 (showcase):
  /// ```dart
  /// // Compact Cards 섹션 - 6개 항목 그리드
  /// AdaptiveCardGrid.fromPreset(
  ///   config: GridLayoutTokens.tagGrid,
  ///   itemCount: 6,
  ///   itemBuilder: (context, index) => CompactCard(...),
  ///   maxContentWidth: ResponsiveTokens.maxContentWidth,
  /// );
  /// ```
  static GridLayoutConfig get tagGrid =>
      forCardType(CardVariant.compact, GridPresetColumns.six);

  /// 고객 카드 4열 레이아웃
  ///
  /// 세로 카드를 4열로 배치합니다.
  /// 고객 로고, 팀 멤버 등 4개 항목 그리드에 최적화되어 있습니다.
  ///
  /// 사용 예시 (showcase):
  /// ```dart
  /// // Customer Cards 섹션 (4개 고객)
  /// AdaptiveCardGrid.fromPreset(
  ///   config: GridLayoutTokens.customerCards,
  ///   itemCount: customers.length,
  ///   itemBuilder: (context, index) => CustomerCard(customers[index]),
  ///   maxContentWidth: ResponsiveTokens.maxContentWidth,
  /// );
  /// ```
  static GridLayoutConfig get customerCards =>
      forCardType(CardVariant.vertical, GridPresetColumns.four);

  // ═══════════════════════════════════════════════════════════════════════════
  // Private Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  static String _cardTypeToKey(CardVariant cardType) {
    return switch (cardType) {
      CardVariant.vertical => 'vertical',
      CardVariant.horizontal => 'horizontal',
      CardVariant.compact => 'compact',
      CardVariant.selectable => 'selectable',
      CardVariant.wide => 'wide',
    };
  }

  static ResponsiveValue<double>? _getAspectRatioForCard(CardVariant cardType) {
    return switch (cardType) {
      CardVariant.vertical => const ResponsiveValue<double>(
        mobile: 3 / 4,
        tablet: 3 / 4,
        desktop: 3 / 4,
      ),
      CardVariant.horizontal => const ResponsiveValue<double>(
        mobile: 4 / 3,
        tablet: 4 / 3,
        desktop: 4 / 3,
      ),
      CardVariant.compact => null, // 자동 높이
      CardVariant.selectable => const ResponsiveValue<double>(
        mobile: 3 / 1,
        tablet: 4 / 1,
        desktop: 5 / 1,
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
