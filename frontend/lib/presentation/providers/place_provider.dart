import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/place/place.dart';
import '../../core/models/place/place_availability.dart';
import '../../core/models/place/place_detail_response.dart';
import '../../core/models/place/place_usage_group.dart';
import '../../core/services/place_service.dart';

// ===== Service Provider =====

/// Provider for PlaceService singleton
final placeServiceProvider = Provider<PlaceService>((ref) {
  return PlaceService();
});

// ===== Data Providers =====

/// Provider for fetching all places
///
/// Returns a list of all places available in the system.
/// Automatically disposes when no longer in use.
final placesProvider = FutureProvider.autoDispose<List<Place>>((ref) async {
  final placeService = ref.watch(placeServiceProvider);

  developer.log(
    'Fetching all places',
    name: 'PlaceProvider',
  );

  try {
    final places = await placeService.getAllPlaces();

    developer.log(
      'Successfully fetched ${places.length} places',
      name: 'PlaceProvider',
    );

    return places;
  } catch (e, stack) {
    developer.log(
      'Failed to fetch places: $e',
      name: 'PlaceProvider',
      error: e,
      stackTrace: stack,
    );
    rethrow;
  }
});

/// Provider for fetching place detail with availabilities
///
/// Returns detailed information about a specific place including
/// its availability schedules and approved group count.
/// Uses family pattern to support multiple place IDs.
final placeDetailProvider = FutureProvider.family
    .autoDispose<PlaceDetailResponse?, int>((ref, placeId) async {
  final placeService = ref.watch(placeServiceProvider);

  developer.log(
    'Fetching place detail for place $placeId',
    name: 'PlaceProvider',
  );

  try {
    final detail = await placeService.getPlaceDetail(placeId);

    if (detail != null) {
      developer.log(
        'Successfully fetched place detail for place $placeId',
        name: 'PlaceProvider',
      );
    } else {
      developer.log(
        'Place detail not found for place $placeId',
        name: 'PlaceProvider',
        level: 900,
      );
    }

    return detail;
  } catch (e, stack) {
    developer.log(
      'Failed to fetch place detail for place $placeId: $e',
      name: 'PlaceProvider',
      error: e,
      stackTrace: stack,
    );
    rethrow;
  }
});

// ===== State Management Provider =====

/// State class for place management
class PlaceManagementState {
  const PlaceManagementState({
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.isSettingAvailabilities = false,
    this.error,
  });

  final bool isCreating;
  final bool isUpdating;
  final bool isDeleting;
  final bool isSettingAvailabilities;
  final String? error;

  bool get isLoading =>
      isCreating || isUpdating || isDeleting || isSettingAvailabilities;

