import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../core/models/group_models.dart';
import '../../core/services/group_service.dart';

/// 현재 사용자가 속한 모든 그룹 목록 Provider
///
/// GroupService를 통해 /api/me/groups API를 호출하여
/// 사용자의 그룹 멤버십 목록을 가져옵니다.
///
/// 자동 정렬: level 오름차순 → id 오름차순
///
/// **세션 스코프 캐싱 (keepAlive + refresh):**
/// - keepAlive(): 글로벌 네비게이션으로 탭 전환 시 provider dispose 방지 (세션 스코프 유지)
/// - 로그아웃 시: provider_reset.dart에서 ref.refresh(myGroupsProvider) 호출로 즉시 재로드
/// - 로그아웃 후 즉시 새 계정 로그인 시 새로운 그룹 목록을 즉시 로드
/// 자세한 설명: docs/troubleshooting/common-errors.md#로그아웃--데이터-캐시-문제
final myGroupsProvider = FutureProvider<List<GroupMembership>>((ref) async {
  // ✅ keepAlive: 탭 전환 시 provider dispose 방지 (세션 스코프 유지)
  ref.keepAlive();

  developer.log(
    '[MyGroupsProvider] API call started (${DateTime.now()})',
    name: 'MyGroupsProvider',
  );

  final groupService = GroupService();
  final groups = await groupService.getMyGroups();

  developer.log(
    '[MyGroupsProvider] API call completed, ${groups.length} groups (${DateTime.now()})',
    name: 'MyGroupsProvider',
  );

  return groups;
});
