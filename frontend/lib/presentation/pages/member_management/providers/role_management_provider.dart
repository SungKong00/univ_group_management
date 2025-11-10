import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/member_models.dart';
import '../../../../core/repositories/repository_providers.dart';

/// 그룹 역할 목록 Provider
final roleListProvider = FutureProvider.autoDispose
    .family<List<GroupRole>, int>((ref, groupId) async {
      final repository = ref.watch(roleRepositoryProvider);
      return await repository.getGroupRoles(groupId);
    });

/// 역할 생성 Provider
class CreateRoleParams {
  final int groupId;
  final String name;
  final String description;
  final List<String> permissions;

  CreateRoleParams({
    required this.groupId,
    required this.name,
    required this.description,
    required this.permissions,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateRoleParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          name == other.name &&
          description == other.description &&
          permissions.toString() == other.permissions.toString();

  @override
  int get hashCode => Object.hash(groupId, name, description, permissions);
}

final createRoleProvider = FutureProvider.autoDispose
    .family<GroupRole, CreateRoleParams>((ref, params) async {
      final repository = ref.watch(roleRepositoryProvider);
      final newRole = await repository.createRole(
        params.groupId,
        params.name,
        params.description,
        params.permissions,
      );

      // 성공 후 역할 목록 새로고침
      ref.invalidate(roleListProvider(params.groupId));

      return newRole;
    });

/// 역할 수정 Provider
class UpdateRoleParams {
  final int groupId;
  final int roleId;
  final String name;
  final String description;
  final List<String> permissions;

  UpdateRoleParams({
    required this.groupId,
    required this.roleId,
    required this.name,
    required this.description,
    required this.permissions,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateRoleParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          roleId == other.roleId &&
          name == other.name &&
          description == other.description &&
          permissions.toString() == other.permissions.toString();

  @override
  int get hashCode =>
      Object.hash(groupId, roleId, name, description, permissions);
}

final updateRoleProvider = FutureProvider.autoDispose
    .family<GroupRole, UpdateRoleParams>((ref, params) async {
      final repository = ref.watch(roleRepositoryProvider);
      final updatedRole = await repository.updateRole(
        params.groupId,
        params.roleId,
        params.name,
        params.description,
        params.permissions,
      );

      // 성공 후 역할 목록 새로고침
      ref.invalidate(roleListProvider(params.groupId));

      return updatedRole;
    });

/// 역할 삭제 Provider
class DeleteRoleParams {
  final int groupId;
  final int roleId;

  DeleteRoleParams({required this.groupId, required this.roleId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeleteRoleParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          roleId == other.roleId;

  @override
  int get hashCode => Object.hash(groupId, roleId);
}

final deleteRoleProvider = FutureProvider.autoDispose
    .family<void, DeleteRoleParams>((ref, params) async {
      final repository = ref.watch(roleRepositoryProvider);
      await repository.deleteRole(params.groupId, params.roleId);

      // 성공 후 역할 목록 새로고침
      ref.invalidate(roleListProvider(params.groupId));
    });