  PlaceManagementState copyWith({
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    bool? isSettingAvailabilities,
    String? error,
    bool clearError = false,
  }) {
    return PlaceManagementState(
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      isSettingAvailabilities:
          isSettingAvailabilities ?? this.isSettingAvailabilities,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for place management operations
class PlaceManagementNotifier extends StateNotifier<PlaceManagementState> {
  PlaceManagementNotifier(this._placeService)
      : super(const PlaceManagementState());

  final PlaceService _placeService;

  /// Create a new place
  Future<Place> createPlace(CreatePlaceRequest request) async {
    state = state.copyWith(isCreating: true, clearError: true);

    try {
      developer.log(
        'Creating place: ${request.building} ${request.roomNumber}',
        name: 'PlaceManagementNotifier',
      );

      final place = await _placeService.createPlace(request);

      state = state.copyWith(isCreating: false);

      developer.log(
        'Successfully created place ${place.id}',
        name: 'PlaceManagementNotifier',
      );

      return place;
    } catch (e, stack) {
      developer.log(
        'Failed to create place: $e',
        name: 'PlaceManagementNotifier',
        error: e,
        stackTrace: stack,
      );

      state = state.copyWith(
        isCreating: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );

      rethrow;
    }
  }

  /// Update an existing place
  Future<Place> updatePlace(int id, UpdatePlaceRequest request) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      developer.log(
        'Updating place $id',
        name: 'PlaceManagementNotifier',
      );

      final place = await _placeService.updatePlace(id, request);

      state = state.copyWith(isUpdating: false);

      developer.log(
        'Successfully updated place $id',
        name: 'PlaceManagementNotifier',
      );

      return place;
    } catch (e, stack) {
      developer.log(
        'Failed to update place $id: $e',
        name: 'PlaceManagementNotifier',
        error: e,
        stackTrace: stack,
      );

      state = state.copyWith(
        isUpdating: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );

      rethrow;
    }
  }

  /// Delete a place
  Future<void> deletePlace(int id) async {
    state = state.copyWith(isDeleting: true, clearError: true);

    try {
      developer.log(
        'Deleting place $id',
        name: 'PlaceManagementNotifier',
      );

      await _placeService.deletePlace(id);

      state = state.copyWith(isDeleting: false);

      developer.log(
        'Successfully deleted place $id',
        name: 'PlaceManagementNotifier',
      );
    } catch (e, stack) {
      developer.log(
        'Failed to delete place $id: $e',
        name: 'PlaceManagementNotifier',
        error: e,
        stackTrace: stack,
      );

      state = state.copyWith(
        isDeleting: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );

      rethrow;
    }
  }

  /// Set availabilities for a place
  Future<void> setAvailabilities(
    int placeId,
    List<AvailabilityRequest> availabilities,
  ) async {
    state = state.copyWith(isSettingAvailabilities: true, clearError: true);

    try {
      developer.log(
        'Setting ${availabilities.length} availabilities for place $placeId',
        name: 'PlaceManagementNotifier',
      );

      await _placeService.setAvailabilities(placeId, availabilities);

      state = state.copyWith(isSettingAvailabilities: false);

      developer.log(
        'Successfully set availabilities for place $placeId',
        name: 'PlaceManagementNotifier',
      );
    } catch (e, stack) {
      developer.log(
        'Failed to set availabilities for place $placeId: $e',
        name: 'PlaceManagementNotifier',
        error: e,
        stackTrace: stack,
      );

      state = state.copyWith(
        isSettingAvailabilities: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );

      rethrow;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for place management operations
final placeManagementProvider =
    StateNotifierProvider<PlaceManagementNotifier, PlaceManagementState>(
        (ref) {
  final placeService = ref.watch(placeServiceProvider);
  return PlaceManagementNotifier(placeService);
});

// ===== Place Usage Permission Providers =====

/// Provider for fetching pending usage requests for a place
///
/// Returns a list of pending usage requests that need approval.
/// Uses family pattern to support multiple place IDs.
final pendingUsageRequestsProvider = FutureProvider.family
    .autoDispose<List<PlaceUsageGroup>, int>((ref, placeId) async {
  final placeService = ref.watch(placeServiceProvider);

  developer.log(
    'Fetching pending usage requests for place $placeId',
    name: 'PlaceProvider',
  );

  try {
    final requests = await placeService.getPendingRequests(placeId);

    developer.log(
      'Successfully fetched ${requests.length} pending requests',
      name: 'PlaceProvider',
    );

    return requests;
  } catch (e, stack) {
    developer.log(
      'Failed to fetch pending requests for place $placeId: $e',
      name: 'PlaceProvider',
      error: e,
      stackTrace: stack,
    );
    rethrow;
  }
});

/// Provider for fetching approved usage groups for a place
///
/// Returns a list of groups that have been approved to use the place.
/// Uses family pattern to support multiple place IDs.
final approvedUsageGroupsProvider = FutureProvider.family
    .autoDispose<List<PlaceUsageGroup>, int>((ref, placeId) async {
  final placeService = ref.watch(placeServiceProvider);

  developer.log(
    'Fetching approved usage groups for place $placeId',
    name: 'PlaceProvider',
  );

  try {
    final groups = await placeService.getApprovedGroups(placeId);

    developer.log(
      'Successfully fetched ${groups.length} approved groups',
      name: 'PlaceProvider',
    );

    return groups;
  } catch (e, stack) {
    developer.log(
      'Failed to fetch approved groups for place $placeId: $e',
      name: 'PlaceProvider',
      error: e,
      stackTrace: stack,
    );
    rethrow;
  }
});
