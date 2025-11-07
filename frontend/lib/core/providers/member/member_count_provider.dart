import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/member_filter.dart';
import '../../repositories/repository_providers.dart';
import 'member_filter_provider.dart';

/// 멤버 카운트 Provider (Phase 3: 예상 결과 개수 미리보기)
///
/// 드래프트 필터를 기반으로 예상 결과 개수를 API로 조회합니다.
/// 300ms 디바운싱을 통해 불필요한 API 호출을 방지합니다.
final memberCountProvider = FutureProvider.family<int, _MemberCountParams>(
  (ref, params) async {
    // 디바운싱: 300ms 대기 후 API 호출
    await Future.delayed(const Duration(milliseconds: 300));

    final memberRepository = ref.watch(memberRepositoryProvider);

    // 드래프트 필터가 비어있으면 전체 멤버 개수 조회
    if (params.filter.isEmpty) {
      final members = await memberRepository.getGroupMembers(params.groupId);
      return members.length;
    }

    // 필터가 있으면 필터링된 멤버 개수 조회
    final members = await memberRepository.getGroupMembers(
      params.groupId,
      queryParameters: params.filter.toQueryParameters() as Map<String, String>,
    );
    return members.length;
  },
);

/// 멤버 카운트 조회 파라미터
class _MemberCountParams {
  final int groupId;
  final MemberFilter filter;

  _MemberCountParams({
    required this.groupId,
    required this.filter,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _MemberCountParams) return false;
    return groupId == other.groupId && filter == other.filter;
  }

  @override
  int get hashCode => Object.hash(groupId, filter);
}

/// 드래프트 기반 멤버 카운트 Provider (편의 래퍼)
///
/// MemberFilterNotifier의 draftFilter를 감지하여 자동으로 카운트를 업데이트합니다.
final draftMemberCountProvider = FutureProvider.family<int, int>(
  (ref, groupId) async {
    final filterNotifier = ref.watch(memberFilterStateProvider(groupId).notifier);
    final draftFilter = filterNotifier.draftFilter;

    // memberCountProvider에 위임
    return ref.watch(
      memberCountProvider(_MemberCountParams(
        groupId: groupId,
        filter: draftFilter,
      )).future,
    );
  },
);
