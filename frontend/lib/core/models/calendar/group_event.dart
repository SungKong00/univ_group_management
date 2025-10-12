import 'package:flutter/material.dart';

/// Enum representing the type of group event.
enum EventType {
  general('GENERAL'),
  targeted('TARGETED'),
  rsvp('RSVP');

  const EventType(this.apiValue);
  final String apiValue;

  static EventType fromApi(String value) {
    final normalized = value.toUpperCase();
    return EventType.values.firstWhere(
      (type) => type.apiValue == normalized,
      orElse: () => EventType.general,
    );
  }
}

/// Domain model for group calendar events.
class GroupEvent {
  const GroupEvent({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    this.description,
    this.location,
    required this.startDate,
    required this.endDate,
    required this.isAllDay,
    required this.isOfficial,
    required this.eventType,
    this.seriesId,
    this.recurrenceRule,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int groupId;
  final String groupName;
  final int creatorId;
  final String creatorName;
  final String title;
  final String? description;
  final String? location;
  final DateTime startDate;
  final DateTime endDate;
  final bool isAllDay;
  final bool isOfficial;
  final EventType eventType;
  final String? seriesId;
  final String? recurrenceRule;
  final Color color;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory GroupEvent.fromJson(Map<String, dynamic> json) {
    return GroupEvent(
      id: (json['id'] as num).toInt(),
      groupId: (json['groupId'] as num).toInt(),
      groupName: json['groupName'] as String,
      creatorId: (json['creatorId'] as num).toInt(),
      creatorName: json['creatorName'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isAllDay: json['isAllDay'] as bool? ?? false,
      isOfficial: json['isOfficial'] as bool? ?? false,
      eventType: EventType.fromApi(json['eventType'] as String? ?? 'GENERAL'),
      seriesId: json['seriesId'] as String?,
      recurrenceRule: json['recurrenceRule'] as String?,
      color: _parseColor(json['color'] as String? ?? '#3B82F6'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'groupName': groupName,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'title': title,
      'description': description,
      'location': location,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isAllDay': isAllDay,
      'isOfficial': isOfficial,
      'eventType': eventType.apiValue,
      'seriesId': seriesId,
      'recurrenceRule': recurrenceRule,
      'color': _colorToHex(color),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Returns true if this event is part of a recurring series.
  bool get isRecurring => seriesId != null;

  /// Returns the duration of the event.
  Duration get duration => endDate.difference(startDate);

  /// Returns true if this event occurs on the given date.
  bool occursOn(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd =
        dayStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    return startDate.isBefore(dayEnd) && endDate.isAfter(dayStart);
  }

  /// Returns the hex color string.
  String get colorHex => _colorToHex(color);

  GroupEvent copyWith({
    int? id,
    int? groupId,
    String? groupName,
    int? creatorId,
    String? creatorName,
    String? title,
    String? description,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAllDay,
    bool? isOfficial,
    EventType? eventType,
    String? seriesId,
    String? recurrenceRule,
    Color? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupEvent(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isAllDay: isAllDay ?? this.isAllDay,
      isOfficial: isOfficial ?? this.isOfficial,
      eventType: eventType ?? this.eventType,
      seriesId: seriesId ?? this.seriesId,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

Color _parseColor(String hex) {
  final normalized = hex.replaceAll('#', '');
  final value = int.parse(normalized, radix: 16);
  return Color(0xFF000000 | value);
}

String _colorToHex(Color color) => '#'
    '${(color.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
