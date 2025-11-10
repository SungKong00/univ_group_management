import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_colors.dart';

/// Compact month calendar widget for group home.
///
/// Features:
/// - Small month view (280px height)
/// - Event dots (max 3 dots per day)
/// - Click-through navigation to full calendar
/// - Minimal design for dashboard
class CompactMonthCalendar extends StatelessWidget {
  /// Currently focused date (determines visible month)
  final DateTime focusedDate;

  /// Currently selected date
  final DateTime? selectedDate;

  /// Callback when user selects a date
  final void Function(DateTime selectedDay, DateTime focusedDay)?
  onDateSelected;

  /// Callback when user changes month
  final void Function(DateTime focusedDay)? onPageChanged;

  /// Map of dates to event colors (for dot display)
  /// Key: normalized date (midnight), Value: list of event colors
  final Map<DateTime, List<Color>> eventColorsByDate;

  /// Callback when user taps a date with events
  final void Function(DateTime date)? onEventDateTap;

  /// Callback when user taps anywhere on the calendar (for navigation to full calendar)
  final VoidCallback? onCalendarTap;

  const CompactMonthCalendar({
    super.key,
    required this.focusedDate,
    this.selectedDate,
    this.onDateSelected,
    this.onPageChanged,
    this.eventColorsByDate = const {},
    this.onEventDateTap,
    this.onCalendarTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final textTheme = Theme.of(context).textTheme;

    // Day of week style (smaller font)
    final baseDowStyle =
        textTheme.labelSmall ??
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w500);
    final dowTextStyle = baseDowStyle.copyWith(
      color: AppColors.neutral500,
      fontWeight: FontWeight.w600,
    );

    final calendarWidget = Column(
      children: [
        // Month header with navigation arrows
        _buildMonthHeader(context),
        const SizedBox(height: 4), // Reduced from AppSpacing.xs (12px) to 4px
        // Compact calendar grid
        TableCalendar<void>(
          locale: 'ko_KR',
          firstDay: DateTime.utc(2000, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: focusedDate,
          availableGestures: AvailableGestures.horizontalSwipe,
          headerVisible: false,
          rowHeight: 36, // Reduced from 38px to 36px
          daysOfWeekHeight: 20, // Reduced from 24px to 20px
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: dowTextStyle,
            weekendStyle: dowTextStyle.copyWith(color: AppColors.neutral600),
          ),
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          selectedDayPredicate: (day) => isSameDay(day, selectedDate),
          onDaySelected: (selectedDay, focusedDay) {
            // If date has events and onEventDateTap is provided, navigate
            final normalizedDate = _normalizeDate(selectedDay);
            if (eventColorsByDate.containsKey(normalizedDate) &&
                onEventDateTap != null) {
              onEventDateTap!(selectedDay);
            } else if (onDateSelected != null) {
              onDateSelected!(selectedDay, focusedDay);
            }
          },
          onPageChanged: onPageChanged,
          calendarStyle: const CalendarStyle(
            isTodayHighlighted: false,
            cellMargin: EdgeInsets.all(2),
            cellPadding: EdgeInsets.zero,
            outsideDaysVisible: true,
          ),
          calendarBuilders: CalendarBuilders<void>(
            defaultBuilder: (context, day, focusedDay) =>
                _buildDayCell(day, focusedDay, now, textTheme),
            todayBuilder: (context, day, focusedDay) =>
                _buildDayCell(day, focusedDay, now, textTheme),
            selectedBuilder: (context, day, focusedDay) =>
                _buildDayCell(day, focusedDay, now, textTheme),
            outsideBuilder: (context, day, focusedDay) =>
                _buildDayCell(day, focusedDay, now, textTheme),
          ),
        ),
      ],
    );

    // Wrap with GestureDetector if onCalendarTap is provided
    if (onCalendarTap != null) {
      return GestureDetector(
        onTap: onCalendarTap,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: calendarWidget,
        ),
      );
    }

    return calendarWidget;
  }

  /// Build month header with navigation
  Widget _buildMonthHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final monthName = _getMonthName(focusedDate.month);
    final year = focusedDate.year;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Month & Year display
        Text(
          '$year년 $monthName',
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.lightOnSurface,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Navigation arrows
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Previous month
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                final prevMonth = DateTime(
                  focusedDate.year,
                  focusedDate.month - 1,
                  1,
                );
                onPageChanged?.call(prevMonth);
              },
            ),
            const SizedBox(width: 4),
            // Next month
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                final nextMonth = DateTime(
                  focusedDate.year,
                  focusedDate.month + 1,
                  1,
                );
                onPageChanged?.call(nextMonth);
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Build individual day cell with event dots
  Widget _buildDayCell(
    DateTime day,
    DateTime focusedDay,
    DateTime now,
    TextTheme textTheme,
  ) {
    final isToday = isSameDay(day, now);
    final isSelected = isSameDay(day, selectedDate);
    final isOutsideMonth = day.month != focusedDay.month;

    // Get event colors for this day
    final normalizedDate = _normalizeDate(day);
    final eventColors = eventColorsByDate[normalizedDate] ?? [];

    // Text style
    final dayTextStyle = textTheme.bodySmall?.copyWith(
      fontSize: 13,
      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
      color: isSelected
          ? AppColors.brandStrong
          : isOutsideMonth
          ? AppColors.neutral400
          : AppColors.neutral800,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: AppColors.brand, width: 1.5)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Day number
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.actionTonalBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${day.day}', style: dayTextStyle),
            )
          else
            Text('${day.day}', style: dayTextStyle),

          const SizedBox(height: 3),

          // Event dots (max 3)
          if (eventColors.isNotEmpty) _buildEventDots(eventColors),
        ],
      ),
    );
  }

  /// Build event dots indicator (max 3 dots)
  Widget _buildEventDots(List<Color> eventColors) {
    // Show max 3 dots
    final displayColors = eventColors.take(3).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: displayColors.asMap().entries.map((entry) {
        final index = entry.key;
        final color = entry.value;

        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 2),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        );
      }).toList(),
    );
  }

  /// Normalize date to midnight (for comparison)
  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Get Korean month name
  String _getMonthName(int month) {
    const monthNames = [
      '1월',
      '2월',
      '3월',
      '4월',
      '5월',
      '6월',
      '7월',
      '8월',
      '9월',
      '10월',
      '11월',
      '12월',
    ];
    return monthNames[month - 1];
  }
}
