import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Header widget for displaying selected groups with event counts
///
/// Features:
/// - Display list of selected groups with color indicators
/// - Show event count per group
/// - Loading state per group (spinner)
/// - Error state per group (error icon + retry)
/// - Add/Remove group actions
///
/// Design System:
/// - AppTheme.titleMedium for header
/// - AppTheme.bodySmall for chip labels
/// - AppSpacing.sm/xs for consistent spacing
/// - Chip component with avatar color indicator
class GroupSelectionHeader extends StatelessWidget {
  /// List of selected groups with id, name, and color
  final List<({int id, String name, Color color})> selectedGroups;

  /// Map of event counts per group ID
  final Map<int, int> eventCounts;

  /// Map of loading states per group ID
  final Map<int, bool> loadingByGroup;

  /// Map of error messages per group ID
  final Map<int, String?> errorByGroup;

  /// Callback when add group button is pressed
  final VoidCallback onAddGroupPressed;

  /// Callback when remove group button is pressed (passes group ID)
  final Function(int groupId) onRemoveGroupPressed;

  /// Callback when retry button is pressed for a group with error
  final Function(int groupId) onRetryPressed;

  const GroupSelectionHeader({
    super.key,
    required this.selectedGroups,
    required this.eventCounts,
    required this.loadingByGroup,
    required this.errorByGroup,
    required this.onAddGroupPressed,
    required this.onRemoveGroupPressed,
    required this.onRetryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Selected group chips (left side)
        Expanded(
          child: selectedGroups.isEmpty
              ? Text(
                  '선택된 그룹이 없습니다',
                  style: AppTheme.bodySmall.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
                )
              : Wrap(
                  spacing: AppSpacing.xxs,
                  runSpacing: AppSpacing.xxs,
                  children: selectedGroups.map((group) {
                    final isLoading = loadingByGroup[group.id] ?? false;
                    final error = errorByGroup[group.id];
                    final eventCount = eventCounts[group.id] ?? 0;

                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: group.color,
                        radius: 6,
                      ),
                      label: Text(
                        '${group.name} ($eventCount개)',
                        style: AppTheme.bodySmall,
                      ),
                      deleteIcon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : error != null
                              ? Tooltip(
                                  message: '재시도: $error',
                                  child: const Icon(Icons.error_outline, size: 16),
                                )
                              : Tooltip(
                                  message: '제거',
                                  child: const Icon(Icons.close, size: 16),
                                ),
                      onDeleted: error != null
                          ? () => onRetryPressed(group.id)
                          : () => onRemoveGroupPressed(group.id),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // Add button (right side, compact)
        OutlinedButton.icon(
          onPressed: onAddGroupPressed,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('추가', style: TextStyle(fontSize: 13)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
