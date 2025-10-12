import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/calendar_models.dart';
import '../../../../core/theme/app_colors.dart';

/// Weekly timetable grid that renders personal schedules in a 30-minute interval layout.
class TimetableWeeklyView extends StatelessWidget {
  const TimetableWeeklyView({
    super.key,
    required this.schedules,
    required this.weekStart,
    required this.onScheduleTap,
  });

  final List<PersonalSchedule> schedules;
  final DateTime weekStart;
  final ValueChanged<PersonalSchedule> onScheduleTap;

  static const int _minutesPerSlot = 30;
  static const double _slotHeight = 44;
  static const double _timeColumnWidth = 64;
  static const double _dayColumnMinWidth = 160;

  /// Calculates the dynamic time range based on schedules.
  /// Returns (startHour, endHour) where:
  /// - Default: (9, 18) when no schedules exist
  /// - Expanded to fit all schedules
  (int, int) _calculateTimeRange(List<PersonalSchedule> schedules) {
    const minStart = 9;
    const minEnd = 18;

    if (schedules.isEmpty) return (minStart, minEnd);

    int earliestHour = minStart;
    int latestHour = minEnd;

    for (var schedule in schedules) {
      final startHour = schedule.startMinutes ~/ 60;
      final endMinutes = schedule.endMinutes;
      final endHour = endMinutes % 60 > 0
          ? (endMinutes ~/ 60) + 1
          : endMinutes ~/ 60;

      earliestHour = math.min(earliestHour, startHour);
      latestHour = math.max(latestHour, endHour);
    }

    return (earliestHour, math.max(latestHour, minEnd));
  }

  @override
  Widget build(BuildContext context) {
    final dayInfos = _buildDayInfos();
    final (startHour, endHour) = _calculateTimeRange(schedules);
    final totalMinutes = (endHour - startHour) * 60;
    final totalSlots = totalMinutes ~/ _minutesPerSlot;
    final totalHeight = totalSlots * _slotHeight;

    final gridWidth =
        _timeColumnWidth + dayInfos.length * _dayColumnMinWidth;

    final header = _buildHeaderRow(context, dayInfos);
    final body = _buildBodyGrid(context, dayInfos, totalHeight, startHour, endHour);

    final grid = SizedBox(
      width: gridWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
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
            final label = '${info.day.shortLabel} (${info.date.day})';
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
                    label,
                    style: textTheme.titleMedium?.copyWith(
                      color: isToday ? AppColors.brand : AppColors.neutral900,
                      fontWeight:
                          isToday ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('MM.dd (E)', 'ko_KR').format(info.date),
                    style: textTheme.bodySmall?.copyWith(
                      color: isToday
                          ? AppColors.brand
                          : AppColors.neutral600,
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
          ...dayInfos.map((info) => _buildDayColumn(context, info, totalHeight, startHour, endHour)),
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
          ...info.schedules.map((schedule) {
            return _buildScheduleBlock(context, schedule, totalMinutes, startHour);
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

  Widget _buildScheduleBlock(
    BuildContext context,
    PersonalSchedule schedule,
    int totalMinutes,
    int startHour,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final startMinutes = math.max(
      0,
      schedule.startMinutes - startHour * 60,
    );
    final endMinutes = math.min(
      totalMinutes,
      schedule.endMinutes - startHour * 60,
    );
    final duration = math.max(endMinutes - startMinutes, _minutesPerSlot);

    final top = (startMinutes / _minutesPerSlot) * _slotHeight;
    final height = math.max(
      (duration / _minutesPerSlot) * _slotHeight,
      36.0,
    );

    return Positioned(
      top: top,
      left: 8,
      right: 8,
      height: height,
      child: GestureDetector(
        onTap: () => onScheduleTap(schedule),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: schedule.color.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: schedule.color.withValues(alpha: 0.95),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: schedule.color.withValues(alpha: 0.25),
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
                schedule.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                schedule.formattedTimeRange,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              if (schedule.location != null &&
                  schedule.location!.trim().isNotEmpty)
                Text(
                  schedule.location!,
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
    final map = <DayOfWeek, List<PersonalSchedule>>{
      for (final day in DayOfWeek.values) day: [],
    };
    for (final schedule in schedules) {
      map[schedule.dayOfWeek]?.add(schedule);
    }

    return List.generate(DayOfWeek.values.length, (index) {
      final day = DayOfWeek.values[index];
      final date = DateUtils.addDaysToDate(weekStart, index);
      final daySchedules = map[day]?.toList() ?? [];
      return _DayInfo(day: day, date: date, schedules: daySchedules);
    });
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayInfo {
  const _DayInfo({
    required this.day,
    required this.date,
    required this.schedules,
  });

  final DayOfWeek day;
  final DateTime date;
  final List<PersonalSchedule> schedules;
}
