import 'package:flutter/material.dart';
import '../../core/models/calendar_models.dart';
import '../widgets/weekly_calendar/weekly_schedule_editor.dart';

/// Adapter for converting between PersonalSchedule and WeeklyScheduleEditor Event
///
/// **Purpose**: Bridge between domain model (PersonalSchedule) and UI component (WeeklyScheduleEditor)
///
/// **Conversion Logic**:
/// - PersonalSchedule uses DayOfWeek enum + TimeOfDay
/// - Event uses (day: int, slot: int) + DateTime for precise rendering
/// - 1 slot = 15 minutes (4 slots per hour)
///
/// **Usage**:
/// ```dart
/// // To Event (for displaying in WeeklyScheduleEditor)
/// final event = PersonalScheduleAdapter.toEvent(schedule, weekStart);
///
/// // From Event (for creating/updating via API)
/// final request = PersonalScheduleAdapter.fromEvent(event, weekStart);
/// ```
class PersonalScheduleAdapter {
  /// Convert PersonalSchedule to Event for WeeklyScheduleEditor
  ///
  /// **Parameters**:
  /// - [schedule]: Domain model from API
  /// - [weekStart]: Monday of the current week (for DateTime calculation)
  ///
  /// **Returns**: Event typedef with cell positions and precise DateTime
  static Event toEvent(PersonalSchedule schedule, DateTime weekStart) {
    // Calculate day index (0 = Monday, 6 = Sunday)
    final dayIndex = schedule.dayOfWeek.index;

    // Calculate date for this day of week
    final date = weekStart.add(Duration(days: dayIndex));

    // Create precise DateTime from TimeOfDay
    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      schedule.startTime.hour,
      schedule.startTime.minute,
    );

    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      schedule.endTime.hour,
      schedule.endTime.minute,
    );

    // Convert TimeOfDay to slot (15-minute intervals)
    final startSlot = _timeToSlot(schedule.startTime);
    final endSlot = _timeToSlot(schedule.endTime) - 1; // Exclusive end

    return (
      id: 'ps-${schedule.id}', // Prefix to distinguish from external events
      title: schedule.title,
      start: (day: dayIndex, slot: startSlot),
      end: (day: dayIndex, slot: endSlot),
      startTime: startDateTime, // Precise minute-level positioning
      endTime: endDateTime, // Precise minute-level positioning
      color: schedule.color, // Pass schedule color
    );
  }

  /// Convert Event back to PersonalScheduleRequest for API
  ///
  /// **Parameters**:
  /// - [event]: UI event from WeeklyScheduleEditor
  /// - [weekStart]: Monday of the current week (for validation)
  ///
  /// **Returns**: Request DTO for create/update API calls
  ///
  /// **Note**: Requires event.startTime and event.endTime to be non-null
  static PersonalScheduleRequest fromEvent(
    Event event,
    DateTime weekStart, {
    String? location,
    Color? color,
  }) {
    assert(
      event.startTime != null && event.endTime != null,
      'Event must have startTime and endTime for conversion',
    );

    // Extract DayOfWeek from day index
    final dayOfWeek = DayOfWeek.values[event.start.day];

    // Convert DateTime to TimeOfDay
    final startTime = TimeOfDay(
      hour: event.startTime!.hour,
      minute: event.startTime!.minute,
    );

    final endTime = TimeOfDay(
      hour: event.endTime!.hour,
      minute: event.endTime!.minute,
    );

    return PersonalScheduleRequest(
      title: event.title,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      location: location,
      color: color ?? kPersonalScheduleColors[0], // Default blue color
    );
  }

  /// Extract PersonalSchedule ID from Event ID
  ///
  /// **Format**: Event.id = 'ps-{scheduleId}'
  ///
  /// **Returns**: Integer ID for API calls, or null if invalid format
  static int? extractScheduleId(String eventId) {
    if (!eventId.startsWith('ps-')) return null;

    final idString = eventId.replaceFirst('ps-', '');
    return int.tryParse(idString);
  }

  /// Check if Event is a PersonalSchedule (vs external group event)
  ///
  /// **Returns**: true if Event.id starts with 'ps-'
  static bool isPersonalScheduleEvent(Event event) {
    return event.id.startsWith('ps-');
  }

  // --- Helper Methods ---

  /// Convert TimeOfDay to slot index (15-minute intervals)
  ///
  /// **Formula**: slot = (hour * 4) + (minute / 15)
  ///
  /// **Example**:
  /// - 09:00 → 36 (9 * 4 + 0)
  /// - 09:15 → 37 (9 * 4 + 1)
  /// - 14:30 → 58 (14 * 4 + 2)
  static int _timeToSlot(TimeOfDay time) {
    return time.hour * 4 + (time.minute ~/ 15);
  }

  /// Convert slot index to TimeOfDay (inverse of _timeToSlot)
  ///
  /// **Note**: Currently unused but provided for completeness
  static TimeOfDay _slotToTime(int slot) {
    final hour = slot ~/ 4;
    final minute = (slot % 4) * 15;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Calculate duration in slots (15-minute units)
  ///
  /// **Note**: Currently unused but provided for completeness
  static int _calculateDurationSlots(TimeOfDay start, TimeOfDay end) {
    final startSlot = _timeToSlot(start);
    final endSlot = _timeToSlot(end);
    return endSlot - startSlot;
  }
}
