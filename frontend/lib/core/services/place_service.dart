import 'dart:developer' as developer;
import '../models/auth_models.dart';
import '../models/place/place_reservation.dart';
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

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => json,
        );

        if (apiResponse.success) {
          developer.log(
            'Successfully canceled reservation $reservationId',
            name: 'PlaceService',
          );
        } else {
          developer.log(
            'Failed to cancel reservation: ${apiResponse.message}',
            name: 'PlaceService',
            level: 900,
          );
          throw Exception(apiResponse.message ?? 'Failed to cancel reservation');
        }
      } else {
        throw Exception('Empty response from server');
      }
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
  // TODO: Add place CRUD APIs when needed

  // ===== Helper Methods =====

  /// Format DateTime to yyyy-MM-dd string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
