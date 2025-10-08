import '../models/member_models.dart';

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

/// Mock 구현체
class MockRoleRepository implements RoleRepository {
  // Mock 데이터 저장소
  final Map<int, List<GroupRole>> _rolesByGroup = {
    1: [
      GroupRole(
        id: 'owner',
        name: 'Owner',
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
        name: 'Advisor',
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
        name: 'Member',
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
