import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/member_models.dart';
import '../../../../core/repositories/repository_providers.dart';
import 'member_list_provider.dart';

/// 가입 신청 목록 Provider
final joinRequestListProvider = FutureProvider.family<List<JoinRequest>, int>((
  ref,
  groupId,
) async {
  final repository = ref.watch(joinRequestRepositoryProvider);
  return await repository.getPendingRequests(groupId);
});

/// 가입 신청 승인 Provider
class ApproveRequestParams {
  final int groupId;
  final int requestId;
  final String roleId;

  ApproveRequestParams({
    required this.groupId,
    required this.requestId,
    required this.roleId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApproveRequestParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          requestId == other.requestId &&
          roleId == other.roleId;

  @override
  int get hashCode => Object.hash(groupId, requestId, roleId);
}

final approveJoinRequestProvider = FutureProvider.autoDispose
    .family<void, ApproveRequestParams>((ref, params) async {
      final repository = ref.watch(joinRequestRepositoryProvider);
      await repository.approveRequest(
        params.groupId,
        params.requestId,
        params.roleId,
      );

      // 성공 후 신청 목록 및 멤버 목록 새로고침
      ref.invalidate(joinRequestListProvider(params.groupId));
      ref.invalidate(memberListProvider(params.groupId));
    });

/// 가입 신청 거절 Provider
class RejectRequestParams {
  final int groupId;
  final int requestId;

  RejectRequestParams({required this.groupId, required this.requestId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RejectRequestParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          requestId == other.requestId;

  @override
  int get hashCode => Object.hash(groupId, requestId);
}

final rejectJoinRequestProvider = FutureProvider.autoDispose
    .family<void, RejectRequestParams>((ref, params) async {
      final repository = ref.watch(joinRequestRepositoryProvider);
      await repository.rejectRequest(params.groupId, params.requestId);

      // 성공 후 신청 목록 새로고침
      ref.invalidate(joinRequestListProvider(params.groupId));
    });
