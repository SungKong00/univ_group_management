import 'package:flutter/material.dart';
import '../../../../../data/models/calendar/calendar_event.dart';
import 'timeline_grid.dart';
import 'event_block.dart';

/// 주간 뷰 위젯
/// 7개 컬럼 (월~일), TimelineGrid + EventBlock 배치
class CalendarWeekView extends StatelessWidget {
  final DateTime weekStart; // 해당 주의 월요일
  final List<CalendarEvent> events;
  final Function(CalendarEvent) onEventTap;

  const CalendarWeekView({
    super.key,
    required this.weekStart,
    required this.events,
    required this.onEventTap,
  });

  static const List<String> weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 시간축 (고정)
                      SizedBox(width: 48, child: TimelineGrid()),
                      // 7개 요일 컬럼
                      Expanded(
                        child: Row(
                          children: List.generate(7, (index) {
                            final date = weekStart.add(Duration(days: index));
                            final dayEvents = _getEventsForDay(date);
                            return Expanded(
                              child: _buildDayColumn(date, dayEvents),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0)), // neutral300
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 48), // 시간축 영역
          ...List.generate(7, (index) {
            final date = weekStart.add(Duration(days: index));
            final isToday = _isToday(date);

            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Text(
                      weekdays[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isToday
                            ? const Color(0xFF6A1B9A) // brandPrimary
                            : const Color(0xFF757575), // neutral600
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isToday
                            ? const Color(0xFF6A1B9A) // brandPrimary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isToday
                              ? Colors.white
                              : const Color(0xFF212121), // neutral900
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayColumn(DateTime date, List<CalendarEvent> dayEvents) {
    final totalHours = TimelineGrid.endHour - TimelineGrid.startHour;
    final totalHeight = totalHours * TimelineGrid.hourHeight;

    // 겹치는 일정 감지
    final eventGroups = _detectOverlaps(dayEvents);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: totalHeight,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: const Color(0xFFE0E0E0), // neutral300
                width: 0.5,
              ),
            ),
          ),
          child: Stack(
            children: [
              // 시간 구분선 (1시간/30분)
              ...List.generate(totalHours * 2, (index) {
                final isHour = index % 2 == 0;
                final top = (index / 2) * TimelineGrid.hourHeight;

                return Positioned(
                  left: 0,
                  right: 0,
                  top: top,
                  child: Container(
                    height: 1,
                    color: isHour
                        ? const Color(0xFFE0E0E0) // neutral300
                        : const Color(0xFFF5F5F5), // neutral100 (더 연한 색)
                  ),
                );
              }),
              // 일정 블록
              ...eventGroups.expand((group) {
                final count = group.length;
                return group.asMap().entries.map((entry) {
                  final index = entry.key;
                  final event = entry.value;
                  final columnWidth = constraints.maxWidth;
                  final blockWidth = count > 1
                      ? (columnWidth - 8) / count
                      : columnWidth - 8;
                  final leftOffset = count > 1
                      ? (blockWidth + 4) * index.toDouble()
                      : 0.0;

                  return EventBlock(
                    event: event,
                    onTap: () => onEventTap(event),
                    width: blockWidth,
                    leftOffset: leftOffset,
                  );
                });
              }),
            ],
          ),
        );
      },
    );
  }

  List<CalendarEvent> _getEventsForDay(DateTime date) {
    return events.where((event) {
      return event.startTime.year == date.year &&
          event.startTime.month == date.month &&
          event.startTime.day == date.day;
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<List<CalendarEvent>> _detectOverlaps(List<CalendarEvent> dayEvents) {
    final List<List<CalendarEvent>> groups = [];
    final processed = <CalendarEvent>{};

    for (final event in dayEvents) {
      if (processed.contains(event)) continue;

      final group = <CalendarEvent>[event];
      processed.add(event);

      for (final other in dayEvents) {
        if (processed.contains(other)) continue;
        if (_isOverlapping(event, other) ||
            group.any((e) => _isOverlapping(e, other))) {
          group.add(other);
          processed.add(other);
        }
      }

      groups.add(group);
    }

    return groups;
  }

  bool _isOverlapping(CalendarEvent a, CalendarEvent b) {
    return a.startTime.isBefore(b.endTime) && a.endTime.isAfter(b.startTime);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
