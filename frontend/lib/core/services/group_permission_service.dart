import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../models/auth_models.dart';
import '../network/dio_client.dart';

/// Service responsible for fetching user permissions in groups.
class GroupPermissionService {
  GroupPermissionService._internal();

  static final GroupPermissionService _instance =
      GroupPermissionService._internal();

  factory GroupPermissionService() => _instance;

  final DioClient _dioClient = DioClient();

  /// Fetch the current user's permissions for a specific group.
  ///
  /// Returns a set of permission names (e.g., {"CALENDAR_MANAGE", "MEMBER_MANAGE"}).
  Future<Set<String>> getMyPermissions(int groupId) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        '/groups/$groupId/permissions',
      );

      if (response.data == null) return {};

      final apiResponse = ApiResponse.fromJson(response.data!, (json) {
        if (json is List) {
          return json.cast<String>().toSet();
        }
        return <String>{};
      });

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }

      throw Exception(apiResponse.message ?? '권한 정보를 불러오지 못했습니다.');
    } on DioException catch (e) {
      developer.log(
        'Failed to load permissions for group $groupId: $e',
        name: 'GroupPermissionService',
        level: 900,
        error: e,
      );
      throw Exception(
        _friendlyMessage(e, fallback: '권한 정보를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.'),
      );
    }
  }
}

String _friendlyMessage(DioException exception, {required String fallback}) {
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
      return '그룹을 찾을 수 없습니다.';
    }
    if (status == 403) {
      return '권한이 없습니다. 그룹 멤버가 아닙니다.';
    }
    if (status == 400) {
      if (responseMessage != null) {
        return responseMessage;
      }
      return '요청이 올바르지 않습니다.';
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
