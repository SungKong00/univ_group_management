import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../models/auth_models.dart';
import '../models/calendar_models.dart';
import '../network/dio_client.dart';

/// Service responsible for personal timetable/calendar interactions.
class CalendarService {
  CalendarService._internal();

  static final CalendarService _instance = CalendarService._internal();

  factory CalendarService() => _instance;

  final DioClient _dioClient = DioClient();
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  /// Fetch current user's personal schedule entries.
  Future<List<PersonalSchedule>> getPersonalSchedules() async {
    try {
      final response =
          await _dioClient.get<Map<String, dynamic>>('/timetable');
      if (response.data == null) return const [];

      final apiResponse = ApiResponse.fromJson(response.data!, (json) {
        if (json is List) {
          return json
              .map(
                (item) =>
                    PersonalSchedule.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        }
        return <PersonalSchedule>[];
      });

      if (apiResponse.success && apiResponse.data != null) {
        developer.log(
          'Fetched ${apiResponse.data!.length} personal schedules',
          name: 'CalendarService',
        );
        return apiResponse.data!;
      }

      developer.log(
        'Failed to fetch schedules: ${apiResponse.message}',
        name: 'CalendarService',
        level: 900,
      );
      throw Exception(apiResponse.message ?? '일정을 불러오지 못했습니다.');
    } on DioException catch (e) {
      developer.log(
        'Network error while fetching schedules: $e',
        name: 'CalendarService',
        level: 900,
        error: e,
      );
      throw Exception(_friendlyMessage(
        e,
        fallback: '일정을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
      ));
    }
  }

  /// Create a new personal schedule entry.
  Future<PersonalSchedule> createPersonalSchedule(
    PersonalScheduleRequest request,
  ) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/timetable',
        data: request.toJson(),
      );

      if (response.data == null) {
        throw Exception('빈 응답을 수신했습니다.');
      }

      final apiResponse = ApiResponse.fromJson(response.data!, (json) {
        return PersonalSchedule.fromJson(json as Map<String, dynamic>);
      });

      if (apiResponse.success && apiResponse.data != null) {
        developer.log(
          'Created personal schedule ${apiResponse.data!.id}',
          name: 'CalendarService',
        );
        return apiResponse.data!;
      }

