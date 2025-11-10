import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/enums/calendar_view.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../providers/calendar_view_provider.dart';

/// Segmented button for selecting calendar view mode (day/week/month)
class CalendarViewSelector extends ConsumerWidget {
  const CalendarViewSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(calendarViewProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.neutral200, width: 1),
        ),
      ),
      child: Center(
        child: SegmentedButton<CalendarView>(
          segments: const [
            ButtonSegment<CalendarView>(
              value: CalendarView.week,
              label: Text('주간'),
            ),
            ButtonSegment<CalendarView>(
              value: CalendarView.month,
              label: Text('월간'),
            ),
          ],
          selected: {currentView},
          onSelectionChanged: (Set<CalendarView> newSelection) {
            ref.read(calendarViewProvider.notifier).setView(newSelection.first);
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.brand;
              }
              return Colors.white;
            }),
            foregroundColor: WidgetStateProperty.resolveWith<Color>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return AppColors.neutral700;
            }),
            side: WidgetStateProperty.all(
              BorderSide(color: AppColors.neutral300),
            ),
          ),
        ),
      ),
    );
  }
}
