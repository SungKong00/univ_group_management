import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/calendar_models.dart';
import '../../core/services/calendar_service.dart';

class TimetableState {
  const TimetableState({
    required this.schedules,
    required this.isLoading,
    required this.isSubmitting,
    required this.weekStart,
    required this.hasLoaded,
    required this.isOverlapView,
    required this.isAddMode,
    this.loadErrorMessage,
    this.snackbarMessage,
    this.snackbarIsError = false,
  });

  factory TimetableState.initial() {
    final now = DateTime.now();
    return TimetableState(
      schedules: const [],
      isLoading: false,
      isSubmitting: false,
      weekStart: _startOfWeek(now),
      hasLoaded: false,
      isOverlapView: true,
      isAddMode: false,
      loadErrorMessage: null,
      snackbarMessage: null,
      snackbarIsError: false,
    );
  }

  final List<PersonalSchedule> schedules;
  final bool isLoading;
  final bool isSubmitting;
  final DateTime weekStart;
  final bool hasLoaded;
  final bool isOverlapView; // 겹친 일정 펼치기 상태
  final bool isAddMode; // 일정 추가 모드 상태
  final String? loadErrorMessage;
  final String? snackbarMessage;
  final bool snackbarIsError;

  TimetableState copyWith({
    List<PersonalSchedule>? schedules,
    bool? isLoading,
    bool? isSubmitting,
    DateTime? weekStart,
    bool? hasLoaded,
    bool? isOverlapView,
    bool? isAddMode,
    String? loadErrorMessage,
    String? snackbarMessage,
    bool? snackbarIsError,
    bool clearLoadError = false,
    bool clearSnackbar = false,
  }) {
    return TimetableState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      weekStart: weekStart ?? this.weekStart,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      isOverlapView: isOverlapView ?? this.isOverlapView,
      isAddMode: isAddMode ?? this.isAddMode,
      loadErrorMessage: clearLoadError
          ? null
          : loadErrorMessage ?? this.loadErrorMessage,
      snackbarMessage: clearSnackbar
          ? null
          : snackbarMessage ?? this.snackbarMessage,
      snackbarIsError: clearSnackbar
          ? false
          : snackbarIsError ?? this.snackbarIsError,
    );
  }
}

class TimetableStateNotifier extends StateNotifier<TimetableState> {
  TimetableStateNotifier(this._service) : super(TimetableState.initial());

  final CalendarService _service;

  Future<void> loadSchedules({bool force = false}) async {
    if (state.isLoading || (!force && state.hasLoaded)) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearLoadError: true,
      clearSnackbar: true,
    );

