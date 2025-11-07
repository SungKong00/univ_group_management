import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/group_explore_filter.dart';
import '../generic/local_filter_notifier.dart';

/// 그룹 탐색 필터 Notifier
///
/// 로컬 필터링을 위한 필터 상태 관리
/// 필터 선택 시 즉시 상태 업데이트 (드래프트 없음)
class GroupExploreFilterNotifier
    extends LocalFilterNotifier<GroupExploreFilter> {
  GroupExploreFilterNotifier() : super(GroupExploreFilter());

  /// 그룹 타입 토글 (다중 선택)
  void toggleGroupType(String type) {
    updateFilter((filter) {
      final current = filter.groupTypes ?? [];
      final updated = current.contains(type)
          ? current.where((t) => t != type).toList()
          : [...current, type];

      return filter.copyWith(
        groupTypes: updated.isEmpty ? null : updated,
      );
    });
  }

  /// 모집 여부 필터
  void toggleRecruiting() {
    updateFilter((filter) {
      return filter.copyWith(
        recruiting: filter.recruiting == true ? null : true,
      );
    });
  }

  /// 태그 토글 (다중 선택)
  void toggleTag(String tag) {
    updateFilter((filter) {
      final current = filter.tags ?? [];
      final updated = current.contains(tag)
          ? current.where((t) => t != tag).toList()
          : [...current, tag];

      return filter.copyWith(
        tags: updated.isEmpty ? null : updated,
      );
    });
  }

  /// 검색어 설정
  void setSearchQuery(String query) {
    updateFilter((filter) {
      return filter.copyWith(
        searchQuery: query.isEmpty ? null : query,
      );
    });
  }
}

/// 그룹 탐색 필터 Provider
final groupExploreFilterProvider =
    StateNotifierProvider<GroupExploreFilterNotifier, GroupExploreFilter>(
  (ref) => GroupExploreFilterNotifier(),
);
