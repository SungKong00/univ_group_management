import 'package:flutter/material.dart';
import '../theme/color_tokens.dart';
import '../theme/typography_tokens.dart';

/// Linear 스타일 Definition List (용어 정의 리스트)
///
/// 특징:
/// - Semantic structure: term + definition
/// - Optional icon/image
/// - Optional clickable term (link)
/// - Configurable gap
class AppDefinitionList extends StatelessWidget {
  final List<AppDefinitionItem> items;
  final double itemGap;
  final EdgeInsets? padding;

  const AppDefinitionList({
    super.key,
    required this.items,
    this.itemGap = 24,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _DefinitionListItem(item: items[i]),
            if (i < items.length - 1) SizedBox(height: itemGap),
          ],
        ],
      ),
    );
  }
}

class _DefinitionListItem extends StatelessWidget {
  final AppDefinitionItem item;

  const _DefinitionListItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon (optional)
        if (item.icon != null) ...[
          Icon(
            item.icon,
            size: 20,
            color: ColorTokens.accent,
          ),
          const SizedBox(width: 12),
        ],

        // Term + Definition
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Term (제목)
              if (item.onTermTap != null)
                GestureDetector(
                  onTap: item.onTermTap,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: _TermText(
                      term: item.term,
                      isLink: true,
                    ),
                  ),
                )
              else
                _TermText(term: item.term),

              const SizedBox(height: 8),

              // Definition (설명)
              Text(
                item.definition,
                style: TypographyTokens.textRegular.copyWith(
                  color: ColorTokens.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TermText extends StatefulWidget {
  final String term;
  final bool isLink;

  const _TermText({
    required this.term,
    this.isLink = false,
  });

  @override
  State<_TermText> createState() => _TermTextState();
}

class _TermTextState extends State<_TermText> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isLink
        ? (_isHovered ? ColorTokens.linkHover : ColorTokens.linkPrimary)
        : ColorTokens.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Text(
        widget.term,
        style: TypographyTokens.textRegular.copyWith(
          color: color,
          fontWeight: TypographyTokens.medium,
        ),
      ),
    );
  }
}

class AppDefinitionItem {
  final String term;
  final String definition;
  final IconData? icon;
  final VoidCallback? onTermTap;

  const AppDefinitionItem({
    required this.term,
    required this.definition,
    this.icon,
    this.onTermTap,
  });
}
