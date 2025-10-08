import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/member_models.dart';
import '../../../../core/repositories/repository_providers.dart';

/// 멤버 목록 Provider
///
/// 특정 그룹의 멤버 목록을 제공합니다.
final memberListProvider = FutureProvider.family<List<GroupMember>, int>((ref, groupId) async {
  final repository = ref.watch(memberRepositoryProvider);
  return await repository.getGroupMembers(groupId);
});

/// 멤버 역할 변경 Provider
///
/// .family를 사용하여 파라미터 전달
class UpdateMemberRoleParams {
  final int groupId;
  final int memberId;
  final String roleId;

  UpdateMemberRoleParams({
    required this.groupId,
    required this.memberId,
    required this.roleId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateMemberRoleParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          memberId == other.memberId &&
          roleId == other.roleId;

  @override
  int get hashCode => Object.hash(groupId, memberId, roleId);
}

final updateMemberRoleProvider = FutureProvider.autoDispose
    .family<GroupMember, UpdateMemberRoleParams>((ref, params) async {
  final repository = ref.watch(memberRepositoryProvider);
  return await repository.updateMemberRole(
    params.groupId,
    params.memberId,
    params.roleId,
  );
});

/// 멤버 제거 Provider
class RemoveMemberParams {
  final int groupId;
  final int memberId;

  RemoveMemberParams({
    required this.groupId,
    required this.memberId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoveMemberParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          memberId == other.memberId;

  @override
  int get hashCode => Object.hash(groupId, memberId);
}

final removeMemberProvider = FutureProvider.autoDispose
    .family<void, RemoveMemberParams>((ref, params) async {
  final repository = ref.watch(memberRepositoryProvider);
  await repository.removeMember(params.groupId, params.memberId);

  // 성공 후 멤버 목록 새로고침
  ref.invalidate(memberListProvider(params.groupId));
});
