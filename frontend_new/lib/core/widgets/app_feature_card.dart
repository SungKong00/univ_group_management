import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/responsive_tokens.dart';

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

    // Hardcoded shadow values (ShadowTokens.low and ShadowTokens.medium)
    final shadow = _isHovered
        ? [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.08), // medium
              blurRadius: 24.0,
              spreadRadius: 0.0,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.05), // low
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
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: widget.width,
          height: widget.height,
          padding: EdgeInsets.all(ResponsiveTokens.cardPadding(width)),
          decoration: BoxDecoration(
            color: colorExt.surfaceSecondary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: shadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 이미지 또는 아이콘
              if (widget.image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.image!,
                )
              else if (widget.icon != null)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colorExt.surfaceTertiary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 32,
                    color: colorExt.brandPrimary,
                  ),
                ),

              const SizedBox(height: 16),

              // 제목
              Text(
                widget.title,
                style: textTheme.bodyLarge!.copyWith(
                  color: colorExt.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

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
