import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/navigation_rail_colors.dart';
import '../theme/enums.dart';
import '../theme/animation_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppNavigationRailAlignment;

/// 네비게이션 레일 아이템 데이터
class AppNavigationRailItem {
  /// 아이콘
  final IconData icon;

  /// 활성 아이콘 (선택적)
  final IconData? activeIcon;

  /// 라벨
  final String label;

  /// 툴팁
  final String? tooltip;

  /// 배지 개수
  final int? badge;

  const AppNavigationRailItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.tooltip,
    this.badge,
  });
}

/// 네비게이션 레일 컴포넌트
///
/// **용도**: 태블릿/데스크톱 좌측 네비게이션
/// **접근성**: 키보드 네비게이션, 스크린 리더 지원
///
/// ```dart
/// AppNavigationRail(
///   selectedIndex: 0,
///   onDestinationSelected: (index) => setState(() => _selectedIndex = index),
///   items: [
///     AppNavigationRailItem(icon: Icons.home, label: '홈'),
///     AppNavigationRailItem(icon: Icons.search, label: '검색'),
///     AppNavigationRailItem(icon: Icons.settings, label: '설정'),
///   ],
/// )
/// ```
class AppNavigationRail extends StatelessWidget {
  /// 현재 선택된 인덱스
  final int selectedIndex;

  /// 선택 변경 콜백
  final ValueChanged<int> onDestinationSelected;

  /// 아이템 목록
  final List<AppNavigationRailItem> items;

  /// 정렬
  final AppNavigationRailAlignment alignment;

  /// 확장 여부 (라벨 표시)
  final bool extended;

  /// 확장 너비
  final double extendedWidth;

  /// 축소 너비
  final double collapsedWidth;

  /// 상단 위젯
  final Widget? leading;

  /// 하단 위젯
  final Widget? trailing;

  /// 라벨 표시 여부
  final bool showLabels;

  const AppNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
    this.alignment = AppNavigationRailAlignment.start,
    this.extended = false,
    this.extendedWidth = 200,
    this.collapsedWidth = 72,
    this.leading,
    this.trailing,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = NavigationRailColors.from(colorExt);

    return AnimatedContainer(
      duration: AnimationTokens.durationSmooth,
      width: extended ? extendedWidth : collapsedWidth,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(right: BorderSide(color: colors.border, width: 1)),
      ),
      child: Column(
        children: [
          if (leading != null) ...[
            Padding(
              padding: EdgeInsets.all(spacingExt.medium),
              child: leading!,
            ),
            Divider(height: 1, color: colors.border),
          ],
          if (alignment == AppNavigationRailAlignment.center) const Spacer(),
          if (alignment == AppNavigationRailAlignment.end) const Spacer(),
          for (int i = 0; i < items.length; i++)
            _NavigationRailItemWidget(
              item: items[i],
              isSelected: i == selectedIndex,
              onTap: () => onDestinationSelected(i),
              colors: colors,
              spacing: spacingExt,
              extended: extended,
              showLabels: showLabels,
            ),
          if (alignment == AppNavigationRailAlignment.start) const Spacer(),
          if (alignment == AppNavigationRailAlignment.center) const Spacer(),
          if (trailing != null) ...[
            Divider(height: 1, color: colors.border),
            Padding(
              padding: EdgeInsets.all(spacingExt.medium),
              child: trailing!,
            ),
          ],
        ],
      ),
    );
  }
}

/// 네비게이션 레일 아이템 위젯
class _NavigationRailItemWidget extends StatefulWidget {
  final AppNavigationRailItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final NavigationRailColors colors;
  final AppSpacingExtension spacing;
  final bool extended;
  final bool showLabels;

  const _NavigationRailItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.spacing,
    required this.extended,
    required this.showLabels,
  });

  @override
  State<_NavigationRailItemWidget> createState() =>
      _NavigationRailItemWidgetState();
}

class _NavigationRailItemWidgetState extends State<_NavigationRailItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colors = widget.colors;

    Widget content = widget.extended
        ? _buildExtendedContent(item, colors)
        : _buildCollapsedContent(item, colors);

    if (!widget.extended) {
      content = Tooltip(message: item.tooltip ?? item.label, child: content);
    }

    return Semantics(
      label: item.label,
      selected: widget.isSelected,
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AnimationTokens.durationQuick,
            margin: EdgeInsets.symmetric(
              horizontal: widget.spacing.small,
              vertical: widget.spacing.labelDescriptionGap,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.extended
                  ? widget.spacing.medium
                  : widget.spacing.small,
              vertical: widget.spacing.small,
            ),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? colors.indicator
                  : _isHovered
                  ? colors.hover
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent(
    AppNavigationRailItem item,
    NavigationRailColors colors,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              widget.isSelected ? (item.activeIcon ?? item.icon) : item.icon,
              size: 24,
              color: widget.isSelected ? colors.iconActive : colors.icon,
            ),
            if (item.badge != null && item.badge! > 0)
              Positioned(
                top: -4,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(minWidth: 14),
                  decoration: BoxDecoration(
                    color: colors.iconActive,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    item.badge! > 99 ? '99+' : '${item.badge}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appColors.textOnBrand,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (widget.showLabels) ...[
          SizedBox(height: widget.spacing.labelDescriptionGap),
          Text(
            item.label,
            style: TextStyle(
              color: widget.isSelected ? colors.textActive : colors.text,
              fontSize: 11,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildExtendedContent(
    AppNavigationRailItem item,
    NavigationRailColors colors,
  ) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              widget.isSelected ? (item.activeIcon ?? item.icon) : item.icon,
              size: 24,
              color: widget.isSelected ? colors.iconActive : colors.icon,
            ),
            if (item.badge != null && item.badge! > 0)
              Positioned(
                top: -4,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(minWidth: 14),
                  decoration: BoxDecoration(
                    color: colors.iconActive,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    item.badge! > 99 ? '99+' : '${item.badge}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appColors.textOnBrand,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(width: widget.spacing.medium),
        Expanded(
          child: Text(
            item.label,
            style: TextStyle(
              color: widget.isSelected ? colors.textActive : colors.text,
              fontSize: 14,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
