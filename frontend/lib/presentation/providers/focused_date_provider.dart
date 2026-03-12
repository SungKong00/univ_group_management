import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing currently focused date in calendar
final focusedDateProvider =
    StateNotifierProvider<FocusedDateNotifier, DateTime>((ref) {
      return FocusedDateNotifier();
    });

/// Notifier for focused date state management
class FocusedDateNotifier extends StateNotifier<DateTime> {
  FocusedDateNotifier() : super(DateTime.now());

  /// Set focused date
  void setDate(DateTime date) {
    state = date;
  }

  /// Move to previous period (day/week/month depending on view)
  /// amount = 0: day/week unit (determined by current view)
  /// amount = 1: month unit
  void previous(int amount) {
    if (amount == 0) {
      // Day/Week mode: Move by 1 day or 7 days
      // For now, we'll handle both day and week as 7 days
      // The calling code determines which unit to use
      state = state.subtract(const Duration(days: 7));
    } else {
      // Month mode
      state = DateTime(state.year, state.month - amount, state.day);
    }
  }

  /// Move to next period (day/week/month depending on view)
  /// amount = 0: day/week unit (determined by current view)
  /// amount = 1: month unit
  void next(int amount) {
    if (amount == 0) {
      // Day/Week mode: Move by 1 day or 7 days
      state = state.add(const Duration(days: 7));
    } else {
      // Month mode
      state = DateTime(state.year, state.month + amount, state.day);
    }
  }

  /// Move to previous day
  void previousDay() {
    state = state.subtract(const Duration(days: 1));
  }

  /// Move to next day
  void nextDay() {
    state = state.add(const Duration(days: 1));
  }

  /// Move to previous week (7 days)
  void previousWeek() {
    state = state.subtract(const Duration(days: 7));
  }

  /// Move to next week (7 days)
  void nextWeek() {
    state = state.add(const Duration(days: 7));
  }

  /// Reset to today
  void resetToToday() {
    state = DateTime.now();
  }
}
