import 'dart:developer' as developer;
import '../models/member_models.dart';
import '../models/auth_models.dart';
import '../network/dio_client.dart';

/// 멤버 관리 Repository
///
/// MVP: Mock 데이터 제공
/// Phase 2: API 연동 시 GroupService와 통합
abstract class MemberRepository {
  Future<List<GroupMember>> getGroupMembers(int groupId);
  Future<GroupMember> updateMemberRole(int groupId, String userId, int roleId);
  Future<void> removeMember(int groupId, String userId);
}

/// API 구현체
class ApiMemberRepository implements MemberRepository {
  final DioClient _dioClient = DioClient();

  @override
  Future<List<GroupMember>> getGroupMembers(int groupId) async {
    try {
      developer.log('Fetching members for group $groupId', name: 'ApiMemberRepository');

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/groups/$groupId/members',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) {
            // PagedApiResponse 구조 처리: data.content에 실제 리스트 존재
            if (json is Map<String, dynamic> && json.containsKey('content')) {
              final content = json['content'];
              if (content is List) {
                return content.map((item) => _parseGroupMember(item as Map<String, dynamic>)).toList();
              }
            }
            // 일반 ApiResponse 구조 처리 (하위 호환성)
            if (json is List) {
              return json.map((item) => _parseGroupMember(item as Map<String, dynamic>)).toList();
            }
            return <GroupMember>[];
          },
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log('Successfully fetched ${apiResponse.data!.length} members', name: 'ApiMemberRepository');
          return apiResponse.data!;
        } else {
          developer.log('Failed to fetch members: ${apiResponse.message}', name: 'ApiMemberRepository', level: 900);
          throw Exception(apiResponse.message ?? 'Failed to fetch members');
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log('Error fetching members: $e', name: 'ApiMemberRepository', level: 900);
      rethrow;
    }
  }

  @override
  Future<GroupMember> updateMemberRole(int groupId, String userId, int roleId) async {
    try {
      developer.log('Updating role for user $userId in group $groupId to role $roleId', name: 'ApiMemberRepository');

      final response = await _dioClient.put<Map<String, dynamic>>(
        '/groups/$groupId/members/$userId/role',
        data: {'roleId': roleId},
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => _parseGroupMember(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log('Successfully updated member role', name: 'ApiMemberRepository');
          return apiResponse.data!;
        } else {
          developer.log('Failed to update member role: ${apiResponse.message}', name: 'ApiMemberRepository', level: 900);
          throw Exception(apiResponse.message ?? 'Failed to update member role');
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log('Error updating member role: $e', name: 'ApiMemberRepository', level: 900);
      rethrow;
    }
  }

  @override
  Future<void> removeMember(int groupId, String userId) async {
    try {
      developer.log('Removing user $userId from group $groupId', name: 'ApiMemberRepository');

      final response = await _dioClient.delete<Map<String, dynamic>>(
        '/groups/$groupId/members/$userId',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => null,
        );

        if (apiResponse.success) {
          developer.log('Successfully removed member', name: 'ApiMemberRepository');
        } else {
          developer.log('Failed to remove member: ${apiResponse.message}', name: 'ApiMemberRepository', level: 900);
          throw Exception(apiResponse.message ?? 'Failed to remove member');
        }
      }
    } catch (e) {
      developer.log('Error removing member: $e', name: 'ApiMemberRepository', level: 900);
      rethrow;
    }
  }

  /// 백엔드 응답을 GroupMember 모델로 변환
  ///
  /// 백엔드 응답 구조:
  /// {
  ///   "id": 123,
  ///   "user": {
  ///     "id": 1,
  ///     "name": "김철수",
  ///     "email": "kim@example.com",
  ///     "profileImageUrl": null,
  ///     ...
  ///   },
  ///   "role": {
  ///     "id": 1,
  ///     "name": "그룹장",
  ///     "permissions": ["GROUP_MANAGE", ...],
  ///     "priority": 100
  ///   },
  ///   "joinedAt": "2025-10-01T12:00:00"
  /// }
  GroupMember _parseGroupMember(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final role = json['role'] as Map<String, dynamic>;

    return GroupMember(
      id: (json['id'] as num).toInt(),
      userId: (user['id'] as num).toString(), // userId는 백엔드의 user.id
      userName: user['name'] as String,
      email: user['email'] as String,
      profileImageUrl: user['profileImageUrl'] as String?,
      studentNo: user['studentNo'] as String?,
      academicYear: (user['academicYear'] as num?)?.toInt(),
      roleName: role['name'] as String,
      roleId: (role['id'] as num).toString(), // roleId는 백엔드의 role.id를 문자열로
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      isActive: true,
    );
  }
}

