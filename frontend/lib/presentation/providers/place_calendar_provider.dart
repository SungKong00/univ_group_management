import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

import '../../core/constants/place_colors.dart';
import '../../core/models/place/place.dart';
import '../../core/models/place/place_reservation.dart';
import '../../core/services/place_service.dart';

/// State class for place calendar
class PlaceCalendarState {
  const PlaceCalendarState({
    this.places = const [],
    this.selectedPlaceIds = const {},
    this.reservations = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Place> places;
  final Set<int> selectedPlaceIds;
  final List<PlaceReservation> reservations;
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

  PlaceCalendarState copyWith({
    List<Place>? places,
    Set<int>? selectedPlaceIds,
    List<PlaceReservation>? reservations,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return PlaceCalendarState(
      places: places ?? this.places,
      selectedPlaceIds: selectedPlaceIds ?? this.selectedPlaceIds,
      reservations: reservations ?? this.reservations,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Provider for place calendar state management
class PlaceCalendarNotifier extends StateNotifier<PlaceCalendarState> {
  PlaceCalendarNotifier() : super(const PlaceCalendarState());

  final PlaceService _placeService = PlaceService();

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
    final newSelection = Set<int>.from(state.selectedPlaceIds);
    if (newSelection.contains(placeId)) {
      newSelection.remove(placeId);
    } else {
      newSelection.add(placeId);
    }
    state = state.copyWith(selectedPlaceIds: newSelection);

    developer.log(
      'Toggled place $placeId, now selected: ${newSelection.contains(placeId)}',
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
    state = state.copyWith(selectedPlaceIds: newSelection);

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
    state = state.copyWith(selectedPlaceIds: {});

    developer.log(
      'Cleared all place selections',
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
