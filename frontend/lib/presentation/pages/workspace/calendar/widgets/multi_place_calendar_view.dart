import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/enums/calendar_view.dart';
import '../../../../../core/models/place/place_reservation.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../providers/place_calendar_provider.dart';
import '../../../calendar/calendar_week_grid_view.dart';
import '../../../calendar/widgets/calendar_month_with_sidebar.dart';

/// Multi-place calendar view showing reservations for selected places
/// Displays all reservations with place-specific colors
/// Supports both month and week views
class MultiPlaceCalendarView extends ConsumerWidget {
  final DateTime focusedDate;
  final DateTime? selectedDate;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDateSelected;
  final void Function(DateTime focusedDay) onPageChanged;
  final void Function(PlaceReservation reservation) onReservationTap;
  final CalendarView view;

  const MultiPlaceCalendarView({
    super.key,
    required this.focusedDate,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onPageChanged,
    required this.onReservationTap,
    this.view = CalendarView.month,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(placeCalendarProvider);
    final reservations = state.selectedPlaceReservations;

    // Week view
    if (view == CalendarView.week) {
      final weekStart = _getWeekStart(focusedDate);
      return CalendarWeekGridView<PlaceReservation>(
        events: reservations,
        weekStart: weekStart,
        onEventTap: onReservationTap,
      );
    }

    // Month view (default)
    return CalendarMonthWithSidebar<PlaceReservation>(
      events: reservations,
      focusedDate: focusedDate,
      selectedDate: selectedDate,
      onDateSelected: onDateSelected,
      onPageChanged: onPageChanged,
      onEventTap: onReservationTap,
      eventChipBuilder: (reservation) => _buildReservationChip(context, reservation),
      eventCardBuilder: (reservation) => _buildReservationCard(context, reservation),
    );
  }

  /// Get Monday of the week containing the given date
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1 (Monday) to 7 (Sunday)
    return date.subtract(Duration(days: weekday - 1));
  }

  /// Build custom reservation chip for calendar cells
  Widget _buildReservationChip(BuildContext context, PlaceReservation reservation) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: reservation.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: reservation.color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reservation.title,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.neutral900,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            reservation.placeName,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.neutral600,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  /// Build custom reservation card for sidebar list
  Widget _buildReservationCard(BuildContext context, PlaceReservation reservation) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightOutline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 60,
            decoration: BoxDecoration(
              color: reservation.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place, size: 14, color: AppColors.neutral600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        reservation.placeName,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.neutral600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: AppColors.neutral600),
                    const SizedBox(width: 4),
                    Text(
                      reservation.formattedTimeRange,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: AppColors.neutral600),
                    const SizedBox(width: 4),
                    Text(
                      reservation.reservedByName,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
