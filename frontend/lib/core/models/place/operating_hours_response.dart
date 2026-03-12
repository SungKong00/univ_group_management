import 'package:flutter/material.dart';
import 'place_availability.dart'; // For DayOfWeek enum

/// Operating hours response model representing when a place is open
/// (New consolidated model replacing PlaceAvailability)
///
/// - Single time slot per day of week (not multiple slots)
/// - isClosed: true if the place is closed on this day
/// - Use PlaceRestrictedTime for prohibited times within operating hours (e.g., lunch breaks)
class OperatingHoursResponse {
  const OperatingHoursResponse({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isClosed,
  });

  final int id;
  final DayOfWeek dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isClosed;

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

  factory OperatingHoursResponse.fromJson(Map<String, dynamic> json) {
    return OperatingHoursResponse(
      id: (json['id'] as num).toInt(),
      dayOfWeek: DayOfWeek.values.byName(json['dayOfWeek'] as String),
      startTime: _parseTimeOfDay(json['startTime'] as String),
      endTime: _parseTimeOfDay(json['endTime'] as String),
      isClosed: json['isClosed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayOfWeek': dayOfWeek.name,
      'startTime': _formatTimeOfDay(startTime),
      'endTime': _formatTimeOfDay(endTime),
      'isClosed': isClosed,
    };
  }

  OperatingHoursResponse copyWith({
    int? id,
    DayOfWeek? dayOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isClosed,
  }) {
    return OperatingHoursResponse(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isClosed: isClosed ?? this.isClosed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OperatingHoursResponse && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'OperatingHoursResponse(id: $id, dayOfWeek: $dayOfWeek, '
        'startTime: ${_formatTimeOfDay(startTime)}, '
        'endTime: ${_formatTimeOfDay(endTime)}, '
        'isClosed: $isClosed)';
  }
}
