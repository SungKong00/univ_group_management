import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models/group_models.dart';
import '../../../../core/services/group_explore_service.dart';

/// Group Explore State
class GroupExploreState extends Equatable {
  const GroupExploreState({
    this.searchQuery = '',
    this.filters = const {},
    this.groups = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.errorMessage,
  });

  final String searchQuery;
  final Map<String, dynamic> filters; // groupType, isRecruiting, tags
  final List<GroupSummaryResponse> groups;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;

  GroupExploreState copyWith({
    String? searchQuery,
    Map<String, dynamic>? filters,
    List<GroupSummaryResponse>? groups,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
  }) {
    return GroupExploreState(
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        filters,
        groups,
        isLoading,
        hasMore,
        currentPage,
        errorMessage,
      ];
}

/// Group Explore State Notifier
class GroupExploreStateNotifier extends StateNotifier<GroupExploreState> {
  GroupExploreStateNotifier() : super(const GroupExploreState());

  final GroupExploreService _service = GroupExploreService();

  /// Search groups with a new query
  Future<void> search(String query) async {
    state = state.copyWith(
      searchQuery: query,
      currentPage: 0,
      groups: [],
      hasMore: true,
    );
    await _loadGroups(reset: true);
  }

  /// Update a filter and reload results
  void updateFilter(String key, dynamic value) {
    final newFilters = Map<String, dynamic>.from(state.filters);
    if (value == null) {
      newFilters.remove(key);
    } else {
      newFilters[key] = value;
    }
    state = state.copyWith(
      filters: newFilters,
      currentPage: 0,
      groups: [],
      hasMore: true,
    );
    _loadGroups(reset: true);
  }

  /// Toggle group type (multi-select)
  void toggleGroupType(String type) {
    final newFilters = Map<String, dynamic>.from(state.filters);
    final groupTypes = List<String>.from((newFilters['groupTypes'] as List<String>?) ?? []);

    if (groupTypes.contains(type)) {
      groupTypes.remove(type);
    } else {
      groupTypes.add(type);
    }

    if (groupTypes.isEmpty) {
      newFilters.remove('groupTypes');
    } else {
      newFilters['groupTypes'] = groupTypes;
    }

    state = state.copyWith(
      filters: newFilters,
      currentPage: 0,
      groups: [],
      hasMore: true,
    );
    _loadGroups(reset: true);
  }

  /// Load groups (with pagination)
  Future<void> _loadGroups({bool reset = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _service.exploreGroups(
        query: state.searchQuery.isEmpty ? null : state.searchQuery,
        filters: state.filters.isEmpty ? null : state.filters,
        page: reset ? 0 : state.currentPage,
        size: 20,
      );

      final newGroups = reset ? response : [...state.groups, ...response];

      state = state.copyWith(
        groups: newGroups,
        hasMore: response.length == 20, // If fetched full page, might have more
        currentPage: (reset ? 0 : state.currentPage) + 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '그룹을 불러오는데 실패했습니다.',
      );
    }
  }

  /// Load more groups (infinite scroll)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await _loadGroups();
  }

  /// Initialize: load groups on first access
  Future<void> initialize() async {
    if (state.groups.isEmpty && !state.isLoading) {
      await _loadGroups(reset: true);
    }
  }

  /// Reset state
  void reset() {
    state = const GroupExploreState();
  }
}

// State Provider
final groupExploreStateProvider =
    StateNotifierProvider<GroupExploreStateNotifier, GroupExploreState>(
  (ref) => GroupExploreStateNotifier(),
);

// Selective Providers (prevent unnecessary rebuilds)
final exploreGroupsProvider = Provider<List<GroupSummaryResponse>>((ref) {
  return ref.watch(groupExploreStateProvider.select((s) => s.groups));
});

final exploreIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(groupExploreStateProvider.select((s) => s.isLoading));
});

final exploreHasMoreProvider = Provider<bool>((ref) {
  return ref.watch(groupExploreStateProvider.select((s) => s.hasMore));
});

final exploreErrorMessageProvider = Provider<String?>((ref) {
  return ref.watch(groupExploreStateProvider.select((s) => s.errorMessage));
});

final exploreSearchQueryProvider = Provider<String>((ref) {
  return ref.watch(groupExploreStateProvider.select((s) => s.searchQuery));
});

final exploreFiltersProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(groupExploreStateProvider.select((s) => s.filters));
});
