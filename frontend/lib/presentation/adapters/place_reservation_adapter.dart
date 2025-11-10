import 'package:flutter/material.dart';
import '../../core/models/place/place_reservation.dart';
import '../widgets/weekly_calendar/weekly_schedule_editor.dart';

/// Adapter for converting between PlaceReservation and WeeklyScheduleEditor Event
///
/// **Purpose**: Bridge between domain model (PlaceReservation) and UI component (WeeklyScheduleEditor)
///
/// **Conversion Logic**:
/// - PlaceReservation uses DateTime (API format)
/// - Event uses (day: int, slot: int) + DateTime for precise rendering
/// - 1 slot = 15 minutes (4 slots per hour)
///
/// **Usage**:
/// ```dart
/// // To Event (for displaying in WeeklyScheduleEditor)
/// final event = PlaceReservationAdapter.toEvent(reservation, weekStart);
///
/// // Extract reservation ID from Event ID
/// final reservationId = PlaceReservationAdapter.extractReservationId(event.id);
/// ```
class PlaceReservationAdapter {
  /// Convert PlaceReservation to Event for WeeklyScheduleEditor
  ///
  /// **Parameters**:
  /// - [reservation]: Domain model from API
  /// - [weekStart]: Monday of the current week (for DateTime calculation)
  ///
  /// **Returns**: Event typedef with cell positions and precise DateTime
  ///
  /// **Note**: Reservations outside the week range are skipped (returns null)
  static Event? toEvent(PlaceReservation reservation, DateTime weekStart) {
    // Calculate week end (Sunday 23:59:59)
    final weekEnd = weekStart.add(const Duration(days: 7));

    // Skip reservations outside the week range
    if (reservation.startDateTime.isAfter(weekEnd) ||
        reservation.endDateTime.isBefore(weekStart)) {
      return null;
    }

    // For multi-day reservations, only show the first day in the week range
    final effectiveStartDate = reservation.startDateTime.isBefore(weekStart)
        ? weekStart
        : reservation.startDateTime;

    final effectiveEndDate = reservation.endDateTime.isAfter(weekEnd)
        ? weekEnd
        : reservation.endDateTime;

    // Calculate day index (0 = Monday, 6 = Sunday)
    final dayIndex = effectiveStartDate.weekday - 1;

    // If the reservation spans multiple days, only show it on the first day
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
      id: 'place-${reservation.id}', // Prefix to distinguish from other event types
      title:
          '${reservation.title} (${reservation.placeName})', // Include place name
      start: (day: dayIndex, slot: startSlot),
      end: (day: dayIndex, slot: endSlot),
      startTime: effectiveStartDate, // Precise minute-level positioning
      endTime: endDateTime, // Precise minute-level positioning
      color: reservation.color, // Place-specific color
    );
  }

  /// Extract PlaceReservation ID from Event ID
  ///
  /// **Format**: Event.id = 'place-{reservationId}'
  ///
  /// **Returns**: Integer ID for API calls, or null if invalid format
  static int? extractReservationId(String eventId) {
    if (!eventId.startsWith('place-')) return null;

    final idString = eventId.replaceFirst('place-', '');
    return int.tryParse(idString);
  }

  /// Check if Event is a PlaceReservation (vs other event types)
  ///
  /// **Returns**: true if Event.id starts with 'place-'
  static bool isPlaceReservation(Event event) {
    return event.id.startsWith('place-');
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
}
