import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/responsive_tokens.dart';
import '../theme/grid_layout_tokens.dart';
import '../theme/enums.dart';
import 'responsive_builder.dart';

/// Adaptive Card Grid - 반응형 카드 그리드 레이아웃
///
/// 화면 너비에 따라 자동으로 열 수와 카드 크기를 조정하는 그리드 컴포넌트입니다.
/// Material Design 3의 5단계 반응형 시스템(XS/SM/MD/LG/XL)을 따릅니다.
///
/// ## 특징
/// - 화면 크기에 따라 열 수 자동 조정
/// - min/max 카드 폭을 클램프하며 레이아웃 계산
/// - 여백이 남을 때 가운데 정렬
/// - grid / wrap / list 모드 지원
///
/// ## 사용법
///
/// ### 방법 1: fromCardType (권장)
/// ```dart
/// AdaptiveCardGrid.fromCardType(
///   cardType: CardVariant.vertical,
///   columns: GridPresetColumns.three,
///   itemCount: items.length,
///   itemBuilder: (context, index) => VerticalCard(...),
/// )
/// ```
///
/// ### 방법 2: fromPreset (Named preset)
/// ```dart
/// final width = MediaQuery.sizeOf(context).width;
/// AdaptiveCardGrid.fromPreset(
///   config: GridLayoutTokens.pricingCards(width),
///   itemCount: items.length,
///   itemBuilder: (context, index) => PricingCard(...),
/// )
/// ```
///
/// ## Breakpoint별 열 수 조정 예시 (3열 vertical 카드)
///
/// | Breakpoint | 화면너비 | 열 수 |
/// |------------|---------|-------|
/// | XS (<450)  | ~400px  | 1열   |
/// | SM (450-768) | ~600px | 2열  |
/// | MD (768-1024) | ~900px | 3열 |
/// | LG (1024-1440) | ~1200px | 3열 |
/// | XL (≥1440) | ~1440px | 3열   |
class AdaptiveCardGrid extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// 최소/최대 카드 폭
  final double minItemWidth;
  final double maxItemWidth;

  /// 열 개수 상한 (null이면 가용 폭 기준)
  final int? maxColumns;

  /// spacing이 null이면 ResponsiveTokens.cardGap 사용
  final double? spacing;

  /// breakpoint별 카드 비율
  final ResponsiveValue<double>? aspectRatio;

  /// grid / wrap / list
  final AdaptiveLayoutMode mode;

  /// 너무 좁은 화면에서 minWidth를 지키기 위해 가로 스크롤 허용
  final bool scrollOnOverflow;

  /// 카드에 AspectRatio를 강제할지 (wrap 모드에서도 동일하게 적용)
  final bool enforceAspectRatio;

  /// 외부 패딩 (섹션 padding 제어)
  final EdgeInsetsGeometry? padding;

  /// 열 계산 시 선호하는 아이템 폭 (null이면 maxItemWidth 사용)
  final double? preferredItemWidth;

  /// 레이아웃 최대 폭 제한 (null이면 부모 제약 사용)
  final double? maxContentWidth;

  /// Align alignment (기본: 가운데)
  final AlignmentGeometry alignment;

  const AdaptiveCardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minItemWidth = 260,
    this.maxItemWidth = 380,
    this.maxColumns,
    this.spacing,
    this.aspectRatio,
    this.mode = AdaptiveLayoutMode.grid,
    this.scrollOnOverflow = true,
    this.enforceAspectRatio = true,
    this.padding,
    this.preferredItemWidth,
    this.maxContentWidth,
    this.alignment = Alignment.center,
  });

  /// 그리드 레이아웃 프리셋으로부터 생성합니다
  ///
  /// [GridLayoutConfig]를 사용하여 그리드 파라미터를 자동으로 설정합니다.
  ///
  /// 사용 예시:
  /// ```dart
  /// final width = MediaQuery.sizeOf(context).width;
  /// AdaptiveCardGrid.fromPreset(
  ///   config: GridLayoutTokens.pricingCards(width),
  ///   itemCount: pricingPlans.length,
  ///   itemBuilder: (context, index) => PricingCard(pricingPlans[index]),
  /// );
  /// ```
  factory AdaptiveCardGrid.fromPreset({
    Key? key,
    required GridLayoutConfig config,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    AdaptiveLayoutMode mode = AdaptiveLayoutMode.grid,
    bool scrollOnOverflow = true,
    EdgeInsetsGeometry? padding,
    double? maxContentWidth,
    AlignmentGeometry alignment = Alignment.center,
    ResponsiveValue<double>? aspectRatioOverride,
    bool? enforceAspectRatioOverride,
  }) {
    return AdaptiveCardGrid(
      key: key,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      minItemWidth: config.minItemWidth,
      maxItemWidth: config.maxItemWidth,
      maxColumns: config.maxColumns,
      preferredItemWidth: config.preferredItemWidth,
      spacing: null, // ResponsiveTokens.cardGap 자동 사용
      aspectRatio: aspectRatioOverride ?? config.aspectRatio,
      enforceAspectRatio:
          enforceAspectRatioOverride ?? config.enforceAspectRatio,
      mode: mode,
      scrollOnOverflow: scrollOnOverflow,
      padding: padding,
      maxContentWidth: maxContentWidth,
      alignment: alignment,
    );
  }

  /// 카드 타입과 컬럼 수로부터 반응형 그리드를 생성합니다 (권장)
  ///
  /// 이 factory는 현재 화면 너비에 따라 GridLayoutTokens를 동적으로 계산합니다.
  /// 5단계 반응형 시스템을 완벽하게 지원합니다.
  ///
  /// 사용 예시:
  /// ```dart
  /// // 반응형 카드 크기로 3열 그리드
  /// AdaptiveCardGrid.fromCardType(
  ///   cardType: CardVariant.vertical,
  ///   columns: GridPresetColumns.three,
  ///   itemCount: pricingPlans.length,
  ///   itemBuilder: (context, index) => PricingCard(pricingPlans[index]),
  /// );
  /// ```
  ///
  /// ## Breakpoint별 열 수 조정
  ///
  /// | 프리셋 | XS | SM | MD | LG | XL |
  /// |--------|----|----|----|----|-----|
  /// | one    | 1  | 1  | 1  | 1  | 1   |
  /// | two    | 1  | 2  | 2  | 2  | 2   |
  /// | three  | 1  | 2  | 3  | 3  | 3   |
  /// | four   | 2  | 2  | 3  | 4  | 4   |
  /// | five   | 2  | 3  | 4  | 5  | 5   |
  /// | six    | 3  | 4  | 5  | 6  | 6   |
  factory AdaptiveCardGrid.fromCardType({
    Key? key,
    required CardVariant cardType,
    required GridPresetColumns columns,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    AdaptiveLayoutMode mode = AdaptiveLayoutMode.grid,
    bool scrollOnOverflow = true,
    EdgeInsetsGeometry? padding,
    double? maxContentWidth,
    AlignmentGeometry alignment = Alignment.center,
    ResponsiveValue<double>? aspectRatioOverride,
    bool? enforceAspectRatioOverride,
  }) {
    return _AdaptiveCardGridWithCardType(
      key: key,
      cardType: cardType,
      columns: columns,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      mode: mode,
      scrollOnOverflow: scrollOnOverflow,
      padding: padding,
      maxContentWidth: maxContentWidth,
      alignment: alignment,
      aspectRatioOverride: aspectRatioOverride,
      enforceAspectRatioOverride: enforceAspectRatioOverride,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final gap = spacing ?? ResponsiveTokens.cardGap(screenWidth);
    final aspect = aspectRatio?.getValueFromWidth(screenWidth) ?? 0.8;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final useHorizontalScroll =
            scrollOnOverflow && availableWidth < minItemWidth;

        final boundedWidth = _applyMaxWidth(
          useHorizontalScroll ? minItemWidth : availableWidth,
        );

        final layout = _resolveLayout(boundedWidth, gap);
        final gridWidth =
            layout.columns * layout.itemWidth +
            math.max(0, layout.columns - 1) * gap;

        final content = switch (mode) {
          AdaptiveLayoutMode.grid || AdaptiveLayoutMode.list => _buildGrid(
            context,
            gap,
            aspect,
            layout.columns,
            layout.itemWidth,
          ),
          AdaptiveLayoutMode.wrap => _buildWrap(
            context,
            gap,
            aspect,
            layout.itemWidth,
          ),
        };

        final aligned = Align(
          alignment: alignment,
          child: SizedBox(width: gridWidth, child: content),
        );

        final padded = Padding(
          padding: padding ?? EdgeInsets.zero,
          child: aligned,
        );

        if (useHorizontalScroll) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: padded,
          );
        }

        return padded;
      },
    );
  }

  _Layout _resolveLayout(double availableWidth, double gap) {
    final isList = mode == AdaptiveLayoutMode.list;

    // List 모드는 항상 1열, 전체 너비 사용
    if (isList) {
      return _Layout(columns: 1, itemWidth: availableWidth);
    }

    // maxColumns가 설정되어 있으면 **강제 적용** (프리셋 기반)
    // 카드 크기는 가용 너비에서 동적으로 계산
    if (maxColumns != null) {
      final columns = maxColumns!;
      // 카드 너비 = (가용너비 - 간격합) / 열수
      final itemWidth = _itemWidthFor(columns, availableWidth, gap);
      // 카드가 너무 넓어지지 않도록만 제한 (minItemWidth 무시 - 열 수 우선)
      return _Layout(
        columns: columns,
        itemWidth: math.min(itemWidth, maxItemWidth),
      );
    }

    // maxColumns 미설정: 기존 자동 계산 로직
    final targetWidth = preferredItemWidth ?? maxItemWidth;
    int columns = math.max(
      1,
      ((availableWidth + gap) / (targetWidth + gap)).floor(),
    );

    // 카드 너비 계산
    double itemWidth = _itemWidthFor(columns, availableWidth, gap);

    // minItemWidth를 만족하지 못하면 열 수 줄이기
    while (itemWidth < minItemWidth && columns > 1) {
      columns -= 1;
      itemWidth = _itemWidthFor(columns, availableWidth, gap);
    }

    // 최종 클램프
    itemWidth = itemWidth.clamp(minItemWidth, maxItemWidth);

    return _Layout(columns: columns, itemWidth: itemWidth);
  }

  double _itemWidthFor(int columns, double availableWidth, double gap) {
    if (columns <= 1) return availableWidth;
    return (availableWidth - gap * (columns - 1)) / columns;
  }

  double _applyMaxWidth(double width) {
    if (maxContentWidth == null) return width;
    return math.min(width, maxContentWidth!);
  }

  Widget _buildGrid(
    BuildContext context,
    double gap,
    double aspect,
    int columns,
    double itemWidth,
  ) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
        childAspectRatio: aspect,
      ),
      itemBuilder: (context, index) {
        return _buildChild(context, index, itemWidth, aspect);
      },
    );
  }

  Widget _buildWrap(
    BuildContext context,
    double gap,
    double aspect,
    double itemWidth,
  ) {
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: List.generate(
        itemCount,
        (index) => _buildChild(context, index, itemWidth, aspect),
      ),
    );
  }

  Widget _buildChild(
    BuildContext context,
    int index,
    double itemWidth,
    double aspect,
  ) {
    final child = itemBuilder(context, index);
    if (!enforceAspectRatio) {
      return SizedBox(width: itemWidth, child: child);
    }
    return SizedBox(
      width: itemWidth,
      child: AspectRatio(aspectRatio: aspect, child: child),
    );
  }
}

