import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums/calendar_view.dart';

/// Provider for managing calendar view mode (day/week/month)
final calendarViewProvider =
    StateNotifierProvider<CalendarViewNotifier, CalendarView>((ref) {
      return CalendarViewNotifier();
    });

/// Notifier for calendar view state management
class CalendarViewNotifier extends StateNotifier<CalendarView> {
  CalendarViewNotifier() : super(CalendarView.month);

  /// Set calendar view mode
  void setView(CalendarView view) {
    state = view;
  }
}
