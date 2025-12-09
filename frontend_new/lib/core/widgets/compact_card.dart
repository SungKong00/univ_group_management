import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/compact_card_colors.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/card_design_tokens.dart';

/// Compact Card - 최소화 카드 (Icon/Image + Title)
///
/// 레이아웃: Icon/Image (center, 64x64) → Title
/// 비율: 1:1 (정사각형, 그리드에 4-6열 표시)
/// 용도: 기능/카테고리 선택, 필터, 미니 정보
class CompactCard extends StatefulWidget {
  /// 카드 제목
  final String title;

  /// 메타 정보 (선택)
  final String? meta;

  /// 아이콘 (IconData)
  final IconData? icon;

  /// 이미지 위젯
  final Widget? image;

  /// 아이콘/이미지 크기 (기본: 64)
  final double contentSize;

  /// 아이콘 색상 (기본: brandPrimary)
  final Color? iconColor;

  /// 탭 콜백
  final VoidCallback? onTap;

  /// 카드 스타일 variant (standard, featured, highlighted)
  final String variant;

  /// 활성화 상태 (선택)
  final bool isSelected;

  const CompactCard({
    super.key,
    required this.title,
    this.meta,
    this.icon,
    this.image,
    this.contentSize = 64,
    this.iconColor,
    this.onTap,
    this.variant = 'standard',
    this.isSelected = false,
  });

  @override
  State<CompactCard> createState() => _CompactCardState();
}

class _CompactCardState extends State<CompactCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;

    // 색상 선택
    final colors = switch (widget.variant) {
      'featured' => CompactCardColors.featured(colorExt),
      'highlighted' => CompactCardColors.highlighted(colorExt),
      _ => CompactCardColors.standard(colorExt),
    };

    // LayoutBuilder: 실제 할당된 카드 너비 기준으로 레이아웃 결정
    return LayoutBuilder(
      builder: (context, constraints) {
        // 화면 너비는 반응형 토큰(padding, gap)에만 사용
        final screenWidth = MediaQuery.sizeOf(context).width;
        final padding = ResponsiveTokens.cardPadding(screenWidth);
        final gap = ResponsiveTokens.cardGap(screenWidth);
        final lineNumbers = CardDesignTokens.textLineNumbersByCard['compact']!;
        final compactSize = widget.contentSize > 0
            ? widget.contentSize
            : CardDesignTokens.iconSizes['compact']!;

        return GestureDetector(
          onTap: widget.onTap,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: CardDesignTokens.hoverAnimationDuration,
              // 크기 제약은 AdaptiveCardGrid가 담당 - 카드는 부모 크기에 맞춤
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? colors.selectedBackground
                    : _isHovered
                        ? colors.backgroundHover
                        : colors.background,
                border: Border.all(
                  color: widget.isSelected
                      ? colors.selectedBorder
                      : colors.border,
                  width: widget.isSelected ? 2 : 1,
                ),
                borderRadius: BorderTokens.largeRadius(),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon or Image
                    if (widget.image != null)
                      SizedBox(
                        width: compactSize,
                        height: compactSize,
                        child: widget.image!,
                      )
                    else if (widget.icon != null)
                      Icon(
                        widget.icon!,
                        size: compactSize,
                        color: widget.isSelected
                            ? colors.selectedTitle
                            : (widget.iconColor ?? colorExt.brandPrimary),
                      )
                    else
                      SizedBox(
                        width: compactSize,
                        height: compactSize,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorExt.surfaceTertiary,
                            borderRadius: BorderTokens.mediumRadius(),
                          ),
                        ),
                      ),

                    SizedBox(height: gap),

                    // Meta (optional)
                    if (widget.meta != null)
                      Text(
                        widget.meta!,
                        style: CardDesignTokens.getMetaStyle(
                          context,
                        ).copyWith(color: colors.meta),
                        textAlign: TextAlign.center,
                        maxLines: lineNumbers['meta'],
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (widget.meta != null) SizedBox(height: gap * 0.5),

                    // Title
                    Text(
                      widget.title,
                      style: CardDesignTokens.getSubtitleStyle(
                        context,
                      ).copyWith(
                        color: widget.isSelected
                            ? colors.selectedTitle
                            : colors.title,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: lineNumbers['title'],
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
