import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/group_models.dart';
import '../providers/group_explore_state_provider.dart';

/// Group Filter Chip Bar
///
/// Displays filter chips for recruitment status and group types.
class GroupFilterChipBar extends ConsumerWidget {
  const GroupFilterChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(exploreFiltersProvider);
    final groupTypes = (filters['groupTypes'] as List<String>?) ?? [];

    return Wrap(
      spacing: AppSpacing.xxs,
      runSpacing: AppSpacing.xxs,
      children: [
        // Recruiting Filter
        FilterChip(
          label: const Text('모집중'),
          selected: filters['recruiting'] == true,
          onSelected: (selected) {
            ref.read(groupExploreStateProvider.notifier).updateFilter(
                  'recruiting',
                  selected ? true : null,
                );
          },
          selectedColor: AppColors.brandLight,
          checkmarkColor: AppColors.brand,
          backgroundColor: AppColors.neutral100,
          labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: filters['recruiting'] == true
                    ? AppColors.brand
                    : AppColors.neutral700,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            side: BorderSide(
              color: filters['recruiting'] == true
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
            final newFilters = Map<String, dynamic>.from(ref.read(exploreFiltersProvider));
            final currentTypes = List<String>.from((newFilters['groupTypes'] as List<String>?) ?? []);

            if (selected) {
              // Add all university-related types
              if (!currentTypes.contains('UNIVERSITY')) currentTypes.add('UNIVERSITY');
              if (!currentTypes.contains('COLLEGE')) currentTypes.add('COLLEGE');
              if (!currentTypes.contains('DEPARTMENT')) currentTypes.add('DEPARTMENT');
            } else {
              // Remove all university-related types
              currentTypes.removeWhere((type) =>
                  type == 'UNIVERSITY' || type == 'COLLEGE' || type == 'DEPARTMENT');
            }

            newFilters['groupTypes'] = currentTypes;
            ref.read(groupExploreStateProvider.notifier).updateFilter(
                  'groupTypes',
                  currentTypes.isEmpty ? null : currentTypes,
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
        ref.read(groupExploreStateProvider.notifier).toggleGroupType(type);
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
