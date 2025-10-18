import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models/recruitment_models.dart';
import '../../../../core/services/recruitment_service.dart';

/// Recruitment Explore State
class RecruitmentExploreState extends Equatable {
  const RecruitmentExploreState({
    this.searchQuery = '',
    this.recruitments = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.errorMessage,
  });

  final String searchQuery;
  final List<RecruitmentSummaryResponse> recruitments;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;

  RecruitmentExploreState copyWith({
    String? searchQuery,
    List<RecruitmentSummaryResponse>? recruitments,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
  }) {
    return RecruitmentExploreState(
      searchQuery: searchQuery ?? this.searchQuery,
      recruitments: recruitments ?? this.recruitments,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        recruitments,
        isLoading,
        hasMore,
        currentPage,
        errorMessage,
      ];
}

/// Recruitment Explore State Notifier
class RecruitmentExploreStateNotifier
    extends StateNotifier<RecruitmentExploreState> {
  RecruitmentExploreStateNotifier() : super(const RecruitmentExploreState());

  final RecruitmentService _service = RecruitmentService();

  /// Search recruitments with a new query
  Future<void> search(String query) async {
    state = state.copyWith(
      searchQuery: query,
      currentPage: 0,
      recruitments: [],
      hasMore: true,
    );
    await _loadRecruitments(reset: true);
  }

  /// Load recruitments (with pagination)
  Future<void> _loadRecruitments({bool reset = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final page = reset ? 0 : state.currentPage;
      final pageSize = 20;

      final response = await _service.searchPublicRecruitments(
        keyword: state.searchQuery.isEmpty ? null : state.searchQuery,
        page: page,
        size: pageSize,
      );

      final newRecruitments =
          reset ? response : [...state.recruitments, ...response];

      state = state.copyWith(
        recruitments: newRecruitments,
        hasMore: response.length >= pageSize, // Has more if we got a full page
        currentPage: page + 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '모집 공고를 불러오는데 실패했습니다.',
      );
    }
  }

  /// Load more recruitments (infinite scroll)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await _loadRecruitments();
  }

  /// Initialize: load recruitments on first access
  Future<void> initialize() async {
    if (state.recruitments.isEmpty && !state.isLoading) {
      await _loadRecruitments(reset: true);
    }
  }

  /// Reset state
  void reset() {
    state = const RecruitmentExploreState();
  }
}

// State Provider
final recruitmentExploreStateProvider = StateNotifierProvider<
    RecruitmentExploreStateNotifier, RecruitmentExploreState>(
  (ref) => RecruitmentExploreStateNotifier(),
);

// Selective Providers (prevent unnecessary rebuilds)
final exploreRecruitmentsProvider =
    Provider<List<RecruitmentSummaryResponse>>((ref) {
  return ref
      .watch(recruitmentExploreStateProvider.select((s) => s.recruitments));
});

final exploreRecruitmentIsLoadingProvider = Provider<bool>((ref) {
  return ref
      .watch(recruitmentExploreStateProvider.select((s) => s.isLoading));
});

final exploreRecruitmentHasMoreProvider = Provider<bool>((ref) {
  return ref.watch(recruitmentExploreStateProvider.select((s) => s.hasMore));
});

final exploreRecruitmentErrorMessageProvider = Provider<String?>((ref) {
  return ref
      .watch(recruitmentExploreStateProvider.select((s) => s.errorMessage));
});

final exploreRecruitmentSearchQueryProvider = Provider<String>((ref) {
  return ref
      .watch(recruitmentExploreStateProvider.select((s) => s.searchQuery));
});