/// 레이아웃 모드
enum AdaptiveLayoutMode {
  /// GridView 기반 (동일 높이)
  grid,

  /// Wrap 기반 (가변 높이)
  wrap,

  /// 단일 열 리스트
  list,
}

class _Layout {
  final int columns;
  final double itemWidth;

  _Layout({required this.columns, required this.itemWidth});
}

// ════════════════════════════════════════════════════════════════════════════
// Helper: AdaptiveCardGrid with responsive CardType
// ════════════════════════════════════════════════════════════════════════════

/// 반응형 카드 타입 기반 적응형 그리드
///
/// fromCardType() factory에서 사용되는 helper 클래스입니다.
/// build() 시점에 현재 화면 너비에 따라 GridLayoutTokens를 동적으로 계산합니다.
class _AdaptiveCardGridWithCardType extends AdaptiveCardGrid {
  final CardVariant cardType;
  final GridPresetColumns columns;
  final ResponsiveValue<double>? aspectRatioOverride;
  final bool? enforceAspectRatioOverride;

  const _AdaptiveCardGridWithCardType({
    super.key,
    required this.cardType,
    required this.columns,
    required super.itemCount,
    required super.itemBuilder,
    super.mode = AdaptiveLayoutMode.grid,
    super.scrollOnOverflow = true,
    super.padding,
    super.maxContentWidth,
    super.alignment = Alignment.center,
    this.aspectRatioOverride,
    this.enforceAspectRatioOverride,
  }) : super(
         minItemWidth: 100, // 임시값 (build에서 계산)
         maxItemWidth: 500, // 임시값 (build에서 계산)
         maxColumns: null,
         spacing: null,
         aspectRatio: null,
         enforceAspectRatio: true,
         preferredItemWidth: null,
       );

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;

    // 현재 화면 너비에 따라 GridLayoutConfig 동적 계산
    final config = GridLayoutTokens.forCardType(
      cardType,
      columns,
      width: width,
    );

    // 계산된 config로 새 AdaptiveCardGrid 생성 후 build
    final grid = AdaptiveCardGrid(
      key: key,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      minItemWidth: config.minItemWidth,
      maxItemWidth: config.maxItemWidth,
      maxColumns: config.maxColumns,
      spacing: spacing,
      aspectRatio: aspectRatioOverride ?? config.aspectRatio,
      mode: mode,
      scrollOnOverflow: scrollOnOverflow,
      enforceAspectRatio:
          enforceAspectRatioOverride ?? config.enforceAspectRatio,
      padding: padding,
      preferredItemWidth: config.preferredItemWidth,
      maxContentWidth: maxContentWidth,
      alignment: alignment,
    );

    return grid.build(context);
  }
}
