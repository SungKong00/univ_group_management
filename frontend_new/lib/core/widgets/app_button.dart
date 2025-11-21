import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_typography_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/button_colors.dart';
import '../theme/enums.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';
import '../theme/component_size_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppButtonVariant, AppButtonSize;

/// App 스타일 버튼 (기본 / 보조 / 유령 변형, 색상 + 높이 피드백)
///
/// **접근성**: 최소 터치 영역 44px 보장 (iOS/Android 권장사항)
/// **반응형**: 화면 크기에 따라 패딩 자동 조정
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationTokens.durationQuick,
      vsync: this,
    );
    _elevationAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: AnimationTokens.curveSmooth),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: AnimationTokens.curveSmooth),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPressed() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final typographyExt = context.appTypography;
    final width = MediaQuery.sizeOf(context).width;
    final borderRadius = ResponsiveTokens.componentBorderRadius(width);

    // ========================================================
    // Step 1: Size 기반 패딩과 텍스트 스타일 결정 (색상 제외)
    // ========================================================
    final (paddingH, paddingV, baseTextStyle) = switch (widget.size) {
      AppButtonSize.small => (
        ResponsiveTokens.buttonSmallPaddingH(width),
        ResponsiveTokens.buttonSmallPaddingV(width),
        typographyExt.buttonSmall.copyWith(height: 1.0),
      ),
      AppButtonSize.medium => (
        ResponsiveTokens.buttonMediumPaddingH(width),
        ResponsiveTokens.buttonMediumPaddingV(width),
        typographyExt.buttonMedium.copyWith(height: 1.0),
      ),
      AppButtonSize.large => (
        ResponsiveTokens.buttonLargePaddingH(width),
        ResponsiveTokens.buttonLargePaddingV(width),
        typographyExt.buttonLarge.copyWith(height: 1.0),
      ),
    };

    final padding = EdgeInsets.symmetric(
      horizontal: paddingH,
      vertical: paddingV,
    );

    // ========================================================
    // Step 2: Variant × Size 조합 기반 색상 결정
    // ========================================================
    final buttonColors = ButtonColors.from(
      colorExt,
      widget.variant,
      widget.size,
    );

    final buttonStyle = switch (widget.variant) {
      AppButtonVariant.primary => ElevatedButton.styleFrom(
        backgroundColor: buttonColors.background,
        foregroundColor: buttonColors.text,
        elevation: 0,
        alignment: Alignment.center,
        padding: padding,
        textStyle: baseTextStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      AppButtonVariant.secondary => OutlinedButton.styleFrom(
        foregroundColor: buttonColors.text,
        backgroundColor: buttonColors.background,
        alignment: Alignment.center,
        padding: padding,
        side: BorderSide(
          color: buttonColors.border,
          width: BorderTokens.widthThin,
        ),
        textStyle: baseTextStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      AppButtonVariant.ghost => TextButton.styleFrom(
        foregroundColor: buttonColors.text,
        alignment: Alignment.center,
        padding: padding,
        textStyle: baseTextStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    };

    final spacingExt = context.appSpacing;

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox.square(
            dimension: ComponentSizeTokens.iconXSmall,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: buttonColors.text,
            ),
          )
        else if (widget.icon != null)
          SizedBox.square(
            dimension: ComponentSizeTokens.iconXSmall,
            child: Icon(widget.icon, size: ComponentSizeTokens.iconXSmall),
          ),
        if (widget.isLoading || widget.icon != null)
          SizedBox(width: spacingExt.small),
        Text(widget.text, style: baseTextStyle),
      ],
    );

    return AnimatedBuilder(
      animation: _elevationAnimation,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, -_elevationAnimation.value * 0.5),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: _elevationAnimation.value,
                  offset: Offset(0, _elevationAnimation.value * 0.5),
                ),
              ],
            ),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: switch (widget.variant) {
                AppButtonVariant.primary => ElevatedButton(
                  onPressed: widget.isLoading ? null : _onPressed,
                  style: buttonStyle,
                  child: child,
                ),
                AppButtonVariant.secondary => OutlinedButton(
                  onPressed: widget.isLoading ? null : _onPressed,
                  style: buttonStyle,
                  child: child,
                ),
                AppButtonVariant.ghost => TextButton(
                  onPressed: widget.isLoading ? null : _onPressed,
                  style: buttonStyle,
                  child: child,
                ),
              },
            ),
          ),
        );
      },
    );
  }
}
