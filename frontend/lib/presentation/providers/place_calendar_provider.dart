import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

import '../../core/constants/place_colors.dart';
import '../../core/models/place/place.dart';
import '../../core/models/place/place_availability.dart';
import '../../core/models/place/place_reservation.dart';
import '../../core/services/place_service.dart';

/// State class for place calendar
class PlaceCalendarState {
  const PlaceCalendarState({
    this.places = const [],
    this.selectedPlaceIds = const {},
    this.reservations = const [],
    this.availabilitiesMap = const {},
      this.requiredDuration,
    this.isLoading = false,
    this.error,
  });

  final List<Place> places;
  final Set<int> selectedPlaceIds;
  final List<PlaceReservation> reservations;
  final Map<int, List<PlaceAvailability>> availabilitiesMap;
  final Duration? requiredDuration; // For multi-place reservation
  final bool isLoading;
  final String? error;

  /// Get selected places
  List<Place> get selectedPlaces {
    return places
        .where((place) => selectedPlaceIds.contains(place.id))
        .toList();
  }

  /// Get reservations for selected places
  List<PlaceReservation> get selectedPlaceReservations {
    return reservations
        .where((reservation) => selectedPlaceIds.contains(reservation.placeId))
        .toList();
  }

  /// Get reservations for a specific place
  List<PlaceReservation> getReservationsForPlace(int placeId) {
    return reservations
        .where((reservation) => reservation.placeId == placeId)
        .toList();
  }

  /// Get reservations for a specific date
  List<PlaceReservation> getReservationsForDate(DateTime date) {
    return selectedPlaceReservations
        .where((reservation) => reservation.occursOn(date))
        .toList();
  }

  /// Get color for a specific place
  Color getColorForPlace(int placeId) {
    final index = places.indexWhere((place) => place.id == placeId);
    if (index == -1) return PlaceColors.palette[0];
    return PlaceColors.getColorForPlace(index);
  }

  /// Get all unique buildings
  Set<String> get buildings {
    return places.map((place) => place.building).toSet();
  }

  /// Get places for a specific building
  List<Place> getPlacesForBuilding(String building) {
    return places.where((place) => place.building == building).toList();
  }

  /// Get availabilities for selected places
  Map<int, List<PlaceAvailability>> get selectedPlaceAvailabilities {
    final result = <int, List<PlaceAvailability>>{};
    for (final placeId in selectedPlaceIds) {
      if (availabilitiesMap.containsKey(placeId)) {
        result[placeId] = availabilitiesMap[placeId]!;
      }
    }
    return result;
  }

