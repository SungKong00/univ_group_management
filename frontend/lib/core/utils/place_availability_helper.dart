import 'package:flutter/material.dart';
import '../models/place/place_availability.dart';
import '../models/place/place_reservation.dart';

/// Helper class for calculating disabled time slots based on place availability
///
/// **Purpose**: Convert place operating hours into disabled slots for WeeklyScheduleEditor
///
/// **Disabled Slots Logic**:
/// - All time slots OUTSIDE operating hours are disabled (gray cells)
/// - If a day has no availability records, the entire day is disabled
/// - Multiple availability windows per day are supported (e.g., 09:00-12:00, 14:00-18:00)
///
/// **Future Extension**: PlaceBlockedTime will be added for specific date blocks
///
/// **Usage**:
/// ```dart
/// // Single place
/// final disabledSlots = PlaceAvailabilityHelper.calculateDisabledSlots(
///   availabilities: placeAvailabilities,
///   weekStart: DateTime(2025, 11, 4), // Monday
/// );
///
/// // Multiple places (merged)
/// final disabledSlots = PlaceAvailabilityHelper.mergeDisabledSlots(
///   availabilitiesMap: {1: [...], 2: [...]},
///   weekStart: DateTime(2025, 11, 4),
/// );
/// ```
class PlaceAvailabilityHelper {
  /// Calculate disabled slots for a single place
  ///
  /// **Parameters**:
  /// - [availabilities]: List of PlaceAvailability records for the place
  /// - [weekStart]: Monday of the current week (00:00:00)
  ///
  /// **Returns**: Set of DateTime representing disabled 15-minute slots
  ///
  /// **Algorithm**:
  /// 1. For each day of the week (Mon-Sun):
  ///    a. Find all availability windows for that day
  ///    b. If no windows → entire day disabled
  ///    c. If windows exist → disable slots outside windows
  /// 2. Generate DateTime for each disabled slot
  static Set<DateTime> calculateDisabledSlots({
    required List<PlaceAvailability> availabilities,
    required DateTime weekStart,
  }) {
    final disabledSlots = <DateTime>{};

    // Process each day of the week
    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = weekStart.add(Duration(days: dayOffset));
      final dayOfWeek = _dartDayOfWeekToEnum(date.weekday);

      // Find availability windows for this day
      final dayAvailabilities = availabilities
          .where((a) => a.dayOfWeek == dayOfWeek)
          .toList()
        ..sort((a, b) => _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)));

      if (dayAvailabilities.isEmpty) {
        // No operating hours → entire day disabled
        _addAllSlotsForDay(disabledSlots, date);
      } else {
        // Operating hours exist → disable slots outside windows
        _addSlotsOutsideAvailability(disabledSlots, date, dayAvailabilities);
      }
    }

    return disabledSlots;
  }

  /// Merge disabled slots for multiple places
  ///
  /// **Parameters**:
  /// - [availabilitiesMap]: Map of placeId → availabilities
  /// - [weekStart]: Monday of the current week
  ///
  /// **Returns**: Set of DateTime representing disabled slots (INTERSECTION)
  ///
  /// **Merge Strategy**: INTERSECTION (conservative)
  /// - Slot is enabled if **at least one place** is available at that time
  /// - Slot is disabled if **all places** are unavailable
  ///
  /// **Example**:
  /// - Place A: 09:00-18:00 (Mon-Fri)
  /// - Place B: 10:00-22:00 (Mon-Sun)
  /// - Result: 09:00-22:00 (Mon-Sun) - users can choose either place
  static Set<DateTime> mergeDisabledSlots({
    required Map<int, List<PlaceAvailability>> availabilitiesMap,
    required DateTime weekStart,
  }) {
    if (availabilitiesMap.isEmpty) {
      // No places → all slots disabled
      final disabledSlots = <DateTime>{};
      for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
        final date = weekStart.add(Duration(days: dayOffset));
        _addAllSlotsForDay(disabledSlots, date);
      }
      return disabledSlots;
    }

    // Calculate disabled slots for each place
    final allPlaceDisabledSlots = availabilitiesMap.entries.map((entry) {
      return calculateDisabledSlots(
        availabilities: entry.value,
        weekStart: weekStart,
      );
    }).toList();

    // INTERSECTION: Slot is disabled if ALL places are disabled
    // (equivalent to: enabled if ANY place is enabled)
    final result = <DateTime>{};

    // Generate all possible slots
    final allSlots = <DateTime>{};
    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = weekStart.add(Duration(days: dayOffset));
      for (var hour = 0; hour < 24; hour++) {
        for (var minute = 0; minute < 60; minute += 15) {
          allSlots.add(DateTime(date.year, date.month, date.day, hour, minute));
        }
      }
    }

    // Check each slot: disabled if ALL places are disabled
    for (final slot in allSlots) {
      final allPlacesDisabled = allPlaceDisabledSlots.every(
        (placeDisabledSlots) => placeDisabledSlots.contains(slot),
      );
      if (allPlacesDisabled) {
        result.add(slot);
      }
    }

    return result;
  }

  // --- Private Helper Methods ---

  /// Add all time slots for a given day
  static void _addAllSlotsForDay(Set<DateTime> disabledSlots, DateTime date) {
    for (var hour = 0; hour < 24; hour++) {
      for (var minute = 0; minute < 60; minute += 15) {
        disabledSlots.add(DateTime(date.year, date.month, date.day, hour, minute));
      }
    }
  }

  /// Add slots outside availability windows
  static void _addSlotsOutsideAvailability(
    Set<DateTime> disabledSlots,
    DateTime date,
    List<PlaceAvailability> sortedAvailabilities,
  ) {
    // Disable slots before first window
    final firstWindow = sortedAvailabilities.first;
    final firstStartMinutes = _timeToMinutes(firstWindow.startTime);
    for (var totalMinutes = 0; totalMinutes < firstStartMinutes; totalMinutes += 15) {
      final hour = totalMinutes ~/ 60;
      final minute = totalMinutes % 60;
      disabledSlots.add(DateTime(date.year, date.month, date.day, hour, minute));
    }

    // Disable gaps between windows
    for (var i = 0; i < sortedAvailabilities.length - 1; i++) {
      final currentWindow = sortedAvailabilities[i];
      final nextWindow = sortedAvailabilities[i + 1];

      final gapStartMinutes = _timeToMinutes(currentWindow.endTime);
      final gapEndMinutes = _timeToMinutes(nextWindow.startTime);

      for (var totalMinutes = gapStartMinutes;
          totalMinutes < gapEndMinutes;
          totalMinutes += 15) {
        final hour = totalMinutes ~/ 60;
        final minute = totalMinutes % 60;
        disabledSlots.add(DateTime(date.year, date.month, date.day, hour, minute));
      }
    }

    // Disable slots after last window
    final lastWindow = sortedAvailabilities.last;
    final lastEndMinutes = _timeToMinutes(lastWindow.endTime);
    for (var totalMinutes = lastEndMinutes; totalMinutes < 24 * 60; totalMinutes += 15) {
      final hour = totalMinutes ~/ 60;
      final minute = totalMinutes % 60;
      disabledSlots.add(DateTime(date.year, date.month, date.day, hour, minute));
    }
  }

  /// Convert Dart's DateTime.weekday (1=Mon, 7=Sun) to DayOfWeek enum
  static DayOfWeek _dartDayOfWeekToEnum(int dartWeekday) {
    // dartWeekday: 1=Mon, 2=Tue, ..., 7=Sun
    // DayOfWeek enum: MONDAY=0, TUESDAY=1, ..., SUNDAY=6
    return DayOfWeek.values[dartWeekday - 1];
  }

  /// Convert TimeOfDay to total minutes since midnight
  static int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  /// Calculate disabled slots for a single place including reservations
  ///
  /// **Returns**: Set of DateTime representing 15-minute slots that are unavailable
  /// because they fall outside operating hours or overlap with existing reservations.
  static Set<DateTime> calculateDisabledSlotsForPlace({
    required List<PlaceAvailability> availabilities,
    required List<PlaceReservation> reservations,
    required DateTime weekStart,
  }) {
    final disabledSlots = <DateTime>{};

    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final currentDate = weekStart.add(Duration(days: dayOffset));

      for (var hour = 0; hour < 24; hour++) {
        for (var minute = 0; minute < 60; minute += 15) {
          final slot = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            hour,
            minute,
          );

          if (!_isSlotAvailable(
            slot: slot,
            availabilities: availabilities,
            reservations: reservations,
          )) {
            disabledSlots.add(slot);
          }
        }
      }
    }

    return disabledSlots;
  }

  /// Check if a place can accommodate a reservation for the specified time range
  static bool canReservePlaceForRange({
    required DateTime startTime,
    required DateTime endTime,
    required List<PlaceAvailability> availabilities,
    required List<PlaceReservation> reservations,
  }) {
    if (!startTime.isBefore(endTime)) return false;
    final durationMinutes = endTime.difference(startTime).inMinutes;

    return _canReserveContinuously(
      startTime: startTime,
      durationMinutes: durationMinutes,
      availabilities: availabilities,
      reservations: reservations,
    );
  }

  // ========================================
  // Duration-based disabled slots calculation
  // ========================================

  /// Calculate disabled slots for multiple places with required duration
  ///
  /// **Parameters**:
  /// - [availabilitiesMap]: Map of placeId → List<PlaceAvailability>
  /// - [reservationsMap]: Map of placeId → List<PlaceReservation>
  /// - [requiredDuration]: Required continuous duration for reservation
  /// - [weekStart]: Monday of the current week (00:00:00)
  ///
  /// **Returns**: Set of DateTime representing disabled 15-minute slots
  ///
  /// **Algorithm**:
  /// A slot is DISABLED if NO place can accommodate a continuous reservation
  /// of the required duration starting from that slot.
  ///
  /// **Example**:
  /// - Place A: 09:00-18:00 operating, no reservations
  /// - Place B: 09:00-18:00 operating, 10:00-12:00 reserved
  /// - Required duration: 2 hours
  /// - Result: 09:00, 12:00-16:00 are enabled (white)
  ///          10:00-11:45, 16:15-18:00 are disabled (gray)
  static Set<DateTime> calculateDisabledSlotsWithDuration({
    required Map<int, List<PlaceAvailability>> availabilitiesMap,
    required Map<int, List<PlaceReservation>> reservationsMap,
    required Duration requiredDuration,
    required DateTime weekStart,
  }) {
    final disabledSlots = <DateTime>{};
    final durationMinutes = requiredDuration.inMinutes;

    // Process each day of the week
    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = weekStart.add(Duration(days: dayOffset));

      // Process each 15-minute slot in the day
      for (var hour = 0; hour < 24; hour++) {
        for (var minute = 0; minute < 60; minute += 15) {
          final slotTime = DateTime(date.year, date.month, date.day, hour, minute);

          // Check if ANY place can accommodate this reservation
          bool anyPlaceAvailable = false;

          for (final entry in availabilitiesMap.entries) {
            final placeId = entry.key;
            final availabilities = entry.value;
            final reservations = reservationsMap[placeId] ?? [];

            if (_canReserveContinuously(
              startTime: slotTime,
              durationMinutes: durationMinutes,
              availabilities: availabilities,
              reservations: reservations,
            )) {
              anyPlaceAvailable = true;
              break; // At least one place is available
            }
          }

          if (!anyPlaceAvailable) {
            disabledSlots.add(slotTime);
          }
        }
      }
    }

    return disabledSlots;
  }

  /// Check if a place can be reserved continuously for the required duration
  ///
  /// **Parameters**:
  /// - [startTime]: Start time of the reservation
  /// - [durationMinutes]: Required duration in minutes
  /// - [availabilities]: Operating hours of the place
  /// - [reservations]: Existing reservations of the place
  ///
  /// **Returns**: true if the place can accommodate the reservation
  ///
  /// **Algorithm**:
  /// 1. Calculate end time (startTime + duration)
  /// 2. Check every 15-minute slot from start to end
  /// 3. If any slot is unavailable → return false
  /// 4. If all slots are available → return true
  static bool _canReserveContinuously({
    required DateTime startTime,
    required int durationMinutes,
    required List<PlaceAvailability> availabilities,
    required List<PlaceReservation> reservations,
  }) {
    final endTime = startTime.add(Duration(minutes: durationMinutes));

    // Check every 15-minute slot in the range
    DateTime current = startTime;
    while (current.isBefore(endTime)) {
      if (!_isSlotAvailable(
        slot: current,
        availabilities: availabilities,
        reservations: reservations,
      )) {
        return false; // Found an unavailable slot
      }
      current = current.add(const Duration(minutes: 15));
    }

    return true; // All slots are available
  }

  /// Check if a single 15-minute slot is available
  ///
  /// **Parameters**:
  /// - [slot]: DateTime of the 15-minute slot
  /// - [availabilities]: Operating hours of the place
  /// - [reservations]: Existing reservations of the place
  ///
  /// **Returns**: true if the slot is available (within operating hours and not reserved)
  static bool _isSlotAvailable({
    required DateTime slot,
    required List<PlaceAvailability> availabilities,
    required List<PlaceReservation> reservations,
  }) {
    // 1. Check operating hours
    if (!_isWithinOperatingHours(slot, availabilities)) {
      return false;
    }

    // 2. Check reservation conflicts
    if (_overlapsWithReservation(slot, reservations)) {
      return false;
    }

    return true;
  }

  /// Check if a slot is within operating hours
  static bool _isWithinOperatingHours(
    DateTime slot,
    List<PlaceAvailability> availabilities,
  ) {
    final dayOfWeek = _dartDayOfWeekToEnum(slot.weekday);
    final slotTime = TimeOfDay.fromDateTime(slot);
    final slotMinutes = _timeToMinutes(slotTime);

    // Find all availability windows for this day
    final dayAvailabilities =
        availabilities.where((a) => a.dayOfWeek == dayOfWeek).toList();

    if (availabilities.isEmpty) {
      return true; // Treat no configured availability as 24/7 open
    }

    if (dayAvailabilities.isEmpty) {
      return false; // Day explicitly closed
    }

    // Check if slot is within any availability window
    for (final availability in dayAvailabilities) {
      final startMinutes = _timeToMinutes(availability.startTime);
      final endMinutes = _timeToMinutes(availability.endTime);

      if (slotMinutes >= startMinutes && slotMinutes < endMinutes) {
        return true; // Within operating hours
      }
    }

    return false; // Outside all windows
  }

  /// Check if a slot overlaps with any existing reservation
  static bool _overlapsWithReservation(
    DateTime slot,
    List<PlaceReservation> reservations,
  ) {
    final slotEnd = slot.add(const Duration(minutes: 15));

    for (final reservation in reservations) {
      // Check if slot overlaps with reservation
      // Overlap if: slot.start < reservation.end AND slot.end > reservation.start
      if (slot.isBefore(reservation.endDateTime) &&
          slotEnd.isAfter(reservation.startDateTime)) {
        return true; // Conflict!
      }
    }

    return false; // No conflicts
  }
}
