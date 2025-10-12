/// Enum representing the type of recurrence pattern.
enum RecurrenceType {
  daily('DAILY'),
  weekly('WEEKLY');

  const RecurrenceType(this.apiValue);
  final String apiValue;

  static RecurrenceType fromApi(String value) {
    final normalized = value.toUpperCase();
    return RecurrenceType.values.firstWhere(
      (type) => type.apiValue == normalized,
      orElse: () => RecurrenceType.daily,
    );
  }
}

/// Represents a recurrence pattern for group events.
/// daysOfWeek: 1=Monday, 7=Sunday (ISO 8601 weekday numbering).
class RecurrencePattern {
  const RecurrencePattern({
    required this.type,
    this.daysOfWeek,
  });

  final RecurrenceType type;
  final List<int>? daysOfWeek;

  factory RecurrencePattern.fromJson(Map<String, dynamic> json) {
    return RecurrencePattern(
      type: RecurrenceType.fromApi(json['type'] as String),
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.apiValue,
      if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
    };
  }

  /// Factory for creating a daily recurrence pattern.
  static RecurrencePattern daily() => const RecurrencePattern(
        type: RecurrenceType.daily,
      );

  /// Factory for creating a weekly recurrence pattern with specific days.
  static RecurrencePattern weekly(List<int> days) => RecurrencePattern(
        type: RecurrenceType.weekly,
        daysOfWeek: days,
      );

  RecurrencePattern copyWith({
    RecurrenceType? type,
    List<int>? daysOfWeek,
  }) {
    return RecurrencePattern(
      type: type ?? this.type,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    );
  }
}
