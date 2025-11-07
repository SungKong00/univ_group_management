import 'package:flutter/material.dart';

/// Base interface for all calendar events (personal and group).
/// This interface enables CalendarWeekGridView to handle both PersonalEvent and GroupEvent.
abstract class CalendarEventBase {
  /// Unique identifier for the event.
  int get id;

  /// Event title.
  String get title;

  /// Optional description.
  String? get description;

  /// Optional location.
  String? get location;

  /// Start date and time.
  /// Note: PersonalEvent uses 'startDateTime', GroupEvent uses 'startDate'.
  DateTime get startDateTime;

  /// End date and time.
  /// Note: PersonalEvent uses 'endDateTime', GroupEvent uses 'endDate'.
  DateTime get endDateTime;

  /// Whether this is an all-day event.
  bool get isAllDay;

  /// Event color for UI rendering.
  Color get color;

  /// Returns true if this event occurs on the given date.
  bool occursOn(DateTime date);

  /// Returns the duration of the event.
  Duration get duration;
}
