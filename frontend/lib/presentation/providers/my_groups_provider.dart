import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/group_models.dart';
import '../../core/services/group_service.dart';

/// 현재 사용자가 속한 모든 그룹 목록 Provider
///
/// GroupService를 통해 /api/me/groups API를 호출하여
/// 사용자의 그룹 멤버십 목록을 가져옵니다.
///
/// 자동 정렬: level 오름차순 → id 오름차순
final myGroupsProvider = FutureProvider<List<GroupMembership>>((ref) async {
  final groupService = GroupService();
  return await groupService.getMyGroups();
});
