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
/// **세션 스코프 캐싱 (keepAlive):**
/// - 글로벌 네비게이션으로 탭 전환 시 provider가 dispose되지 않도록 keepAlive 사용
/// - 워크스페이스 그룹 선택 상태가 탭 전환 후에도 메모리에 유지됨
/// - 로그아웃 시에는 core/providers/provider_reset.dart에서 명시적으로 invalidate됩니다.
final myGroupsProvider = FutureProvider<List<GroupMembership>>((ref) async {
  // ✅ keepAlive: 탭 전환 시 provider dispose 방지 (세션 스코프 유지)
  ref.keepAlive();

  final groupService = GroupService();
  return await groupService.getMyGroups();
});