  PlaceCalendarState copyWith({
    List<Place>? places,
    Set<int>? selectedPlaceIds,
    List<PlaceReservation>? reservations,
    Map<int, List<PlaceAvailability>>? availabilitiesMap,
    Duration? requiredDuration,
    bool clearDuration = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return PlaceCalendarState(
      places: places ?? this.places,
      selectedPlaceIds: selectedPlaceIds ?? this.selectedPlaceIds,
      reservations: reservations ?? this.reservations,
      availabilitiesMap: availabilitiesMap ?? this.availabilitiesMap,
      requiredDuration:
          clearDuration ? null : (requiredDuration ?? this.requiredDuration),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Provider for place calendar state management
class PlaceCalendarNotifier extends StateNotifier<PlaceCalendarState> {
  PlaceCalendarNotifier() : super(const PlaceCalendarState());

  final PlaceService _placeService = PlaceService();

  /// Load availabilities for selected places
  ///
  /// This method fetches availability schedules for all selected places
  /// Uses PlaceService.getPlaceDetail API for each place
  Future<void> loadAvailabilities() async {
    // Don't load if no places are selected
    if (state.selectedPlaceIds.isEmpty) {
      developer.log(
        'No places selected, skipping availability load',
        name: 'PlaceCalendarProvider',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      developer.log(
        'Loading availabilities for places ${state.selectedPlaceIds.toList()}',
        name: 'PlaceCalendarProvider',
      );

      final availabilitiesMap = <int, List<PlaceAvailability>>{};

      // Fetch availability for each selected place
      for (final placeId in state.selectedPlaceIds) {
        try {
          final placeDetail = await _placeService.getPlaceDetail(placeId);
          if (placeDetail != null && placeDetail.operatingHours.isNotEmpty) {
            // Convert OperatingHoursResponse → PlaceAvailability
            final availabilities = placeDetail.operatingHours
                .where((oh) => !oh.isClosed) // Skip closed days
                .map((oh) => PlaceAvailability(
                      id: oh.id,
                      dayOfWeek: oh.dayOfWeek,
                      startTime: oh.startTime,
                      endTime: oh.endTime,
                      displayOrder: 0, // Single slot per day
                    ))
                .toList();

            availabilitiesMap[placeId] = availabilities;
            developer.log(
              'Loaded ${availabilities.length} operating hours for place $placeId',
              name: 'PlaceCalendarProvider',
            );
          } else {
            // No operating hours → place operates 24/7 or not configured
            availabilitiesMap[placeId] = [];
            developer.log(
              'No operating hours found for place $placeId (24/7 or not configured)',
              name: 'PlaceCalendarProvider',
            );
          }
        } catch (e) {
          developer.log(
            'Error loading availability for place $placeId: $e',
            name: 'PlaceCalendarProvider',
            level: 900,
          );
          // Continue loading other places
          availabilitiesMap[placeId] = [];
        }
      }

      developer.log(
        'Successfully loaded availabilities for ${availabilitiesMap.length} places',
        name: 'PlaceCalendarProvider',
      );

      state = state.copyWith(
        availabilitiesMap: availabilitiesMap,
        isLoading: false,
      );
    } catch (e) {
      developer.log(
        'Error loading availabilities: $e',
        name: 'PlaceCalendarProvider',
        level: 900,
      );
      state = state.copyWith(
        isLoading: false,
        error: '운영 시간 정보를 불러오는데 실패했습니다: $e',
      );
    }
  }

  /// Load reservations for selected places and date range
  ///
  /// This method uses the PlaceService.getPlaceCalendar API which fetches
  /// reservations for multiple places in a single request
  Future<void> loadReservations({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Don't load if no places are selected
    if (state.selectedPlaceIds.isEmpty) {
      developer.log(
        'No places selected, skipping reservation load',
        name: 'PlaceCalendarProvider',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      developer.log(
        'Loading reservations for places ${state.selectedPlaceIds.toList()} from $startDate to $endDate',
        name: 'PlaceCalendarProvider',
      );

      // Fetch reservations for all selected places
      final calendarData = await _placeService.getPlaceCalendar(
        placeIds: state.selectedPlaceIds.toList(),
        startDate: startDate,
        endDate: endDate,
      );

      // Flatten the map into a list of reservations with colors
      final reservations = <PlaceReservation>[];
      for (final entry in calendarData.entries) {
        final placeId = entry.key;
        final placeReservations = entry.value;
        final color = state.getColorForPlace(placeId);

        // Add color to each reservation
        for (final reservation in placeReservations) {
          reservations.add(reservation.copyWith(color: color));
        }
      }

      developer.log(
        'Successfully loaded ${reservations.length} reservations',
        name: 'PlaceCalendarProvider',
      );

      state = state.copyWith(
        reservations: reservations,
        isLoading: false,
      );
    } catch (e) {
      developer.log(
        'Error loading reservations: $e',
        name: 'PlaceCalendarProvider',
        level: 900,
      );
      state = state.copyWith(
        isLoading: false,
        error: '예약 목록을 불러오는데 실패했습니다: $e',
      );
    }
  }

  /// Set available places
  ///
  /// This should be called when places are loaded from another source
  /// (e.g., group settings or place management screen)
  void setPlaces(List<Place> places) {
    developer.log(
      'Setting ${places.length} places',
      name: 'PlaceCalendarProvider',
    );
    state = state.copyWith(places: places);
  }

  /// Toggle place selection
  void togglePlaceSelection(int placeId) {
    if (state.selectedPlaceIds.contains(placeId)) {
      deselectPlace(placeId);
    } else {
      selectPlace(placeId);
    }

    final nowSelected = state.selectedPlaceIds.contains(placeId);
    developer.log(
      'Toggled place $placeId, now selected: $nowSelected',
      name: 'PlaceCalendarProvider',
    );
  }

  /// Select a place
  void selectPlace(int placeId) {
    final newSelection = Set<int>.from(state.selectedPlaceIds)..add(placeId);
    state = state.copyWith(selectedPlaceIds: newSelection);

    developer.log(
      'Selected place $placeId',
      name: 'PlaceCalendarProvider',
    );
  }

  /// Deselect a place
  void deselectPlace(int placeId) {
    final newSelection = Set<int>.from(state.selectedPlaceIds)..remove(placeId);
    state = state.copyWith(
      selectedPlaceIds: newSelection,
      clearDuration: newSelection.length <= 1,
    );

    developer.log(
      'Deselected place $placeId',
      name: 'PlaceCalendarProvider',
    );
  }

  /// Select multiple places
  void selectPlaces(List<int> placeIds) {
    final newSelection = Set<int>.from(state.selectedPlaceIds)..addAll(placeIds);
    state = state.copyWith(selectedPlaceIds: newSelection);

    developer.log(
      'Selected ${placeIds.length} places',
      name: 'PlaceCalendarProvider',
    );
  }

  /// Clear all place selections
  void clearSelection() {
    state = state.copyWith(
      selectedPlaceIds: {},
      clearDuration: true,
    );

    developer.log(
      'Cleared all place selections',
      name: 'PlaceCalendarProvider',
    );
  }

  /// Set required duration for multi-place reservations
  void setRequiredDuration(Duration duration) {
    state = state.copyWith(requiredDuration: duration);

    developer.log(
      'Set required duration to ${duration.inMinutes} minutes',
      name: 'PlaceCalendarProvider',
    );
  }

  /// Clear required duration (e.g., when returning to single place mode)
  void clearRequiredDuration() {
    if (state.requiredDuration == null) return;
    state = state.copyWith(clearDuration: true);

    developer.log(
      'Cleared required duration',
      name: 'PlaceCalendarProvider',
    );
  }

  /// Create a new place reservation
  Future<PlaceReservation> createReservation({
    required int placeId,
    required CreatePlaceReservationRequest request,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      developer.log(
        'Creating reservation for place $placeId',
        name: 'PlaceCalendarProvider',
      );

      // Call API to create reservation
      final reservation = await _placeService.createReservation(
        placeId: placeId,
        request: request,
      );

      // Add color based on place
      final color = state.getColorForPlace(placeId);
      final coloredReservation = reservation.copyWith(color: color);

      // Add to state
      state = state.copyWith(
        reservations: [...state.reservations, coloredReservation],
        isLoading: false,
      );

      developer.log(
        'Successfully created reservation ${reservation.id}',
        name: 'PlaceCalendarProvider',
      );

      return coloredReservation;
    } catch (e) {
      developer.log(
        'Error creating reservation: $e',
        name: 'PlaceCalendarProvider',
        level: 900,
      );
      state = state.copyWith(
        isLoading: false,
        error: '예약 추가에 실패했습니다: $e',
      );
      rethrow;
    }
  }

  /// Update an existing reservation
  Future<PlaceReservation> updateReservation({
    required int reservationId,
    required UpdatePlaceReservationRequest request,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      developer.log(
        'Updating reservation $reservationId',
        name: 'PlaceCalendarProvider',
      );

      // Call API to update reservation
      final reservation = await _placeService.updateReservation(
        reservationId: reservationId,
        request: request,
      );

      // Add color based on place
      final color = state.getColorForPlace(reservation.placeId);
      final coloredReservation = reservation.copyWith(color: color);

      // Update in state
      final updatedReservations = state.reservations.map((r) {
        if (r.id == reservationId) {
          return coloredReservation;
        }
        return r;
      }).toList();

      state = state.copyWith(
        reservations: updatedReservations,
        isLoading: false,
      );

      developer.log(
        'Successfully updated reservation $reservationId',
        name: 'PlaceCalendarProvider',
      );

      return coloredReservation;
    } catch (e) {
      developer.log(
        'Error updating reservation: $e',
        name: 'PlaceCalendarProvider',
        level: 900,
      );
      state = state.copyWith(
        isLoading: false,
        error: '예약 수정에 실패했습니다: $e',
      );
      rethrow;
    }
  }

  /// Cancel a reservation
  Future<void> cancelReservation(int reservationId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      developer.log(
        'Canceling reservation $reservationId',
        name: 'PlaceCalendarProvider',
      );

      // Call API to cancel reservation
      await _placeService.cancelReservation(reservationId);

      // Remove from state
      state = state.copyWith(
        reservations: state.reservations
            .where((r) => r.id != reservationId)
            .toList(),
        isLoading: false,
      );

      developer.log(
        'Successfully canceled reservation $reservationId',
        name: 'PlaceCalendarProvider',
      );
    } catch (e) {
      developer.log(
        'Error canceling reservation: $e',
        name: 'PlaceCalendarProvider',
        level: 900,
      );
      state = state.copyWith(
        isLoading: false,
        error: '예약 취소에 실패했습니다: $e',
      );
      rethrow;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider instance
final placeCalendarProvider =
    StateNotifierProvider<PlaceCalendarNotifier, PlaceCalendarState>((ref) {
  return PlaceCalendarNotifier();
});
