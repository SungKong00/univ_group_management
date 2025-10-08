import 'dart:developer' as developer;
import '../models/member_models.dart';
import '../models/auth_models.dart';
import '../network/dio_client.dart';

/// 가입 신청 관리 Repository
///
/// MVP: Mock 데이터 제공
/// Phase 2: API 연동 시 GroupService와 통합
abstract class JoinRequestRepository {
  Future<List<JoinRequest>> getPendingRequests(int groupId);
  Future<void> approveRequest(int groupId, int requestId, String roleId);
  Future<void> rejectRequest(int groupId, int requestId);
}

/// API 구현체
class ApiJoinRequestRepository implements JoinRequestRepository {
  final DioClient _dioClient = DioClient();

  @override
  Future<List<JoinRequest>> getPendingRequests(int groupId) async {
    try {
      developer.log('Fetching pending join requests for group $groupId', name: 'ApiJoinRequestRepository');

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/groups/$groupId/join-requests',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) {
            if (json is List) {
              return json.map((item) => _parseJoinRequest(item as Map<String, dynamic>)).toList();
            }
            return <JoinRequest>[];
          },
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log('Successfully fetched ${apiResponse.data!.length} join requests', name: 'ApiJoinRequestRepository');
          return apiResponse.data!;
        } else {
          developer.log('Failed to fetch join requests: ${apiResponse.message}', name: 'ApiJoinRequestRepository', level: 900);
          throw Exception(apiResponse.message ?? 'Failed to fetch join requests');
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log('Error fetching join requests: $e', name: 'ApiJoinRequestRepository', level: 900);
      rethrow;
    }
  }

  @override
  Future<void> approveRequest(int groupId, int requestId, String roleId) async {
    try {
      developer.log('Approving join request $requestId for group $groupId with role $roleId', name: 'ApiJoinRequestRepository');

      final response = await _dioClient.patch<Map<String, dynamic>>(
        '/groups/$groupId/join-requests/$requestId',
        data: {
          'decision': 'APPROVE',
          'assignedRoleId': int.parse(roleId), // roleId를 정수로 변환
        },
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => null,
        );

        if (apiResponse.success) {
          developer.log('Successfully approved join request', name: 'ApiJoinRequestRepository');
        } else {
          developer.log('Failed to approve join request: ${apiResponse.message}', name: 'ApiJoinRequestRepository', level: 900);
          throw Exception(apiResponse.message ?? 'Failed to approve join request');
        }
      }
    } catch (e) {
      developer.log('Error approving join request: $e', name: 'ApiJoinRequestRepository', level: 900);
      rethrow;
    }
  }

  @override
  Future<void> rejectRequest(int groupId, int requestId) async {
    try {
      developer.log('Rejecting join request $requestId for group $groupId', name: 'ApiJoinRequestRepository');

      final response = await _dioClient.patch<Map<String, dynamic>>(
        '/groups/$groupId/join-requests/$requestId',
        data: {
          'decision': 'REJECT',
        },
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => null,
        );

        if (apiResponse.success) {
          developer.log('Successfully rejected join request', name: 'ApiJoinRequestRepository');
        } else {
          developer.log('Failed to reject join request: ${apiResponse.message}', name: 'ApiJoinRequestRepository', level: 900);
          throw Exception(apiResponse.message ?? 'Failed to reject join request');
        }
      }
    } catch (e) {
      developer.log('Error rejecting join request: $e', name: 'ApiJoinRequestRepository', level: 900);
      rethrow;
    }
  }

  /// 백엔드 응답을 JoinRequest 모델로 변환
  ///
  /// 백엔드 응답 구조:
  /// {
  ///   "id": 1,
  ///   "user": {
  ///     "id": 123,
  ///     "name": "강민준",
  ///     "email": "kang@example.com",
  ///     "profileImageUrl": null
  ///   },
  ///   "message": "지원 동기",
  ///   "requestedAt": "2024-10-01T12:00:00",
  ///   "status": "PENDING"
  /// }
  JoinRequest _parseJoinRequest(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;

    return JoinRequest(
      id: (json['id'] as num).toInt(),
      userId: (user['id'] as num).toString(),
      userName: user['name'] as String,
      email: user['email'] as String,
      profileImageUrl: user['profileImageUrl'] as String?,
      message: json['message'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      status: JoinRequestStatus.fromString(json['status'] as String),
    );
  }
}

/// Mock 구현체
class MockJoinRequestRepository implements JoinRequestRepository {
  // Mock 데이터 저장소
  final Map<int, List<JoinRequest>> _requestsByGroup = {
    1: [
      JoinRequest(
        id: 1,
        userId: 'user010',
        userName: '강민준',
        email: 'kang@example.com',
        profileImageUrl: null,
        message: '컴퓨터공학과 학생입니다. 알고리즘 스터디에 참여하고 싶습니다.',
        requestedAt: DateTime(2024, 10, 1),
        status: JoinRequestStatus.pending,
      ),
      JoinRequest(
        id: 2,
        userId: 'user011',
        userName: '서연우',
        email: 'seo@example.com',
        profileImageUrl: null,
        message: '프로젝트 경험을 쌓고 싶어 지원합니다.',
        requestedAt: DateTime(2024, 10, 3),
        status: JoinRequestStatus.pending,
      ),
      JoinRequest(
        id: 3,
        userId: 'user012',
        userName: '윤지호',
        email: 'yoon@example.com',
        profileImageUrl: null,
        message: '같은 학과 학생으로서 함께 성장하고 싶습니다.',
        requestedAt: DateTime(2024, 10, 5),
        status: JoinRequestStatus.pending,
      ),
    ],
  };

  @override
  Future<List<JoinRequest>> getPendingRequests(int groupId) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final requests = _requestsByGroup[groupId] ?? [];
    return requests.where((r) => r.status == JoinRequestStatus.pending).toList();
  }

  @override
  Future<void> approveRequest(int groupId, int requestId, String roleId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final requests = _requestsByGroup[groupId];
    if (requests == null) {
      throw Exception('Group not found');
    }

    final requestIndex = requests.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) {
      throw Exception('Request not found');
    }

    // 상태를 승인으로 변경 (실제로는 멤버 목록에 추가되어야 함)
    requests.removeAt(requestIndex);
  }

  @override
  Future<void> rejectRequest(int groupId, int requestId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final requests = _requestsByGroup[groupId];
    if (requests == null) {
      throw Exception('Group not found');
    }

    final requestIndex = requests.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) {
      throw Exception('Request not found');
    }

    // 요청 제거
    requests.removeAt(requestIndex);
  }
}
