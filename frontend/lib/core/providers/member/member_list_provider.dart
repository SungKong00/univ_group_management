import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/member_models.dart';
import '../../repositories/repository_providers.dart';
import '../extensions/ref_extensions.dart';
import 'member_filter_provider.dart';

/// 필터가 적용된 그룹 멤버 목록 조회 Provider
///
/// 현재 활성화된 필터를 적용하여 멤버 목록을 조회합니다.
/// 필터가 없으면 전체 멤버를 반환합니다.
///
/// 성능 최적화:
/// - 캐싱: 동일한 필터 조합은 5분간 캐시
/// - autoDispose: 사용하지 않을 때 자동 해제
final filteredGroupMembersProvider = FutureProvider.autoDispose
    .family<List<GroupMember>, int>((ref, groupId) async {
  // 5분간 캐시 유지
  ref.cacheFor(const Duration(minutes: 5));

  // 현재 필터 상태 감시
  final filter = ref.watch(memberFilterStateProvider(groupId));
  final memberRepository = ref.watch(memberRepositoryProvider);

  // 필터가 없으면 전체 조회
  if (!filter.isActive) {
    return memberRepository.getGroupMembers(groupId);
  }

  // 필터 적용하여 조회
  return memberRepository.getGroupMembers(
    groupId,
    queryParameters: filter.toQueryParameters() as Map<String, String>,
  );
});

/// 전체 그룹 멤버 목록 조회 Provider (필터 미적용)
///
/// 필터와 무관하게 항상 전체 멤버를 조회합니다.
/// 주로 통계나 역할 할당 시 사용됩니다.
final allGroupMembersProvider = FutureProvider.autoDispose
    .family<List<GroupMember>, int>((ref, groupId) async {
  final memberRepository = ref.watch(memberRepositoryProvider);
  return memberRepository.getGroupMembers(groupId);
});
