import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/tab_colors.dart';
import '../theme/responsive_tokens.dart';
import '../theme/animation_tokens.dart';

/// Linear 스타일 Content Tabs (Radio Button Group)
///
/// 특징:
/// - Underline indicator with smooth sliding animation
/// - Active/Inactive text color transition
/// - Mutually exclusive selection (radio button)
/// - 여러 탭을 뛰어넘어도 자연스럽게 이동하는 indicator
class AppTabs extends StatefulWidget {
  final List<AppTabItem> tabs;
  final int initialIndex;
  final ValueChanged<int>? onTabChanged;
  final double indicatorHeight;
  final Duration animationDuration;
  final Curve animationCurve;

  const AppTabs({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.onTabChanged,
    this.indicatorHeight = 2.0,
    this.animationDuration = AnimationTokens.durationSmooth,
    this.animationCurve = AnimationTokens.curveSlide,
  });

  @override
  State<AppTabs> createState() => _AppTabsState();
}

class _AppTabsState extends State<AppTabs> {
  late int _selectedIndex;
  final List<GlobalKey> _tabKeys = [];
  Rect _indicatorRect = Rect.zero;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _tabKeys.addAll(List.generate(widget.tabs.length, (_) => GlobalKey()));

    // 초기 indicator 위치 설정 (첫 프레임 이후)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateIndicatorRect(_selectedIndex);
    });
  }

  void _selectTab(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    _updateIndicatorRect(index);
    widget.onTabChanged?.call(index);
  }

  void _updateIndicatorRect(int index) {
    final RenderBox? renderBox =
        _tabKeys[index].currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final parentRenderBox = context.findRenderObject() as RenderBox?;
    if (parentRenderBox == null) return;

    final parentPosition = parentRenderBox.localToGlobal(Offset.zero);
    final left = position.dx - parentPosition.dx;
    final width = renderBox.size.width;

    setState(() {
      _indicatorRect = Rect.fromLTWH(left, 0, width, widget.indicatorHeight);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final tabColors = TabColors.standard(colorExt);

    return SizedBox(
      height: 50 + widget.indicatorHeight,
      child: Stack(
        children: [
          // 탭 버튼들
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < widget.tabs.length; i++)
                _TabButton(
                  key: _tabKeys[i],
                  label: widget.tabs[i].label,
                  isActive: _selectedIndex == i,
                  onTap: () => _selectTab(i),
                ),
            ],
          ),
          // 슬라이딩 Indicator (TweenAnimationBuilder 사용)
          Positioned(
            bottom: 0,
            child: TweenAnimationBuilder<Rect?>(
              tween: RectTween(begin: _indicatorRect, end: _indicatorRect),
              duration: widget.animationDuration,
              curve: widget.animationCurve,
              builder: (context, Rect? rect, child) {
                if (rect == null || rect == Rect.zero) {
                  return const SizedBox.shrink();
                }
                return Transform.translate(
                  offset: Offset(rect.left, 0),
                  child: Container(
                    width: rect.width,
                    height: rect.height,
                    decoration: BoxDecoration(
                      color: tabColors.indicator,
                      borderRadius: BorderRadius.circular(rect.height / 2),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final tabColors = TabColors.standard(colorExt);
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;

    final textColor = widget.isActive
        ? tabColors.textActive
        : (_isHovered ? colorExt.textSecondary : tabColors.text);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // ✅ Padding 영역도 클릭 가능하게
        onTap: widget.onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveTokens.cardGap(width),
            vertical: ResponsiveTokens.cardGap(width) * 0.75,
          ),
          child: AnimatedDefaultTextStyle(
            duration: AnimationTokens.durationQuick,
            style: textTheme.bodyLarge!.copyWith(
              color: textColor,
              fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

class AppTabItem {
  final String label;
  final Widget? content;

  const AppTabItem({required this.label, this.content});
}
