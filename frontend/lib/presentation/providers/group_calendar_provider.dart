import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/calendar/group_event.dart';
import '../../core/models/calendar/recurrence_pattern.dart';
import '../../core/models/calendar/update_scope.dart';
import '../../core/services/group_calendar_service.dart';

/// State class for group calendar.
class GroupCalendarState {
  const GroupCalendarState({
    required this.events,
    required this.isLoading,
    this.errorMessage,
  });

  factory GroupCalendarState.initial() =>
      const GroupCalendarState(events: [], isLoading: false);

  final List<GroupEvent> events;
  final bool isLoading;
  final String? errorMessage;

  GroupCalendarState copyWith({
    List<GroupEvent>? events,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GroupCalendarState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  /// Returns events that occur on the specified date.
  List<GroupEvent> getEventsForDate(DateTime date) {
    return events.where((event) => event.occursOn(date)).toList();
  }
}

/// Notifier for managing group calendar state.
class GroupCalendarNotifier extends StateNotifier<GroupCalendarState> {
  GroupCalendarNotifier(this._service) : super(GroupCalendarState.initial());

  final GroupCalendarService _service;

  /// Loads events within the specified date range.
  Future<void> loadEvents({
    required int groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!mounted) return; // ✅ dispose 후 실행 방지
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final events = await _service.getEvents(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return; // ✅ 비동기 작업 완료 후 dispose 체크
      state = state.copyWith(isLoading: false, events: events);
    } catch (e, stack) {
      developer.log(
        'Failed to load group events for group $groupId: $e',
        name: 'GroupCalendarNotifier',
        error: e,
        stackTrace: stack,
      );

      if (!mounted) return; // ✅ 에러 처리 전 dispose 체크
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Creates a new group event (single or recurring).
  Future<void> createEvent({
    required int groupId,
    required String title,
    String? description,
    String? locationText,
    int? placeId,
    required DateTime startDate,
    required DateTime endDate,
    bool isAllDay = false,
    bool isOfficial = false,
    required String color,
    RecurrencePattern? recurrence,
  }) async {
    try {
      final newEvents = await _service.createEvent(
        groupId: groupId,
        title: title,
        description: description,
        locationText: locationText,
        placeId: placeId,
        startDate: startDate,
        endDate: endDate,
        isAllDay: isAllDay,
        isOfficial: isOfficial,
        color: color,
        recurrence: recurrence,
      );

      state = state.copyWith(
        events: [...state.events, ...newEvents],
        clearError: true,
      );
    } catch (e, stack) {
      developer.log(
        'Failed to create group event for group $groupId: $e',
        name: 'GroupCalendarNotifier',
        error: e,
        stackTrace: stack,
      );

      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );

      rethrow;
    }
  }

  /// Updates an existing group event.
  Future<void> updateEvent({
    required int groupId,
    required int eventId,
    required String title,
    String? description,
    String? locationText,
    int? placeId,
    required DateTime startDate,
    required DateTime endDate,
    bool isAllDay = false,
    required String color,
    UpdateScope updateScope = UpdateScope.thisEvent,
  }) async {
    try {
      final updatedEvents = await _service.updateEvent(
        groupId: groupId,
        eventId: eventId,
        title: title,
        description: description,
        locationText: locationText,
        placeId: placeId,
        startDate: startDate,
        endDate: endDate,
        isAllDay: isAllDay,
        color: color,
        updateScope: updateScope,
      );

      final newEvents = [...state.events];

      if (updateScope == UpdateScope.thisEvent) {
        newEvents.removeWhere((e) => e.id == eventId);
      } else {
        final targetEvent = newEvents.firstWhere((e) => e.id == eventId);
        final seriesId = targetEvent.seriesId;
        if (seriesId != null) {
          newEvents.removeWhere(
            (e) =>
                e.seriesId == seriesId && e.startDate.isAfter(DateTime.now()),
          );
        }
      }

      newEvents.addAll(updatedEvents);

      state = state.copyWith(events: newEvents, clearError: true);
    } catch (e, stack) {
      developer.log(
        'Failed to update group event $eventId for group $groupId: $e',
        name: 'GroupCalendarNotifier',
        error: e,
        stackTrace: stack,
      );

      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );

      rethrow;
    }
  }

  /// Deletes a group event.
  Future<void> deleteEvent({
    required int groupId,
    required int eventId,
    UpdateScope deleteScope = UpdateScope.thisEvent,
  }) async {
    try {
      await _service.deleteEvent(
        groupId: groupId,
        eventId: eventId,
        deleteScope: deleteScope,
      );

      final newEvents = [...state.events];

      if (deleteScope == UpdateScope.thisEvent) {
        newEvents.removeWhere((e) => e.id == eventId);
      } else {
        final targetEvent = newEvents.firstWhere((e) => e.id == eventId);
        final seriesId = targetEvent.seriesId;
        if (seriesId != null) {
          newEvents.removeWhere(
            (e) =>
                e.seriesId == seriesId && e.startDate.isAfter(DateTime.now()),
          );
        }
      }

      state = state.copyWith(events: newEvents, clearError: true);
    } catch (e, stack) {
      developer.log(
        'Failed to delete group event $eventId for group $groupId: $e',
        name: 'GroupCalendarNotifier',
        error: e,
        stackTrace: stack,
      );

      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );

      rethrow;
    }
  }

  /// Clears the current state.
  void clear() {
    state = GroupCalendarState.initial();
  }
}

/// Provider for group calendar state.
/// Use a separate provider per group by using `.family`.
final groupCalendarProvider = StateNotifierProvider.autoDispose
    .family<GroupCalendarNotifier, GroupCalendarState, int>((ref, groupId) {
      return GroupCalendarNotifier(GroupCalendarService());
    });
