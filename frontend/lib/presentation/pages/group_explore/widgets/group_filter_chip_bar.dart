import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/group_explore/group_explore_filter_provider.dart';

/// Group Filter Chip Bar
///
/// Displays filter chips for recruitment status and group types.
class GroupFilterChipBar extends ConsumerWidget {
  const GroupFilterChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(groupExploreFilterProvider);
    final groupTypes = filter.groupTypes ?? [];

    return Wrap(
      spacing: AppSpacing.xxs,
      runSpacing: AppSpacing.xxs,
      children: [
        // Recruiting Filter
        FilterChip(
          label: const Text('모집중'),
          selected: filter.recruiting == true,
          onSelected: (selected) {
            ref.read(groupExploreFilterProvider.notifier).toggleRecruiting();
          },
          selectedColor: AppColors.brandLight,
          checkmarkColor: AppColors.brand,
          backgroundColor: AppColors.neutral100,
          labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: filter.recruiting == true
                    ? AppColors.brand
                    : AppColors.neutral700,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            side: BorderSide(
              color: filter.recruiting == true
                  ? AppColors.brand
                  : AppColors.neutral300,
            ),
          ),
        ),

        // University Group Filter (includes UNIVERSITY, COLLEGE, DEPARTMENT)
        FilterChip(
          label: const Text('대학그룹'),
          selected: groupTypes.contains('UNIVERSITY') ||
              groupTypes.contains('COLLEGE') ||
              groupTypes.contains('DEPARTMENT'),
          onSelected: (selected) {
            // Toggle all three types together
            final current = groupTypes.toList();
            if (selected) {
              if (!current.contains('UNIVERSITY')) current.add('UNIVERSITY');
              if (!current.contains('COLLEGE')) current.add('COLLEGE');
              if (!current.contains('DEPARTMENT')) current.add('DEPARTMENT');
            } else {
              current.removeWhere((type) =>
                  type == 'UNIVERSITY' || type == 'COLLEGE' || type == 'DEPARTMENT');
            }
            ref.read(groupExploreFilterProvider.notifier).updateFilter(
              (f) => f.copyWith(
                groupTypes: current.isEmpty ? null : current,
              ),
            );
          },
          selectedColor: AppColors.brandLight,
          checkmarkColor: AppColors.brand,
          backgroundColor: AppColors.neutral100,
          labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: (groupTypes.contains('UNIVERSITY') ||
                        groupTypes.contains('COLLEGE') ||
                        groupTypes.contains('DEPARTMENT'))
                    ? AppColors.brand
                    : AppColors.neutral700,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            side: BorderSide(
              color: (groupTypes.contains('UNIVERSITY') ||
                      groupTypes.contains('COLLEGE') ||
                      groupTypes.contains('DEPARTMENT'))
                  ? AppColors.brand
                  : AppColors.neutral300,
            ),
          ),
        ),

        // Autonomous Group Filter
        _buildGroupTypeChip(
          context,
          ref,
          label: '자율그룹',
          type: 'AUTONOMOUS',
          isSelected: groupTypes.contains('AUTONOMOUS'),
        ),

        // Official Group Filter
        _buildGroupTypeChip(
          context,
          ref,
          label: '공식그룹',
          type: 'OFFICIAL',
          isSelected: groupTypes.contains('OFFICIAL'),
        ),
      ],
    );
  }

  Widget _buildGroupTypeChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String type,
    required bool isSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        ref.read(groupExploreFilterProvider.notifier).toggleGroupType(type);
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
