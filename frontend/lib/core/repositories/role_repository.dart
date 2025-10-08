import 'dart:developer' as developer;
import '../models/member_models.dart';
import '../models/auth_models.dart';
import '../network/dio_client.dart';

/// 역할 관리 Repository
///
/// MVP: Mock 데이터 제공
/// Phase 2: API 연동 시 GroupService와 통합
abstract class RoleRepository {
  Future<List<GroupRole>> getGroupRoles(int groupId);
  Future<GroupRole> createRole(int groupId, String name, String description, List<String> permissions);
  Future<GroupRole> updateRole(int groupId, String roleId, String name, String description, List<String> permissions);
  Future<void> deleteRole(int groupId, String roleId);
}

/// API 구현체
class ApiRoleRepository implements RoleRepository {
  final DioClient _dioClient = DioClient();

  @override
  Future<List<GroupRole>> getGroupRoles(int groupId) async {
    try {
      developer.log('Fetching roles for group $groupId', name: 'ApiRoleRepository');

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/groups/$groupId/roles',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) {
            if (json is List) {
              return json.map((item) => _parseGroupRole(item as Map<String, dynamic>)).toList();
            }
            return <GroupRole>[];
          },
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log('Successfully fetched ${apiResponse.data!.length} roles', name: 'ApiRoleRepository');
          return apiResponse.data!;
        } else {
          developer.log('Failed to fetch roles: ${apiResponse.message}', name: 'ApiRoleRepository', level: 900);
          throw Exception(apiResponse.message ?? 'Failed to fetch roles');
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log('Error fetching roles: $e', name: 'ApiRoleRepository', level: 900);
      rethrow;
    }
  }

  @override
  Future<GroupRole> createRole(
    int groupId,
    String name,
    String description,
    List<String> permissions,
  ) async {
    try {
      developer.log('Creating role in group $groupId: $name', name: 'ApiRoleRepository');

      final response = await _dioClient.post<Map<String, dynamic>>(
        '/groups/$groupId/roles',
        data: {
          'name': name,
          'description': description,
          'permissions': permissions,
        },
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => _parseGroupRole(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log('Successfully created role', name: 'ApiRoleRepository');
          return apiResponse.data!;
        } else {
          developer.log('Failed to create role: ${apiResponse.message}', name: 'ApiRoleRepository', level: 900);
          throw Exception(apiResponse.message ?? 'Failed to create role');
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log('Error creating role: $e', name: 'ApiRoleRepository', level: 900);
      rethrow;
    }
  }

  @override
  Future<GroupRole> updateRole(
    int groupId,
    String roleId,
    String name,
    String description,
    List<String> permissions,
  ) async {
    try {
      developer.log('Updating role $roleId in group $groupId', name: 'ApiRoleRepository');

      final response = await _dioClient.put<Map<String, dynamic>>(
        '/groups/$groupId/roles/$roleId',
        data: {
          'name': name,
          'description': description,
          'permissions': permissions,
        },
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => _parseGroupRole(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log('Successfully updated role', name: 'ApiRoleRepository');
          return apiResponse.data!;
        } else {
          developer.log('Failed to update role: ${apiResponse.message}', name: 'ApiRoleRepository', level: 900);
          throw Exception(apiResponse.message ?? 'Failed to update role');
        }
      }

      throw Exception('Empty response from server');
    } catch (e) {
      developer.log('Error updating role: $e', name: 'ApiRoleRepository', level: 900);
      rethrow;
    }
  }

  @override
  Future<void> deleteRole(int groupId, String roleId) async {
    try {
      developer.log('Deleting role $roleId from group $groupId', name: 'ApiRoleRepository');

      final response = await _dioClient.delete<Map<String, dynamic>>(
        '/groups/$groupId/roles/$roleId',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => null,
        );

        if (apiResponse.success) {
          developer.log('Successfully deleted role', name: 'ApiRoleRepository');
        } else {
          developer.log('Failed to delete role: ${apiResponse.message}', name: 'ApiRoleRepository', level: 900);
          throw Exception(apiResponse.message ?? 'Failed to delete role');
        }
      }
    } catch (e) {
      developer.log('Error deleting role: $e', name: 'ApiRoleRepository', level: 900);
      rethrow;
    }
  }

  /// 백엔드 응답을 GroupRole 모델로 변환
  ///
  /// 백엔드 응답 구조:
  /// {
  ///   "id": 1,
  ///   "name": "그룹장",
  ///   "description": "그룹 소유자",
  ///   "isSystemRole": true,
  ///   "priority": 100,
  ///   "permissions": ["GROUP_MANAGE", "MEMBER_MANAGE", ...]
  /// }
  GroupRole _parseGroupRole(Map<String, dynamic> json) {
    return GroupRole(
      id: (json['id'] as num).toString(), // id를 문자열로 변환
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      isSystemRole: json['isSystemRole'] as bool? ?? false,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Mock 구현체
class MockRoleRepository implements RoleRepository {
  // Mock 데이터 저장소
  final Map<int, List<GroupRole>> _rolesByGroup = {
    1: [
      GroupRole(
        id: 'owner',
        name: '그룹장',
        description: '그룹 소유자 (모든 권한)',
        isSystemRole: true,
        priority: 1,
        permissions: [
          'GROUP_MANAGE',
          'MEMBER_MANAGE',
          'CHANNEL_MANAGE',
          'RECRUITMENT_MANAGE',
        ],
        memberCount: 1,
      ),
      GroupRole(
        id: 'advisor',
        name: '교수',
        description: '자문 역할 (대부분의 권한)',
        isSystemRole: true,
        priority: 2,
        permissions: [
          'GROUP_MANAGE',
          'MEMBER_MANAGE',
          'CHANNEL_MANAGE',
          'RECRUITMENT_MANAGE',
        ],
        memberCount: 1,
      ),
      GroupRole(
        id: 'member',
        name: '멤버',
        description: '일반 멤버',
        isSystemRole: true,
        priority: 3,
        permissions: [],
        memberCount: 3,
      ),
    ],
  };

  int _nextRoleId = 1000; // 커스텀 역할 ID 생성용

  @override
  Future<List<GroupRole>> getGroupRoles(int groupId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _rolesByGroup[groupId] ?? [];
  }

  @override
  Future<GroupRole> createRole(
    int groupId,
    String name,
    String description,
    List<String> permissions,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final newRole = GroupRole(
      id: 'role_${_nextRoleId++}',
      name: name,
      description: description,
      isSystemRole: false,
      priority: 100, // 커스텀 역할은 낮은 우선순위
      permissions: permissions,
      memberCount: 0,
    );

    if (_rolesByGroup[groupId] == null) {
      _rolesByGroup[groupId] = [];
    }
    _rolesByGroup[groupId]!.add(newRole);

    return newRole;
  }

  @override
  Future<GroupRole> updateRole(
    int groupId,
    String roleId,
    String name,
    String description,
    List<String> permissions,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final roles = _rolesByGroup[groupId];
    if (roles == null) {
      throw Exception('Group not found');
    }

    final roleIndex = roles.indexWhere((r) => r.id == roleId);
    if (roleIndex == -1) {
      throw Exception('Role not found');
    }

    final role = roles[roleIndex];
    if (role.isSystemRole) {
      throw Exception('Cannot modify system role');
    }

    final updatedRole = role.copyWith(
      name: name,
      description: description,
      permissions: permissions,
    );

    _rolesByGroup[groupId]![roleIndex] = updatedRole;
    return updatedRole;
  }

  @override
  Future<void> deleteRole(int groupId, String roleId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final roles = _rolesByGroup[groupId];
    if (roles == null) {
      throw Exception('Group not found');
    }

    final role = roles.firstWhere(
      (r) => r.id == roleId,
      orElse: () => throw Exception('Role not found'),
    );

    if (role.isSystemRole) {
      throw Exception('Cannot delete system role');
    }

    _rolesByGroup[groupId] = roles.where((r) => r.id != roleId).toList();
  }
}
