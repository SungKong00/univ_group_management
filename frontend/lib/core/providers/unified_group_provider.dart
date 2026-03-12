import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../models/group_models.dart';
import '../models/group_explore_filter.dart';
import '../services/group_explore_service.dart';
import 'group_explore/group_explore_filter_provider.dart';

/// 그룹 계층 트리 노드 (GroupTreeNode 대체)
class UnifiedGroupTreeNode with EquatableMixin {
  final GroupSummaryResponse group;
  final List<UnifiedGroupTreeNode> children;
  final int level;

  UnifiedGroupTreeNode({
    required this.group,
    this.children = const [],
    this.level = 0,
  });

  @override
  List<Object?> get props => [group.id, children, level];
}

/// 통합 그룹 데이터 상태
class UnifiedGroupState extends Equatable {
  UnifiedGroupState({
    this.allGroups = const [],
    GroupExploreFilter? filter,
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.totalCount = 0,
    this.usePagination = false,
  }) : filter = filter ?? GroupExploreFilter();

  final List<GroupSummaryResponse> allGroups; // API로부터 로드된 전체 그룹
  final GroupExploreFilter filter; // 통합 필터
  final bool isLoading;
  final String? errorMessage;

  // Pagination fields
  final int currentPage; // 현재 페이지 (페이지네이션 모드에서만 사용)
  final bool hasMore; // 더 불러올 데이터가 있는지
  final bool isLoadingMore; // 추가 로딩 중인지
  final int totalCount; // 전체 그룹 수
  final bool usePagination; // 페이지네이션 사용 여부 (true: 페이지네이션, false: 전체 로드)

  /// 필터링된 그룹 목록 (리스트 뷰용)
  List<GroupSummaryResponse> get filteredGroups {
    final result = _filterGroups(allGroups, filter);
    return result;
  }

  /// 계층구조 트리 노드 (계층구조 뷰용)
  /// Note: GroupSummaryResponse에 parentId가 없어서 계층 구조 구축 불가
  /// 향후 GroupHierarchyNode를 사용하도록 수정 필요
  List<UnifiedGroupTreeNode> get hierarchyTree {
    // 임시로 빈 리스트 반환
    // TODO: 계층구조를 위해서는 GroupHierarchyNode 사용 필요
    return [];
    // return _buildHierarchyTree(filteredGroups);
  }

  /// 로컬 필터링 함수
  List<GroupSummaryResponse> _filterGroups(
    List<GroupSummaryResponse> groups,
    GroupExploreFilter filter,
  ) {
    // 필터가 비활성 상태면 전체 그룹 반환
    if (!filter.isActive) {
      return groups;
    }

    final filtered = groups.where((group) {
      // groupType 필터
      if (filter.groupTypes?.isNotEmpty ?? false) {
        final groupTypeStr = group.groupType.name.toUpperCase();
        final matches = filter.groupTypes!.contains(groupTypeStr);
        if (!matches) {
          return false;
        }
      }

      // recruiting 필터
      if (filter.recruiting != null) {
        final matches = group.isRecruiting == filter.recruiting;
        if (!matches) {
          return false;
        }
      }

      // tags 필터
      if (filter.tags?.isNotEmpty ?? false) {
        final hasAllTags = filter.tags!.every(
          (tag) => group.tags.contains(tag),
        );
        if (!hasAllTags) return false;
      }

      // searchQuery 필터
      if (filter.searchQuery?.isNotEmpty ?? false) {
        if (!group.name.toLowerCase().contains(
          filter.searchQuery!.toLowerCase(),
        )) {
          return false;
        }
      }

      return true;
    }).toList();

    return filtered;
  }

  // 계층구조 트리 구축 함수
  // Note: GroupSummaryResponse에 parentId가 없어서 사용 불가
  // TODO: GroupHierarchyNode를 사용하도록 수정 필요

  // List<UnifiedGroupTreeNode> _buildHierarchyTree(
  //   List<GroupSummaryResponse> groups,
  // ) {
  //   // 그룹 ID를 키로 하는 맵 생성
  //   final groupMap = <int, GroupSummaryResponse>{};
  //   for (final group in groups) {
  //     groupMap[group.id] = group;
  //   }
  //
  //   // 루트 노드 찾기 (parent_id가 null인 그룹)
  //   final roots = <UnifiedGroupTreeNode>[];
  //   for (final group in groups) {
  //     // 부모 그룹이 없거나, 부모가 필터링된 목록에 없으면 루트
  //     if (group.parentId == null || !groupMap.containsKey(group.parentId)) {
  //       roots.add(_buildNode(group, groups, groupMap));
  //     }
  //   }
  //
  //   return roots;
  // }
  //
  // /// 재귀적으로 노드 구축
  // UnifiedGroupTreeNode _buildNode(
  //   GroupSummaryResponse group,
  //   List<GroupSummaryResponse> filteredGroups,
  //   Map<int, GroupSummaryResponse> groupMap,
  // ) {
  //   // 이 그룹의 자식 찾기
  //   final children = filteredGroups
  //       .where((g) => g.parentId == group.id)
  //       .map((child) => _buildNode(child, filteredGroups, groupMap))
  //       .toList();
  //
  //   return UnifiedGroupTreeNode(
  //     group: group,
  //     children: children,
  //     level: 0, // 계층 레벨은 UI에서 계산
  //   );
  // }

