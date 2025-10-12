import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/group_permission_service.dart';

/// 특정 그룹에 대한 현재 사용자의 권한 목록 Provider
///
/// GroupPermissionService를 통해 /api/groups/{groupId}/permissions API를 호출하여
/// 사용자가 해당 그룹에서 가지는 권한(예: CALENDAR_MANAGE, MEMBER_MANAGE)을 가져옵니다.
///
/// FutureProvider.family를 사용하여 그룹 ID별로 캐시됩니다.
/// autoDispose를 사용하여 사용하지 않을 때 자동으로 메모리에서 해제됩니다.
final groupPermissionsProvider =
    FutureProvider.family.autoDispose<Set<String>, int>((
  ref,
  groupId,
) async {
  final service = GroupPermissionService();
  return await service.getMyPermissions(groupId);
});

/// 특정 그룹에서 특정 권한을 가지고 있는지 확인하는 헬퍼 Provider
///
/// 사용 예:
/// ```dart
/// final hasCalendarManage = ref.watch(
///   hasPermissionProvider((groupId: 1, permission: 'CALENDAR_MANAGE'))
/// );
/// ```
final hasPermissionProvider = FutureProvider.family
    .autoDispose<bool, ({int groupId, String permission})>((
  ref,
  params,
) async {
  final permissions =
      await ref.watch(groupPermissionsProvider(params.groupId).future);
  return permissions.contains(params.permission);
});
