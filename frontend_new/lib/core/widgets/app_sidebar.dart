import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/nav_sidebar_colors.dart';
import '../theme/enums.dart';
import '../theme/animation_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppSidebarStyle;

/// 사이드바 아이템 데이터
class AppSidebarItem {
  /// 아이템 제목
  final String title;

  /// 아이콘
  final IconData icon;

  /// 클릭 콜백
  final VoidCallback? onTap;

  /// 활성화 여부
  final bool isActive;

  /// 비활성화 여부
  final bool isDisabled;

  /// 배지 텍스트
  final String? badge;

  /// 툴팁 (컴팩트 모드용)
  final String? tooltip;

  const AppSidebarItem({
    required this.title,
    required this.icon,
    this.onTap,
    this.isActive = false,
    this.isDisabled = false,
    this.badge,
    this.tooltip,
  });
}

/// 사이드바 그룹 데이터
class AppSidebarGroup {
  /// 그룹 제목
  final String? title;

  /// 그룹 아이템 목록
  final List<AppSidebarItem> items;

  const AppSidebarGroup({this.title, required this.items});
}

/// 사이드바 컴포넌트
///
/// **용도**: 대시보드 네비게이션, 관리자 메뉴, 앱 주요 메뉴
/// **접근성**: 키보드 네비게이션, 스크린 리더 지원
///
/// ```dart
/// AppSidebar(
///   groups: [
///     AppSidebarGroup(
///       title: '메인',
///       items: [
///         AppSidebarItem(title: '홈', icon: Icons.home, isActive: true),
///         AppSidebarItem(title: '대시보드', icon: Icons.dashboard),
///       ],
///     ),
///   ],
/// )
/// ```
class AppSidebar extends StatefulWidget {
  /// 사이드바 그룹 목록
  final List<AppSidebarGroup> groups;

  /// 스타일
  final AppSidebarStyle style;

  /// 헤더 위젯
  final Widget? header;

  /// 푸터 위젯
  final Widget? footer;

  /// 확장 너비 (standard 모드)
  final double expandedWidth;

  /// 축소 너비 (compact 모드)
  final double collapsedWidth;

  /// 확장 상태 (expandable 모드용)
  final bool isExpanded;

  /// 확장 상태 변경 콜백
  final ValueChanged<bool>? onExpandedChanged;

  const AppSidebar({
    super.key,
    required this.groups,
    this.style = AppSidebarStyle.standard,
    this.header,
    this.footer,
    this.expandedWidth = 240,
    this.collapsedWidth = 72,
    this.isExpanded = true,
    this.onExpandedChanged,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  void didUpdateWidget(AppSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      _isExpanded = widget.isExpanded;
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onExpandedChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = NavSidebarColors.from(colorExt, widget.style);

    final isCompact =
        widget.style == AppSidebarStyle.compact ||
        (widget.style == AppSidebarStyle.expandable && !_isExpanded);

    final width = isCompact ? widget.collapsedWidth : widget.expandedWidth;

    return AnimatedContainer(
      duration: AnimationTokens.durationSmooth,
      width: width,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(right: BorderSide(color: colors.border, width: 1)),
      ),
      child: Column(
        children: [
          if (widget.header != null)
            _buildHeader(colors, spacingExt, isCompact),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: spacingExt.small),
              children: [
                for (final group in widget.groups)
                  _buildGroup(group, colors, spacingExt, isCompact),
              ],
            ),
          ),
          if (widget.style == AppSidebarStyle.expandable)
            _buildToggleButton(colors, spacingExt),
          if (widget.footer != null)
            _buildFooter(colors, spacingExt, isCompact),
        ],
      ),
    );
  }

  Widget _buildHeader(
    NavSidebarColors colors,
    AppSpacingExtension spacing,
    bool isCompact,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing.medium),
      decoration: BoxDecoration(
        color: colors.headerBackground,
        border: Border(bottom: BorderSide(color: colors.divider, width: 1)),
      ),
      child: isCompact ? Center(child: widget.header!) : widget.header!,
    );
  }

  Widget _buildFooter(
    NavSidebarColors colors,
    AppSpacingExtension spacing,
    bool isCompact,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing.medium),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.divider, width: 1)),
      ),
      child: isCompact ? Center(child: widget.footer!) : widget.footer!,
    );
  }

  Widget _buildGroup(
    AppSidebarGroup group,
    NavSidebarColors colors,
    AppSpacingExtension spacing,
    bool isCompact,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (group.title != null && !isCompact)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.medium,
              vertical: spacing.small,
            ),
            child: Text(
              group.title!.toUpperCase(),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        for (final item in group.items)
          _SidebarItemWidget(
            item: item,
            colors: colors,
            spacing: spacing,
            isCompact: isCompact,
          ),
        SizedBox(height: spacing.small),
      ],
    );
  }

  Widget _buildToggleButton(
    NavSidebarColors colors,
    AppSpacingExtension spacing,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.small),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.divider, width: 1)),
      ),
      child: IconButton(
        onPressed: _toggleExpanded,
        icon: AnimatedRotation(
          duration: AnimationTokens.durationQuick,
          turns: _isExpanded ? 0 : 0.5,
          child: Icon(Icons.chevron_left, color: colors.toggle),
        ),
        tooltip: _isExpanded ? '사이드바 접기' : '사이드바 펼치기',
      ),
    );
  }
}

