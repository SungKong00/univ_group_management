import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../domain/models/calendar_event_base.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';

/// Generic month calendar component with sidebar event list.
///
/// Features:
/// - Responsive layout: Row (wide screen) or Column (narrow screen)
/// - Calendar grid with date selection
/// - Event list sidebar showing selected date's events
/// - Customizable event rendering via builder callbacks
///
/// Type parameter T must extend CalendarEventBase interface.
class CalendarMonthWithSidebar<T extends CalendarEventBase> extends StatefulWidget {
  /// List of all events to display
  final List<T> events;

  /// Currently focused date (determines visible month)
  final DateTime focusedDate;

  /// Currently selected date (determines event list)
  final DateTime? selectedDate;

  /// Callback when user selects a date
  final void Function(DateTime selectedDay, DateTime focusedDay) onDateSelected;

  /// Callback when user changes month
  final void Function(DateTime focusedDay) onPageChanged;

  /// Callback when user taps an event
  final void Function(T event) onEventTap;

  /// Optional custom builder for event chip in calendar cell
  /// If null, uses default chip
  final Widget Function(T event)? eventChipBuilder;

  /// Optional custom builder for event card in sidebar list
  /// If null, uses default card
  final Widget Function(T event)? eventCardBuilder;

  const CalendarMonthWithSidebar({
    super.key,
    required this.events,
    required this.focusedDate,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onPageChanged,
    required this.onEventTap,
    this.eventChipBuilder,
    this.eventCardBuilder,
  });

  @override
  State<CalendarMonthWithSidebar<T>> createState() =>
      _CalendarMonthWithSidebarState<T>();
}