  UnifiedGroupState copyWith({
    List<GroupSummaryResponse>? allGroups,
    GroupExploreFilter? filter,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    int? totalCount,
    bool? usePagination,
  }) {
    return UnifiedGroupState(
      allGroups: allGroups ?? this.allGroups,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      totalCount: totalCount ?? this.totalCount,
      usePagination: usePagination ?? this.usePagination,
    );
  }

  @override
  List<Object?> get props => [
    allGroups,
    filter,
    isLoading,
    errorMessage,
    currentPage,
    hasMore,
    isLoadingMore,
    totalCount,
    usePagination,
  ];
}

/// 통합 그룹 데이터 Notifier
///
/// 리스트와 계층구조 뷰를 위한 단일 데이터 소스를 관리합니다.
/// - API 호출: 1회 (getAllGroups)
/// - 필터: 통합 (groupExploreFilterProvider)
/// - 데이터: 양쪽 뷰에서 공유
class UnifiedGroupStateNotifier extends StateNotifier<UnifiedGroupState> {
  UnifiedGroupStateNotifier(this.ref) : super(UnifiedGroupState());

  final Ref ref;
  final GroupExploreService _service = GroupExploreService();

  /// 초기화: 하이브리드 전략
  ///
  /// 1. 먼저 전체 그룹 개수 확인 (page=0, size=1로 조회)
  /// 2. 그룹 개수 ≤ 500: 전체 로드 (getAllGroups) + 로컬 필터링
  /// 3. 그룹 개수 > 500: 페이지네이션 (getGroups) + 무한 스크롤
  Future<void> initialize() async {
    // 이미 로드됨
    if (state.allGroups.isNotEmpty && !state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 1. 먼저 전체 개수 확인 (page=0, size=1)
      final countResponse = await _service.getGroups(
        page: 0,
        size: 1,
        queryParams: {},
      );
      final totalCount = countResponse.data.pagination.totalElements;

      // 2. 전략 결정
      if (totalCount <= 500) {
        // 전체 로드 모드
        final allGroups = await _service.getAllGroups();
        state = state.copyWith(
          allGroups: allGroups,
          totalCount: totalCount,
          usePagination: false,
          isLoading: false,
        );
      } else {
        // 페이지네이션 모드
        final response = await _service.getGroups(
          page: 0,
          size: 20,
          queryParams: state.filter.toQueryParameters(),
        );
        state = state.copyWith(
          allGroups: response.data.content,
          currentPage: 0,
          hasMore: !response.data.pagination.last,
          totalCount: totalCount,
          usePagination: true,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '그룹을 불러오는데 실패했습니다.',
      );
    }
  }

  /// 필터 적용
  ///
  /// - usePagination == false: 로컬 필터링만
  /// - usePagination == true: API 재호출 필요
  Future<void> applyFilter(GroupExploreFilter filter) async {
    if (!state.usePagination) {
      // 전체 로드 모드: 로컬 필터링만
      state = state.copyWith(filter: filter);
      return;
    }

    // 페이지네이션 모드: API 재호출
    state = state.copyWith(filter: filter, isLoading: true, errorMessage: null);

    try {
      final response = await _service.getGroups(
        page: 0,
        size: 20,
        queryParams: filter.toQueryParameters(),
      );

      state = state.copyWith(
        allGroups: response.data.content,
        currentPage: 0,
        hasMore: !response.data.pagination.last,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '필터 적용에 실패했습니다.');
    }
  }

  /// 무한 스크롤: 다음 페이지 로드
  ///
  /// 페이지네이션 모드에서만 사용됩니다.
  Future<void> loadMore() async {
    // 전체 로드 모드에서는 무시
    if (!state.usePagination) return;

    // 이미 로딩 중이거나 더 이상 데이터가 없으면 무시
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final response = await _service.getGroups(
        page: nextPage,
        size: 20,
        queryParams: state.filter.toQueryParameters(),
      );

      state = state.copyWith(
        allGroups: [...state.allGroups, ...response.data.content],
        currentPage: nextPage,
        hasMore: !response.data.pagination.last,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: '추가 데이터를 불러오는데 실패했습니다.',
      );
    }
  }

  /// 상태 초기화
  void reset() {
    state = UnifiedGroupState();
  }
}

/// 통합 그룹 데이터 Provider
final unifiedGroupProvider =
    StateNotifierProvider<UnifiedGroupStateNotifier, UnifiedGroupState>((ref) {
      final notifier = UnifiedGroupStateNotifier(ref);

      // 필터 변경 감지 및 자동 적용
      ref.listen<GroupExploreFilter>(groupExploreFilterProvider, (
        previous,
        next,
      ) {
        if (previous != next) {
          notifier.applyFilter(next);
        }
      });

      return notifier;
    });