      throw Exception(apiResponse.message ?? '일정 생성에 실패했습니다.');
    } on DioException catch (e) {
      developer.log(
        'Failed to create schedule: $e',
        name: 'CalendarService',
        level: 900,
        error: e,
      );
      throw Exception(_friendlyMessage(
        e,
        fallback: '일정 생성에 실패했습니다. 다시 시도해주세요.',
      ));
    }
  }

  /// Update an existing personal schedule entry.
  Future<PersonalSchedule> updatePersonalSchedule(
    int id,
    PersonalScheduleRequest request,
  ) async {
    try {
      final response = await _dioClient.put<Map<String, dynamic>>(
        '/timetable/$id',
        data: request.toJson(),
      );

      if (response.data == null) {
        throw Exception('빈 응답을 수신했습니다.');
      }

      final apiResponse = ApiResponse.fromJson(response.data!, (json) {
        return PersonalSchedule.fromJson(json as Map<String, dynamic>);
      });

      if (apiResponse.success && apiResponse.data != null) {
        developer.log(
          'Updated personal schedule $id',
          name: 'CalendarService',
        );
        return apiResponse.data!;
      }

      throw Exception(apiResponse.message ?? '일정 수정에 실패했습니다.');
    } on DioException catch (e) {
      developer.log(
        'Failed to update schedule $id: $e',
        name: 'CalendarService',
        level: 900,
        error: e,
      );
      throw Exception(_friendlyMessage(
        e,
        fallback: '일정 수정에 실패했습니다. 다시 시도해주세요.',
      ));
    }
  }

  /// Delete a personal schedule by id.
  Future<void> deletePersonalSchedule(int id) async {
    try {
      await _dioClient.delete<void>('/timetable/$id');
      developer.log('Deleted personal schedule $id', name: 'CalendarService');
    } on DioException catch (e) {
      developer.log(
        'Failed to delete schedule $id: $e',
        name: 'CalendarService',
        level: 900,
        error: e,
      );
      throw Exception(_friendlyMessage(
        e,
        fallback: '일정 삭제에 실패했습니다. 다시 시도해주세요.',
      ));
    }
  }

  /// Fetch personal calendar events within a date range.
  Future<List<PersonalEvent>> getPersonalEvents(
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        '/calendar',
        queryParameters: {
          'start': _dateFormatter.format(rangeStart),
          'end': _dateFormatter.format(rangeEnd),
        },
      );
      if (response.data == null) return const [];

      final apiResponse = ApiResponse.fromJson(response.data!, (json) {
        if (json is List) {
          return json
              .map(
                (item) => PersonalEvent.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        }
        return <PersonalEvent>[];
      });

      if (apiResponse.success && apiResponse.data != null) {
        developer.log(
          'Fetched ${apiResponse.data!.length} personal events',
          name: 'CalendarService',
        );
        return apiResponse.data!;
      }

      throw Exception(apiResponse.message ?? '이벤트를 불러오지 못했습니다.');
    } on DioException catch (e) {
      developer.log(
        'Failed to load events: $e',
        name: 'CalendarService',
        level: 900,
        error: e,
      );
      throw Exception(_friendlyMessage(
        e,
        fallback: '이벤트를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
      ));
    }
  }

  Future<PersonalEvent> createPersonalEvent(
    PersonalEventRequest request,
  ) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/calendar',
        data: request.toJson(),
      );

      if (response.data == null) {
        throw Exception('빈 응답을 수신했습니다.');
      }

      final apiResponse = ApiResponse.fromJson(response.data!, (json) {
        return PersonalEvent.fromJson(json as Map<String, dynamic>);
      });

      if (apiResponse.success && apiResponse.data != null) {
        developer.log(
          'Created personal event ${apiResponse.data!.id}',
          name: 'CalendarService',
        );
        return apiResponse.data!;
      }

      throw Exception(apiResponse.message ?? '이벤트 생성에 실패했습니다.');
    } on DioException catch (e) {
      developer.log(
        'Failed to create event: $e',
        name: 'CalendarService',
        level: 900,
        error: e,
      );
      throw Exception(_friendlyMessage(
        e,
        fallback: '이벤트 생성에 실패했습니다. 다시 시도해주세요.',
      ));
    }
  }

  Future<PersonalEvent> updatePersonalEvent(
    int id,
    PersonalEventRequest request,
  ) async {
    try {
      final response = await _dioClient.put<Map<String, dynamic>>(
        '/calendar/$id',
        data: request.toJson(),
      );

      if (response.data == null) {
        throw Exception('빈 응답을 수신했습니다.');
      }

      final apiResponse = ApiResponse.fromJson(response.data!, (json) {
        return PersonalEvent.fromJson(json as Map<String, dynamic>);
      });

      if (apiResponse.success && apiResponse.data != null) {
        developer.log(
          'Updated personal event $id',
          name: 'CalendarService',
        );
        return apiResponse.data!;
      }

      throw Exception(apiResponse.message ?? '이벤트 수정에 실패했습니다.');
    } on DioException catch (e) {
      developer.log(
        'Failed to update event $id: $e',
        name: 'CalendarService',
        level: 900,
        error: e,
      );
      throw Exception(_friendlyMessage(
        e,
        fallback: '이벤트 수정에 실패했습니다. 다시 시도해주세요.',
      ));
    }
  }

  Future<void> deletePersonalEvent(int id) async {
    try {
      await _dioClient.delete<void>('/calendar/$id');
      developer.log('Deleted personal event $id', name: 'CalendarService');
    } on DioException catch (e) {
      developer.log(
        'Failed to delete event $id: $e',
        name: 'CalendarService',
        level: 900,
        error: e,
      );
      throw Exception(_friendlyMessage(
        e,
        fallback: '이벤트 삭제에 실패했습니다. 다시 시도해주세요.',
      ));
    }
  }
}

String _friendlyMessage(
  DioException exception, {
  required String fallback,
}) {
  final response = exception.response;
  final status = response?.statusCode;

  String? responseMessage;
  final data = response?.data;
  if (data is Map) {
    final message = data['message'];
    if (message is String && message.isNotEmpty) {
      responseMessage = message;
    }
  }

  if (status != null) {
    if (status >= 500) {
      return '서버가 준비 중이에요. 잠시 후 다시 시도해주세요.';
    }
    if (status == 404) {
      return '요청한 일정을 찾을 수 없습니다.';
    }
    if (status == 400) {
      if (responseMessage != null) {
        return responseMessage;
      }
      return '요청이 올바르지 않습니다. 입력값을 확인해주세요.';
    }
  }

  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return '네트워크 연결이 원활하지 않습니다. 연결 상태를 확인해주세요.';
    case DioExceptionType.connectionError:
      return '서버에 연결할 수 없습니다. 잠시 후 다시 시도해주세요.';
    default:
      if (responseMessage != null) {
        return responseMessage;
      }
      return fallback;
  }
}
