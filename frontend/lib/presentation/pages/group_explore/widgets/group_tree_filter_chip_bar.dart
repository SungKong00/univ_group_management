import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/group_tree_state_provider.dart';

/// Group Tree Filter Chip Bar
///
/// Filter chips for hierarchical tree view (recruiting, autonomous, official groups).
/// University groups are always shown regardless of filters.
class GroupTreeFilterChipBar extends ConsumerWidget {
  const GroupTreeFilterChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(treeFiltersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xxs,
          runSpacing: AppSpacing.xxs,
          children: [
            // Recruiting Filter
            _buildFilterChip(
              context,
              ref,
              label: '모집중',
              filterKey: 'showRecruiting',
              isSelected: filters['showRecruiting'] == true,
            ),

            // Autonomous Group Filter
            _buildFilterChip(
              context,
              ref,
              label: '자율그룹',
              filterKey: 'showAutonomous',
              isSelected: filters['showAutonomous'] == true,
            ),

            // Official Group Filter
            _buildFilterChip(
              context,
              ref,
              label: '공식그룹',
              filterKey: 'showOfficial',
              isSelected: filters['showOfficial'] == true,
            ),
          ],
        ),
        // Info message
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '※ 대학그룹(대학교, 단과대, 학과)은 항상 표시됩니다',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.neutral500,
              ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String filterKey,
    required bool isSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        ref.read(groupTreeStateProvider.notifier).toggleFilter(filterKey);
      },
      selectedColor: AppColors.brandLight,
      checkmarkColor: AppColors.brand,
      backgroundColor: AppColors.neutral100,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected ? AppColors.brand : AppColors.neutral700,
          ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        side: BorderSide(
          color: isSelected ? AppColors.brand : AppColors.neutral300,
        ),
      ),
    );
  }
}
