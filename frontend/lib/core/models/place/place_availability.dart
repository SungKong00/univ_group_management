import 'package:flutter/material.dart';

/// Enum representing days of the week (matches backend)
/// Names are in UPPERCASE to match backend API format
// ignore_for_file: constant_identifier_names
enum DayOfWeek {
  MONDAY,
  TUESDAY,
  WEDNESDAY,
  THURSDAY,
  FRIDAY,
  SATURDAY,
  SUNDAY,
}

/// Extension to get localized day name
extension DayOfWeekExt on DayOfWeek {
  String get displayName {
    switch (this) {
      case DayOfWeek.MONDAY:
        return '월요일';
      case DayOfWeek.TUESDAY:
        return '화요일';
      case DayOfWeek.WEDNESDAY:
        return '수요일';
      case DayOfWeek.THURSDAY:
        return '목요일';
      case DayOfWeek.FRIDAY:
        return '금요일';
      case DayOfWeek.SATURDAY:
        return '토요일';
      case DayOfWeek.SUNDAY:
        return '일요일';
    }
  }

  String get shortName {
    switch (this) {
      case DayOfWeek.MONDAY:
        return '월';
      case DayOfWeek.TUESDAY:
        return '화';
      case DayOfWeek.WEDNESDAY:
        return '수';
      case DayOfWeek.THURSDAY:
        return '목';
      case DayOfWeek.FRIDAY:
        return '금';
      case DayOfWeek.SATURDAY:
        return '토';
      case DayOfWeek.SUNDAY:
        return '일';
    }
  }
}

/// Place availability model representing time slots when a place is available
class PlaceAvailability {
  const PlaceAvailability({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.displayOrder,
  });

  final int id;
  final DayOfWeek dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int displayOrder;

  /// Parse time string from backend (format: "HH:mm:ss")
  static TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    if (parts.length < 2) {
      throw FormatException('Invalid time format: $time');
    }
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// Format TimeOfDay to backend format (format: "HH:mm:ss")
  static String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:00';
  }

  factory PlaceAvailability.fromJson(Map<String, dynamic> json) {
    return PlaceAvailability(
      id: (json['id'] as num).toInt(),
      dayOfWeek: DayOfWeek.values.byName(json['dayOfWeek'] as String),
      startTime: _parseTimeOfDay(json['startTime'] as String),
      endTime: _parseTimeOfDay(json['endTime'] as String),
      displayOrder: (json['displayOrder'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayOfWeek': dayOfWeek.name,
      'startTime': _formatTimeOfDay(startTime),
      'endTime': _formatTimeOfDay(endTime),
      'displayOrder': displayOrder,
    };
  }

  PlaceAvailability copyWith({
    int? id,
    DayOfWeek? dayOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? displayOrder,
  }) {
    return PlaceAvailability(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlaceAvailability && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PlaceAvailability(id: $id, dayOfWeek: $dayOfWeek, '
        'startTime: ${_formatTimeOfDay(startTime)}, '
        'endTime: ${_formatTimeOfDay(endTime)}, '
        'displayOrder: $displayOrder)';
  }
}

/// Request payload for creating or updating availability
class AvailabilityRequest {
  const AvailabilityRequest({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.displayOrder,
  });

  final DayOfWeek dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int displayOrder;

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek.name,
      'startTime': PlaceAvailability._formatTimeOfDay(startTime),
      'endTime': PlaceAvailability._formatTimeOfDay(endTime),
      'displayOrder': displayOrder,
    };
  }
}
