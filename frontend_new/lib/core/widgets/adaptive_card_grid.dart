import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/responsive_tokens.dart';
import '../theme/grid_layout_tokens.dart';
import 'responsive_builder.dart';

/// Adaptive card grid/wrap for reusable v2 components.
///
/// 특징:
/// - min/max 카드 폭을 클램프하며 열 수를 자동 계산
/// - 여백이 남을 때 가운데 정렬, 필요 시 가로 스크롤 옵션 제공
/// - grid / wrap / list 모드 지원 (높이 제각각 카드도 대응)
/// - breakpoint별 비율/간격을 design token으로 일관 관리
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
  ///
  /// 실제 렌더링 폭은 min/max 클램프를 적용하며, 열 수를 결정할 때만
  /// 이 값이 사용됩니다. (예: 1024px에서 3열을 강제하려면 320 등)
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

  /// 그리드 레이아웃 프리셋으로부터 생성합니다.
  ///
  /// [GridLayoutConfig]를 사용하여 그리드 파라미터를 자동으로 설정합니다.
  /// 이를 통해 반복적인 픽셀 계산을 제거하고 일관된 레이아웃을 보장합니다.
  ///
  /// 사용 예시:
  /// ```dart
  /// // Named preset 사용
  /// AdaptiveCardGrid.fromPreset(
  ///   config: GridLayoutTokens.pricingCards,
  ///   itemCount: pricingPlans.length,
  ///   itemBuilder: (context, index) => PricingCard(pricingPlans[index]),
  ///   maxContentWidth: ResponsiveTokens.maxContentWidth,
  /// );
  ///
  /// // 커스텀 프리셋
  /// final config = GridLayoutTokens.forCardType(
  ///   CardVariant.vertical,
  ///   columns: GridPresetColumns.three,
  /// );
  /// AdaptiveCardGrid.fromPreset(
  ///   config: config,
  ///   itemCount: items.length,
  ///   itemBuilder: (context, index) => MyCard(items[index]),
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
    // Optional overrides for preset configuration
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
    final targetWidth = preferredItemWidth ?? maxItemWidth;
    final isList = mode == AdaptiveLayoutMode.list;
    int columns = isList
        ? 1
        : math.max(1, ((availableWidth + gap) / (targetWidth + gap)).floor());

    if (maxColumns != null) {
      columns = math.min(columns, maxColumns!);
    }

    double itemWidth = _itemWidthFor(columns, availableWidth, gap);

    while (itemWidth < minItemWidth && columns > 1) {
      columns -= 1;
      itemWidth = _itemWidthFor(columns, availableWidth, gap);
    }

    itemWidth = itemWidth.clamp(
      mode == AdaptiveLayoutMode.list ? 0 : minItemWidth,
      maxItemWidth,
    );

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

enum AdaptiveLayoutMode { grid, wrap, list }

class _Layout {
  final int columns;
  final double itemWidth;

  _Layout({required this.columns, required this.itemWidth});
}
