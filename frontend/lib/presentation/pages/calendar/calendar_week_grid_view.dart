import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/calendar_models.dart';
import '../../../core/theme/app_colors.dart';

/// Calendar week grid view that renders personal events in a timetable-like layout.
/// Similar to TimetableWeeklyView, but designed for calendar events (PersonalEvent).
///
/// Features:
/// - Displays events across 7 days (Mon-Sun) in a grid
/// - Time range: 06:00 - 24:00 (same as timetable)
/// - All-day events shown in a separate area above the grid
/// - Multi-day events split across date columns
/// - Highlights today with brand color
class CalendarWeekGridView extends StatelessWidget {
  const CalendarWeekGridView({
    super.key,
    required this.events,
    required this.weekStart,
    required this.onEventTap,
  });

  final List<PersonalEvent> events;
  final DateTime weekStart;
  final ValueChanged<PersonalEvent> onEventTap;

  static const int _minutesPerSlot = 30;
  static const double _slotHeight = 44;
  static const double _timeColumnWidth = 64;
  static const double _dayColumnMinWidth = 160;
  static const double _allDayAreaHeight = 80;

  /// Calculates the dynamic time range based on events.
  /// Returns (startHour, endHour) where:
  /// - Default: (9, 18) when no timed events exist
  /// - Expanded to fit all timed events (all-day events ignored)
  (int, int) _calculateTimeRange(List<PersonalEvent> events) {
    const minStart = 9;
    const minEnd = 18;

    // Filter out all-day events
    final timedEvents = events.where((e) => !e.isAllDay).toList();
    if (timedEvents.isEmpty) return (minStart, minEnd);

    int earliestHour = minStart;
    int latestHour = minEnd;

    for (var event in timedEvents) {
      final startHour = event.startDateTime.hour;
      final endHour = event.endDateTime.minute > 0
          ? event.endDateTime.hour + 1
          : event.endDateTime.hour;

      earliestHour = math.min(earliestHour, startHour);
      latestHour = math.max(latestHour, endHour);
    }

    return (earliestHour, math.max(latestHour, minEnd));
  }

