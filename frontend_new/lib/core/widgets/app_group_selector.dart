import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/group_selector_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';

/// 그룹 데이터
class GroupData {
  /// 그룹 ID
  final String id;

  /// 그룹 이름
  final String name;

  /// 부모 그룹 ID (최상위면 null)
  final String? parentId;

  /// 계층 레벨 (0부터 시작)
  final int level;

  const GroupData({
    required this.id,
    required this.name,
    this.parentId,
    this.level = 0,
  });
}

/// 그룹 선택기 컴포넌트
///
/// 계층적 그룹 목록을 드롭다운으로 표시합니다.
/// DFS 기반으로 부모-자식 관계를 유지하며 표시합니다.
///
/// **기능**:
/// - 계층적 그룹 표시 (들여쓰기로 레벨 표현)
/// - 현재 선택된 그룹 강조
/// - 그룹 선택 콜백
///
/// ```dart
/// AppGroupSelector(
///   groups: [
///     GroupData(id: '1', name: '한신대학교', level: 0),
///     GroupData(id: '2', name: 'AI/SW학부', parentId: '1', level: 1),
///     GroupData(id: '3', name: '컴퓨터공학과', parentId: '2', level: 2),
///   ],
///   selectedGroupId: '3',
///   onGroupSelected: (id) => print('Selected: $id'),
/// )
/// ```
class AppGroupSelector extends StatelessWidget {
  /// 그룹 목록 (이미 DFS 순서로 정렬되어 있어야 함)
  final List<GroupData> groups;

  /// 선택된 그룹 ID
  final String? selectedGroupId;

  /// 그룹 선택 콜백
  final ValueChanged<String> onGroupSelected;

  /// 최대 높이
  final double maxHeight;

  /// 너비
  final double width;

  const AppGroupSelector({
    super.key,
    required this.groups,
    this.selectedGroupId,
    required this.onGroupSelected,
    this.maxHeight = 300,
    this.width = 280,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = GroupSelectorColors.from(colorExt);

    return Container(
      width: width,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border, width: BorderTokens.widthThin),
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: spacingExt.small,
            offset: Offset(0, spacingExt.xs),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(vertical: spacingExt.small),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final isSelected = group.id == selectedGroupId;

            return _GroupItem(
              group: group,
              isSelected: isSelected,
              onTap: () => onGroupSelected(group.id),
              colors: colors,
              spacing: spacingExt,
            );
          },
        ),
      ),
    );
  }
}

/// 그룹 아이템 위젯
class _GroupItem extends StatefulWidget {
  final GroupData group;
  final bool isSelected;
  final VoidCallback onTap;
  final GroupSelectorColors colors;
  final AppSpacingExtension spacing;

  const _GroupItem({
    required this.group,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.spacing,
  });

  @override
  State<_GroupItem> createState() => _GroupItemState();
}

class _GroupItemState extends State<_GroupItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final backgroundColor = widget.isSelected
        ? widget.colors.itemActive
        : _isHovered
        ? widget.colors.itemHover
        : Colors.transparent;

    final textColor = widget.isSelected
        ? widget.colors.itemTextActive
        : widget.colors.itemText;

    // 레벨에 따른 들여쓰기
    final indentation = widget.group.level * widget.spacing.large;

    return Semantics(
      label: widget.group.name,
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
            padding: EdgeInsets.symmetric(
              horizontal: widget.spacing.medium,
              vertical: widget.spacing.small,
            ),
            color: backgroundColor,
            child: Row(
              children: [
                // 계층 인디케이터 (들여쓰기)
                if (widget.group.level > 0) ...[
                  SizedBox(width: indentation),
                  _buildHierarchyIndicator(),
                  SizedBox(width: widget.spacing.small),
                ],
                // 그룹 이름
                Expanded(
                  child: Text(
                    widget.group.name,
                    style: _getTextStyle(textTheme)?.copyWith(
                      color: textColor,
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 선택 체크 아이콘
                if (widget.isSelected)
                  Icon(
                    Icons.check,
                    size: ComponentSizeTokens.iconXSmall + 2,
                    color: widget.colors.checkIcon,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHierarchyIndicator() {
    return Container(
      width: widget.spacing.medium,
      height: widget.spacing.medium,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: widget.colors.hierarchyIndicator,
            width: BorderTokens.widthThin,
          ),
          bottom: BorderSide(
            color: widget.colors.hierarchyIndicator,
            width: BorderTokens.widthThin,
          ),
        ),
      ),
    );
  }

  TextStyle? _getTextStyle(TextTheme textTheme) {
    // 레벨이 깊을수록 폰트 크기 약간 감소
    return switch (widget.group.level) {
      0 => textTheme.bodyMedium,
      1 => textTheme.bodySmall,
      _ => textTheme.labelMedium,
    };
  }
}

/// 그룹 선택기를 오버레이로 표시하는 헬퍼
///
/// ```dart
/// showGroupSelector(
///   context: context,
///   anchorKey: _groupHeaderKey,
///   groups: myGroups,
///   selectedGroupId: currentGroupId,
///   onGroupSelected: (id) {
///     setState(() => currentGroupId = id);
///     Navigator.pop(context);
///   },
/// );
/// ```
void showGroupSelector({
  required BuildContext context,
  required GlobalKey anchorKey,
  required List<GroupData> groups,
  required String? selectedGroupId,
  required ValueChanged<String> onGroupSelected,
  double maxHeight = 300,
  double width = 280,
}) {
  final renderBox = anchorKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return;

  final offset = renderBox.localToGlobal(Offset.zero);
  final size = renderBox.size;
  final spacing = context.appSpacing;

  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) {
      return Stack(
        children: [
          // 외부 탭으로 닫기
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
          ),
          // 드롭다운
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height + spacing.xs,
            child: Material(
              color: Colors.transparent,
              child: AppGroupSelector(
                groups: groups,
                selectedGroupId: selectedGroupId,
                onGroupSelected: (id) {
                  onGroupSelected(id);
                  Navigator.pop(context);
                },
                maxHeight: maxHeight,
                width: width,
              ),
            ),
          ),
        ],
      );
    },
  );
}
