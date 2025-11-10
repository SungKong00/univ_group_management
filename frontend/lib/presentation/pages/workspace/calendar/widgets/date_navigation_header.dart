import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/enums/calendar_view.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../providers/calendar_view_provider.dart';
import '../../../../providers/focused_date_provider.dart';

/// Navigation header for calendar date control
/// Displays current date period and provides navigation controls
class DateNavigationHeader extends ConsumerWidget {
  const DateNavigationHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedDate = ref.watch(focusedDateProvider);
    final currentView = ref.watch(calendarViewProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.neutral200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Previous button
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _onPrevious(ref, currentView),
            tooltip: '이전',
          ),

          // Date text
          Expanded(
            child: Center(
              child: Text(
                _formatDateText(focusedDate, currentView),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // Next button
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _onNext(ref, currentView),
            tooltip: '다음',
          ),

          const SizedBox(width: AppSpacing.xs),

          // Today button
          SizedBox(
            width: 80,
            height: 40,
            child: OutlinedButton(
              onPressed: () {
                ref.read(focusedDateProvider.notifier).resetToToday();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                side: BorderSide(color: AppColors.brand),
                foregroundColor: AppColors.brand,
              ),
              child: const Text('오늘'),
            ),
          ),
        ],
      ),
    );
  }

  void _onPrevious(WidgetRef ref, CalendarView view) {
    final notifier = ref.read(focusedDateProvider.notifier);
    switch (view) {
      case CalendarView.week:
        notifier.previousWeek(); // Move by 7 days
        break;
      case CalendarView.month:
        notifier.previous(1); // Move by months
        break;
    }
  }

  void _onNext(WidgetRef ref, CalendarView view) {
    final notifier = ref.read(focusedDateProvider.notifier);
    switch (view) {
      case CalendarView.week:
        notifier.nextWeek(); // Move by 7 days
        break;
      case CalendarView.month:
        notifier.next(1); // Move by months
        break;
    }
  }

  String _formatDateText(DateTime date, CalendarView view) {
    switch (view) {
      case CalendarView.week:
        // Week view: Show week start ~ end
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        if (weekStart.month == weekEnd.month) {
          return '${DateFormat('yyyy년 M월', 'ko_KR').format(weekStart)} '
              '${weekStart.day}일 ~ ${weekEnd.day}일';
        } else {
          return '${DateFormat('M월 d일', 'ko_KR').format(weekStart)} ~ '
              '${DateFormat('M월 d일', 'ko_KR').format(weekEnd)}';
        }
      case CalendarView.month:
        return DateFormat('yyyy년 M월', 'ko_KR').format(date);
    }
  }
}
