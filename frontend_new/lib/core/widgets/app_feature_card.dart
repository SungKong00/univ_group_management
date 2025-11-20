import 'package:flutter/material.dart';
import '../theme/color_tokens.dart';
import '../theme/typography_tokens.dart';
import '../theme/shadow_tokens.dart';
import '../theme/animation_tokens.dart';

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
    final shadow = _isHovered ? ShadowTokens.medium : ShadowTokens.low;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AnimationTokens.regular,
          curve: AnimationTokens.easeOutCubic,
          width: widget.width,
          height: widget.height,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1011), // rgb(15, 16, 17)
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
                    color: ColorTokens.backgroundLevel2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 32,
                    color: ColorTokens.accent,
                  ),
                ),

              const SizedBox(height: 16),

              // 제목
              Text(
                widget.title,
                style: TypographyTokens.textLarge.copyWith(
                  color: ColorTokens.textPrimary,
                  fontWeight: TypographyTokens.semibold,
                ),
              ),

              const SizedBox(height: 8),

              // 부제목
              Text(
                widget.subtitle,
                style: TypographyTokens.textRegular.copyWith(
                  color: ColorTokens.textSecondary,
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