class _CalendarMonthWithSidebarState<T extends CalendarEventBase>
    extends State<CalendarMonthWithSidebar<T>> {
  /// Group events by date for efficient lookup
  Map<DateTime, List<T>> get eventsByDate {
    final map = <DateTime, List<T>>{};
    for (final event in widget.events) {
      final normalizedStart = _normalizeDate(event.startDateTime);
      final normalizedEnd = _normalizeDate(event.endDateTime);

      // Add event to all dates it spans
      var currentDate = normalizedStart;
      while (currentDate.isBefore(normalizedEnd) ||
          currentDate.isAtSameMomentAs(normalizedEnd)) {
        map.putIfAbsent(currentDate, () => []).add(event);
        currentDate = currentDate.add(const Duration(days: 1));
      }
    }
    return map;
  }

  /// Get events for selected date, sorted
  List<T> get selectedEvents {
    if (widget.selectedDate == null) return [];
    final events = eventsByDate[_normalizeDate(widget.selectedDate!)] ?? [];
    return _sortEventsForDay(events, widget.selectedDate!);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final textTheme = Theme.of(context).textTheme;
    final baseDowStyle = textTheme.labelMedium ??
        textTheme.bodyMedium ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
    final dowTextStyle = baseDowStyle.copyWith(
      color: AppColors.neutral500,
      fontWeight: FontWeight.w600,
    );

    // Calendar widget
    final calendarWidget = Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightOutline, width: 1),
      ),
      child: TableCalendar<T>(
        locale: 'ko_KR',
        firstDay: DateTime.utc(2000, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: widget.focusedDate,
        availableGestures: AvailableGestures.horizontalSwipe,
        headerVisible: false,
        rowHeight: 96,
        daysOfWeekHeight: 32,
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: dowTextStyle,
          weekendStyle: dowTextStyle.copyWith(color: AppColors.neutral600),
        ),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) => isSameDay(day, widget.selectedDate),
        onDaySelected: widget.onDateSelected,
        onPageChanged: widget.onPageChanged,
        eventLoader: (day) =>
            eventsByDate[_normalizeDate(day)] ?? <T>[],
        calendarStyle: const CalendarStyle(
          isTodayHighlighted: false,
          cellMargin: EdgeInsets.all(4),
          cellPadding: EdgeInsets.all(6),
          outsideDaysVisible: true,
          canMarkersOverflow: true,
        ),
        calendarBuilders: CalendarBuilders<T>(
          markerBuilder: (context, day, events) => const SizedBox.shrink(),
          defaultBuilder: (context, day, focusedDay) =>
              _buildDayCell(day, focusedDay, now),
          todayBuilder: (context, day, focusedDay) =>
              _buildDayCell(day, focusedDay, now),
          selectedBuilder: (context, day, focusedDay) =>
              _buildDayCell(day, focusedDay, now),
          outsideBuilder: (context, day, focusedDay) =>
              _buildDayCell(day, focusedDay, now),
        ),
      ),
    );

    // Event list widget
    final eventListWidget = Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightOutline, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          top: AppSpacing.sm,
          bottom: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.selectedDate != null
                  ? DateFormat('M월 d일 (E)', 'ko_KR')
                      .format(widget.selectedDate!)
                  : '날짜를 선택하세요',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: _buildEventList(),
            ),
          ],
        ),
      ),
    );

    // Responsive layout
    return LayoutBuilder(
      builder: (context, constraints) {
        // constraints가 무한인지 검증
        final hasFiniteWidth = !constraints.hasInfiniteWidth;
        final hasFiniteHeight = !constraints.hasInfiniteHeight;
        final isWideScreen = hasFiniteWidth && constraints.maxWidth >= 1024;

        if (isWideScreen) {
          // Wide screen: Row layout (calendar 70% + event list 30%)
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: calendarWidget,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: hasFiniteHeight ? constraints.maxHeight : double.infinity,
                  child: eventListWidget,
                ),
              ),
            ],
          );
        } else {
          // Narrow screen: Column layout
          return Column(
            children: [
              calendarWidget,
              const SizedBox(height: AppSpacing.sm),
              Expanded(child: eventListWidget),
            ],
          );
        }
      },
    );
  }

  /// Build day cell with events
  Widget _buildDayCell(DateTime day, DateTime focusedDay, DateTime now) {
    final events =
        eventsByDate[_normalizeDate(day)] ?? <T>[];
    final sortedEvents = _sortEventsForDay(events, day);

    final isToday = isSameDay(day, now);
    final isSelected = isSameDay(day, widget.selectedDate);
    final isOutsideMonth = day.month != focusedDay.month;

    final textTheme = Theme.of(context).textTheme;
    final borderColor = isSelected ? AppColors.brand : Colors.transparent;

    final dayTextStyle = textTheme.bodyMedium?.copyWith(
      fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
      color: isSelected
          ? AppColors.brandStrong
          : isOutsideMonth
              ? AppColors.neutral400
              : AppColors.neutral800,
    );

    Widget dayLabel = Text('${day.day}', style: dayTextStyle);

    if (isToday) {
      dayLabel = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.actionTonalBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: dayLabel,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      alignment: Alignment.topLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              dayLabel,
              if (sortedEvents.isNotEmpty) ...[
                const SizedBox(height: 4),
                for (var i = 0; i < sortedEvents.length; i++)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
                    child: widget.eventChipBuilder != null
                        ? widget.eventChipBuilder!(sortedEvents[i])
                        : _buildDefaultEventChip(sortedEvents[i]),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build event list for selected date
  Widget _buildEventList() {
    if (widget.selectedDate == null) {
      return Center(
        child: Text(
          '날짜를 선택하세요',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.neutral500,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (selectedEvents.isEmpty) {
      return Center(
        child: Text(
          '선택한 날짜에 일정이 없습니다.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.neutral500,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final event = selectedEvents[index];
        return SizedBox(
          height: 80, // 고정 높이 지정 (Sliver 에러 방지)
          child: InkWell(
            onTap: () => widget.onEventTap(event),
            child: widget.eventCardBuilder != null
                ? widget.eventCardBuilder!(event)
                : _buildDefaultEventCard(event),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemCount: selectedEvents.length,
    );
  }

  /// Default event chip builder (used in calendar cells)
  Widget _buildDefaultEventChip(T event) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: event.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: event.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        event.title,
        style: textTheme.labelSmall?.copyWith(
          color: AppColors.neutral800,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Default event card builder (used in sidebar list)
  Widget _buildDefaultEventCard(T event) {
    final textTheme = Theme.of(context).textTheme;
    final timeFormatter = DateFormat('HH:mm');
    final timeLabel = event.isAllDay
        ? '종일'
        : '${timeFormatter.format(event.startDateTime)} ~ ${timeFormatter.format(event.endDateTime)}';

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
            height: 48,
            decoration: BoxDecoration(
              color: event.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  timeLabel,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
                if (event.location != null && event.location!.isNotEmpty)
                  Text(
                    event.location!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Normalize date to midnight (for comparison)
  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Sort events for a specific day
  List<T> _sortEventsForDay(Iterable<T> events, DateTime day) {
    final sorted = events.toList()
      ..sort((a, b) => _compareEventsForDay(a, b, day));
    return sorted;
  }

  /// Compare events for sorting on a specific day
  int _compareEventsForDay(T a, T b, DateTime day) {
    final aStart = _effectiveStartForDay(a, day);
    final bStart = _effectiveStartForDay(b, day);
    final result = aStart.compareTo(bStart);
    if (result != 0) {
      return result;
    }
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  /// Get effective start time for an event on a specific day
  DateTime _effectiveStartForDay(T event, DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    if (event.startDateTime.isBefore(dayStart)) {
      return dayStart;
    }
    return event.startDateTime;
  }
}
