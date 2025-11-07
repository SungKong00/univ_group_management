import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/calendar_models.dart';
import '../../core/services/calendar_service.dart';
import '../../core/services/local_storage.dart';

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

/// Calendar Snapshot - 캘린더 상태를 메모리에 캐싱하기 위한 스냅샷
class CalendarSnapshot {
  const CalendarSnapshot({
    required this.view,
    required this.focusedDate,
    required this.selectedDate,
  });

  final CalendarViewType view;
  final DateTime focusedDate;
  final DateTime selectedDate;

  /// JSON으로 직렬화 (LocalStorage 저장용)
  Map<String, dynamic> toJson() {
    return {
      'view': view.name,
      'focusedDate': focusedDate.toIso8601String(),
      'selectedDate': selectedDate.toIso8601String(),
    };
  }

  /// JSON에서 복원
  factory CalendarSnapshot.fromJson(Map<String, dynamic> json) {
    return CalendarSnapshot(
      view: CalendarViewType.values.firstWhere(
        (v) => v.name == json['view'],
        orElse: () => CalendarViewType.month,
      ),
      focusedDate: DateTime.parse(json['focusedDate'] as String),
      selectedDate: DateTime.parse(json['selectedDate'] as String),
    );
  }
}

class CalendarEventsNotifier extends StateNotifier<CalendarEventsState> {
  CalendarEventsNotifier(this._service) : super(CalendarEventsState.initial());

  final CalendarService _service;

  /// 메모리 캐시: 캘린더 상태 스냅샷 (탭 전환 시 복원용)
  static CalendarSnapshot? _cachedSnapshot;

  Future<void> initialize() async {
    if (state.hasInitialized) return;

    try {
      // 1. 메모리 스냅샷 확인 (최우선)
      if (_cachedSnapshot != null) {
        if (kDebugMode) {
          developer.log(
            'Restoring calendar state from memory snapshot: ${_cachedSnapshot!.view.name}',
            name: 'CalendarEventsNotifier',
          );
        }
        _loadSnapshot();
        await loadEvents();
        state = state.copyWith(hasInitialized: true);
        return;
      }

      // 2. LocalStorage에서 복원
      final localStorage = LocalStorage.instance;
      final lastViewType = await localStorage.getLastCalendarViewType();
      final lastDate = await localStorage.getLastCalendarDate();

      if (lastViewType != null || lastDate != null) {
        if (kDebugMode) {
          developer.log(
            'Restoring calendar state from LocalStorage: view=$lastViewType, date=$lastDate',
            name: 'CalendarEventsNotifier',
          );
        }

        // 뷰 타입 복원
        CalendarViewType? restoredView;
        if (lastViewType != null) {
          try {
            restoredView = CalendarViewType.values.firstWhere(
              (v) => v.name == lastViewType,
            );
          } catch (_) {
            restoredView = CalendarViewType.month;
          }
        }

        // 날짜 복원
        final restoredDate = lastDate != null ? _normalizeDate(lastDate) : null;

        state = state.copyWith(
          view: restoredView ?? state.view,
          focusedDate: restoredDate ?? state.focusedDate,
          selectedDate: restoredDate ?? state.selectedDate,
        );
      }

      await loadEvents();
      state = state.copyWith(hasInitialized: true);
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Failed to restore calendar state: $e',
          name: 'CalendarEventsNotifier',
          level: 900,
        );
      }
      await loadEvents();
      state = state.copyWith(hasInitialized: true);
    }
  }

  /// 현재 상태를 스냅샷으로 저장 (메모리 캐싱)
  void saveSnapshot() {
    _cachedSnapshot = CalendarSnapshot(
      view: state.view,
      focusedDate: state.focusedDate,
      selectedDate: state.selectedDate,
    );
  }

  /// Clears cached snapshots and resets state (used during logout)
  void clearSnapshots() {
    _cachedSnapshot = null;
    state = CalendarEventsState.initial();
  }

  /// 스냅샷에서 상태 복원
  void _loadSnapshot() {
    if (_cachedSnapshot != null) {
      state = state.copyWith(
        view: _cachedSnapshot!.view,
        focusedDate: _cachedSnapshot!.focusedDate,
        selectedDate: _cachedSnapshot!.selectedDate,
      );
    }
  }

  /// LocalStorage에 현재 상태 저장
  void _saveToLocalStorage() {
    final localStorage = LocalStorage.instance;
    localStorage.saveLastCalendarViewType(state.view.name);
    localStorage.saveLastCalendarDate(state.selectedDate);
  }

  /// dispose 시 자동 저장
  @override
  void dispose() {
    saveSnapshot();
    _saveToLocalStorage();
    super.dispose();
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
    _saveToLocalStorage(); // 뷰 변경 시 즉시 저장
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
    _saveToLocalStorage(); // 날짜 선택 시 즉시 저장
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
