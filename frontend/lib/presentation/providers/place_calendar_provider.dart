import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/place_colors.dart';
import '../../core/models/place/place.dart';
import '../../core/models/place/place_reservation.dart';

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
  final Set<String> selectedPlaceIds;
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
  List<PlaceReservation> getReservationsForPlace(String placeId) {
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
  Color getColorForPlace(String placeId) {
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
    Set<String>? selectedPlaceIds,
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
  PlaceCalendarNotifier() : super(const PlaceCalendarState()) {
    _loadMockData();
  }

  /// Load mock data for testing
  void _loadMockData() {
    // Mock places (5-6 places)
    final mockPlaces = [
      const Place(
        id: 'place-1',
        managingGroupId: 1,
        building: '60주년 기념관',
        roomNumber: '18203',
        alias: 'AISC랩실',
        capacity: 30,
      ),
      const Place(
        id: 'place-2',
        managingGroupId: 1,
        building: '60주년 기념관',
        roomNumber: '18204',
        alias: '세미나실',
        capacity: 20,
      ),
      const Place(
        id: 'place-3',
        managingGroupId: 2,
        building: '창의관',
        roomNumber: '201',
        alias: null,
        capacity: 40,
      ),
      const Place(
        id: 'place-4',
        managingGroupId: 2,
        building: '창의관',
        roomNumber: '202',
        alias: '회의실',
        capacity: 15,
      ),
      const Place(
        id: 'place-5',
        managingGroupId: 3,
        building: '학생회관',
        roomNumber: '301',
        alias: '동아리방',
        capacity: 25,
      ),
    ];

    // Mock reservations (10 reservations)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final mockReservations = [
      // Today
      PlaceReservation(
        id: 1,
        placeId: 'place-1',
        placeName: '60주년 기념관-18203 (AISC랩실)',
        groupId: 1,
        groupName: '컴퓨터공학과',
        groupEventId: 101,
        title: '알고리즘 스터디',
        startDateTime: today.add(const Duration(hours: 14)),
        endDateTime: today.add(const Duration(hours: 16)),
        description: '주간 알고리즘 문제 풀이',
        color: PlaceColors.getColorForPlace(0),
        createdAt: today.subtract(const Duration(days: 3)),
        updatedAt: today.subtract(const Duration(days: 3)),
      ),
      PlaceReservation(
        id: 2,
        placeId: 'place-2',
        placeName: '60주년 기념관-18204 (세미나실)',
        groupId: 1,
        groupName: '컴퓨터공학과',
        groupEventId: 102,
        title: '캡스톤 회의',
        startDateTime: today.add(const Duration(hours: 10)),
        endDateTime: today.add(const Duration(hours: 12)),
        description: '캡스톤 프로젝트 진행 상황 회의',
        color: PlaceColors.getColorForPlace(1),
        createdAt: today.subtract(const Duration(days: 5)),
        updatedAt: today.subtract(const Duration(days: 5)),
      ),
      PlaceReservation(
        id: 3,
        placeId: 'place-3',
        placeName: '창의관-201',
        groupId: 2,
        groupName: '전자공학과',
        groupEventId: 103,
        title: '회로 설계 세미나',
        startDateTime: today.add(const Duration(hours: 15)),
        endDateTime: today.add(const Duration(hours: 17)),
        color: PlaceColors.getColorForPlace(2),
        createdAt: today.subtract(const Duration(days: 2)),
        updatedAt: today.subtract(const Duration(days: 2)),
      ),

      // Tomorrow
      PlaceReservation(
        id: 4,
        placeId: 'place-1',
        placeName: '60주년 기념관-18203 (AISC랩실)',
        groupId: 1,
        groupName: '컴퓨터공학과',
        groupEventId: 104,
        title: 'AI 세미나',
        startDateTime: today.add(const Duration(days: 1, hours: 13)),
        endDateTime: today.add(const Duration(days: 1, hours: 15)),
        description: '딥러닝 최신 논문 리뷰',
        color: PlaceColors.getColorForPlace(0),
        createdAt: today.subtract(const Duration(days: 1)),
        updatedAt: today.subtract(const Duration(days: 1)),
      ),
      PlaceReservation(
        id: 5,
        placeId: 'place-4',
        placeName: '창의관-202 (회의실)',
        groupId: 2,
        groupName: '전자공학과',
        groupEventId: 105,
        title: '학회 정기 모임',
        startDateTime: today.add(const Duration(days: 1, hours: 16)),
        endDateTime: today.add(const Duration(days: 1, hours: 18)),
        color: PlaceColors.getColorForPlace(3),
        createdAt: today.subtract(const Duration(days: 4)),
        updatedAt: today.subtract(const Duration(days: 4)),
      ),

      // Day after tomorrow
      PlaceReservation(
        id: 6,
        placeId: 'place-5',
        placeName: '학생회관-301 (동아리방)',
        groupId: 3,
        groupName: '밴드 동아리',
        groupEventId: 106,
        title: '합주 연습',
        startDateTime: today.add(const Duration(days: 2, hours: 18)),
        endDateTime: today.add(const Duration(days: 2, hours: 21)),
        description: '학교 축제 준비',
        color: PlaceColors.getColorForPlace(4),
        createdAt: today.subtract(const Duration(days: 7)),
        updatedAt: today.subtract(const Duration(days: 7)),
      ),
      PlaceReservation(
        id: 7,
        placeId: 'place-2',
        placeName: '60주년 기념관-18204 (세미나실)',
        groupId: 1,
        groupName: '컴퓨터공학과',
        groupEventId: 107,
        title: '졸업 프로젝트 발표',
        startDateTime: today.add(const Duration(days: 2, hours: 14)),
        endDateTime: today.add(const Duration(days: 2, hours: 17)),
        color: PlaceColors.getColorForPlace(1),
        createdAt: today.subtract(const Duration(days: 10)),
        updatedAt: today.subtract(const Duration(days: 10)),
      ),

      // Next week
      PlaceReservation(
        id: 8,
        placeId: 'place-3',
        placeName: '창의관-201',
        groupId: 2,
        groupName: '전자공학과',
        groupEventId: 108,
        title: '신입생 환영회',
        startDateTime: today.add(const Duration(days: 7, hours: 18)),
        endDateTime: today.add(const Duration(days: 7, hours: 21)),
        description: '신입생 환영 행사',
        color: PlaceColors.getColorForPlace(2),
        createdAt: today.subtract(const Duration(days: 14)),
        updatedAt: today.subtract(const Duration(days: 14)),
      ),
      PlaceReservation(
        id: 9,
        placeId: 'place-1',
        placeName: '60주년 기념관-18203 (AISC랩실)',
        groupId: 1,
        groupName: '컴퓨터공학과',
        groupEventId: 109,
        title: '해커톤 준비',
        startDateTime: today.add(const Duration(days: 8, hours: 10)),
        endDateTime: today.add(const Duration(days: 8, hours: 18)),
        description: '전국 대학생 해커톤 준비',
        color: PlaceColors.getColorForPlace(0),
        createdAt: today.subtract(const Duration(days: 20)),
        updatedAt: today.subtract(const Duration(days: 20)),
      ),
      PlaceReservation(
        id: 10,
        placeId: 'place-4',
        placeName: '창의관-202 (회의실)',
        groupId: 2,
        groupName: '전자공학과',
        groupEventId: 110,
        title: '연구실 세미나',
        startDateTime: today.add(const Duration(days: 9, hours: 15)),
        endDateTime: today.add(const Duration(days: 9, hours: 17)),
        color: PlaceColors.getColorForPlace(3),
        createdAt: today.subtract(const Duration(days: 15)),
        updatedAt: today.subtract(const Duration(days: 15)),
      ),
    ];

    state = state.copyWith(
      places: mockPlaces,
      reservations: mockReservations,
    );
  }

  /// Load places for a group (will be replaced with API call)
  Future<void> loadPlaces(int groupId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO: Replace with actual API call
      // await _placeService.getPlaces(groupId);

      // For now, use mock data (already loaded in constructor)
      await Future.delayed(const Duration(milliseconds: 300));

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '장소 목록을 불러오는데 실패했습니다: $e',
      );
    }
  }

  /// Load reservations for a date range (will be replaced with API call)
  Future<void> loadReservations({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO: Replace with actual API call
      // await _placeService.getReservations(startDate, endDate);

      // For now, use mock data (already loaded in constructor)
      await Future.delayed(const Duration(milliseconds: 300));

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '예약 목록을 불러오는데 실패했습니다: $e',
      );
    }
  }

  /// Toggle place selection
  void togglePlaceSelection(String placeId) {
    final newSelection = Set<String>.from(state.selectedPlaceIds);
    if (newSelection.contains(placeId)) {
      newSelection.remove(placeId);
    } else {
      newSelection.add(placeId);
    }
    state = state.copyWith(selectedPlaceIds: newSelection);
  }

  /// Select a place
  void selectPlace(String placeId) {
    final newSelection = Set<String>.from(state.selectedPlaceIds)..add(placeId);
    state = state.copyWith(selectedPlaceIds: newSelection);
  }

  /// Deselect a place
  void deselectPlace(String placeId) {
    final newSelection = Set<String>.from(state.selectedPlaceIds)..remove(placeId);
    state = state.copyWith(selectedPlaceIds: newSelection);
  }

  /// Clear all place selections
  void clearSelection() {
    state = state.copyWith(selectedPlaceIds: {});
  }

  /// Add a reservation (will be replaced with API call)
  Future<void> addReservation(PlaceReservationRequest request) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO: Replace with actual API call
      // await _placeService.createReservation(request);

      // For now, add to mock data
      await Future.delayed(const Duration(milliseconds: 300));

      // Create mock reservation
      final place = state.places.firstWhere((p) => p.id == request.placeId);
      final newReservation = PlaceReservation(
        id: DateTime.now().millisecondsSinceEpoch ~/  1000, // Use timestamp as int ID
        placeId: request.placeId,
        placeName: place.displayName,
        groupId: 1, // Mock group ID
        groupName: '컴퓨터공학과', // Mock group name
        groupEventId: request.groupEventId,
        title: request.title,
        startDateTime: request.startDateTime,
        endDateTime: request.endDateTime,
        description: request.description,
        color: state.getColorForPlace(request.placeId),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        reservations: [...state.reservations, newReservation],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '예약 추가에 실패했습니다: $e',
      );
      rethrow;
    }
  }

  /// Delete a reservation (will be replaced with API call)
  Future<void> deleteReservation(int reservationId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO: Replace with actual API call
      // await _placeService.deleteReservation(reservationId);

      // For now, remove from mock data
      await Future.delayed(const Duration(milliseconds: 300));

      state = state.copyWith(
        reservations: state.reservations
            .where((r) => r.id != reservationId)
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '예약 삭제에 실패했습니다: $e',
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