  @override
  Widget build(BuildContext context) {
    final dayInfos = _buildDayInfos();
    final (startHour, endHour) = _calculateTimeRange(events);
    final totalMinutes = (endHour - startHour) * 60;
    final totalSlots = totalMinutes ~/ _minutesPerSlot;
    final totalHeight = totalSlots * _slotHeight;

    final gridWidth = _timeColumnWidth + dayInfos.length * _dayColumnMinWidth;

    final header = _buildHeaderRow(context, dayInfos);
    final allDayArea = _buildAllDayArea(context, dayInfos);
    final body = _buildBodyGrid(context, dayInfos, totalHeight, startHour, endHour);

    final grid = SizedBox(
      width: gridWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          if (allDayArea != null) allDayArea,
          body,
        ],
      ),
    );

    final horizontalController = ScrollController();
    final verticalController = ScrollController();

    return Scrollbar(
      controller: verticalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: verticalController,
        child: Scrollbar(
          controller: horizontalController,
          thumbVisibility: true,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: horizontalController,
            scrollDirection: Axis.horizontal,
            child: grid,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(
    BuildContext context,
    List<_DayInfo> dayInfos,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final today = DateTime.now();

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.lightOutline, width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: _timeColumnWidth),
          ...dayInfos.map((info) {
            final isToday = _isSameDate(info.date, today);
            final weekdayLabel = _getWeekdayShortLabel(info.date);
            return Container(
              width: _dayColumnMinWidth,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.lightOutline, width: 1),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$weekdayLabel (${info.date.day})',
                    style: textTheme.titleMedium?.copyWith(
                      color: isToday ? AppColors.brand : AppColors.neutral900,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('MM.dd (E)', 'ko_KR').format(info.date),
                    style: textTheme.bodySmall?.copyWith(
                      color: isToday ? AppColors.brand : AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget? _buildAllDayArea(
    BuildContext context,
    List<_DayInfo> dayInfos,
  ) {
    final hasAllDayEvents =
        dayInfos.any((info) => info.allDayEvents.isNotEmpty);
    if (!hasAllDayEvents) return null;

    return Container(
      height: _allDayAreaHeight,
      decoration: const BoxDecoration(
        color: AppColors.lightBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.lightOutline, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _timeColumnWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: 8, top: 8),
              child: Align(
                alignment: Alignment.topRight,
                child: Text(
                  '종일',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral500,
                      ),
                ),
              ),
            ),
          ),
          ...dayInfos.map((info) {
            return Container(
              width: _dayColumnMinWidth,
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.lightOutline, width: 1),
                ),
              ),
              child: info.allDayEvents.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: info.allDayEvents.map((event) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _buildAllDayEventCard(context, event),
                        );
                      }).toList(),
                    ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAllDayEventCard(BuildContext context, PersonalEvent event) {
    return GestureDetector(
      onTap: () => onEventTap(event),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: event.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: event.color.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Text(
          event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.neutral800,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  Widget _buildBodyGrid(
    BuildContext context,
    List<_DayInfo> dayInfos,
    double totalHeight,
    int startHour,
    int endHour,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.lightBackground,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeColumn(context, totalHeight, startHour, endHour),
          ...dayInfos
              .map((info) => _buildDayColumn(context, info, totalHeight, startHour, endHour)),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(BuildContext context, double totalHeight, int startHour, int endHour) {
    final textTheme = Theme.of(context).textTheme;
    final totalSlots = ((endHour - startHour) * 60) ~/ _minutesPerSlot;

    return SizedBox(
      width: _timeColumnWidth,
      height: totalHeight,
      child: Column(
        children: List.generate(totalSlots, (index) {
          final minutesFromStart = index * _minutesPerSlot;
          final isHourMark = minutesFromStart % 60 == 0;
          final hour = startHour + minutesFromStart ~/ 60;
          return SizedBox(
            height: _slotHeight,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 6),
                child: isHourMark
                    ? Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.neutral500,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayColumn(
    BuildContext context,
    _DayInfo info,
    double totalHeight,
    int startHour,
    int endHour,
  ) {
    final isToday = _isSameDate(info.date, DateTime.now());

    final background = isToday
        ? AppColors.brand.withValues(alpha: 0.04)
        : Colors.white;

    final totalMinutes = (endHour - startHour) * 60;

    return Container(
      width: _dayColumnMinWidth,
      height: totalHeight,
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.lightOutline, width: 1),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(color: background),
          ),
          _buildGridLines(totalMinutes),
          ...info.timedEvents.map((event) {
            return _buildEventBlock(context, event, info.date, totalMinutes, startHour);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGridLines(int totalMinutes) {
    final totalSlots = totalMinutes ~/ _minutesPerSlot;

    return Column(
      children: List.generate(totalSlots, (index) {
        final isHourLine = index % 2 == 0;
        return Container(
          height: _slotHeight,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isHourLine
                    ? AppColors.lightOutline
                    : AppColors.lightOutline.withValues(alpha: 0.35),
                width: isHourLine ? 1 : 0.5,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEventBlock(
    BuildContext context,
    PersonalEvent event,
    DateTime dayDate,
    int totalMinutes,
    int startHour,
  ) {
    final textTheme = Theme.of(context).textTheme;

    // Calculate effective start/end for this day only
    final dayStart = DateTime(dayDate.year, dayDate.month, dayDate.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final effectiveStart = event.startDateTime.isBefore(dayStart)
        ? dayStart
        : event.startDateTime;
    final effectiveEnd =
        event.endDateTime.isAfter(dayEnd) ? dayEnd : event.endDateTime;

    final startMinutesOfDay = effectiveStart.hour * 60 + effectiveStart.minute;
    final endMinutesOfDay = effectiveEnd.hour * 60 + effectiveEnd.minute;

    final startMinutes = math.max(0, startMinutesOfDay - startHour * 60);
    final endMinutes = math.min(totalMinutes, endMinutesOfDay - startHour * 60);
    final duration = math.max(endMinutes - startMinutes, _minutesPerSlot);

    final top = (startMinutes / _minutesPerSlot) * _slotHeight;
    final height = math.max((duration / _minutesPerSlot) * _slotHeight, 36.0);

    final timeFormatter = DateFormat('HH:mm');
    final timeLabel =
        '${timeFormatter.format(effectiveStart)} ~ ${timeFormatter.format(effectiveEnd)}';

    return Positioned(
      top: top,
      left: 8,
      right: 8,
      height: height,
      child: GestureDetector(
        onTap: () => onEventTap(event),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: event.color.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: event.color.withValues(alpha: 0.95),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: event.color.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                timeLabel,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              if (event.location != null && event.location!.trim().isNotEmpty)
                Text(
                  event.location!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<_DayInfo> _buildDayInfos() {
    final dayMap = <DateTime, _DayEventCollection>{};

    // Initialize all 7 days of the week
    for (int i = 0; i < 7; i++) {
      final date = DateUtils.addDaysToDate(weekStart, i);
      final normalizedDate = _normalizeDate(date);
      dayMap[normalizedDate] = _DayEventCollection(
        date: normalizedDate,
        allDayEvents: [],
        timedEvents: [],
      );
    }

    // Distribute events to days
    for (final event in events) {
      for (final entry in dayMap.entries) {
        if (event.occursOn(entry.key)) {
          if (event.isAllDay) {
            entry.value.allDayEvents.add(event);
          } else {
            entry.value.timedEvents.add(event);
          }
        }
      }
    }

    // Convert to list
    return dayMap.values
        .map((collection) => _DayInfo(
              date: collection.date,
              allDayEvents: collection.allDayEvents,
              timedEvents: collection.timedEvents,
            ))
        .toList();
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _getWeekdayShortLabel(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return '월';
      case DateTime.tuesday:
        return '화';
      case DateTime.wednesday:
        return '수';
      case DateTime.thursday:
        return '목';
      case DateTime.friday:
        return '금';
      case DateTime.saturday:
        return '토';
      case DateTime.sunday:
        return '일';
      default:
        return '';
    }
  }
}

class _DayEventCollection {
  _DayEventCollection({
    required this.date,
    required this.allDayEvents,
    required this.timedEvents,
  });

  final DateTime date;
  final List<PersonalEvent> allDayEvents;
  final List<PersonalEvent> timedEvents;
}

class _DayInfo {
  const _DayInfo({
    required this.date,
    required this.allDayEvents,
    required this.timedEvents,
  });

  final DateTime date;
  final List<PersonalEvent> allDayEvents;
  final List<PersonalEvent> timedEvents;
}
