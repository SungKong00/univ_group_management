import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../common/app_empty_state.dart';

/// Bottom sheet for selecting groups to display in calendar
///
/// Features:
/// - List of available groups with checkboxes
/// - Multi-select support
/// - Real-time state updates
/// - Draggable sheet for better UX
/// - Loading/error state display
/// - Retry mechanism for failed loads
///
/// Design System:
/// - AppTheme.headlineSmall for title
/// - AppTheme.bodyMedium for group names
/// - CheckboxListTile for consistent checkbox styling
/// - DraggableScrollableSheet for responsive sizing
class GroupPickerBottomSheet extends StatefulWidget {
  /// List of all available groups user can select from
  final List<({int id, String name})> availableGroups;

  /// Currently selected group IDs
  final Set<int> selectedGroupIds;

  /// Callback when selection changes (passes groupId and new selected state)
  final Function(int groupId, bool selected) onChanged;

  /// Loading state for group list
  final bool isLoading;

  /// Error message for failed group load
  final String? errorMessage;

  /// Callback to retry loading groups
  final VoidCallback? onRetry;

  const GroupPickerBottomSheet({
    super.key,
    required this.availableGroups,
    required this.selectedGroupIds,
    required this.onChanged,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  State<GroupPickerBottomSheet> createState() => _GroupPickerBottomSheetState();
}

class _GroupPickerBottomSheetState extends State<GroupPickerBottomSheet> {
  late Set<int> _localSelectedIds;

  @override
  void initState() {
    super.initState();
    // Create local copy of selected IDs for immediate UI updates
    _localSelectedIds = Set.from(widget.selectedGroupIds);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text('그룹 선택', style: AppTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),

            // Loading state
            if (widget.isLoading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: AppSpacing.sm),
                      Text('그룹 목록 불러오는 중...'),
                    ],
                  ),
                ),
              )
            // Error state
            else if (widget.errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '그룹 목록을 불러올 수 없습니다',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.errorMessage!,
                      style: AppTheme.bodySmall.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (widget.onRetry != null)
                      ElevatedButton.icon(
                        onPressed: widget.onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 시도'),
                      ),
                  ],
                ),
              )
            // Empty state
            else if (widget.availableGroups.isEmpty)
              AppEmptyState.noGroups()
            // Group list
            else
              ...widget.availableGroups.map((group) {
                final isSelected = _localSelectedIds.contains(group.id);

                return CheckboxListTile(
                  title: Text(group.name, style: AppTheme.bodyMedium),
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _localSelectedIds.add(group.id);
                      } else {
                        _localSelectedIds.remove(group.id);
                      }
                    });

                    // Notify parent immediately
                    widget.onChanged(group.id, checked ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxs,
                    vertical: 0,
                  ),
                );
              }),

            const SizedBox(height: AppSpacing.md),

            // Done button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              ),
              child: const Text('완료'),
            ),
          ],
        ),
      ),
    );
  }
}
