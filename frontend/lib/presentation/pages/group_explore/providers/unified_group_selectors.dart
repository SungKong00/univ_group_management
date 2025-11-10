import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/group_models.dart';
import '../../../../core/providers/unified_group_provider.dart';

/// 리스트 뷰용 필터링된 그룹
///
/// 통합 데이터 소스에서 필터링된 그룹 목록을 제공합니다.
/// 필터 변경 시 자동으로 업데이트됩니다.
final listViewGroupsProvider = Provider<List<GroupSummaryResponse>>((ref) {
  final groups = ref.watch(
    unifiedGroupProvider.select((s) => s.filteredGroups),
  );
  print('🔍 [DEBUG] listViewGroupsProvider: ${groups.length} groups');
  return groups;
});

/// 계층구조 뷰용 트리 노드
///
/// 필터링된 그룹으로부터 구축한 계층구조 트리를 제공합니다.
/// 필터 변경 시 자동으로 트리를 다시 구축합니다.
final treeViewNodesProvider = Provider<List<UnifiedGroupTreeNode>>((ref) {
  return ref.watch(unifiedGroupProvider.select((s) => s.hierarchyTree));
});

/// 로딩 상태 (양쪽 뷰 공유)
///
/// 초기 데이터 로딩 상태를 제공합니다.
final groupLoadingProvider = Provider<bool>((ref) {
  return ref.watch(unifiedGroupProvider.select((s) => s.isLoading));
});

/// 에러 메시지 (양쪽 뷰 공유)
///
/// 데이터 로딩 중 발생한 에러를 제공합니다.
final groupErrorProvider = Provider<String?>((ref) {
  return ref.watch(unifiedGroupProvider.select((s) => s.errorMessage));
});

/// 페이지네이션 사용 여부
///
/// true: 페이지네이션 모드 (무한 스크롤)
/// false: 전체 로드 모드 (로컬 필터링)
final usePaginationProvider = Provider<bool>((ref) {
  return ref.watch(unifiedGroupProvider.select((s) => s.usePagination));
});

/// 더 불러올 데이터가 있는지 여부
///
/// 페이지네이션 모드에서만 사용됩니다.
final hasMoreProvider = Provider<bool>((ref) {
  return ref.watch(unifiedGroupProvider.select((s) => s.hasMore));
});

/// 추가 로딩 중인지 여부
///
/// 무한 스크롤로 다음 페이지를 로드하는 중인지 나타냅니다.
final isLoadingMoreProvider = Provider<bool>((ref) {
  return ref.watch(unifiedGroupProvider.select((s) => s.isLoadingMore));
});

/// 전체 그룹 개수
///
/// 필터링 전 전체 그룹 수를 나타냅니다.
final totalCountProvider = Provider<int>((ref) {
  return ref.watch(unifiedGroupProvider.select((s) => s.totalCount));
});
