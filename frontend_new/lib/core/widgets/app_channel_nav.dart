import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/channel_nav_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';

/// 채널 아이템 데이터
class ChannelItem {
  /// 채널 ID
  final String id;

  /// 채널 이름
  final String name;

  /// 채널 아이콘
  final IconData icon;

  /// 미읽음 개수
  final int unreadCount;

  const ChannelItem({
    required this.id,
    required this.name,
    this.icon = Icons.tag,
    this.unreadCount = 0,
  });
}

/// 채널 섹션 데이터
class ChannelSection {
  /// 섹션 ID
  final String id;

  /// 섹션 제목 (null이면 제목 없음)
  final String? title;

  /// 섹션 아이템 목록
  final List<ChannelItem> items;

  /// 섹션 접기/펼치기 가능 여부
  final bool collapsible;

  const ChannelSection({
    required this.id,
    this.title,
    required this.items,
    this.collapsible = false,
  });
}

/// 채널 네비게이션 컴포넌트
///
/// 워크스페이스 내 채널 목록을 표시하는 사이드바입니다.
///
/// **기능**:
/// - 그룹 헤더 (드롭다운으로 그룹 선택)
/// - 섹션별 채널 목록 (그룹 메뉴, 채널, 관리자 메뉴)
/// - 채널별 미읽음 배지
/// - 슬라이드 인 애니메이션
///
/// ```dart
/// AppChannelNav(
///   groupName: '컴퓨터공학과',
///   groupRole: '멤버',
///   sections: [
///     ChannelSection(
///       id: 'menu',
///       title: '그룹 메뉴',
///       items: [
///         ChannelItem(id: 'home', name: '그룹 홈', icon: Icons.home),
///         ChannelItem(id: 'calendar', name: '캘린더', icon: Icons.calendar_today),
///       ],
///     ),
///     ChannelSection(
///       id: 'channels',
///       title: '채널',
///       items: [
///         ChannelItem(id: '1', name: '일반', icon: Icons.tag, unreadCount: 5),
///         ChannelItem(id: '2', name: '공지사항', icon: Icons.campaign),
///       ],
///     ),
///   ],
///   selectedChannelId: '1',
///   onChannelSelected: (id) => print('Selected channel: $id'),
///   onGroupTap: () => showGroupDropdown(),
/// )
/// ```
class AppChannelNav extends StatefulWidget {
  /// 그룹 이름
  final String groupName;

  /// 사용자 역할 (멤버, 관리자 등)
  final String? groupRole;

  /// 섹션 목록
  final List<ChannelSection> sections;

  /// 선택된 채널 ID
  final String? selectedChannelId;

  /// 채널 선택 콜백
  final ValueChanged<String> onChannelSelected;

  /// 그룹 헤더 탭 콜백
  final VoidCallback? onGroupTap;

  /// 너비
  final double width;

  /// 슬라이드 인 애니메이션 활성화
  final bool enableSlideAnimation;

  const AppChannelNav({
    super.key,
    required this.groupName,
    this.groupRole,
    required this.sections,
    this.selectedChannelId,
    required this.onChannelSelected,
    this.onGroupTap,
    this.width = 240,
    this.enableSlideAnimation = true,
  });

  @override
  State<AppChannelNav> createState() => _AppChannelNavState();
}

