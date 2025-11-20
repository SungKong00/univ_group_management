import 'package:flutter/material.dart';
import '../theme/color_tokens.dart';
import '../theme/typography_tokens.dart';
import '../theme/animation_tokens.dart';

/// Linear 스타일 Content Tabs (Radio Button Group)
///
/// 특징:
/// - Underline indicator with smooth animation
/// - Active/Inactive text color transition
/// - Mutually exclusive selection (radio button)
class AppTabs extends StatefulWidget {
  final List<AppTabItem> tabs;
  final int initialIndex;
  final ValueChanged<int>? onTabChanged;
  final double indicatorHeight;
  final Duration animationDuration;

  const AppTabs({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.onTabChanged,
    this.indicatorHeight = 2.0,
    this.animationDuration = const Duration(milliseconds: 250),
  });

  @override
  State<AppTabs> createState() => _AppTabsState();
}

class _AppTabsState extends State<AppTabs> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _selectTab(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    widget.onTabChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 탭 버튼들
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < widget.tabs.length; i++)
              _TabButton(
                label: widget.tabs[i].label,
                isActive: _selectedIndex == i,
                onTap: () => _selectTab(i),
                showIndicator: _selectedIndex == i,
                indicatorHeight: widget.indicatorHeight,
                animationDuration: widget.animationDuration,
              ),
          ],
        ),
      ],
    );
  }
}

class _TabButton extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool showIndicator;
  final double indicatorHeight;
  final Duration animationDuration;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.showIndicator,
    required this.indicatorHeight,
    required this.animationDuration,
  });

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isActive
        ? ColorTokens.textPrimary
        : (_isHovered ? ColorTokens.textSecondary : ColorTokens.textTertiary);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: AnimatedDefaultTextStyle(
                duration: AnimationTokens.fast,
                style: TypographyTokens.textLarge.copyWith(
                  color: textColor,
                  fontWeight: widget.isActive
                      ? TypographyTokens.medium
                      : FontWeight.normal,
                ),
                child: Text(widget.label),
              ),
            ),
            // Indicator (각 버튼 아래에 직접 배치)
            Container(
              height: widget.indicatorHeight,
              color: widget.showIndicator ? ColorTokens.accent : Colors.transparent,
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppTabItem {
  final String label;
  final Widget? content;

  const AppTabItem({
    required this.label,
    this.content,
  });
}