    try {
      final schedules = await _service.getPersonalSchedules();
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        schedules: _sortedSchedules(schedules),
        clearLoadError: true,
      );
    } catch (e) {
      developer.log(
        'Failed to load schedules: $e',
        name: 'TimetableProvider',
        level: 900,
      );
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        loadErrorMessage: _messageFromError(e),
      );
    }
  }

  Future<bool> refresh() async {
    await loadSchedules(force: true);
    return !state.isLoading && state.loadErrorMessage == null;
  }

  Future<bool> createSchedule(PersonalScheduleRequest request) async {
    state = state.copyWith(isSubmitting: true, clearSnackbar: true);
    try {
      final created = await _service.createPersonalSchedule(request);
      final updated = [...state.schedules, created];
      state = state.copyWith(
        isSubmitting: false,
        schedules: _sortedSchedules(updated),
        snackbarMessage: '새로운 일정을 추가했어요.',
        snackbarIsError: false,
      );
      return true;
    } catch (e) {
      developer.log(
        'Failed to create schedule: $e',
        name: 'TimetableProvider',
        level: 900,
      );
      state = state.copyWith(
        isSubmitting: false,
        snackbarMessage: _messageFromError(e),
        snackbarIsError: true,
      );
      return false;
    }
  }

  Future<bool> updateSchedule(int id, PersonalScheduleRequest request) async {
    state = state.copyWith(isSubmitting: true, clearSnackbar: true);
    try {
      final updatedSchedule = await _service.updatePersonalSchedule(
        id,
        request,
      );
      final updated = state.schedules
          .map((s) => s.id == id ? updatedSchedule : s)
          .toList();
      state = state.copyWith(
        isSubmitting: false,
        schedules: _sortedSchedules(updated),
        snackbarMessage: '일정을 수정했습니다.',
        snackbarIsError: false,
      );
      return true;
    } catch (e) {
      developer.log(
        'Failed to update schedule: $e',
        name: 'TimetableProvider',
        level: 900,
      );
      state = state.copyWith(
        isSubmitting: false,
        snackbarMessage: _messageFromError(e),
        snackbarIsError: true,
      );
      return false;
    }
  }

  Future<bool> deleteSchedule(int id) async {
    state = state.copyWith(isSubmitting: true, clearSnackbar: true);
    try {
      await _service.deletePersonalSchedule(id);
      final updated = state.schedules.where((s) => s.id != id).toList();
      state = state.copyWith(
        isSubmitting: false,
        schedules: updated,
        snackbarMessage: '일정을 삭제했습니다.',
        snackbarIsError: false,
      );
      return true;
    } catch (e) {
      developer.log(
        'Failed to delete schedule: $e',
        name: 'TimetableProvider',
        level: 900,
      );
      state = state.copyWith(
        isSubmitting: false,
        snackbarMessage: _messageFromError(e),
        snackbarIsError: true,
      );
      return false;
    }
  }

  bool hasOverlap(PersonalScheduleRequest request, {int? excludeId}) {
    final candidates = state.schedules.where((schedule) {
      if (schedule.dayOfWeek != request.dayOfWeek) {
        return false;
      }
      if (excludeId != null && schedule.id == excludeId) {
        return false;
      }
      return true;
    });

    final start = _minutesSinceMidnight(request.startTime);
    final end = _minutesSinceMidnight(request.endTime);

    for (final schedule in candidates) {
      final existingStart = schedule.startMinutes;
      final existingEnd = schedule.endMinutes;

      final overlaps = start < existingEnd && end > existingStart;
      if (overlaps) {
        return true;
      }
    }
    return false;
  }

  void goToPreviousWeek() {
    final previous = state.weekStart.subtract(const Duration(days: 7));
    state = state.copyWith(weekStart: previous);
  }

  void goToNextWeek() {
    final next = state.weekStart.add(const Duration(days: 7));
    state = state.copyWith(weekStart: next);
  }

  void goToCurrentWeek() {
    state = state.copyWith(weekStart: _startOfWeek(DateTime.now()));
  }

  void clearSnackbar() {
    state = state.copyWith(clearSnackbar: true);
  }

  void toggleOverlapView() {
    state = state.copyWith(isOverlapView: !state.isOverlapView);
  }

  void toggleAddMode() {
    state = state.copyWith(isAddMode: !state.isAddMode);
  }

  static List<PersonalSchedule> _sortedSchedules(
    List<PersonalSchedule> schedules,
  ) {
    final sorted = [...schedules];
    sorted.sort((a, b) {
      final dayCompare = a.dayOfWeek.index.compareTo(b.dayOfWeek.index);
      if (dayCompare != 0) {
        return dayCompare;
      }
      return a.startMinutes.compareTo(b.startMinutes);
    });
    return sorted;
  }

  static int _minutesSinceMidnight(TimeOfDay value) =>
      value.hour * 60 + value.minute;
}

final timetableStateProvider =
    StateNotifierProvider<TimetableStateNotifier, TimetableState>((ref) {
      return TimetableStateNotifier(CalendarService());
    });

DateTime _startOfWeek(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final difference = normalized.weekday - DateTime.monday;
  return normalized.subtract(Duration(days: difference < 0 ? 6 : difference));
}

String _messageFromError(Object error) {
  final raw = error.toString();
  const prefix = 'Exception: ';
  if (raw.startsWith(prefix)) {
    return raw.substring(prefix.length);
  }
  return raw;
}
