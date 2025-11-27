import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/skeleton_colors.dart';
import '../theme/enums.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';
import '../theme/responsive_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppSkeletonType;

/// 로딩 중 플레이스홀더를 표시하는 Skeleton 컴포넌트
///
/// **용도**: 데이터 로딩 중 UI 골격 표시
/// **접근성**: 스크린 리더에 로딩 상태 알림
///
/// ```dart
/// // 텍스트 스켈레톤
/// AppSkeleton(
///   type: AppSkeletonType.text,
///   width: 200,
///   height: 16,
/// )
///
/// // 원형 스켈레톤 (아바타)
/// AppSkeleton(
///   type: AppSkeletonType.circle,
///   width: 48,
///   height: 48,
/// )
///
/// // 사각형 스켈레톤 (이미지)
/// AppSkeleton(
///   type: AppSkeletonType.rectangle,
///   width: double.infinity,
///   height: 200,
/// )
/// ```
class AppSkeleton extends StatefulWidget {
  /// 스켈레톤 타입
  final AppSkeletonType type;

  /// 너비 (null일 경우 부모에 맞춤)
  final double? width;

  /// 높이
  final double? height;

  /// 커스텀 테두리 반경
  final BorderRadius? borderRadius;

  /// Shimmer 효과 활성화 여부
  final bool enableShimmer;

  const AppSkeleton({
    super.key,
    this.type = AppSkeletonType.text,
    this.width,
    this.height,
    this.borderRadius,
    this.enableShimmer = true,
  });

  /// 텍스트 라인 스켈레톤 팩토리
  factory AppSkeleton.text({
    Key? key,
    double? width,
    double height = 16,
    bool enableShimmer = true,
  }) {
    return AppSkeleton(
      key: key,
      type: AppSkeletonType.text,
      width: width,
      height: height,
      enableShimmer: enableShimmer,
    );
  }

  /// 원형 스켈레톤 팩토리 (아바타용)
  factory AppSkeleton.circle({
    Key? key,
    double size = 48,
    bool enableShimmer = true,
  }) {
    return AppSkeleton(
      key: key,
      type: AppSkeletonType.circle,
      width: size,
      height: size,
      enableShimmer: enableShimmer,
    );
  }

  /// 사각형 스켈레톤 팩토리 (이미지용)
  factory AppSkeleton.rectangle({
    Key? key,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    bool enableShimmer = true,
  }) {
    return AppSkeleton(
      key: key,
      type: AppSkeletonType.rectangle,
      width: width,
      height: height,
      borderRadius: borderRadius,
      enableShimmer: enableShimmer,
    );
  }

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationTokens.curveSmooth,
      ),
    );
    if (widget.enableShimmer) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AppSkeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableShimmer != oldWidget.enableShimmer) {
      if (widget.enableShimmer) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final width = MediaQuery.sizeOf(context).width;
    final colors = SkeletonColors.standard(colorExt);

    // 타입별 테두리 반경
    final effectiveBorderRadius = widget.borderRadius ??
        switch (widget.type) {
          AppSkeletonType.text => BorderTokens.smallRadius(),
          AppSkeletonType.circle => BorderRadius.circular(1000),
          AppSkeletonType.rectangle =>
            BorderRadius.circular(ResponsiveTokens.componentBorderRadius(width)),
        };

    // 기본 높이
    final effectiveHeight = widget.height ??
        switch (widget.type) {
          AppSkeletonType.text => 16.0,
          AppSkeletonType.circle => 48.0,
          AppSkeletonType.rectangle => 100.0,
        };

    // 기본 너비
    final effectiveWidth = widget.width ??
        switch (widget.type) {
          AppSkeletonType.text => double.infinity,
          AppSkeletonType.circle => effectiveHeight,
          AppSkeletonType.rectangle => double.infinity,
        };

    return Semantics(
      label: '로딩 중',
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: effectiveWidth,
            height: effectiveHeight,
            decoration: BoxDecoration(
              borderRadius: effectiveBorderRadius,
              gradient: widget.enableShimmer
                  ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        colors.base,
                        colors.highlight,
                        colors.base,
                      ],
                      stops: [
                        (_animation.value - 1).clamp(0.0, 1.0),
                        _animation.value.clamp(0.0, 1.0),
                        (_animation.value + 1).clamp(0.0, 1.0),
                      ],
                    )
                  : null,
              color: widget.enableShimmer ? null : colors.base,
            ),
          );
        },
      ),
    );
  }
}

/// 여러 줄 텍스트 스켈레톤
///
/// ```dart
/// AppSkeletonLines(
///   lines: 3,
///   spacing: 8,
/// )
/// ```
class AppSkeletonLines extends StatelessWidget {
  /// 줄 수
  final int lines;

