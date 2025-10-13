import 'package:flutter/material.dart';

import '../../../domain/models/calendar_event_base.dart';

/// Place reservation model representing a scheduled booking of a place
class PlaceReservation implements CalendarEventBase {
  const PlaceReservation({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.groupId,
    required this.groupName,
    required this.groupEventId,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.description,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  final int id;
  final String placeId;
  final String placeName;
  final int groupId;
  final String groupName;
  final int groupEventId;
  @override
  final String title;
  @override
  final DateTime startDateTime;
  @override
  final DateTime endDateTime;
  @override
  final String? description;
  @override
  final Color color;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Reservations are never all-day
  @override
  bool get isAllDay => false;

  /// Location is the place name for display purposes
  @override
  String? get location => placeName;

  /// Duration of the reservation
  @override
  Duration get duration => endDateTime.difference(startDateTime);

  /// Check if the reservation occurs on a specific date
  @override
  bool occursOn(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return startDateTime.isBefore(dayEnd) && endDateTime.isAfter(dayStart);
  }

  /// Check if the reservation overlaps with a given time range
  bool overlapsWith(DateTime start, DateTime end) {
    return startDateTime.isBefore(end) && endDateTime.isAfter(start);
  }

  /// Format time range for display (HH:mm ~ HH:mm)
  String get formattedTimeRange {
    final startTime =
        '${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')}';
    final endTime =
        '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
    return '$startTime ~ $endTime';
  }

  /// Format date range for display
  String get formattedDateRange {
    final sameDay = startDateTime.year == endDateTime.year &&
        startDateTime.month == endDateTime.month &&
        startDateTime.day == endDateTime.day;

    if (sameDay) {
      return '${startDateTime.year}-${startDateTime.month.toString().padLeft(2, '0')}-${startDateTime.day.toString().padLeft(2, '0')} $formattedTimeRange';
    }

    return '${_formatDateTime(startDateTime)} ~ ${_formatDateTime(endDateTime)}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  factory PlaceReservation.fromJson(Map<String, dynamic> json) {
    return PlaceReservation(
      id: (json['id'] as num).toInt(),
      placeId: json['placeId'] as String,
      placeName: json['placeName'] as String,
      groupId: (json['groupId'] as num).toInt(),
      groupName: json['groupName'] as String,
      groupEventId: (json['groupEventId'] as num).toInt(),
      title: json['title'] as String,
      startDateTime: DateTime.parse(json['startDateTime'] as String),
      endDateTime: DateTime.parse(json['endDateTime'] as String),
      description: json['description'] as String?,
      color: _parseColor(json['color'] as String? ?? '#3B82F6'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placeId': placeId,
      'placeName': placeName,
      'groupId': groupId,
      'groupName': groupName,
      'groupEventId': groupEventId,
      'title': title,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'description': description,
      'color': _colorToHex(color),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PlaceReservation copyWith({
    int? id,
    String? placeId,
    String? placeName,
    int? groupId,
    String? groupName,
    int? groupEventId,
    String? title,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? description,
    Color? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlaceReservation(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupEventId: groupEventId ?? this.groupEventId,
      title: title ?? this.title,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlaceReservation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PlaceReservation(id: $id, place: $placeName, title: $title, time: $formattedTimeRange)';
  }
}

/// Request payload for creating a place reservation
class PlaceReservationRequest {
  const PlaceReservationRequest({
    required this.placeId,
    required this.groupEventId,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.description,
  });

  final String placeId;
  final int groupEventId;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? description;

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'groupEventId': groupEventId,
      'title': title,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'description': description?.trim().isEmpty == true ? null : description,
    };
  }
}

// Helper functions
Color _parseColor(String hex) {
  final normalized = hex.replaceAll('#', '');
  final value = int.parse(normalized, radix: 16);
  return Color(0xFF000000 | value);
}

String _colorToHex(Color color) =>
    '#${(color.value & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
