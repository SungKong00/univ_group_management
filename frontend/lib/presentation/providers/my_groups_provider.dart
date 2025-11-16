import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../core/models/group_models.dart';
import '../../core/services/group_service.dart';
import 'auth_provider.dart';

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

  // ✅ 변경 사항: currentUserProvider를 watch하여 로그인/로그아웃 변화를 반응형으로 감지
  final currentUserAsync = ref.watch(currentUserProvider);

  // 로딩 중이면 아직 사용자 결정 안 됨 → 빈 리스트 (워크스페이스 진입 대기)
  if (currentUserAsync.isLoading) {
    developer.log(
      '[MyGroupsProvider] Waiting for user to resolve (loading)',
      name: 'MyGroupsProvider',
    );
    return [];
  }

  // 에러 시에도 그룹 호출을 시도하지 않고 빈 리스트 반환 (상위 UI에서 에러 표시 가능)
  if (currentUserAsync.hasError) {
    developer.log(
      '[MyGroupsProvider] Skipping API call (user load error)',
      name: 'MyGroupsProvider',
      level: 500, // INFO 수준으로 완화
    );
    return [];
  }

  final currentUser = currentUserAsync.value; // UserInfo? (null = 로그아웃 상태)

  // ✅ 로그인되지 않은 상태면 API 호출 차단 → 빈 리스트 반환
  if (currentUser == null) {
    developer.log(
      '[MyGroupsProvider] Skipping API call (user not logged in)',
      name: 'MyGroupsProvider',
    );
    return [];
  }

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
