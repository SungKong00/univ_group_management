import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/calendar_models.dart';
import '../../core/services/calendar_service.dart';

enum CalendarViewType { month, week, day }

class CalendarEventsState {
  const CalendarEventsState({
    required this.events,
    required this.isLoading,
    required this.isMutating,
    required this.view,
    required this.focusedDate,
    required this.selectedDate,
    this.rangeStart,
    this.rangeEnd,
    this.loadErrorMessage,
    this.snackbarMessage,
    this.snackbarIsError = false,
    this.hasInitialized = false,
  });

  factory CalendarEventsState.initial() {
    final today = DateTime.now();
    final normalizedToday = _normalizeDate(today);
    return CalendarEventsState(
      events: const [],
      isLoading: false,
      isMutating: false,
      view: CalendarViewType.month,
      focusedDate: normalizedToday,
      selectedDate: normalizedToday,
      hasInitialized: false,
    );
  }

  final List<PersonalEvent> events;
  final bool isLoading;
  final bool isMutating;
  final CalendarViewType view;
  final DateTime focusedDate;
  final DateTime selectedDate;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final String? loadErrorMessage;
  final String? snackbarMessage;
  final bool snackbarIsError;
  final bool hasInitialized;

  UnmodifiableMapView<DateTime, List<PersonalEvent>> get eventsByDate {
    final map = <DateTime, List<PersonalEvent>>{};
    for (final event in events) {
      var current = _normalizeDate(event.startDateTime);
      final last = _normalizeDate(event.endDateTime);
      while (!current.isAfter(last)) {
        map.putIfAbsent(current, () => []).add(event);
        current = current.add(const Duration(days: 1));
      }
    }
    return UnmodifiableMapView(map);
  }

  CalendarEventsState copyWith({
    List<PersonalEvent>? events,
    bool? isLoading,
    bool? isMutating,
    CalendarViewType? view,
    DateTime? focusedDate,
    DateTime? selectedDate,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    String? loadErrorMessage,
    String? snackbarMessage,
    bool? snackbarIsError,
    bool? hasInitialized,
    bool clearLoadError = false,
    bool clearSnackbar = false,
  }) {
    return CalendarEventsState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      view: view ?? this.view,
      focusedDate: focusedDate ?? this.focusedDate,
      selectedDate: selectedDate ?? this.selectedDate,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
      loadErrorMessage:
          clearLoadError ? null : loadErrorMessage ?? this.loadErrorMessage,
      snackbarMessage:
          clearSnackbar ? null : snackbarMessage ?? this.snackbarMessage,
      snackbarIsError:
          clearSnackbar ? false : snackbarIsError ?? this.snackbarIsError,
      hasInitialized: hasInitialized ?? this.hasInitialized,
    );
  }
}

class CalendarEventsNotifier extends StateNotifier<CalendarEventsState> {
  CalendarEventsNotifier(this._service) : super(CalendarEventsState.initial());

  final CalendarService _service;

  Future<void> initialize() async {
    if (state.hasInitialized) return;
    await loadEvents();
    state = state.copyWith(hasInitialized: true);
  }

  Future<void> loadEvents({bool force = false}) async {
    if (state.isLoading) return;

    final range = _calculateRange(state.view, state.focusedDate, state.selectedDate);
    if (!force &&
        state.rangeStart != null &&
        state.rangeEnd != null &&
        state.rangeStart == range.start &&
        state.rangeEnd == range.end) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearLoadError: true,
    );

