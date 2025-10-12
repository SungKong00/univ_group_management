import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../models/auth_models.dart';
import '../models/calendar/group_event.dart';
import '../models/calendar/recurrence_pattern.dart';
import '../models/calendar/update_scope.dart';
import '../network/dio_client.dart';

/// Service responsible for group calendar interactions.
class GroupCalendarService {
  GroupCalendarService._internal();

  static final GroupCalendarService _instance =
      GroupCalendarService._internal();

  factory GroupCalendarService() => _instance;

  final DioClient _dioClient = DioClient();
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  /// Fetch group calendar events within a date range.
  Future<List<GroupEvent>> getEvents({
    required int groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        '/groups/$groupId/events',
        queryParameters: {
          'startDate': _dateFormatter.format(startDate),
          'endDate': _dateFormatter.format(endDate),
        },
      );

      if (response.data == null) return const [];

      final apiResponse = ApiResponse.fromJson(response.data!, (json) {
        if (json is List) {
          return json
              .map(
                (item) => GroupEvent.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        }
        return <GroupEvent>[];
      });

      if (apiResponse.success && apiResponse.data != null) {
        developer.log(
          'Fetched ${apiResponse.data!.length} group events for group $groupId',
          name: 'GroupCalendarService',
        );
        return apiResponse.data!;
      }

      throw Exception(
        apiResponse.message ?? '그룹 일정을 불러오지 못했습니다.',
      );
    } on DioException catch (e) {
      developer.log(
        'Failed to load group events for group $groupId: $e',
        name: 'GroupCalendarService',
        level: 900,
        error: e,
      );
      throw Exception(_friendlyMessage(
        e,
        fallback: '그룹 일정을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
      ));
    }
  }

  /// Create a new group calendar event (single or recurring).
  Future<List<GroupEvent>> createEvent({
    required int groupId,
    required String title,
    String? description,
    String? location,
    required DateTime startDate,
    required DateTime endDate,
    bool isAllDay = false,
    bool isOfficial = false,
    required String color,
    RecurrencePattern? recurrence,
  }) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/groups/$groupId/events',
        data: {
          'title': title,
          'description': description?.trim().isEmpty == true ? null : description,
          'location': location?.trim().isEmpty == true ? null : location,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'isAllDay': isAllDay,
          'isOfficial': isOfficial,
          'color': color,
          'eventType': 'GENERAL',
          if (recurrence != null) 'recurrence': recurrence.toJson(),
        },
      );

      if (response.data == null) {
        throw Exception('빈 응답을 수신했습니다.');
      }

      final apiResponse = ApiResponse.fromJson(response.data!, (json) {
        if (json is List) {
          return json
              .map(
                (item) => GroupEvent.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        }
        return <GroupEvent>[];
      });

      if (apiResponse.success && apiResponse.data != null) {
        developer.log(
          'Created ${apiResponse.data!.length} group event(s) for group $groupId',
          name: 'GroupCalendarService',
        );
        return apiResponse.data!;
      }

      throw Exception(
        apiResponse.message ?? '그룹 일정 생성에 실패했습니다.',
      );
    } on DioException catch (e) {
      developer.log(
        'Failed to create group event for group $groupId: $e',
        name: 'GroupCalendarService',
        level: 900,
        error: e,
      );
      throw Exception(_friendlyMessage(
        e,
        fallback: '그룹 일정 생성에 실패했습니다. 다시 시도해주세요.',
      ));
    }
  }

  /// Update an existing group calendar event.
  Future<List<GroupEvent>> updateEvent({
    required int groupId,
    required int eventId,
    required String title,
    String? description,
    String? location,
    required DateTime startDate,
    required DateTime endDate,
    bool isAllDay = false,
    required String color,
    UpdateScope updateScope = UpdateScope.thisEvent,
  }) async {
    try {
      final response = await _dioClient.put<Map<String, dynamic>>(
        '/groups/$groupId/events/$eventId',
        data: {
          'title': title,
          'description': description?.trim().isEmpty == true ? null : description,
          'location': location?.trim().isEmpty == true ? null : location,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'isAllDay': isAllDay,
          'color': color,
          'updateScope': updateScope.apiValue,
        },
      );

      if (response.data == null) {
        throw Exception('빈 응답을 수신했습니다.');
      }

      final apiResponse = ApiResponse.fromJson(response.data!, (json) {
        if (json is List) {
          return json
              .map(
                (item) => GroupEvent.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        }
        return <GroupEvent>[];
      });

      if (apiResponse.success && apiResponse.data != null) {
        developer.log(
          'Updated ${apiResponse.data!.length} group event(s) for group $groupId',
          name: 'GroupCalendarService',
        );
        return apiResponse.data!;
      }

      throw Exception(
        apiResponse.message ?? '그룹 일정 수정에 실패했습니다.',
      );
    } on DioException catch (e) {
      developer.log(
        'Failed to update group event $eventId for group $groupId: $e',
        name: 'GroupCalendarService',
        level: 900,
        error: e,
      );
      throw Exception(_friendlyMessage(
        e,
        fallback: '그룹 일정 수정에 실패했습니다. 다시 시도해주세요.',
      ));
    }
  }

  /// Delete a group calendar event.
  Future<void> deleteEvent({
    required int groupId,
    required int eventId,
    UpdateScope deleteScope = UpdateScope.thisEvent,
  }) async {
    try {
      await _dioClient.delete<void>(
        '/groups/$groupId/events/$eventId',
        queryParameters: {
          'scope': deleteScope.apiValue,
        },
      );
      developer.log(
        'Deleted group event $eventId for group $groupId',
        name: 'GroupCalendarService',
      );
    } on DioException catch (e) {
      developer.log(
        'Failed to delete group event $eventId for group $groupId: $e',
        name: 'GroupCalendarService',
        level: 900,
        error: e,
      );
      throw Exception(_friendlyMessage(
        e,
        fallback: '그룹 일정 삭제에 실패했습니다. 다시 시도해주세요.',
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
    if (status == 403) {
      return '권한이 없습니다. 그룹 관리자에게 문의하세요.';
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
