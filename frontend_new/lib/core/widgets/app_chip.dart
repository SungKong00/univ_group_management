import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/chip_colors.dart';
import '../theme/enums.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';
import '../theme/responsive_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppChipType, AppChipSize;

/// 태그, 필터, 선택 항목을 표시하는 Chip 컴포넌트
///
/// **용도**: 라벨, 필터 선택, 입력된 값 표시
/// **접근성**: 최소 터치 영역 보장, 포커스 상태 표시
///
/// ```dart
/// // 필터 칩
/// AppChip(
///   label: '진행중',
///   type: AppChipType.filter,
///   isSelected: _selectedFilter == 'progress',
///   onTap: () => setState(() => _selectedFilter = 'progress'),
/// )
///
/// // 입력 칩 (삭제 가능)
/// AppChip(
///   label: 'Flutter',
///   type: AppChipType.input,
///   onDelete: () => _removeTag('Flutter'),
/// )
///
/// // 아이콘 포함 칩
/// AppChip(
///   label: '중요',
///   leadingIcon: Icons.star,
///   type: AppChipType.filter,
///   isSelected: true,
/// )
/// ```
class AppChip extends StatefulWidget {
  /// 칩 라벨
  final String label;

  /// 칩 타입 (filter, input, suggestion)
  final AppChipType type;

  /// 칩 크기
  final AppChipSize size;

  /// 선택 상태
  final bool isSelected;

  /// 비활성화 상태
  final bool isDisabled;

  /// 탭 콜백
  final VoidCallback? onTap;

  /// 삭제 콜백 (input 타입에서 사용)
  final VoidCallback? onDelete;

  /// 선행 아이콘
  final IconData? leadingIcon;

  /// 커스텀 색상 (기본: 타입별 자동)
  final Color? customColor;

  const AppChip({
    super.key,
    required this.label,
    this.type = AppChipType.filter,
    this.size = AppChipSize.medium,
    this.isSelected = false,
    this.isDisabled = false,
    this.onTap,
    this.onDelete,
    this.leadingIcon,
    this.customColor,
  });

  @override
  State<AppChip> createState() => _AppChipState();
}

class _AppChipState extends State<AppChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final colors = ChipColors.from(colorExt, widget.type);

    // 사이즈별 스타일
    final (paddingH, paddingV, iconSize) = switch (widget.size) {
      AppChipSize.small => (
        spacingExt.small,
        spacingExt.xs,
        ResponsiveTokens.iconSize(width) - 2,
      ),
      AppChipSize.medium => (
        spacingExt.medium,
        spacingExt.xs,
        ResponsiveTokens.iconSize(width),
      ),
    };

    // 상태별 색상
    final backgroundColor = widget.isDisabled
        ? colors.background.withValues(alpha: 0.5)
        : widget.isSelected
        ? colors.backgroundSelected
        : _isHovered
        ? colors.backgroundHover
        : colors.background;

    final textColor = widget.isDisabled
        ? colors.text.withValues(alpha: 0.5)
        : widget.isSelected
        ? colors.textSelected
        : widget.customColor ?? colors.text;

    final borderColor = widget.isDisabled
        ? colors.border.withValues(alpha: 0.5)
        : widget.isSelected
        ? colors.borderSelected
        : colors.border;

    return Semantics(
      label: widget.label,
      selected: widget.isSelected,
      enabled: !widget.isDisabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.isDisabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: AnimationTokens.durationQuick,
            padding: EdgeInsets.symmetric(
              horizontal: paddingH,
              vertical: paddingV,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(
                color: borderColor,
                width: BorderTokens.widthThin,
              ),
              borderRadius: BorderTokens.roundRadius(),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Leading icon
                if (widget.leadingIcon != null) ...[
                  Icon(widget.leadingIcon, size: iconSize, color: textColor),
                  SizedBox(width: spacingExt.componentIconGap / 2),
                ],

                // Label
                Text(
                  widget.label,
                  style: textTheme.bodySmall?.copyWith(
                    color: textColor,
                    fontWeight: widget.isSelected
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),

                // Delete icon (input type)
                if (widget.type == AppChipType.input &&
                    widget.onDelete != null) ...[
                  SizedBox(width: spacingExt.componentIconGap / 2),
                  GestureDetector(
                    onTap: widget.isDisabled ? null : widget.onDelete,
                    child: Icon(
                      Icons.close,
                      size: iconSize - 2,
                      color: colors.deleteIcon,
                    ),
                  ),
                ],

                // Checkmark (filter type, selected)
                if (widget.type == AppChipType.filter && widget.isSelected) ...[
                  SizedBox(width: spacingExt.componentIconGap / 2),
                  Icon(Icons.check, size: iconSize - 2, color: textColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip 그룹 (선택형)
///
/// ```dart
/// AppChipGroup(
///   chips: ['전체', '진행중', '완료', '취소'],
///   selectedIndex: _selectedIndex,
///   onSelected: (index) => setState(() => _selectedIndex = index),
/// )
/// ```
class AppChipGroup extends StatelessWidget {
  /// 칩 라벨 목록
  final List<String> chips;

  /// 선택된 인덱스 (null = 선택 없음)
  final int? selectedIndex;

  /// 선택 콜백
  final ValueChanged<int>? onSelected;

  /// 칩 타입
  final AppChipType type;

  /// 칩 크기
  final AppChipSize size;

  /// 칩 사이 간격
  final double spacing;

  /// 다중 선택 허용
  final bool allowMultiple;

  /// 다중 선택 시 선택된 인덱스 목록
  final Set<int>? selectedIndices;

  /// 다중 선택 콜백
  final ValueChanged<Set<int>>? onMultiSelected;

  const AppChipGroup({
    super.key,
    required this.chips,
    this.selectedIndex,
    this.onSelected,
    this.type = AppChipType.filter,
    this.size = AppChipSize.medium,
    this.spacing = 8.0, // spacingExt.small과 동일
    this.allowMultiple = false,
    this.selectedIndices,
    this.onMultiSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (int i = 0; i < chips.length; i++)
          AppChip(
            label: chips[i],
            type: type,
            size: size,
            isSelected: allowMultiple
                ? (selectedIndices?.contains(i) ?? false)
                : selectedIndex == i,
            onTap: () {
              if (allowMultiple) {
                final newSet = Set<int>.from(selectedIndices ?? {});
                if (newSet.contains(i)) {
                  newSet.remove(i);
                } else {
                  newSet.add(i);
                }
                onMultiSelected?.call(newSet);
              } else {
                onSelected?.call(i);
              }
            },
          ),
      ],
    );
  }
}
