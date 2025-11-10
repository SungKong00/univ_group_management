import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/group_models.dart';
import '../../../../core/services/group_service.dart';

/// GroupService Provider
final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService();
});

/// 하위 그룹 생성 요청 목록 Provider
final subGroupRequestListProvider = FutureProvider.autoDispose
    .family<List<SubGroupRequestResponse>, int>((ref, groupId) async {
      final service = ref.watch(groupServiceProvider);
      return await service.getSubGroupRequests(groupId);
    });

/// 대기 중인 하위 그룹 생성 요청 개수 Provider
final pendingSubGroupRequestCountProvider = FutureProvider.autoDispose
    .family<int, int>((ref, groupId) async {
      final requests = await ref.watch(
        subGroupRequestListProvider(groupId).future,
      );
      return requests.where((request) => request.status == 'PENDING').length;
    });

/// 하위 그룹 생성 요청 승인 Params
class ApproveSubGroupRequestParams {
  final int groupId;
  final int requestId;
  final String? responseMessage;

  ApproveSubGroupRequestParams({
    required this.groupId,
    required this.requestId,
    this.responseMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApproveSubGroupRequestParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          requestId == other.requestId &&
          responseMessage == other.responseMessage;

  @override
  int get hashCode => Object.hash(groupId, requestId, responseMessage);
}

/// 하위 그룹 생성 요청 승인 Provider
final approveSubGroupRequestProvider = FutureProvider.autoDispose
    .family<void, ApproveSubGroupRequestParams>((ref, params) async {
      final service = ref.watch(groupServiceProvider);
      await service.reviewSubGroupRequest(
        params.groupId,
        params.requestId,
        ReviewSubGroupRequestRequest(
          action: 'APPROVE',
          responseMessage: params.responseMessage,
        ),
      );

      // 성공 후 요청 목록 새로고침
      ref.invalidate(subGroupRequestListProvider(params.groupId));
    });

/// 하위 그룹 생성 요청 거절 Params
class RejectSubGroupRequestParams {
  final int groupId;
  final int requestId;
  final String? responseMessage;

  RejectSubGroupRequestParams({
    required this.groupId,
    required this.requestId,
    this.responseMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RejectSubGroupRequestParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          requestId == other.requestId &&
          responseMessage == other.responseMessage;

  @override
  int get hashCode => Object.hash(groupId, requestId, responseMessage);
}

/// 하위 그룹 생성 요청 거절 Provider
final rejectSubGroupRequestProvider = FutureProvider.autoDispose
    .family<void, RejectSubGroupRequestParams>((ref, params) async {
      final service = ref.watch(groupServiceProvider);
      await service.reviewSubGroupRequest(
        params.groupId,
        params.requestId,
        ReviewSubGroupRequestRequest(
          action: 'REJECT',
          responseMessage: params.responseMessage,
        ),
      );

      // 성공 후 요청 목록 새로고침
      ref.invalidate(subGroupRequestListProvider(params.groupId));
    });