/// Mock 구현체
class MockMemberRepository implements MemberRepository {
  // Mock 데이터 저장소
  final Map<int, List<GroupMember>> _membersByGroup = {
    1: [
      GroupMember(
        id: 1,
        userId: 'user001',
        userName: '김철수',
        email: 'kim@example.com',
        profileImageUrl: null,
        studentNo: '2020123456',
        academicYear: 4,
        roleName: '그룹장',
        roleId: 'owner',
        joinedAt: DateTime(2024, 1, 15),
      ),
      GroupMember(
        id: 2,
        userId: 'user002',
        userName: '이영희',
        email: 'lee@example.com',
        profileImageUrl: null,
        studentNo: null,
        academicYear: null,
        roleName: '교수',
        roleId: 'advisor',
        joinedAt: DateTime(2024, 2, 20),
      ),
      GroupMember(
        id: 3,
        userId: 'user003',
        userName: '박민수',
        email: 'park@example.com',
        profileImageUrl: null,
        studentNo: '2021234567',
        academicYear: 3,
        roleName: '멤버',
        roleId: 'member',
        joinedAt: DateTime(2024, 3, 10),
      ),
      GroupMember(
        id: 4,
        userId: 'user004',
        userName: '최지혜',
        email: 'choi@example.com',
        profileImageUrl: null,
        studentNo: '2022345678',
        academicYear: 2,
        roleName: '멤버',
        roleId: 'member',
        joinedAt: DateTime(2024, 3, 15),
      ),
      GroupMember(
        id: 5,
        userId: 'user005',
        userName: '정우성',
        email: 'jung@example.com',
        profileImageUrl: null,
        studentNo: '2023456789',
        academicYear: 1,
        roleName: '멤버',
        roleId: 'member',
        joinedAt: DateTime(2024, 4, 1),
      ),
    ],
  };

  @override
  Future<List<GroupMember>> getGroupMembers(int groupId) async {
    await Future.delayed(const Duration(milliseconds: 300)); // 네트워크 지연 시뮬레이션
    return _membersByGroup[groupId] ?? [];
  }

  @override
  Future<GroupMember> updateMemberRole(
    int groupId,
    String userId,
    int roleId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final members = _membersByGroup[groupId];
    if (members == null) {
      throw Exception('Group not found');
    }

    final memberIndex = members.indexWhere((m) => m.userId == userId);
    if (memberIndex == -1) {
      throw Exception('Member not found');
    }

    // 역할 이름 매핑 (간단한 구현)
    final roleNameMap = {
      '1': '그룹장',
      '2': '교수',
      '3': '멤버',
    };

    final updatedMember = members[memberIndex].copyWith(
      roleId: roleId.toString(),
      roleName: roleNameMap[roleId.toString()] ?? 'Unknown',
    );

    _membersByGroup[groupId]![memberIndex] = updatedMember;
    return updatedMember;
  }

  @override
  Future<void> removeMember(int groupId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final members = _membersByGroup[groupId];
    if (members == null) {
      throw Exception('Group not found');
    }

    _membersByGroup[groupId] = members.where((m) => m.userId != userId).toList();
  }
}
