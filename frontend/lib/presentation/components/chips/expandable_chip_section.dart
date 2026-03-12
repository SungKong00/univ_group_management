import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import './compact_chip.dart';

/// 확장 가능한 칩 섹션 컴포넌트
///
/// **용도**: 여러 선택 가능한 칩을 표시하고, 특정 개수를 초과하면 "더보기" 버튼으로 확장
///
/// **특징**:
/// - 초기에는 제한된 개수만 표시 (기본 6개)
/// - "더보기"/"접기" 버튼으로 전체 목록 토글
/// - Wrap 레이아웃으로 반응형 지원
/// - CompactChip 사용으로 일관된 디자인
///
/// **사용 예시**:
/// ```dart
/// ExpandableChipSection<GroupRole>(
///   items: roles,
///   selectedItems: selectedRoles,
///   itemLabel: (role) => role.name,
///   onSelectionChanged: (selected) => updateSelection(selected),
///   initialDisplayCount: 6,
/// )
/// ```
class ExpandableChipSection<T> extends StatefulWidget {
  /// 선택 가능한 항목 목록
  final List<T> items;

  /// 현재 선택된 항목 목록
  final List<T> selectedItems;

  /// 항목 → 라벨 변환 함수
  final String Function(T) itemLabel;

  /// 선택 변경 콜백 (전체 선택 목록 전달)
  final void Function(List<T>) onSelectionChanged;

  /// 초기 표시 개수 (기본값: 6)
  final int initialDisplayCount;

  /// "더보기" 버튼 텍스트 (기본값: "더보기")
  final String expandText;

  /// "접기" 버튼 텍스트 (기본값: "접기")
  final String collapseText;

  /// 활성화 여부
  final bool enabled;

  const ExpandableChipSection({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.itemLabel,
    required this.onSelectionChanged,
    this.initialDisplayCount = 6,
    this.expandText = '더보기',
    this.collapseText = '접기',
    this.enabled = true,
  });

  @override
  State<ExpandableChipSection<T>> createState() =>
      _ExpandableChipSectionState<T>();
}

class _ExpandableChipSectionState<T> extends State<ExpandableChipSection<T>> {
  bool _isExpanded = false;

  void _toggleItem(T item) {
    if (!widget.enabled) return;

    final updatedSelection = List<T>.from(widget.selectedItems);
    if (updatedSelection.contains(item)) {
      updatedSelection.remove(item);
    } else {
      updatedSelection.add(item);
    }
    widget.onSelectionChanged(updatedSelection);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: Text(
            '선택 가능한 항목이 없습니다',
            style: AppTheme.bodyMedium.copyWith(color: AppColors.neutral600),
          ),
        ),
      );
    }

    final shouldShowExpandButton =
        widget.items.length > widget.initialDisplayCount;
    final displayedItems = _isExpanded
        ? widget.items
        : widget.items.take(widget.initialDisplayCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip List
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topLeft,
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: displayedItems.map((item) {
              final isSelected = widget.selectedItems.contains(item);
              return CompactChip(
                label: widget.itemLabel(item),
                selected: isSelected,
                onTap: () => _toggleItem(item),
                enabled: widget.enabled,
              );
            }).toList(),
          ),
        ),

        // 더보기/접기 버튼
        if (shouldShowExpandButton) ...[
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            onTap: widget.enabled
                ? () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded
                        ? widget.collapseText
                        : '${widget.expandText} (${widget.items.length - widget.initialDisplayCount}개 더)',
                    style: AppTheme.bodySmall.copyWith(
                      color: widget.enabled
                          ? AppColors.action
                          : AppColors.neutral400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: widget.enabled
                        ? AppColors.action
                        : AppColors.neutral400,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
