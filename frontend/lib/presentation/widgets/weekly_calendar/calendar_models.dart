import 'package:flutter/material.dart';

// md 파일의 TimeRange 정의를 따름
@immutable
class TimeRange {
  final DateTime start;
  final DateTime end;

  const TimeRange({required this.start, required this.end});

  Duration get duration => end.difference(start);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

// md 파일의 CalendarEventBase 정의를 따름
abstract class CalendarEventBase {
  final String id;
  final TimeRange timeRange;

  CalendarEventBase({required this.id, required this.timeRange});
}
