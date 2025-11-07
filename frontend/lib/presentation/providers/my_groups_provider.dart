import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/group_models.dart';
import '../../core/services/group_service.dart';

/// 현재 사용자가 속한 모든 그룹 목록 Provider
///
/// GroupService를 통해 /api/me/groups API를 호출하여
/// 사용자의 그룹 멤버십 목록을 가져옵니다.
///
/// 자동 정렬: level 오름차순 → id 오름차순
///
/// autoDispose를 사용하여 사용하지 않을 때 자동으로 메모리에서 해제됩니다.
/// 로그아웃 시에는 core/providers/provider_reset.dart에서 명시적으로 invalidate됩니다.
final myGroupsProvider = FutureProvider.autoDispose<List<GroupMembership>>((
  ref,
) async {
  final groupService = GroupService();
  return await groupService.getMyGroups();
});
