import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/vertical_card_colors.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/card_design_tokens.dart';

/// Vertical Card - 이미지 상단 + 텍스트 컴포넌트
///
/// 레이아웃: Image (top) → Title → Subtitle → Description → Actions
/// 비율: 3:4 ~ 4:5 (세로 스크롤 최적화)
class VerticalCard extends StatefulWidget {
  /// 카드 제목
  final String title;

  /// 카드 부제목 (선택)
  final String? subtitle;

  /// 카드 설명
  final String? description;

  /// 메타 정보 (선택)
  final String? meta;

  /// 이미지 위젯 (상단)
  final Widget? image;

  /// 이미지 AspectRatio (기본: 3/4)
  final double imageAspectRatio;

  /// 액션 버튼들
  final List<Widget>? actions;

  /// 탭 콜백
  final VoidCallback? onTap;

  /// 카드 스타일 variant (standard, featured, highlighted)
  final String variant;

  /// 카드 높이 (고정)
  final double? height;

  const VerticalCard({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.meta,
    this.image,
    this.imageAspectRatio = 3 / 4,
    this.actions,
    this.onTap,
    this.variant = 'standard',
    this.height,
  });

  @override
  State<VerticalCard> createState() => _VerticalCardState();
}

class _VerticalCardState extends State<VerticalCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final width = MediaQuery.sizeOf(context).width;

    // 색상 선택
    final colors = switch (widget.variant) {
      'featured' => VerticalCardColors.featured(colorExt),
      'highlighted' => VerticalCardColors.highlighted(colorExt),
      _ => VerticalCardColors.standard(colorExt),
    };

    final padding = ResponsiveTokens.cardPadding(width);
    final gap = ResponsiveTokens.cardGap(width);
    final lineNumbers = CardDesignTokens.textLineNumbersByCard['vertical']!;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              if (widget.image != null)
                AspectRatio(
                  aspectRatio: widget.imageAspectRatio,
                  child: widget.image!,
                ),

              // Content Section
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meta
                      if (widget.meta != null)
                        Text(
                          widget.meta!,
                          style: CardDesignTokens.getMetaStyle(context).copyWith(
                            color: colors.meta,
                          ),
                        ),
                      if (widget.meta != null) SizedBox(height: gap * 0.5),

                      // Title
                      Text(
                        widget.title,
                        style: CardDesignTokens.getTitleStyle(context).copyWith(
                          color: colors.title,
                        ),
                        maxLines: lineNumbers['title'],
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: gap * 0.5),

                      // Subtitle
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: CardDesignTokens.getSubtitleStyle(context).copyWith(
                            color: colors.subtitle,
                          ),
                          maxLines: lineNumbers['subtitle'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (widget.subtitle != null) SizedBox(height: gap),

                      // Description
                      if (widget.description != null)
                        Expanded(
                          child: Text(
                            widget.description!,
                            style: CardDesignTokens.getDescriptionStyle(context).copyWith(
                              color: colors.description,
                            ),
                            maxLines: lineNumbers['description'],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (widget.description != null) SizedBox(height: gap),

                      // Actions
                      if (widget.actions != null && widget.actions!.isNotEmpty)
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
    );
  }
}
