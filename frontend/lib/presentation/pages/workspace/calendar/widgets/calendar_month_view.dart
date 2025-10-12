import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../../core/models/calendar/group_event.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../providers/focused_date_provider.dart';
import 'atoms/event_card.dart';

/// Month view widget for group calendar using table_calendar package.
///
/// Features:
/// - Calendar grid with inline event cards in each cell
/// - Scrollable event list per cell (max 3 visible)
/// - Official/Unofficial color-coded event cards
/// - Today/selected date highlighting
/// - Date navigation via focusedDateProvider
/// - Card tap opens event detail dialog
class CalendarMonthView extends ConsumerStatefulWidget {
  final List<GroupEvent> events;
  final Function(GroupEvent)? onEventTap;

  const CalendarMonthView({
    super.key,
    required this.events,
    this.onEventTap,
  });

  @override
  ConsumerState<CalendarMonthView> createState() => _CalendarMonthViewState();
}

class _CalendarMonthViewState extends ConsumerState<CalendarMonthView> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final focusedDate = ref.watch(focusedDateProvider);

    return TableCalendar<GroupEvent>(
      // Calendar range: 2020-01-01 ~ 2030-12-31
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime(2030, 12, 31),
      focusedDay: focusedDate,

      // Display settings
      calendarFormat: CalendarFormat.month,
      headerVisible: false, // We use custom DateNavigationHeader
      daysOfWeekVisible: true,

      // Date selection
      selectedDayPredicate: (day) {
        return _selectedDate != null && isSameDay(_selectedDate, day);
      },

      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDate = selectedDay;
        });

        // Update focused date in global state
        ref.read(focusedDateProvider.notifier).setDate(focusedDay);
      },

      // Event loading
      eventLoader: _getEventsForDay,

      // Styling
      calendarStyle: _buildCalendarStyle(),
      daysOfWeekStyle: _buildDaysOfWeekStyle(),

      // Custom cell builders
      calendarBuilders: CalendarBuilders<GroupEvent>(
        // Custom cell builder to show event cards inline
        defaultBuilder: (context, day, focusedDay) {
          return _buildDayCell(day, false, false);
        },
        selectedBuilder: (context, day, focusedDay) {
          return _buildDayCell(day, false, true);
        },
        todayBuilder: (context, day, focusedDay) {
          return _buildDayCell(day, true, false);
        },
        outsideBuilder: (context, day, focusedDay) {
          return _buildDayCell(day, false, false, isOutside: true);
        },
      ),
    );
  }

  /// Build custom day cell with inline event cards
  Widget _buildDayCell(
    DateTime day,
    bool isToday,
    bool isSelected, {
    bool isOutside = false,
  }) {
    final events = _getEventsForDay(day);

    // Determine text color and background
    Color textColor = AppColors.neutral900;
    Color? backgroundColor;
    FontWeight fontWeight = FontWeight.normal;

    // Border styling for selected date
    Color borderColor = AppColors.neutral300;
    double borderWidth = 0.5;

    if (isOutside) {
      textColor = AppColors.neutral500;
    } else if (isSelected) {
      backgroundColor = AppColors.brand;
      textColor = Colors.white;
      fontWeight = FontWeight.w600;
      // Emphasized border for selected date
      borderColor = AppColors.brandStrong;
      borderWidth = 2.5;
    } else if (isToday) {
      backgroundColor = AppColors.actionTonalBg;
      textColor = AppColors.brandStrong;
      fontWeight = FontWeight.w700; // Bold for today
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: isSelected || isToday ? BoxShape.rectangle : BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date number
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
          ),
          // Event cards list (scrollable)
          if (events.isNotEmpty)
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                itemCount: events.length,
                separatorBuilder: (context, index) => const SizedBox(height: 2),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return EventCard(
                    event: event,
                    onTap: () {
                      if (widget.onEventTap != null) {
                        widget.onEventTap!(event);
                      }
                    },
                  );
                },
              ),
            )
          else
            // Empty space for days without events
            const Expanded(child: SizedBox.shrink()),
        ],
      ),
    );
  }

  /// Get events for a specific day
  List<GroupEvent> _getEventsForDay(DateTime day) {
    return widget.events.where((event) => event.occursOn(day)).toList();
  }

  /// Build calendar style
  CalendarStyle _buildCalendarStyle() {
    return const CalendarStyle(
      // Cell shape and padding
      cellMargin: EdgeInsets.all(2),
      cellPadding: EdgeInsets.all(0),

      // Row height to accommodate multiple event cards
      rowDecoration: BoxDecoration(),

      // Hide default markers (we use custom cell builder)
      markerDecoration: BoxDecoration(color: Colors.transparent),
      markersMaxCount: 0,

      // Disable default today/selected decorations (we use custom builders)
      todayDecoration: BoxDecoration(color: Colors.transparent),
      selectedDecoration: BoxDecoration(color: Colors.transparent),
      todayTextStyle: TextStyle(color: Colors.transparent),
      selectedTextStyle: TextStyle(color: Colors.transparent),
    );
  }

  /// Build days of week style (Mon, Tue, Wed, ...)
  DaysOfWeekStyle _buildDaysOfWeekStyle() {
    return const DaysOfWeekStyle(
      weekdayStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.neutral700,
      ),
      weekendStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.neutral600,
      ),
    );
  }
}
