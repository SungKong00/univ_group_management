import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/card_colors.dart';
import '../theme/enums.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';

/// App 스타일 카드 (Border + Shadow + Hover 효과)
///
/// **반응형**:
/// - Mobile: 12px padding, 8px border radius
/// - Tablet: 16px padding, 12px border radius
/// - Desktop: 20px padding, 12px border radius
///
/// **Shadow 시스템**:
/// - none: 그림자 없음 (기본값)
/// - low: 0px 2px 4px rgba(255,255,255,0.05) (미묘한 그림자)
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool hasBorder;
  final Color? backgroundColor;
  final AppCardElevation elevation;
  final double? disabledOpacity;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.hasBorder = true,
    this.backgroundColor,
    this.elevation = AppCardElevation.none, // 기본값: 그림자 없음
    this.disabledOpacity,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration:
          AnimationTokens.durationSmooth, // Linear speed_regular_transition
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationTokens.curveDefault, // Linear ease_out_cubic
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<BoxShadow> _getShadow(bool isHovered) {
    if (widget.disabledOpacity != null) {
      // 비활성화 상태: opacity 적용된 그림자
      return _getBaseShadow().map((shadow) {
        return BoxShadow(
          color: shadow.color.withValues(
            alpha: shadow.color.a * widget.disabledOpacity!,
          ),
          blurRadius: shadow.blurRadius,
          offset: shadow.offset,
        );
      }).toList();
    }

    // 활성화 상태: hover 시 다음 단계 shadow로 전환
    if (isHovered && widget.onTap != null) {
      return _getHoverShadow();
    }

    return _getBaseShadow();
  }

  List<BoxShadow> _getBaseShadow() {
    return switch (widget.elevation) {
      AppCardElevation.none => const [
        BoxShadow(
          color: Colors.transparent,
          blurRadius: 0,
          offset: Offset(0, 0),
        ),
      ],
      // overlayLight: rgba(255,255,255,0.05) 사용
      AppCardElevation.low => const [
        BoxShadow(
          color: Color(0x0DFFFFFF), // overlayLight
          blurRadius: 4.0,
          spreadRadius: 0.0,
          offset: Offset(0, 2),
        ),
      ],
    };
  }

  List<BoxShadow> _getHoverShadow() {
    // hover 시 약간 더 진한 shadow 사용
    return switch (widget.elevation) {
      // overlayLight 사용
      AppCardElevation.none => const [
        BoxShadow(
          color: Color(0x0DFFFFFF), // overlayLight
          blurRadius: 4.0,
          spreadRadius: 0.0,
          offset: Offset(0, 2),
        ),
      ],
      // overlayMedium: rgba(255,255,255,0.08) 사용
      AppCardElevation.low => const [
        BoxShadow(
          color: Color(0x14FFFFFF), // overlayMedium
          blurRadius: 24.0,
          spreadRadius: 0.0,
          offset: Offset(0, 4),
        ),
      ],
    };
  }

  void _onEnter() {
    if (widget.onTap != null && widget.disabledOpacity == null) {
      setState(() => _isHovered = true);
      _controller.forward();
    }
  }

  void _onExit() {
    if (widget.disabledOpacity == null) {
      setState(() => _isHovered = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final cardColors = CardColors.standard(colorExt);

    final width = MediaQuery.sizeOf(context).width;
    final bgColor = widget.backgroundColor ?? cardColors.background;
    final opacity = widget.disabledOpacity ?? 1.0;
    final effectiveColor = bgColor.withValues(alpha: bgColor.a * opacity);
    final borderRadius = ResponsiveTokens.componentBorderRadius(width);
    final defaultPadding = EdgeInsets.all(ResponsiveTokens.cardPadding(width));

    final card = MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: AnimationTokens.durationSmooth,
              curve: AnimationTokens.curveDefault,
              padding: widget.padding ?? defaultPadding,
              decoration: BoxDecoration(
                color: effectiveColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: widget.hasBorder
                    ? Border.all(
                        color: cardColors.border.withValues(alpha: opacity),
                        width: BorderTokens.widthThin,
                      )
                    : null,
                boxShadow: _getShadow(_isHovered),
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(onTap: widget.onTap, child: card);
    }

    return card;
  }
}
