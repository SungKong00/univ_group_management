import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/global_nav_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';

/// 글로벌 네비게이션 아이템 데이터
class GlobalNavItem {
  /// 아이템 ID (라우팅용)
  final String id;

  /// 아이템 제목
  final String title;

  /// 아이템 설명
  final String? description;

  /// 기본 아이콘
  final IconData icon;

  /// 활성 아이콘
  final IconData? activeIcon;

  const GlobalNavItem({
    required this.id,
    required this.title,
    this.description,
    required this.icon,
    this.activeIcon,
  });
}

/// 글로벌 네비게이션 레이아웃 모드
enum GlobalNavLayoutMode {
  /// 하단 바 (모바일)
  bottom,

  /// 축소 사이드바 (아이콘만)
  collapsed,

  /// 확장 사이드바 (아이콘 + 텍스트)
  expanded,
}

/// 글로벌 네비게이션 컴포넌트
///
/// 앱의 메인 탭(홈, 캘린더, 워크스페이스, 활동, 프로필)을 표시합니다.
/// 화면 크기에 따라 하단 바 또는 사이드바로 표시됩니다.
///
/// **기능**:
/// - 5개 탭 네비게이션
/// - 반응형 레이아웃 (하단바 / 축소 사이드바 / 확장 사이드바)
/// - 축소/확장 애니메이션
/// - 사용자 정보 카드 (사이드바 하단)
///
/// ```dart
/// AppGlobalNavigation(
///   items: [
///     GlobalNavItem(id: 'home', title: '홈', icon: Icons.home_outlined, activeIcon: Icons.home),
///     GlobalNavItem(id: 'workspace', title: '워크스페이스', icon: Icons.work_outline, activeIcon: Icons.work),
///   ],
///   selectedId: 'home',
///   onItemSelected: (id) => print('Selected: $id'),
///   layoutMode: GlobalNavLayoutMode.expanded,
/// )
/// ```
class AppGlobalNavigation extends StatefulWidget {
  /// 네비게이션 아이템 목록
  final List<GlobalNavItem> items;

  /// 선택된 아이템 ID
  final String selectedId;

  /// 아이템 선택 콜백
  final ValueChanged<String> onItemSelected;

  /// 레이아웃 모드
  final GlobalNavLayoutMode layoutMode;

  /// 사용자 정보 위젯 (사이드바 하단)
  final Widget? userInfo;

  /// 확장 너비
  final double expandedWidth;

  /// 축소 너비
  final double collapsedWidth;

  const AppGlobalNavigation({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onItemSelected,
    this.layoutMode = GlobalNavLayoutMode.expanded,
    this.userInfo,
    this.expandedWidth = 256,
    this.collapsedWidth = 80,
  });

  @override
  State<AppGlobalNavigation> createState() => _AppGlobalNavigationState();
}

