import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/bottom_nav_colors.dart';
import '../theme/enums.dart';
import '../theme/animation_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppBottomNavStyle;

/// 하단 네비게이션 아이템 데이터
class AppBottomNavItem {
  /// 아이콘
  final IconData icon;

  /// 활성 아이콘 (선택적)
  final IconData? activeIcon;

  /// 라벨
  final String label;

  /// 배지 개수
  final int? badge;

  /// 툴팁
  final String? tooltip;

  const AppBottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badge,
    this.tooltip,
  });
}

/// 하단 네비게이션 컴포넌트
///
/// **용도**: 모바일 주요 탭 이동, 앱 메인 네비게이션
/// **접근성**: 키보드 네비게이션, 스크린 리더 지원
///
/// ```dart
/// AppBottomNav(
///   currentIndex: 0,
///   onTap: (index) => setState(() => _currentIndex = index),
///   items: [
///     AppBottomNavItem(icon: Icons.home, label: '홈'),
///     AppBottomNavItem(icon: Icons.search, label: '검색'),
///     AppBottomNavItem(icon: Icons.person, label: '프로필'),
///   ],
/// )
/// ```
class AppBottomNav extends StatelessWidget {
  /// 현재 선택된 인덱스
  final int currentIndex;

  /// 아이템 클릭 콜백
  final ValueChanged<int> onTap;

  /// 아이템 목록
  final List<AppBottomNavItem> items;

  /// 스타일
  final AppBottomNavStyle style;

  /// 높이
  final double height;

  /// 그림자 표시 여부
  final bool showShadow;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.style = AppBottomNavStyle.standard,
    this.height = 64,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = BottomNavColors.from(colorExt, style);

    return Container(
      height: height + MediaQuery.paddingOf(context).bottom,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border, width: 1)),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: colorExt.shadow.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < items.length; i++)
              Expanded(
                child: _BottomNavItemWidget(
                  item: items[i],
                  isActive: i == currentIndex,
                  onTap: () => onTap(i),
                  colors: colors,
                  spacing: spacingExt,
                  style: style,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 하단 네비게이션 아이템 위젯
class _BottomNavItemWidget extends StatefulWidget {
  final AppBottomNavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final BottomNavColors colors;
  final AppSpacingExtension spacing;
  final AppBottomNavStyle style;

  const _BottomNavItemWidget({
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.colors,
    required this.spacing,
    required this.style,
  });

  @override
  State<_BottomNavItemWidget> createState() => _BottomNavItemWidgetState();
}

class _BottomNavItemWidgetState extends State<_BottomNavItemWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colors = widget.colors;
    final isActive = widget.isActive;
    final showLabel =
        widget.style == AppBottomNavStyle.standard ||
        (widget.style == AppBottomNavStyle.shifting && isActive);

    return Semantics(
      label: item.label,
      selected: isActive,
      button: true,
      child: Tooltip(
        message: item.tooltip ?? item.label,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AnimationTokens.durationQuick,
            padding: EdgeInsets.symmetric(
              horizontal: widget.spacing.small,
              vertical: widget.spacing.xs,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedScale(
                      duration: AnimationTokens.durationQuick,
                      scale: _isPressed ? 0.9 : 1.0,
                      child: AnimatedContainer(
                        duration: AnimationTokens.durationQuick,
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.spacing.medium,
                          vertical: widget.spacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? colors.indicator
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isActive ? (item.activeIcon ?? item.icon) : item.icon,
                          size: 24,
                          color: isActive ? colors.iconActive : colors.icon,
                        ),
                      ),
                    ),
                    if (item.badge != null && item.badge! > 0)
                      Positioned(
                        top: -4,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          constraints: const BoxConstraints(minWidth: 16),
                          decoration: BoxDecoration(
                            color: colors.badgeBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.badge! > 99 ? '99+' : '${item.badge}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.badgeText,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (showLabel) ...[
                  SizedBox(height: widget.spacing.labelDescriptionGap),
                  AnimatedDefaultTextStyle(
                    duration: AnimationTokens.durationQuick,
                    style: TextStyle(
                      color: isActive ? colors.textActive : colors.text,
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