  /// 마지막 줄 너비 비율 (0.0 ~ 1.0)
  final double lastLineWidthRatio;

  /// Shimmer 효과 활성화
  final bool enableShimmer;

  const AppSkeletonLines({
    super.key,
    this.lines = 3,
    this.lastLineWidthRatio = 0.7,
    this.enableShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLast = index == lines - 1;
        return Padding(
          padding: EdgeInsets.only(
            bottom: isLast ? 0 : spacingExt.small,
          ),
          child: FractionallySizedBox(
            widthFactor: isLast ? lastLineWidthRatio : 1.0,
            child: AppSkeleton.text(
              enableShimmer: enableShimmer,
            ),
          ),
        );
      }),
    );
  }
}

/// 카드 스켈레톤 프리셋
///
/// ```dart
/// // 세로 카드 스켈레톤
/// AppSkeletonCard.vertical()
///
/// // 가로 카드 스켈레톤
/// AppSkeletonCard.horizontal()
///
/// // 컴팩트 카드 스켈레톤
/// AppSkeletonCard.compact()
/// ```
class AppSkeletonCard extends StatelessWidget {
  /// 카드 타입
  final CardVariant variant;

  /// Shimmer 효과 활성화
  final bool enableShimmer;

  const AppSkeletonCard({
    super.key,
    this.variant = CardVariant.vertical,
    this.enableShimmer = true,
  });

  /// 세로 카드 스켈레톤
  factory AppSkeletonCard.vertical({
    Key? key,
    bool enableShimmer = true,
  }) {
    return AppSkeletonCard(
      key: key,
      variant: CardVariant.vertical,
      enableShimmer: enableShimmer,
    );
  }

  /// 가로 카드 스켈레톤
  factory AppSkeletonCard.horizontal({
    Key? key,
    bool enableShimmer = true,
  }) {
    return AppSkeletonCard(
      key: key,
      variant: CardVariant.horizontal,
      enableShimmer: enableShimmer,
    );
  }

  /// 컴팩트 카드 스켈레톤
  factory AppSkeletonCard.compact({
    Key? key,
    bool enableShimmer = true,
  }) {
    return AppSkeletonCard(
      key: key,
      variant: CardVariant.compact,
      enableShimmer: enableShimmer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      decoration: BoxDecoration(
        color: colorExt.surfaceSecondary,
        borderRadius: BorderRadius.circular(ResponsiveTokens.componentBorderRadius(screenWidth)),
        border: Border.all(
          color: colorExt.borderPrimary,
          width: BorderTokens.widthThin,
        ),
      ),
      child: switch (variant) {
        CardVariant.vertical => _buildVertical(spacingExt),
        CardVariant.horizontal => _buildHorizontal(spacingExt),
        CardVariant.compact => _buildCompact(spacingExt),
        CardVariant.selectable => _buildVertical(spacingExt),
        CardVariant.wide => _buildHorizontal(spacingExt),
      },
    );
  }

  Widget _buildVertical(AppSpacingExtension spacingExt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이미지 영역
        AppSkeleton.rectangle(
          height: 160,
          borderRadius: BorderRadius.only(
            topLeft: BorderTokens.mediumRadius().topLeft,
            topRight: BorderTokens.mediumRadius().topRight,
          ),
          enableShimmer: enableShimmer,
        ),
        // 텍스트 영역
        Padding(
          padding: EdgeInsets.all(spacingExt.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton.text(
                width: 120,
                height: 20,
                enableShimmer: enableShimmer,
              ),
              SizedBox(height: spacingExt.small),
              AppSkeletonLines(
                lines: 2,
                enableShimmer: enableShimmer,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontal(AppSpacingExtension spacingExt) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이미지 영역
        AppSkeleton.rectangle(
          width: 120,
          height: 120,
          borderRadius: BorderRadius.only(
            topLeft: BorderTokens.mediumRadius().topLeft,
            bottomLeft: BorderTokens.mediumRadius().bottomLeft,
          ),
          enableShimmer: enableShimmer,
        ),
        // 텍스트 영역
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(spacingExt.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton.text(
                  width: 100,
                  height: 20,
                  enableShimmer: enableShimmer,
                ),
                SizedBox(height: spacingExt.small),
                AppSkeletonLines(
                  lines: 2,
                  enableShimmer: enableShimmer,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompact(AppSpacingExtension spacingExt) {
    return Padding(
      padding: EdgeInsets.all(spacingExt.medium),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSkeleton.circle(
            size: 48,
            enableShimmer: enableShimmer,
          ),
          SizedBox(height: spacingExt.small),
          AppSkeleton.text(
            width: 80,
            height: 14,
            enableShimmer: enableShimmer,
          ),
        ],
      ),
    );
  }
}