class _AppGlobalNavigationState extends State<AppGlobalNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _collapseController;
  late Animation<double> _collapseAnimation;

  @override
  void initState() {
    super.initState();
    _collapseController = AnimationController(
      duration: AnimationTokens.durationSmooth,
      vsync: this,
    );
    _collapseAnimation = CurvedAnimation(
      parent: _collapseController,
      curve: AnimationTokens.curveSmooth,
    );

    if (widget.layoutMode == GlobalNavLayoutMode.collapsed) {
      _collapseController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AppGlobalNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layoutMode != widget.layoutMode) {
      if (widget.layoutMode == GlobalNavLayoutMode.collapsed) {
        _collapseController.forward();
      } else if (widget.layoutMode == GlobalNavLayoutMode.expanded) {
        _collapseController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _collapseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.layoutMode == GlobalNavLayoutMode.bottom) {
      return _buildBottomNavigation(context);
    }
    return _buildSidebarNavigation(context);
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final colorExt = context.appColors;
    final colors = GlobalNavColors.from(colorExt);

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          top: BorderSide(color: colors.border, width: BorderTokens.widthThin),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: widget.items.map((item) {
              final isSelected = item.id == widget.selectedId;
              return Expanded(
                child: _BottomNavItem(
                  item: item,
                  isSelected: isSelected,
                  colors: colors,
                  onTap: () => widget.onItemSelected(item.id),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarNavigation(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = GlobalNavColors.from(colorExt);

    return AnimatedBuilder(
      animation: _collapseAnimation,
      builder: (context, child) {
        final width = _calculateWidth();
        final isCollapsed = _collapseAnimation.value > 0.5;

        return Container(
          width: width,
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(
              right: BorderSide(
                color: colors.border,
                width: BorderTokens.widthThin,
              ),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    vertical: spacingExt.medium,
                    horizontal: spacingExt.small,
                  ),
                  children: widget.items.map((item) {
                    final isSelected = item.id == widget.selectedId;
                    return _SidebarNavItem(
                      item: item,
                      isSelected: isSelected,
                      isCollapsed: isCollapsed,
                      collapseProgress: _collapseAnimation.value,
                      colors: colors,
                      spacing: spacingExt,
                      onTap: () => widget.onItemSelected(item.id),
                    );
                  }).toList(),
                ),
              ),
              if (widget.userInfo != null)
                _buildUserInfoArea(colors, spacingExt, isCollapsed),
            ],
          ),
        );
      },
    );
  }

  double _calculateWidth() {
    final expanded = widget.expandedWidth;
    final collapsed = widget.collapsedWidth;
    return expanded - (expanded - collapsed) * _collapseAnimation.value;
  }

  Widget _buildUserInfoArea(
    GlobalNavColors colors,
    AppSpacingExtension spacing,
    bool isCollapsed,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.medium),
      decoration: BoxDecoration(
        color: colors.userAreaBackground,
        border: Border(
          top: BorderSide(color: colors.border, width: BorderTokens.widthThin),
        ),
      ),
      child: isCollapsed ? Center(child: widget.userInfo!) : widget.userInfo!,
    );
  }
}

/// 하단 네비게이션 아이템
class _BottomNavItem extends StatelessWidget {
  final GlobalNavItem item;
  final bool isSelected;
  final GlobalNavColors colors;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.item,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = isSelected ? (item.activeIcon ?? item.icon) : item.icon;
    final color = isSelected ? colors.iconActive : colors.icon;
    final spacing = context.appSpacing;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: item.title,
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.xs,
            vertical: spacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: ComponentSizeTokens.iconMedium, color: color),
              SizedBox(height: spacing.xs),
              Text(
                item.title,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? colors.textActive : colors.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 사이드바 네비게이션 아이템
class _SidebarNavItem extends StatefulWidget {
  final GlobalNavItem item;
  final bool isSelected;
  final bool isCollapsed;
  final double collapseProgress;
  final GlobalNavColors colors;
  final AppSpacingExtension spacing;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.item,
    required this.isSelected,
    required this.isCollapsed,
    required this.collapseProgress,
    required this.colors,
    required this.spacing,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final icon = widget.isSelected
        ? (widget.item.activeIcon ?? widget.item.icon)
        : widget.item.icon;
    final iconColor = widget.isSelected
        ? widget.colors.iconActive
        : widget.colors.icon;
    final textColor = widget.isSelected
        ? widget.colors.textActive
        : widget.colors.text;

    final backgroundColor = widget.isSelected
        ? widget.colors.itemActive
        : _isHovered
        ? widget.colors.itemHover
        : Colors.transparent;

    Widget content = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          margin: EdgeInsets.symmetric(vertical: widget.spacing.xs),
          padding: EdgeInsets.symmetric(
            horizontal: widget.spacing.medium,
            vertical: widget.spacing.small,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: ComponentSizeTokens.iconMedium,
                color: iconColor,
              ),
              if (!widget.isCollapsed) ...[
                SizedBox(width: widget.spacing.medium),
                Expanded(
                  child: Opacity(
                    opacity: 1 - widget.collapseProgress,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.title,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: widget.isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.item.description != null)
                          Text(
                            widget.item.description!,
                            style: textTheme.bodySmall?.copyWith(
                              color: widget.colors.text,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.isCollapsed) {
      content = Tooltip(message: widget.item.title, child: content);
    }

    return Semantics(
      label: widget.item.title,
      button: true,
      selected: widget.isSelected,
      child: content,
    );
  }
}