class _AppChannelNavState extends State<AppChannelNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: AnimationTokens.durationSmooth,
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideController,
            curve: AnimationTokens.curveSmooth,
          ),
        );

    if (widget.enableSlideAnimation) {
      _slideController.forward();
    } else {
      _slideController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = ChannelNavColors.from(colorExt);

    Widget content = Container(
      width: widget.width,
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
          _GroupHeader(
            groupName: widget.groupName,
            groupRole: widget.groupRole,
            onTap: widget.onGroupTap,
            colors: colors,
            spacing: spacingExt,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: spacingExt.small),
              children: [
                for (final section in widget.sections)
                  _ChannelSection(
                    section: section,
                    selectedChannelId: widget.selectedChannelId,
                    onChannelSelected: widget.onChannelSelected,
                    colors: colors,
                    spacing: spacingExt,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.enableSlideAnimation) {
      content = SlideTransition(position: _slideAnimation, child: content);
    }

    return content;
  }
}

/// 그룹 헤더
class _GroupHeader extends StatefulWidget {
  final String groupName;
  final String? groupRole;
  final VoidCallback? onTap;
  final ChannelNavColors colors;
  final AppSpacingExtension spacing;

  const _GroupHeader({
    required this.groupName,
    this.groupRole,
    this.onTap,
    required this.colors,
    required this.spacing,
  });

  @override
  State<_GroupHeader> createState() => _GroupHeaderState();
}

class _GroupHeaderState extends State<_GroupHeader> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: '${widget.groupName} 그룹',
      button: widget.onTap != null,
      child: MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AnimationTokens.durationQuick,
            padding: EdgeInsets.all(widget.spacing.medium),
            decoration: BoxDecoration(
              color: _isHovered
                  ? widget.colors.itemHover
                  : widget.colors.headerBackground,
              border: Border(
                bottom: BorderSide(
                  color: widget.colors.divider,
                  width: BorderTokens.widthThin,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.groupName,
                        style: textTheme.titleSmall?.copyWith(
                          color: widget.colors.headerText,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.groupRole != null) ...[
                        SizedBox(height: widget.spacing.labelDescriptionGap),
                        Text(
                          widget.groupRole!,
                          style: textTheme.bodySmall?.copyWith(
                            color: widget.colors.headerTextSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.onTap != null)
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: ComponentSizeTokens.iconSmall,
                    color: widget.colors.dropdownIcon,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 채널 섹션
class _ChannelSection extends StatefulWidget {
  final ChannelSection section;
  final String? selectedChannelId;
  final ValueChanged<String> onChannelSelected;
  final ChannelNavColors colors;
  final AppSpacingExtension spacing;

  const _ChannelSection({
    required this.section,
    this.selectedChannelId,
    required this.onChannelSelected,
    required this.colors,
    required this.spacing,
  });

  @override
  State<_ChannelSection> createState() => _ChannelSectionState();
}

class _ChannelSectionState extends State<_ChannelSection> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.section.title != null) _buildSectionHeader(),
        if (!_isCollapsed)
          for (final item in widget.section.items)
            _ChannelItemWidget(
              item: item,
              isSelected: item.id == widget.selectedChannelId,
              onTap: () => widget.onChannelSelected(item.id),
              colors: widget.colors,
              spacing: widget.spacing,
            ),
        SizedBox(height: widget.spacing.small),
      ],
    );
  }

  Widget _buildSectionHeader() {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.spacing.medium,
        vertical: widget.spacing.small,
      ),
      child: Row(
        children: [
          if (widget.section.collapsible)
            GestureDetector(
              onTap: () => setState(() => _isCollapsed = !_isCollapsed),
              child: Icon(
                _isCollapsed ? Icons.chevron_right : Icons.keyboard_arrow_down,
                size: ComponentSizeTokens.iconXSmall,
                color: widget.colors.sectionTitle,
              ),
            ),
          if (widget.section.collapsible) SizedBox(width: widget.spacing.xs),
          Text(
            widget.section.title!.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: widget.colors.sectionTitle,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// 채널 아이템 위젯
class _ChannelItemWidget extends StatefulWidget {
  final ChannelItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final ChannelNavColors colors;
  final AppSpacingExtension spacing;

  const _ChannelItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.spacing,
  });

  @override
  State<_ChannelItemWidget> createState() => _ChannelItemWidgetState();
}

class _ChannelItemWidgetState extends State<_ChannelItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final backgroundColor = widget.isSelected
        ? widget.colors.itemActive
        : _isHovered
        ? widget.colors.itemHover
        : widget.colors.itemBackground;

    final iconColor = widget.isSelected
        ? widget.colors.itemIconActive
        : widget.colors.itemIcon;

    final textColor = widget.isSelected
        ? widget.colors.itemTextActive
        : widget.colors.itemText;

    return Semantics(
      label: widget.item.name,
      button: true,
      selected: widget.isSelected,
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
              horizontal: widget.spacing.small,
              vertical: widget.spacing.small,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(
                  widget.item.icon,
                  size: ComponentSizeTokens.iconXSmall + 2,
                  color: iconColor,
                ),
                SizedBox(width: widget.spacing.small),
                Expanded(
                  child: Text(
                    widget.item.name,
                    style: textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: widget.isSelected
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.item.unreadCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.spacing.small,
                      vertical: widget.spacing.labelDescriptionGap,
                    ),
                    decoration: BoxDecoration(
                      color: widget.colors.badgeBackground,
                      borderRadius: BorderRadius.circular(
                        BorderTokens.radiusRound,
                      ),
                    ),
                    child: Text(
                      widget.item.unreadCount > 99
                          ? '99+'
                          : widget.item.unreadCount.toString(),
                      style: textTheme.labelSmall?.copyWith(
                        color: widget.colors.badgeText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
