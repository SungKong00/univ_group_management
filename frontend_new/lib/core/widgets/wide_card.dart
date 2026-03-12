import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/wide_card_colors.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/card_design_tokens.dart';

/// Wide Card - 와이드 배너/프로모션 카드
///
/// 레이아웃: Full-width banner with image overlay
/// 비율: 21:9 (아주 와이드, 배너용)
/// 용도: 프로모션, 광고, 중요 공지사항
class WideCard extends StatefulWidget {
  /// 카드 제목
  final String title;

  /// 카드 부제목
  final String? subtitle;

  /// 카드 설명
  final String? description;

  /// CTA 버튼 텍스트
  final String? ctaText;

  /// 배경 이미지/컨텐츠
  final Widget? backgroundContent;

  /// 배경 이미지 고정 높이
  final double height;

  /// 탭 콜백
  final VoidCallback? onTap;

  /// CTA 콜백
  final VoidCallback? onCtaPressed;

  /// 카드 스타일 variant (standard, featured, highlighted)
  final String variant;

  /// 오버레이 강도 (0.0 ~ 1.0)
  final double overlayOpacity;

  const WideCard({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.ctaText,
    this.backgroundContent,
    this.height = 200,
    this.onTap,
    this.onCtaPressed,
    this.variant = 'standard',
    this.overlayOpacity = 0.3,
  });

  @override
  State<WideCard> createState() => _WideCardState();
}

class _WideCardState extends State<WideCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final width = MediaQuery.sizeOf(context).width;

    // 색상 선택
    final colors = switch (widget.variant) {
      'featured' => WideCardColors.featured(colorExt),
      'highlighted' => WideCardColors.highlighted(colorExt),
      _ => WideCardColors.standard(colorExt),
    };

    final padding = ResponsiveTokens.cardPadding(width);
    final gap = ResponsiveTokens.cardGap(width);
    final lineNumbers = CardDesignTokens.textLineNumbersByCard['wide']!;
    final minCardHeight = widget.height > 0
        ? widget.height
        : CardDesignTokens.wideCardHeight;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: CardDesignTokens.hoverAnimationDuration,
          constraints: BoxConstraints(minHeight: minCardHeight),
          decoration: BoxDecoration(
            color: _isHovered ? colors.backgroundHover : colors.background,
            border: Border.all(color: colors.border),
            borderRadius: BorderTokens.largeRadius(),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Background Content
              if (widget.backgroundContent != null)
                Positioned.fill(child: widget.backgroundContent!),

              // Overlay (Dark/Light)
              Positioned.fill(
                child: Container(
                  color: context.appColors.shadow.withValues(
                    alpha: widget.overlayOpacity,
                  ),
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(padding * 1.5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      widget.title,
                      style: textTheme.headlineMedium!.copyWith(
                        color: colors.title,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: lineNumbers['title'],
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: gap),

                    // Subtitle
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: CardDesignTokens.getSubtitleStyle(
                          context,
                        ).copyWith(color: colors.subtitle),
                        maxLines: lineNumbers['subtitle'],
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (widget.subtitle != null) SizedBox(height: gap * 0.5),

                    // Description
                    if (widget.description != null)
                      Text(
                        widget.description!,
                        style: CardDesignTokens.getDescriptionStyle(
                          context,
                        ).copyWith(color: colors.description),
                        maxLines: lineNumbers['description'],
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (widget.description != null) SizedBox(height: gap * 1.5),

                    // CTA Button
                    if (widget.ctaText != null)
                      SizedBox(
                        height: ResponsiveTokens.buttonHeight(width),
                        child: Material(
                          color: colors.ctaBackground,
                          borderRadius: BorderTokens.mediumRadius(),
                          child: InkWell(
                            onTap: widget.onCtaPressed,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    ResponsiveTokens.buttonMediumPaddingH(
                                      width,
                                    ),
                              ),
                              child: Center(
                                child: Text(
                                  widget.ctaText!,
                                  style: textTheme.bodyMedium!.copyWith(
                                    color: colors.ctaText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
