import 'dart:developer' as developer;
import '../models/auth_models.dart';
import '../models/place/place.dart';
import '../models/place/place_availability.dart';
import '../models/place/place_detail_response.dart';
import '../models/place/place_reservation.dart';
import '../models/place/place_usage_group.dart';
import '../network/dio_client.dart';

/// Place Service
///
/// Provides API methods for managing places and their reservations.
class PlaceService {
  static final PlaceService _instance = PlaceService._internal();
  factory PlaceService() => _instance;
  PlaceService._internal();

  final DioClient _dioClient = DioClient();

  // ===== Place Reservation APIs =====

  /// Create a new place reservation
  ///
  /// POST /api/places/{placeId}/reservations
  /// Returns the created reservation
  Future<PlaceReservation> createReservation({
    required int placeId,
    required CreatePlaceReservationRequest request,
  }) async {
    try {
      developer.log(
        'Creating reservation for place $placeId',
        name: 'PlaceService',
      );

      final response = await _dioClient.post<Map<String, dynamic>>(
        '/places/$placeId/reservations',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => PlaceReservation.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully created reservation ${apiResponse.data!.id}',
            name: 'PlaceService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to create reservation: ${apiResponse.message}',
            name: 'PlaceService',
            level: 900,
          );
          throw Exception(apiResponse.message ?? 'Failed to create reservation');
        }
      } else {
        throw Exception('Empty response from server');
      }
    } catch (e) {
      developer.log(
        'Error creating reservation: $e',
        name: 'PlaceService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Get reservations for a specific place
  ///
  /// GET /api/places/{placeId}/reservations?startDate={date}&endDate={date}
  /// Returns list of reservations for the given date range
  Future<List<PlaceReservation>> getReservations({
    required int placeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      developer.log(
        'Fetching reservations for place $placeId from $startDate to $endDate',
        name: 'PlaceService',
      );

      // Format dates as yyyy-MM-dd
      final startDateStr = _formatDate(startDate);
      final endDateStr = _formatDate(endDate);

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/places/$placeId/reservations',
        queryParameters: {
          'startDate': startDateStr,
          'endDate': endDateStr,
        },
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is List) {
            return json
                .map(
                  (item) =>
                      PlaceReservation.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
          return <PlaceReservation>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched ${apiResponse.data!.length} reservations',
            name: 'PlaceService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch reservations: ${apiResponse.message}',
            name: 'PlaceService',
            level: 900,
          );
          return [];
        }
      }

      return [];
    } catch (e) {
      developer.log(
        'Error fetching reservations: $e',
        name: 'PlaceService',
        level: 900,
      );
      return [];
    }
  }

  /// Update an existing reservation
  ///
  /// PATCH /api/reservations/{reservationId}
  /// Returns the updated reservation
  Future<PlaceReservation> updateReservation({
    required int reservationId,
    required UpdatePlaceReservationRequest request,
  }) async {
    try {
      developer.log(
        'Updating reservation $reservationId',
        name: 'PlaceService',
      );

      final response = await _dioClient.patch<Map<String, dynamic>>(
        '/reservations/$reservationId',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => PlaceReservation.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully updated reservation $reservationId',
            name: 'PlaceService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to update reservation: ${apiResponse.message}',
            name: 'PlaceService',
            level: 900,
          );
          throw Exception(apiResponse.message ?? 'Failed to update reservation');
        }
      } else {
        throw Exception('Empty response from server');
      }
    } catch (e) {
      developer.log(
        'Error updating reservation: $e',
        name: 'PlaceService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Cancel a reservation
  ///
  /// DELETE /api/reservations/{reservationId}
  Future<void> cancelReservation(int reservationId) async {
    try {
      developer.log(
        'Canceling reservation $reservationId',
        name: 'PlaceService',
      );

      final response = await _dioClient.delete<Map<String, dynamic>>(
        '/reservations/$reservationId',
      );

      // Any 2xx status code is considered success for DELETE operations
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        developer.log(
          'Successfully canceled reservation $reservationId (status: ${response.statusCode})',
          name: 'PlaceService',
        );
        return;
      }

      // Non-2xx responses
      developer.log(
        'Failed to cancel reservation: Unexpected status code ${response.statusCode}',
        name: 'PlaceService',
        level: 900,
      );
      throw Exception('Failed to cancel reservation: Unexpected response status');
    } catch (e) {
      developer.log(
        'Error canceling reservation: $e',
        name: 'PlaceService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Get calendar view for multiple places
  ///
  /// GET /api/places/calendar?placeIds={ids}&startDate={date}&endDate={date}
  /// Returns reservations grouped by place
  Future<Map<int, List<PlaceReservation>>> getPlaceCalendar({
    required List<int> placeIds,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      developer.log(
        'Fetching calendar for places $placeIds from $startDate to $endDate',
        name: 'PlaceService',
      );

      // Format dates as yyyy-MM-dd
      final startDateStr = _formatDate(startDate);
      final endDateStr = _formatDate(endDate);

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/places/calendar',
        queryParameters: {
          'placeIds': placeIds.join(','),
          'startDate': startDateStr,
          'endDate': endDateStr,
        },
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is List) {
            // Parse PlaceCalendarResponse list
            final result = <int, List<PlaceReservation>>{};
            for (final item in json) {
              final map = item as Map<String, dynamic>;
              final placeId = (map['placeId'] as num).toInt();
              final reservations = (map['reservations'] as List)
                  .map((r) =>
                      PlaceReservation.fromJson(r as Map<String, dynamic>))
                  .toList();
              result[placeId] = reservations;
            }
            return result;
          }
          return <int, List<PlaceReservation>>{};
        });

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched calendar for ${apiResponse.data!.length} places',
            name: 'PlaceService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch place calendar: ${apiResponse.message}',
            name: 'PlaceService',
            level: 900,
          );
          return {};
        }
      }

      return {};
    } catch (e) {
      developer.log(
        'Error fetching place calendar: $e',
        name: 'PlaceService',
        level: 900,
      );
      return {};
    }
  }

  // ===== Place Management APIs =====

  /// Get all places
  ///
  /// GET /api/places
  /// Returns list of all places
  Future<List<Place>> getAllPlaces() async {
    try {
      developer.log(
        'Fetching all places',
        name: 'PlaceService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>('/places');

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is List) {
            return json
                .map((item) => Place.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return <Place>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched ${apiResponse.data!.length} places',
            name: 'PlaceService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch places: ${apiResponse.message}',
            name: 'PlaceService',
            level: 900,
          );
          // Return empty list if API reports failure (but no exception)
          return [];
        }
      }

      developer.log(
        'Empty response from server when fetching places',
        name: 'PlaceService',
        level: 900,
      );
      return [];
    } catch (e, stack) {
      developer.log(
        'Error fetching places: $e',
        name: 'PlaceService',
        error: e,
        stackTrace: stack,
        level: 1000, // ERROR level
      );
      // Rethrow to allow Provider to show error state
      rethrow;
    }
  }

  /// Get reservable places for a specific group
  ///
  /// GET /api/groups/{groupId}/reservable-places
  /// Returns list of places the group is approved to use
  Future<List<Place>> getReservablePlaces(int groupId) async {
    try {
      developer.log(
        'Fetching reservable places for group $groupId',
        name: 'PlaceService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>('/groups/$groupId/reservable-places');

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is List) {
            return json
                .map((item) => Place.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return <Place>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched ${apiResponse.data!.length} reservable places for group $groupId',
            name: 'PlaceService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch reservable places: ${apiResponse.message}',
            name: 'PlaceService',
            level: 900,
          );
          return [];
        }
      }

      developer.log(
        'Empty response from server when fetching reservable places',
        name: 'PlaceService',
        level: 900,
      );
      return [];
    } catch (e, stack) {
      developer.log(
        'Error fetching reservable places for group $groupId: $e',
        name: 'PlaceService',
        error: e,
        stackTrace: stack,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Get place detail with availabilities
  ///
  /// GET /api/places/{id}
  /// Returns place detail including availability schedules
  Future<PlaceDetailResponse?> getPlaceDetail(int id) async {
    try {
      developer.log(
        'Fetching place detail for place $id',
        name: 'PlaceService',
      );

      final response =
          await _dioClient.get<Map<String, dynamic>>('/places/$id');

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => PlaceDetailResponse.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched place detail for place $id',
            name: 'PlaceService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch place detail: ${apiResponse.message}',
            name: 'PlaceService',
            level: 900,
          );
          return null;
        }
      }

      developer.log(
        'Empty response from server when fetching place detail',
        name: 'PlaceService',
        level: 900,
      );
      return null;
    } catch (e, stack) {
      developer.log(
        'Error fetching place detail for place $id: $e',
        name: 'PlaceService',
        error: e,
        stackTrace: stack,
        level: 1000, // ERROR level
      );
      // Rethrow to allow Provider to show error state
      rethrow;
    }
  }

  /// Create a new place
  ///
  /// POST /api/places
  /// Returns the created place
  Future<Place> createPlace(CreatePlaceRequest request) async {
    try {
      developer.log(
        'Creating place: ${request.building} ${request.roomNumber}',
        name: 'PlaceService',
      );

      final response = await _dioClient.post<Map<String, dynamic>>(
        '/places',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => Place.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully created place ${apiResponse.data!.id}',
            name: 'PlaceService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to create place: ${apiResponse.message}',
            name: 'PlaceService',
            level: 900,
          );
          throw Exception(apiResponse.message ?? 'Failed to create place');
        }
      } else {
        throw Exception('Empty response from server');
      }
    } catch (e) {
      developer.log(
        'Error creating place: $e',
        name: 'PlaceService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Update an existing place
  ///
  /// PATCH /api/places/{id}
  /// Returns the updated place
  Future<Place> updatePlace(int id, UpdatePlaceRequest request) async {
    try {
      developer.log(
        'Updating place $id',
        name: 'PlaceService',
      );

      final response = await _dioClient.patch<Map<String, dynamic>>(
        '/places/$id',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => Place.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully updated place $id',
            name: 'PlaceService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to update place: ${apiResponse.message}',
            name: 'PlaceService',
            level: 900,
          );
          throw Exception(apiResponse.message ?? 'Failed to update place');
        }
      } else {
        throw Exception('Empty response from server');
      }
    } catch (e) {
      developer.log(
        'Error updating place: $e',
        name: 'PlaceService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Delete a place
  ///
  /// DELETE /api/places/{id}
  Future<void> deletePlace(int id) async {
    try {
      developer.log(
        'Deleting place $id',
        name: 'PlaceService',
      );

      final response =
          await _dioClient.delete<Map<String, dynamic>>('/places/$id');

      // Handle 204 No Content response (successful deletion)
      if (response.statusCode == 204) {
        developer.log(
          'Successfully deleted place $id (204 No Content)',
          name: 'PlaceService',
        );
        return;
      }

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => json,
        );

        if (apiResponse.success) {
          developer.log(
            'Successfully deleted place $id',
            name: 'PlaceService',
          );
        } else {
          developer.log(
            'Failed to delete place: ${apiResponse.message}',
            name: 'PlaceService',
            level: 900,
          );
          throw Exception(apiResponse.message ?? 'Failed to delete place');
        }
      } else {
        // Empty response body but status code is 2xx (success)
        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          developer.log(
            'Successfully deleted place $id (empty response but 2xx status)',
            name: 'PlaceService',
          );
          return;
        }
        throw Exception('Empty response from server');
      }
    } catch (e, stack) {
      developer.log(
        'Error deleting place $id: $e',
        name: 'PlaceService',
        error: e,
        stackTrace: stack,
        level: 1000, // ERROR level
      );
      rethrow;
    }
  }

  /// Set availabilities for a place
  ///
  /// POST /api/places/{placeId}/availabilities
  /// Replaces all existing availabilities with the provided list
  Future<void> setAvailabilities(
    int placeId,
    List<AvailabilityRequest> availabilities,
  ) async {
    try {
      developer.log(
        'Setting ${availabilities.length} availabilities for place $placeId',
        name: 'PlaceService',
      );

      final response = await _dioClient.post<Map<String, dynamic>>(
        '/places/$placeId/availabilities',
        data: availabilities.map((a) => a.toJson()).toList(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => json,
        );

        if (apiResponse.success) {
          developer.log(
            'Successfully set availabilities for place $placeId',
            name: 'PlaceService',
          );
        } else {
          developer.log(
            'Failed to set availabilities: ${apiResponse.message}',
            name: 'PlaceService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to set availabilities',
          );
        }
      } else {
        throw Exception('Empty response from server');
      }
    } catch (e) {
      developer.log(
        'Error setting availabilities: $e',
        name: 'PlaceService',
        level: 900,
      );
      rethrow;
    }
  }

  // ===== Place Usage Permission APIs =====

  /// Create a new usage permission request
  ///
  /// POST /api/places/{placeId}/usage-requests
  /// Returns the created usage group record
  Future<PlaceUsageGroup> createUsageRequest({
    required int placeId,
    String? reason,
  }) async {
    try {
      developer.log(
        'Creating usage request for place $placeId',
        name: 'PlaceService',
      );

      final response = await _dioClient.post<Map<String, dynamic>>(
        '/places/$placeId/usage-requests',
        data: CreateUsageRequestRequest(reason: reason).toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => PlaceUsageGroup.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully created usage request for place $placeId',
            name: 'PlaceService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to create usage request: ${apiResponse.message}',
            name: 'PlaceService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to create usage request',
          );
        }
      } else {
        throw Exception('Empty response from server');
      }
    } catch (e) {
      developer.log(
        'Error creating usage request: $e',
        name: 'PlaceService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Update usage permission status (approve/reject)
  ///
  /// PATCH /api/places/{placeId}/usage-groups/{groupId}
  /// Returns the updated usage group record
  Future<PlaceUsageGroup> updateUsageStatus({
    required int placeId,
    required int groupId,
    required UsageStatus status,
    String? rejectionReason,
  }) async {
    try {
      developer.log(
        'Updating usage status for place $placeId, group $groupId to $status',
        name: 'PlaceService',
      );

      final response = await _dioClient.patch<Map<String, dynamic>>(
        '/places/$placeId/usage-groups/$groupId',
        data: UpdateUsageStatusRequest(
          status: status,
          rejectionReason: rejectionReason,
        ).toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => PlaceUsageGroup.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully updated usage status',
            name: 'PlaceService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to update usage status: ${apiResponse.message}',
            name: 'PlaceService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to update usage status',
          );
        }
      } else {
        throw Exception('Empty response from server');
      }
    } catch (e) {
      developer.log(
        'Error updating usage status: $e',
        name: 'PlaceService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Revoke usage permission for a group
  ///
  /// DELETE /api/places/{placeId}/usage-groups/{groupId}
  /// Returns metadata about deleted reservations
  Future<Map<String, dynamic>> revokeUsagePermission({
    required int placeId,
    required int groupId,
  }) async {
    try {
      developer.log(
        'Revoking usage permission for place $placeId, group $groupId',
        name: 'PlaceService',
      );

      final response = await _dioClient.delete<Map<String, dynamic>>(
        '/places/$placeId/usage-groups/$groupId',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => json as Map<String, dynamic>,
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully revoked usage permission',
            name: 'PlaceService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to revoke usage permission: ${apiResponse.message}',
            name: 'PlaceService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to revoke usage permission',
          );
        }
      } else {
        throw Exception('Empty response from server');
      }
    } catch (e) {
      developer.log(
        'Error revoking usage permission: $e',
        name: 'PlaceService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Get pending usage requests for a place
  ///
  /// GET /api/places/{placeId}/usage-requests/pending
  /// Returns list of pending usage requests
  Future<List<PlaceUsageGroup>> getPendingRequests(int placeId) async {
    try {
      developer.log(
        'Fetching pending requests for place $placeId',
        name: 'PlaceService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/places/$placeId/usage-requests/pending',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is List) {
            return json
                .map((item) =>
                    PlaceUsageGroup.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return <PlaceUsageGroup>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched ${apiResponse.data!.length} pending requests',
            name: 'PlaceService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch pending requests: ${apiResponse.message}',
            name: 'PlaceService',
            level: 900,
          );
          return [];
        }
      }

      return [];
    } catch (e) {
      developer.log(
        'Error fetching pending requests: $e',
        name: 'PlaceService',
        level: 900,
      );
      return [];
    }
  }

  /// Get approved usage groups for a place
  ///
  /// GET /api/places/{placeId}/usage-groups
  /// Returns list of approved groups
  Future<List<PlaceUsageGroup>> getApprovedGroups(int placeId) async {
    try {
      developer.log(
        'Fetching approved groups for place $placeId',
        name: 'PlaceService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/places/$placeId/usage-groups',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is List) {
            return json
                .map((item) =>
                    PlaceUsageGroup.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return <PlaceUsageGroup>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched ${apiResponse.data!.length} approved groups',
            name: 'PlaceService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch approved groups: ${apiResponse.message}',
            name: 'PlaceService',
            level: 900,
          );
          return [];
        }
      }

      return [];
    } catch (e) {
      developer.log(
        'Error fetching approved groups: $e',
        name: 'PlaceService',
        level: 900,
      );
      return [];
    }
  }

  // ===== Helper Methods =====

  /// Format DateTime to yyyy-MM-dd string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
