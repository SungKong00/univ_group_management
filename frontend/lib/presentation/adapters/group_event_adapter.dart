import 'package:flutter/material.dart';
import '../../core/models/calendar/group_event.dart';
import '../widgets/weekly_calendar/weekly_schedule_editor.dart';

/// Adapter for converting between GroupEvent and WeeklyScheduleEditor Event
///
/// **Purpose**: Bridge between domain model (GroupEvent) and UI component (WeeklyScheduleEditor)
///
/// **Conversion Logic**:
/// - GroupEvent uses DateTime (API format)
/// - Event uses (day: int, slot: int) + DateTime for precise rendering
/// - 1 slot = 15 minutes (4 slots per hour)
///
/// **Usage**:
/// ```dart
/// // To Event (for displaying in WeeklyScheduleEditor)
/// final event = GroupEventAdapter.toEvent(groupEvent, weekStart);
///
/// // From Event (for creating/updating via API)
/// final request = GroupEventAdapter.fromEvent(event, weekStart, original: originalEvent);
/// ```
class GroupEventAdapter {
  /// Convert GroupEvent to Event for WeeklyScheduleEditor
  ///
  /// **Parameters**:
  /// - [event]: Domain model from API
  /// - [weekStart]: Monday of the current week (for DateTime calculation)
  ///
  /// **Returns**: Event typedef with cell positions and precise DateTime
  ///
  /// **Note**: Events outside the week range are skipped (returns null)
  static Event? toEvent(GroupEvent event, DateTime weekStart) {
    // Skip all-day events (WeeklyScheduleEditor only handles time events)
    if (event.isAllDay) return null;

    // Calculate week end (Sunday)
    final weekEnd = weekStart.add(const Duration(days: 7));

    // Skip events outside the week range
    if (event.startDate.isAfter(weekEnd) || event.endDate.isBefore(weekStart)) {
      return null;
    }

    // For multi-day events, only show the first day in the week range
    final effectiveStartDate = event.startDate.isBefore(weekStart)
        ? weekStart
        : event.startDate;

    final effectiveEndDate = event.endDate.isAfter(weekEnd)
        ? weekEnd
        : event.endDate;

    // Calculate day index (0 = Monday, 6 = Sunday)
    final dayIndex = effectiveStartDate.weekday - 1;

    // If the event spans multiple days, only show it on the first day
    // and cap the end time to the end of that day
    final DateTime endDateTime;
    if (effectiveStartDate.day != effectiveEndDate.day) {
      // Cap to end of the start day
      endDateTime = DateTime(
        effectiveStartDate.year,
        effectiveStartDate.month,
        effectiveStartDate.day,
        23,
        59,
      );
    } else {
      endDateTime = effectiveEndDate;
    }

    // Convert TimeOfDay to slot (15-minute intervals)
    final startSlot = _timeToSlot(TimeOfDay.fromDateTime(effectiveStartDate));
    final endSlot =
        _timeToSlot(TimeOfDay.fromDateTime(endDateTime)) - 1; // Exclusive end

    return (
      id: 'group-${event.id}', // Prefix to distinguish from personal schedules
      title: event.title,
      start: (day: dayIndex, slot: startSlot),
      end: (day: dayIndex, slot: endSlot),
      startTime: effectiveStartDate, // Precise minute-level positioning
      endTime: endDateTime, // Precise minute-level positioning
      color: event.color, // Pass event color
    );
  }

  /// Convert Event back to request parameters for API
  ///
  /// **Parameters**:
  /// - [event]: UI event from WeeklyScheduleEditor
  /// - [weekStart]: Monday of the current week (for DateTime calculation)
  /// - [original]: Optional original GroupEvent (for update operations)
  ///
  /// **Returns**: Map of request parameters for create/update API calls
  ///
  /// **Note**: This method only extracts time changes from the drag operation.
  /// Additional fields (description, location, recurrence, etc.) should be
  /// filled in by the dialog before API call.
  static Map<String, dynamic> fromEvent(
    Event event,
    DateTime weekStart, {
    GroupEvent? original,
  }) {
    assert(
      event.startTime != null && event.endTime != null,
      'Event must have startTime and endTime for conversion',
    );

    // Create DateTime from Event (precise minute-level)
    final startDate = event.startTime!;
    final endDate = event.endTime!;

    // Base parameters from drag operation
    final params = <String, dynamic>{
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isAllDay': false, // WeeklyScheduleEditor only handles time events
    };

    // Copy fields from original if available
    if (original != null) {
      params['title'] = original.title;
      params['description'] = original.description;
      params['location'] = original.location;
      params['isOfficial'] = original.isOfficial;
      params['color'] = _colorToHex(original.color);
    } else {
      // Default values for new events (will be overwritten by dialog)
      params['title'] = event.title;
      params['isOfficial'] = false;
      params['color'] = _colorToHex(event.color ?? Colors.blue);
    }

    return params;
  }

  /// Extract GroupEvent ID from Event ID
  ///
  /// **Format**: Event.id = 'group-{eventId}'
  ///
  /// **Returns**: Integer ID for API calls, or null if invalid format
  static int? extractEventId(String eventId) {
    if (!eventId.startsWith('group-')) return null;

    final idString = eventId.replaceFirst('group-', '');
    return int.tryParse(idString);
  }

  /// Check if Event is a GroupEvent (vs personal schedule)
  ///
  /// **Returns**: true if Event.id starts with 'group-'
  static bool isGroupEvent(Event event) {
    return event.id.startsWith('group-');
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

  /// Convert Color to hex string
  static String _colorToHex(Color color) =>
      '#'
      '${(color.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
