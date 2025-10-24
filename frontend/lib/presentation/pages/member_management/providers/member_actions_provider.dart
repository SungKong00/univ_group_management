import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/member_models.dart';
import '../../../../core/repositories/repository_providers.dart';
import '../../../../core/providers/member/member_list_provider.dart';

/// 멤버 역할 변경 파라미터
class UpdateMemberRoleParams {
  final int groupId;
  final String userId;
  final int roleId;

  UpdateMemberRoleParams({
    required this.groupId,
    required this.userId,
    required this.roleId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateMemberRoleParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          userId == userId &&
          roleId == roleId;

  @override
  int get hashCode => Object.hash(groupId, userId, roleId);
}

/// 멤버 역할 변경 Provider
///
/// 역할 변경 후 자동으로 filteredGroupMembersProvider를 갱신합니다.
final updateMemberRoleProvider = FutureProvider.autoDispose
    .family<GroupMember, UpdateMemberRoleParams>((ref, params) async {
      final repository = ref.watch(memberRepositoryProvider);
      final result = await repository.updateMemberRole(
        params.groupId,
        params.userId,
        params.roleId,
      );

      // ✅ 올바른 Provider 갱신 (UI가 watch하는 Provider)
      ref.invalidate(filteredGroupMembersProvider(params.groupId));

      return result;
    });

/// 멤버 제거 파라미터
class RemoveMemberParams {
  final int groupId;
  final String userId;

  RemoveMemberParams({required this.groupId, required this.userId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoveMemberParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          userId == userId;

  @override
  int get hashCode => Object.hash(groupId, userId);
}

/// 멤버 제거 Provider
///
/// 멤버 제거 후 자동으로 filteredGroupMembersProvider를 갱신합니다.
final removeMemberProvider = FutureProvider.autoDispose
    .family<void, RemoveMemberParams>((ref, params) async {
      final repository = ref.watch(memberRepositoryProvider);
      await repository.removeMember(params.groupId, params.userId);

      // ✅ 올바른 Provider 갱신 (UI가 watch하는 Provider)
      ref.invalidate(filteredGroupMembersProvider(params.groupId));
    });
