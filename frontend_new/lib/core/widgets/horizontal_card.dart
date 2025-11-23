import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/horizontal_card_colors.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/card_design_tokens.dart';

/// Horizontal Card - 이미지 좌측 + 텍스트 우측
///
/// 레이아웃: Image (left) → Title/Subtitle/Description (right)
/// 비율: 4:3 ~ 16:9 (가로 스크롤 최적화)
class HorizontalCard extends StatefulWidget {
  /// 카드 제목
  final String title;

  /// 카드 부제목 (선택)
  final String? subtitle;

  /// 카드 설명
  final String? description;

  /// 메타 정보 (선택)
  final String? meta;

  /// 이미지 위젯 (좌측)
  final Widget? image;

  /// 이미지 너비 비율 (0.3 ~ 0.5)
  final double imageWidthRatio;

  /// 액션 버튼들
  final List<Widget>? actions;

  /// 탭 콜백
  final VoidCallback? onTap;

  /// 카드 스타일 variant (standard, featured, highlighted)
  final String variant;

  const HorizontalCard({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.meta,
    this.image,
    this.imageWidthRatio = 0.4,
    this.actions,
    this.onTap,
    this.variant = 'standard',
  });

  @override
  State<HorizontalCard> createState() => _HorizontalCardState();
}

class _HorizontalCardState extends State<HorizontalCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;

    // 색상 선택
    final colors = switch (widget.variant) {
      'featured' => HorizontalCardColors.featured(colorExt),
      'highlighted' => HorizontalCardColors.highlighted(colorExt),
      _ => HorizontalCardColors.standard(colorExt),
    };

    final screenWidth = MediaQuery.sizeOf(context).width;
    final padding = ResponsiveTokens.cardPadding(screenWidth);
    final gap = ResponsiveTokens.cardGap(screenWidth);
    final lineNumbers = CardDesignTokens.textLineNumbersByCard['horizontal']!;

    // 디자인 시스템 기반 이미지 너비 계산
    final cardSizes = CardDesignTokens.getCardWidths('horizontal', screenWidth);
    final cardPreferredWidth = cardSizes['preferred']!;
    final imageWidth = cardPreferredWidth * widget.imageWidthRatio;

    // 이미지 비율 기반 최소 높이 자동 계산
    final imageAspectRatio = CardDesignTokens.imageAspectRatios['horizontal']!;
    final minHeight = imageWidth / imageAspectRatio;

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: CardDesignTokens.hoverAnimationDuration,
          decoration: BoxDecoration(
            color: _isHovered ? colors.backgroundHover : colors.background,
            border: Border.all(color: colors.border),
            borderRadius: BorderTokens.largeRadius(),
          ),
          clipBehavior: Clip.antiAlias,
          // ConstrainedBox: 이미지 비율 기반 최소 높이 자동 계산
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Section (Left)
                if (widget.image != null)
                  SizedBox(
                    width: imageWidth,
                    child: AspectRatio(
                      aspectRatio:
                          CardDesignTokens.imageAspectRatios['horizontal']!,
                      child: widget.image!,
                    ),
                  ),

                // Content Section (Right)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Meta
                        if (widget.meta != null)
                          Text(
                            widget.meta!,
                            style: CardDesignTokens.getMetaStyle(
                              context,
                            ).copyWith(color: colors.meta),
                          ),
                        if (widget.meta != null) SizedBox(height: gap * 0.5),

                        // Title
                        Text(
                          widget.title,
                          style: CardDesignTokens.getTitleStyle(
                            context,
                          ).copyWith(color: colors.title),
                          maxLines: lineNumbers['title'],
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: gap * 0.5),

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
                        if (widget.subtitle != null)
                          SizedBox(height: gap * 0.5),

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
                        if (widget.description != null) SizedBox(height: gap),

                        // Actions
                        if (widget.actions != null &&
                            widget.actions!.isNotEmpty)
                          Wrap(
                            spacing: gap * 0.5,
                            runSpacing: gap * 0.5,
                            children: widget.actions!,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
