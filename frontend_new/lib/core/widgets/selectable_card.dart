import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/selectable_card_colors.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/card_design_tokens.dart';

/// Selectable Card - 선택 가능한 카드 (체크박스 + 콘텐츠)
///
/// 레이아웃: Checkbox (left) → Title/Subtitle (right)
/// 용도: 다중선택, 필터, 항목 선택
class SelectableCard extends StatefulWidget {
  /// 카드 제목
  final String title;

  /// 카드 부제목 (선택)
  final String? subtitle;

  /// 선택 상태
  final bool isSelected;

  /// 선택 상태 변경 콜백
  final ValueChanged<bool>? onSelected;

  /// 추가 콘텐츠 위젯 (선택)
  final Widget? trailing;

  /// 카드 스타일 variant (standard, featured)
  final String variant;

  /// 비활성화 상태
  final bool isEnabled;

  const SelectableCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.isSelected,
    this.onSelected,
    this.trailing,
    this.variant = 'standard',
    this.isEnabled = true,
  });

  @override
  State<SelectableCard> createState() => _SelectableCardState();
}

class _SelectableCardState extends State<SelectableCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final width = MediaQuery.sizeOf(context).width;

    // 색상 선택
    final colors = switch (widget.variant) {
      'featured' => SelectableCardColors.featured(colorExt),
      'highlighted' => SelectableCardColors.highlighted(colorExt),
      _ => SelectableCardColors.standard(colorExt),
    };

    final padding = ResponsiveTokens.cardPadding(width);
    final gap = ResponsiveTokens.cardGap(width);
    final lineNumbers = CardDesignTokens.textLineNumbersByCard['selectable']!;

    return GestureDetector(
      onTap: widget.isEnabled
          ? () {
              widget.onSelected?.call(!widget.isSelected);
            }
          : null,
      child: MouseRegion(
        onEnter: widget.isEnabled ? (_) => setState(() => _isHovered = true) : null,
        onExit: widget.isEnabled ? (_) => setState(() => _isHovered = false) : null,
        child: Opacity(
          opacity: widget.isEnabled ? 1.0 : CardDesignTokens.disabledOpacity,
          child: AnimatedContainer(
            duration: CardDesignTokens.hoverAnimationDuration,
            decoration: BoxDecoration(
            color: widget.isSelected
                ? colors.backgroundSelected
                : _isHovered
                    ? colors.backgroundHover
                    : colors.background,
            border: Border.all(
              color: widget.isSelected ? colors.borderSelected : colors.border,
              width: widget.isSelected ? CardDesignTokens.selectedBorderWidth : CardDesignTokens.normalBorderWidth,
            ),
            borderRadius: BorderTokens.largeRadius(),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              children: [
                // Checkbox
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: widget.isSelected,
                    onChanged: widget.isEnabled
                        ? (value) {
                            widget.onSelected?.call(value ?? false);
                          }
                        : null,
                    fillColor: WidgetStateProperty.all(
                      widget.isSelected
                          ? colorExt.brandPrimary
                          : colors.checkboxBg,
                    ),
                    side: WidgetStateBorderSide.resolveWith(
                      (states) => BorderSide(
                        color: colors.checkboxBorder,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: gap),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        style: CardDesignTokens.getSubtitleStyle(context).copyWith(
                          color: colors.title,
                        ),
                        maxLines: lineNumbers['title'],
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.subtitle != null) SizedBox(height: gap * 0.5),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: CardDesignTokens.getDescriptionStyle(context).copyWith(
                            color: colors.subtitle,
                          ),
                          maxLines: lineNumbers['subtitle'],
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // Trailing (optional)
                if (widget.trailing != null) ...[
                  SizedBox(width: gap),
                  widget.trailing!,
                ],
              ],
            ),
          ),
            ),
        ),
      ),
    );
  }
}
