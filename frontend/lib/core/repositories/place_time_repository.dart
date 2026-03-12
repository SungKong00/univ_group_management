import 'dart:developer' as developer;
import '../models/place_time_models.dart';
import '../models/auth_models.dart';
import '../network/dio_client.dart';

/// 장소 시간 관리 Repository
abstract class PlaceTimeRepository {
  // 운영시간
  Future<List<OperatingHoursResponse>> getOperatingHours(int placeId);
  Future<List<OperatingHoursResponse>> setOperatingHours(
    int placeId,
    SetOperatingHoursRequest request,
  );

  // 금지시간
  Future<List<RestrictedTimeResponse>> getRestrictedTimes(int placeId);
  Future<RestrictedTimeResponse> addRestrictedTime(
    int placeId,
    AddRestrictedTimeRequest request,
  );
  Future<RestrictedTimeResponse> updateRestrictedTime(
    int placeId,
    int restrictedTimeId,
    AddRestrictedTimeRequest request,
  );
  Future<void> deleteRestrictedTime(int placeId, int restrictedTimeId);

  // 임시 휴무
  Future<List<PlaceClosureResponse>> getClosures(
    int placeId,
    String from,
    String to,
  );
  Future<PlaceClosureResponse> addFullDayClosure(
    int placeId,
    AddFullDayClosureRequest request,
  );
  Future<PlaceClosureResponse> addPartialClosure(
    int placeId,
    AddPartialClosureRequest request,
  );
  Future<void> deleteClosure(int placeId, int closureId);

  // 예약 가능 시간
  Future<AvailableTimesResponse> getAvailableTimes(int placeId, String date);
}

/// API 구현체
class ApiPlaceTimeRepository implements PlaceTimeRepository {
  final DioClient _dioClient = DioClient();

  // ========================================
  // 운영시간 API
  // ========================================

  @override
  Future<List<OperatingHoursResponse>> getOperatingHours(int placeId) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        '/places/$placeId/operating-hours',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is List) {
            return json
                .map(
                  (item) => OperatingHoursResponse.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList();
          }
          return <OperatingHoursResponse>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw Exception(
            apiResponse.message ?? 'Failed to fetch operating hours',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error fetching operating hours: $e',
        name: 'ApiPlaceTimeRepository',
        level: 900,
      );
      rethrow;
    }
  }

  @override
  Future<List<OperatingHoursResponse>> setOperatingHours(
    int placeId,
    SetOperatingHoursRequest request,
  ) async {
    try {
      final response = await _dioClient.put<Map<String, dynamic>>(
        '/places/$placeId/operating-hours',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is List) {
            return json
                .map(
                  (item) => OperatingHoursResponse.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList();
          }
          return <OperatingHoursResponse>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw Exception(
            apiResponse.message ?? 'Failed to set operating hours',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error setting operating hours: $e',
        name: 'ApiPlaceTimeRepository',
        level: 900,
      );
      rethrow;
    }
  }

  // ========================================
  // 금지시간 API
  // ========================================

  @override
  Future<List<RestrictedTimeResponse>> getRestrictedTimes(int placeId) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        '/places/$placeId/restricted-times',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is List) {
            return json
                .map(
                  (item) => RestrictedTimeResponse.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList();
          }
          return <RestrictedTimeResponse>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw Exception(
            apiResponse.message ?? 'Failed to fetch restricted times',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error fetching restricted times: $e',
        name: 'ApiPlaceTimeRepository',
        level: 900,
      );
      rethrow;
    }
  }

  @override
  Future<RestrictedTimeResponse> addRestrictedTime(
    int placeId,
    AddRestrictedTimeRequest request,
  ) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/places/$placeId/restricted-times',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) =>
              RestrictedTimeResponse.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw Exception(
            apiResponse.message ?? 'Failed to add restricted time',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error adding restricted time: $e',
        name: 'ApiPlaceTimeRepository',
        level: 900,
      );
      rethrow;
    }
  }

  @override
  Future<RestrictedTimeResponse> updateRestrictedTime(
    int placeId,
    int restrictedTimeId,
    AddRestrictedTimeRequest request,
  ) async {
    try {
      final response = await _dioClient.patch<Map<String, dynamic>>(
        '/places/$placeId/restricted-times/$restrictedTimeId',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) =>
              RestrictedTimeResponse.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw Exception(
            apiResponse.message ?? 'Failed to update restricted time',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error updating restricted time: $e',
        name: 'ApiPlaceTimeRepository',
        level: 900,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteRestrictedTime(int placeId, int restrictedTimeId) async {
    try {
      final response = await _dioClient.delete<Map<String, dynamic>>(
        '/places/$placeId/restricted-times/$restrictedTimeId',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => null,
        );

        if (!apiResponse.success) {
          throw Exception(
            apiResponse.message ?? 'Failed to delete restricted time',
          );
        }
      }
    } catch (e) {
      developer.log(
        'Error deleting restricted time: $e',
        name: 'ApiPlaceTimeRepository',
        level: 900,
      );
      rethrow;
    }
  }

  // ========================================
  // 임시 휴무 API
  // ========================================

  @override
  Future<List<PlaceClosureResponse>> getClosures(
    int placeId,
    String from,
    String to,
  ) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        '/places/$placeId/closures',
        queryParameters: {'from': from, 'to': to},
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is List) {
            return json
                .map(
                  (item) => PlaceClosureResponse.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList();
          }
          return <PlaceClosureResponse>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw Exception(apiResponse.message ?? 'Failed to fetch closures');
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error fetching closures: $e',
        name: 'ApiPlaceTimeRepository',
        level: 900,
      );
      rethrow;
    }
  }

  @override
  Future<PlaceClosureResponse> addFullDayClosure(
    int placeId,
    AddFullDayClosureRequest request,
  ) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/places/$placeId/closures/full-day',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => PlaceClosureResponse.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw Exception(
            apiResponse.message ?? 'Failed to add full day closure',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error adding full day closure: $e',
        name: 'ApiPlaceTimeRepository',
        level: 900,
      );
      rethrow;
    }
  }

  @override
  Future<PlaceClosureResponse> addPartialClosure(
    int placeId,
    AddPartialClosureRequest request,
  ) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/places/$placeId/closures/partial',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => PlaceClosureResponse.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw Exception(
            apiResponse.message ?? 'Failed to add partial closure',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error adding partial closure: $e',
        name: 'ApiPlaceTimeRepository',
        level: 900,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteClosure(int placeId, int closureId) async {
    try {
      final response = await _dioClient.delete<Map<String, dynamic>>(
        '/places/$placeId/closures/$closureId',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => null,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Failed to delete closure');
        }
      }
    } catch (e) {
      developer.log(
        'Error deleting closure: $e',
        name: 'ApiPlaceTimeRepository',
        level: 900,
      );
      rethrow;
    }
  }

  // ========================================
  // 예약 가능 시간 API
  // ========================================

  @override
  Future<AvailableTimesResponse> getAvailableTimes(
    int placeId,
    String date,
  ) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        '/places/$placeId/available-times',
        queryParameters: {'date': date},
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) =>
              AvailableTimesResponse.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw Exception(
            apiResponse.message ?? 'Failed to fetch available times',
          );
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log(
        'Error fetching available times: $e',
        name: 'ApiPlaceTimeRepository',
        level: 900,
      );
      rethrow;
    }
  }
}