/// 사이드바 아이템 위젯
class _SidebarItemWidget extends StatefulWidget {
  final AppSidebarItem item;
  final NavSidebarColors colors;
  final AppSpacingExtension spacing;
  final bool isCompact;

  const _SidebarItemWidget({
    required this.item,
    required this.colors,
    required this.spacing,
    required this.isCompact,
  });

  @override
  State<_SidebarItemWidget> createState() => _SidebarItemWidgetState();
}

class _SidebarItemWidgetState extends State<_SidebarItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colors = widget.colors;
    final spacing = widget.spacing;

    Widget itemWidget = Semantics(
      label: item.title,
      button: true,
      enabled: !item.isDisabled,
      child: MouseRegion(
        cursor: item.isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: item.isDisabled ? null : item.onTap,
          child: AnimatedContainer(
            duration: AnimationTokens.durationQuick,
            margin: EdgeInsets.symmetric(
              horizontal: spacing.small,
              vertical: spacing.labelDescriptionGap,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? spacing.small : spacing.medium,
              vertical: spacing.small,
            ),
            decoration: BoxDecoration(
              color: item.isActive
                  ? colors.itemActive
                  : _isHovered
                  ? colors.itemHover
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: widget.isCompact
                ? _buildCompactContent(item, colors)
                : _buildExpandedContent(item, colors, spacing),
          ),
        ),
      ),
    );

    if (widget.isCompact) {
      itemWidget = Tooltip(
        message: item.tooltip ?? item.title,
        child: itemWidget,
      );
    }

    return itemWidget;
  }

  Widget _buildCompactContent(AppSidebarItem item, NavSidebarColors colors) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          item.icon,
          size: 24,
          color: item.isActive
              ? colors.iconActive
              : item.isDisabled
              ? colors.icon.withValues(alpha: 0.5)
              : colors.icon,
        ),
        if (item.badge != null)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: colors.iconActive,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.badge!,
                style: TextStyle(
                  color: context.appColors.textOnBrand,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExpandedContent(
    AppSidebarItem item,
    NavSidebarColors colors,
    AppSpacingExtension spacing,
  ) {
    return Row(
      children: [
        Icon(
          item.icon,
          size: 20,
          color: item.isActive
              ? colors.iconActive
              : item.isDisabled
              ? colors.icon.withValues(alpha: 0.5)
              : colors.icon,
        ),
        SizedBox(width: spacing.small),
        Expanded(
          child: Text(
            item.title,
            style: TextStyle(
              color: item.isActive
                  ? colors.iconActive
                  : item.isDisabled
                  ? colors.text.withValues(alpha: 0.5)
                  : colors.text,
              fontSize: 14,
              fontWeight: item.isActive ? FontWeight.w600 : FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (item.badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colors.iconActive.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.badge!,
              style: TextStyle(
                color: colors.iconActive,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
