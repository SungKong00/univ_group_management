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

    return Wrap(
      spacing: AppSpacing.xxs,
      runSpacing: AppSpacing.xxs,
      children: [
        // Recruiting Filter
        FilterChip(
          label: const Text('모집중'),
          selected: filters['isRecruiting'] == true,
          onSelected: (selected) {
            ref.read(groupExploreStateProvider.notifier).updateFilter(
                  'isRecruiting',
                  selected ? true : null,
                );
          },
          selectedColor: AppColors.brandLight,
          checkmarkColor: AppColors.brand,
          backgroundColor: AppColors.neutral100,
          labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: filters['isRecruiting'] == true
                    ? AppColors.brand
                    : AppColors.neutral700,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            side: BorderSide(
              color: filters['isRecruiting'] == true
                  ? AppColors.brand
                  : AppColors.neutral300,
            ),
          ),
        ),

        // Autonomous Group Filter
        FilterChip(
          label: const Text('자율그룹'),
          selected: filters['groupType'] == 'AUTONOMOUS',
          onSelected: (selected) {
            ref.read(groupExploreStateProvider.notifier).updateFilter(
                  'groupType',
                  selected ? 'AUTONOMOUS' : null,
                );
          },
          selectedColor: AppColors.brandLight,
          checkmarkColor: AppColors.brand,
          backgroundColor: AppColors.neutral100,
          labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: filters['groupType'] == 'AUTONOMOUS'
                    ? AppColors.brand
                    : AppColors.neutral700,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            side: BorderSide(
              color: filters['groupType'] == 'AUTONOMOUS'
                  ? AppColors.brand
                  : AppColors.neutral300,
            ),
          ),
        ),

        // Official Group Filter
        FilterChip(
          label: const Text('공식그룹'),
          selected: filters['groupType'] == 'OFFICIAL',
          onSelected: (selected) {
            ref.read(groupExploreStateProvider.notifier).updateFilter(
                  'groupType',
                  selected ? 'OFFICIAL' : null,
                );
          },
          selectedColor: AppColors.brandLight,
          checkmarkColor: AppColors.brand,
          backgroundColor: AppColors.neutral100,
          labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: filters['groupType'] == 'OFFICIAL'
                    ? AppColors.brand
                    : AppColors.neutral700,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            side: BorderSide(
              color: filters['groupType'] == 'OFFICIAL'
                  ? AppColors.brand
                  : AppColors.neutral300,
            ),
          ),
        ),
      ],
    );
  }
}
