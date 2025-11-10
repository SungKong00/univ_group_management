import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/calendar_event_base.dart';

/// Enum representing days of the week aligned with backend string values.
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

extension DayOfWeekX on DayOfWeek {
  static DayOfWeek fromApi(String value) {
    final normalized = value.toUpperCase();
    return DayOfWeek.values.firstWhere(
      (day) => day.apiValue == normalized,
      orElse: () => DayOfWeek.monday,
    );
  }

  String get apiValue => name.toUpperCase();

  String get shortLabel {
    switch (this) {
      case DayOfWeek.monday:
        return '월';
      case DayOfWeek.tuesday:
        return '화';
      case DayOfWeek.wednesday:
        return '수';
      case DayOfWeek.thursday:
        return '목';
      case DayOfWeek.friday:
        return '금';
      case DayOfWeek.saturday:
        return '토';
      case DayOfWeek.sunday:
        return '일';
    }
  }

  /// Returns a localized label such as "월요일".
  String get longLabel => '$shortLabel요일';

  /// Helper to align with [DateTime.weekday] where Monday is 1.
  int get weekdayNumber => index + 1;

  /// Returns the date within the provided [weekStart] that matches this day.
  DateTime toDateInWeek(DateTime weekStart) =>
      DateUtils.addDaysToDate(weekStart, index);
}

/// Domain model for personal weekly schedules.
class PersonalSchedule {
  const PersonalSchedule({
    required this.id,
    required this.title,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.color,
  });

  final int id;
  final String title;
  final DayOfWeek dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? location;
  final Color color;

  factory PersonalSchedule.fromJson(Map<String, dynamic> json) {
    return PersonalSchedule(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      dayOfWeek: DayOfWeekX.fromApi(json['dayOfWeek'] as String),
      startTime: _parseTime(json['startTime'] as String),
      endTime: _parseTime(json['endTime'] as String),
      location: json['location'] as String?,
      color: _parseColor(json['color'] as String? ?? '#3B82F6'),
    );
  }

  PersonalSchedule copyWith({
    int? id,
    String? title,
    DayOfWeek? dayOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? location,
    Color? color,
  }) {
    return PersonalSchedule(
      id: id ?? this.id,
      title: title ?? this.title,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      color: color ?? this.color,
    );
  }

  String get colorHex => _colorToHex(color);

  int get startMinutes => _minutesSinceMidnight(startTime);

  int get endMinutes => _minutesSinceMidnight(endTime);

  int get durationMinutes => endMinutes - startMinutes;

  String get formattedTimeRange =>
      '${_timeFormat.format(_timeOfDayToDate(startTime))} ~ ${_timeFormat.format(_timeOfDayToDate(endTime))}';
}

/// Payload used for create/update mutations.
class PersonalScheduleRequest {
  PersonalScheduleRequest({
    required this.title,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.color,
  });

  final String title;
  final DayOfWeek dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? location;
  final Color color;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'dayOfWeek': dayOfWeek.apiValue,
      'startTime': _formatTime(startTime),
      'endTime': _formatTime(endTime),
      'location': location?.trim().isEmpty == true ? null : location,
      'color': _colorToHex(color),
    };
  }
}

/// Default color palette (5 options) defined in the MVP spec.
/// 개인 일정용 색상 팔레트 (흰색 텍스트와 충분한 대비 확보)
const List<Color> kPersonalScheduleColors = [
  Color(0xFF1D4ED8), // Blue 700 (UI/UX actionPrimary)
  Color(0xFFDC2626), // Red 600
  Color(0xFF059669), // Green 600
  Color(0xFFD97706), // Orange 600
  Color(0xFF5C068C), // Brand Purple
];

final DateFormat _timeFormat = DateFormat('HH:mm');

TimeOfDay _parseTime(String value) {
  final parts = value.split(':');
  if (parts.length < 2) {
    throw FormatException('Invalid time format', value);
  }
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  return TimeOfDay(hour: hour, minute: minute);
}

String _formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

Color _parseColor(String hex) {
  final normalized = hex.replaceAll('#', '');
  final value = int.parse(normalized, radix: 16);
  return Color(0xFF000000 | value);
}

String _colorToHex(Color color) =>
    '#'
    '${(color.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

int _minutesSinceMidnight(TimeOfDay value) => value.hour * 60 + value.minute;

DateTime _timeOfDayToDate(TimeOfDay time) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, time.hour, time.minute);
}

/// Personal calendar event (단발성 일정) representation.
class PersonalEvent implements CalendarEventBase {
  const PersonalEvent({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.startDateTime,
    required this.endDateTime,
    required this.isAllDay,
    required this.color,
  });

  @override
  final int id;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String? location;
  @override
  final DateTime startDateTime;
  @override
  final DateTime endDateTime;
  @override
  final bool isAllDay;
  @override
  final Color color;

  factory PersonalEvent.fromJson(Map<String, dynamic> json) {
    return PersonalEvent(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startDateTime: DateTime.parse(json['startDateTime'] as String),
      endDateTime: DateTime.parse(json['endDateTime'] as String),
      isAllDay: json['isAllDay'] as bool? ?? false,
      color: _parseColor(json['color'] as String? ?? '#3B82F6'),
    );
  }

  PersonalEvent copyWith({
    int? id,
    String? title,
    String? description,
    String? location,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? isAllDay,
    Color? color,
  }) {
    return PersonalEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      isAllDay: isAllDay ?? this.isAllDay,
      color: color ?? this.color,
    );
  }

  @override
  Duration get duration => endDateTime.difference(startDateTime);

  @override
  bool occursOn(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    return startDateTime.isBefore(dayEnd) && endDateTime.isAfter(dayStart);
  }
}

class PersonalEventRequest {
  PersonalEventRequest({
    required this.title,
    this.description,
    this.location,
    required this.startDateTime,
    required this.endDateTime,
    this.isAllDay = false,
    required this.color,
  });

  final String title;
  final String? description;
  final String? location;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isAllDay;
  final Color color;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description?.trim().isEmpty == true ? null : description,
      'location': location?.trim().isEmpty == true ? null : location,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'isAllDay': isAllDay,
      'color': _colorToHex(color),
    };
  }
}
