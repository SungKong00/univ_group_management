import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../providers/place_calendar_provider.dart';
import '../../../../widgets/weekly_calendar/duration_input_dialog.dart';

/// Popover content for place selection
/// Displays building categories with room chips for quick multi-selection
class PlaceSelectorPopover extends ConsumerWidget {
  final VoidCallback onClose;

  const PlaceSelectorPopover({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(placeCalendarProvider);
    final buildings = state.buildings.toList()..sort();

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(AppRadius.card),
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 500,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.neutral200,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, state),

            const Divider(height: 1),

            // Building categories with room chips
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (buildings.isEmpty)
                      _buildEmptyState(context)
                    else
                      ...buildings.map((building) {
                        final places = state.getPlacesForBuilding(building);
                        return _buildBuildingCategory(
                          context,
                          ref,
                          building,
                          places,
                          state.selectedPlaceIds,
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PlaceCalendarState state) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Text(
            '장소 선택',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          if (state.selectedPlaceIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(AppComponents.badgeRadius),
              ),
              child: Text(
                '${state.selectedPlaceIds.length}',
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const Spacer(),
          IconButton(
            tooltip: '닫기',
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 20),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingCategory(
    BuildContext context,
    WidgetRef ref,
    String building,
    List places,
    Set<int> selectedPlaceIds,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Building category header
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            building,
            style: AppTheme.titleMedium.copyWith(
              color: AppColors.neutral700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Room chips
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: places.map((place) {
            final isSelected = selectedPlaceIds.contains(place.id);
            return FilterChip(
              label: Text(place.displayName),
              selected: isSelected,
              onSelected: (_) async {
                final notifier = ref.read(placeCalendarProvider.notifier);
                final currentState = ref.read(placeCalendarProvider);
                final wasSelected = currentState.selectedPlaceIds.contains(place.id);

                if (wasSelected) {
                  notifier.deselectPlace(place.id);
                  // When returning to single-place mode, clear required duration
                  final remaining = currentState.selectedPlaceIds.length - 1;
                  if (remaining <= 1) {
                    notifier.clearRequiredDuration();
                  }
                  return;
                }

                final previousCount = currentState.selectedPlaceIds.length;
                notifier.selectPlace(place.id);

                // Ensure duration prompt only when moving into multi-place mode
                final updatedState = ref.read(placeCalendarProvider);
                final selectionCount = updatedState.selectedPlaceIds.length;
                final needsDuration =
                    selectionCount >= 2 && updatedState.requiredDuration == null;

                if (needsDuration) {
                  final duration = await showDialog<Duration>(
                    context: context,
                    builder: (ctx) => const DurationInputDialog(),
                  );

                  if (duration != null) {
                    notifier.setRequiredDuration(duration);
                  } else {
                    // Revert selection if user cancelled duration selection
                    notifier.deselectPlace(place.id);
                    if (previousCount <= 1) {
                      notifier.clearRequiredDuration();
                    }
                  }
                }
              },
              backgroundColor: AppColors.neutral100,
              selectedColor: AppColors.brandLight,
              checkmarkColor: AppColors.brand,
              labelStyle: AppTheme.bodySmall.copyWith(
                color: isSelected ? AppColors.brand : AppColors.neutral700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 8,
              ),
              visualDensity: VisualDensity.compact,
              showCheckmark: true,
            );
          }).toList(),
        ),

        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off,
              size: 48,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '등록된 장소가 없습니다',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
