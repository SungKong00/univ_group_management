import '../../core/models/calendar_models.dart';
import '../widgets/weekly_calendar/weekly_schedule_editor.dart';

/// Adapter for converting between PersonalEvent and WeeklyScheduleEditor Event
///
/// **Purpose**: Bridge between domain model (PersonalEvent) and UI component (WeeklyScheduleEditor)
///
/// **Conversion Logic**:
/// - PersonalEvent uses startDateTime/endDateTime
/// - Event uses (day: int, slot: int) + DateTime for precise rendering
/// - 1 slot = 15 minutes (4 slots per hour)
///
/// **Usage**:
/// ```dart
/// // To Event (for displaying in WeeklyScheduleEditor)
/// final event = PersonalEventAdapter.toEvent(personalEvent, weekStart);
/// ```
class PersonalEventAdapter {
  /// Convert PersonalEvent to Event for WeeklyScheduleEditor
  ///
  /// **Parameters**:
  /// - [event]: Domain model from API
  /// - [weekStart]: Monday of the current week (for cell position calculation)
  ///
  /// **Returns**: Event typedef with cell positions and precise DateTime
  static Event toEvent(PersonalEvent event, DateTime weekStart) {
    // Calculate day index (0 = Monday, 6 = Sunday)
    final dayIndex = event.startDateTime.weekday - DateTime.monday;

    // Convert DateTime to slot (15-minute intervals)
    final startSlot = _dateTimeToSlot(event.startDateTime);
    final endSlot = _dateTimeToSlot(event.endDateTime) - 1; // Exclusive end

    return (
      id: 'pe-${event.id}', // Prefix to distinguish from schedule events
      title: event.title,
      start: (day: dayIndex, slot: startSlot),
      end: (day: dayIndex, slot: endSlot),
      startTime: event.startDateTime, // Precise minute-level positioning
      endTime: event.endDateTime, // Precise minute-level positioning
      color: event.color, // Pass event color
    );
  }

  /// Extract PersonalEvent ID from Event ID
  ///
  /// **Format**: Event.id = 'pe-{eventId}'
  ///
  /// **Returns**: Integer ID for API calls, or null if invalid format
  static int? extractEventId(String eventId) {
    if (!eventId.startsWith('pe-')) return null;

    final idString = eventId.replaceFirst('pe-', '');
    return int.tryParse(idString);
  }

  /// Check if Event is a PersonalEvent (vs schedule event)
  ///
  /// **Returns**: true if Event.id starts with 'pe-'
  static bool isPersonalEvent(Event event) {
    return event.id.startsWith('pe-');
  }

  // --- Helper Methods ---

  /// Convert DateTime to slot index (15-minute intervals)
  ///
  /// **Formula**: slot = (hour * 4) + (minute / 15)
  ///
  /// **Example**:
  /// - 09:00 → 36 (9 * 4 + 0)
  /// - 09:15 → 37 (9 * 4 + 1)
  /// - 14:30 → 58 (14 * 4 + 2)
  static int _dateTimeToSlot(DateTime dateTime) {
    return dateTime.hour * 4 + (dateTime.minute ~/ 15);
  }
}
