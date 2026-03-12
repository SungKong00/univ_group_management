import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';
import '../theme/component_size_tokens.dart';

/// Linear 스타일 Feature Card (대형 클릭 가능 카드)
///
/// 특징:
/// - 이미지/아이콘 + 제목 + 부제목
/// - hover 시 shadow 증가
/// - 클릭 가능 (onTap)
/// - 16px border radius
class AppFeatureCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget? image;
  final IconData? icon;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const AppFeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.image,
    this.icon,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  State<AppFeatureCard> createState() => _AppFeatureCardState();
}

class _AppFeatureCardState extends State<AppFeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;

    // Shadow using semantic overlay tokens
    final shadow = _isHovered
        ? [
            BoxShadow(
              color: colorExt.overlayMedium, // rgba(255,255,255,0.08)
              blurRadius: 24.0,
              spreadRadius: 0.0,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: colorExt.overlayLight, // rgba(255,255,255,0.05)
              blurRadius: 4.0,
              spreadRadius: 0.0,
              offset: const Offset(0, 2),
            ),
          ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AnimationTokens.durationSmooth,
          curve: AnimationTokens.curveDefault,
          width: widget.width,
          height: widget.height,
          padding: EdgeInsets.all(ResponsiveTokens.cardPadding(width)),
          decoration: BoxDecoration(
            color: colorExt.surfaceSecondary,
            borderRadius: BorderTokens.xxlRadius(),
            boxShadow: shadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 이미지 또는 아이콘
              if (widget.image != null)
                ClipRRect(
                  borderRadius: BorderTokens.largeRadius(),
                  child: widget.image!,
                )
              else if (widget.icon != null)
                Container(
                  width: ComponentSizeTokens.boxXLarge,
                  height: ComponentSizeTokens.boxXLarge,
                  decoration: BoxDecoration(
                    color: colorExt.surfaceTertiary,
                    borderRadius: BorderTokens.xlRadius(),
                  ),
                  child: Icon(
                    widget.icon,
                    size: ComponentSizeTokens.iconLarge,
                    color: colorExt.brandPrimary,
                  ),
                ),

              const SizedBox(height: ComponentSizeTokens.iconXSmall),

              // 제목
              Text(
                widget.title,
                style: textTheme.bodyLarge!.copyWith(
                  color: colorExt.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: ResponsiveTokens.space8),

              // 부제목
              Text(
                widget.subtitle,
                style: textTheme.bodyMedium!.copyWith(
                  color: colorExt.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