    try {
      final events = await _service.getPersonalEvents(range.start, range.end);
      state = state.copyWith(
        isLoading: false,
        events: _sortedEvents(events),
        rangeStart: range.start,
        rangeEnd: range.end,
        clearLoadError: true,
      );
    } catch (e, stack) {
      developer.log('Failed to load personal events: $e',
          name: 'CalendarEventsNotifier', error: e, stackTrace: stack);
      state = state.copyWith(
        isLoading: false,
        loadErrorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() async {
    await loadEvents(force: true);
  }

  void changeView(CalendarViewType view) {
    if (state.view == view) return;
    final adjusted =
        view == CalendarViewType.day ? state.selectedDate : state.focusedDate;
    state = state.copyWith(view: view, focusedDate: adjusted);
    loadEvents();
  }

  void goToToday() {
    final today = _normalizeDate(DateTime.now());
    state = state.copyWith(focusedDate: today, selectedDate: today);
    loadEvents(force: true);
  }

  void goToNextRange() {
    final next = _advance(
      state.focusedDate,
      state.view,
      forward: true,
    );
    state = state.copyWith(focusedDate: next);
    loadEvents();
  }

  void goToPreviousRange() {
    final previous = _advance(
      state.focusedDate,
      state.view,
      forward: false,
    );
    state = state.copyWith(focusedDate: previous);
    loadEvents();
  }

  void selectDate(DateTime date) {
    final normalized = _normalizeDate(date);
    state = state.copyWith(selectedDate: normalized, focusedDate: normalized);
    loadEvents();
  }

  void setFocusedDate(DateTime date) {
    final normalized = _normalizeDate(date);
    state = state.copyWith(focusedDate: normalized);
    loadEvents();
  }

  Future<bool> createEvent(PersonalEventRequest request) async {
    state = state.copyWith(isMutating: true, clearSnackbar: true);
    try {
      final created = await _service.createPersonalEvent(request);
      final events = _sortedEvents([...state.events, created]);
      state = state.copyWith(
        isMutating: false,
        events: events,
        snackbarMessage: '이벤트를 추가했습니다.',
        snackbarIsError: false,
      );
      return true;
    } catch (e, stack) {
      developer.log('Failed to create event: $e',
          name: 'CalendarEventsNotifier', error: e, stackTrace: stack);
      state = state.copyWith(
        isMutating: false,
        snackbarMessage: e.toString().replaceFirst('Exception: ', ''),
        snackbarIsError: true,
      );
      return false;
    }
  }

  Future<bool> updateEvent(int id, PersonalEventRequest request) async {
    state = state.copyWith(isMutating: true, clearSnackbar: true);
    try {
      final updated = await _service.updatePersonalEvent(id, request);
      final events =
          state.events.map((event) => event.id == id ? updated : event).toList();
      state = state.copyWith(
        isMutating: false,
        events: _sortedEvents(events),
        snackbarMessage: '이벤트를 수정했습니다.',
        snackbarIsError: false,
      );
      return true;
    } catch (e, stack) {
      developer.log('Failed to update event: $e',
          name: 'CalendarEventsNotifier', error: e, stackTrace: stack);
      state = state.copyWith(
        isMutating: false,
        snackbarMessage: e.toString().replaceFirst('Exception: ', ''),
        snackbarIsError: true,
      );
      return false;
    }
  }

  Future<bool> deleteEvent(int id) async {
    state = state.copyWith(isMutating: true, clearSnackbar: true);
    try {
      await _service.deletePersonalEvent(id);
      final events = state.events.where((event) => event.id != id).toList();
      state = state.copyWith(
        isMutating: false,
        events: events,
        snackbarMessage: '이벤트를 삭제했습니다.',
        snackbarIsError: false,
      );
      return true;
    } catch (e, stack) {
      developer.log('Failed to delete event: $e',
          name: 'CalendarEventsNotifier', error: e, stackTrace: stack);
      state = state.copyWith(
        isMutating: false,
        snackbarMessage: e.toString().replaceFirst('Exception: ', ''),
        snackbarIsError: true,
      );
      return false;
    }
  }

  void clearSnackbar() {
    state = state.copyWith(clearSnackbar: true);
  }

  static List<PersonalEvent> _sortedEvents(List<PersonalEvent> events) {
    final sorted = [...events];
    sorted.sort((a, b) {
      final startCompare = a.startDateTime.compareTo(b.startDateTime);
      if (startCompare != 0) {
        return startCompare;
      }
      return a.endDateTime.compareTo(b.endDateTime);
    });
    return sorted;
  }
}

final calendarEventsProvider =
    StateNotifierProvider<CalendarEventsNotifier, CalendarEventsState>((ref) {
  return CalendarEventsNotifier(CalendarService());
});

class _DateRange {
  const _DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

_DateRange _calculateRange(
  CalendarViewType view,
  DateTime focused,
  DateTime selected,
) {
  switch (view) {
    case CalendarViewType.month:
      final startOfMonth = DateTime(focused.year, focused.month, 1);
      final endOfMonth = DateTime(focused.year, focused.month + 1, 1)
          .subtract(const Duration(days: 1));
      return _DateRange(start: startOfMonth, end: endOfMonth);
    case CalendarViewType.week:
      final weekday = focused.weekday; // 1 = Monday … 7 = Sunday
      final start = focused.subtract(Duration(days: weekday - DateTime.monday));
      final end = start.add(const Duration(days: 6));
      return _DateRange(start: start, end: end);
    case CalendarViewType.day:
      final day = _normalizeDate(selected);
      return _DateRange(start: day, end: day);
  }
}

DateTime _advance(
  DateTime current,
  CalendarViewType view, {
  required bool forward,
}) {
  final delta = forward ? 1 : -1;
  switch (view) {
    case CalendarViewType.month:
      return DateTime(current.year, current.month + delta, current.day);
    case CalendarViewType.week:
      return current.add(Duration(days: 7 * delta));
    case CalendarViewType.day:
      return current.add(Duration(days: delta));
  }
}

DateTime _normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);
