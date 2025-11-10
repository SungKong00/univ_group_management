import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../core/models/recruitment_models.dart';
import '../../core/services/recruitment_service.dart';

/// Provider for recruitment service instance
final recruitmentServiceProvider = Provider<RecruitmentService>((ref) {
  return RecruitmentService();
});

/// State for recruiting groups
class RecruitingGroupsState {
  const RecruitingGroupsState({
    this.recruitments = const [],
    this.isLoading = false,
    this.error,
  });

  final List<RecruitmentSummaryResponse> recruitments;
  final bool isLoading;
  final String? error;

  RecruitingGroupsState copyWith({
    List<RecruitmentSummaryResponse>? recruitments,
    bool? isLoading,
    String? error,
  }) {
    return RecruitingGroupsState(
      recruitments: recruitments ?? this.recruitments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for recruiting groups
class RecruitingGroupsNotifier extends StateNotifier<RecruitingGroupsState> {
  RecruitingGroupsNotifier(this._recruitmentService)
    : super(const RecruitingGroupsState()) {
    // Automatically load data on creation
    loadRecruitingGroups();
  }

  final RecruitmentService _recruitmentService;

  /// Load recruiting groups from API
  Future<void> loadRecruitingGroups() async {
    if (state.isLoading) {
      developer.log(
        'Already loading recruiting groups, skipping...',
        name: 'RecruitingGroupsNotifier',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      developer.log(
        'Loading recruiting groups...',
        name: 'RecruitingGroupsNotifier',
      );

      // Fetch public recruitments with OPEN status
      final recruitments = await _recruitmentService.searchPublicRecruitments(
        page: 0,
        size: 20, // Fetch up to 20 recruiting groups
      );

      developer.log(
        'Successfully loaded ${recruitments.length} recruiting groups',
        name: 'RecruitingGroupsNotifier',
      );

      state = state.copyWith(
        recruitments: recruitments,
        isLoading: false,
        error: null,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load recruiting groups: $e',
        name: 'RecruitingGroupsNotifier',
        level: 900,
        error: e,
        stackTrace: stackTrace,
      );

      state = state.copyWith(isLoading: false, error: '모집 중인 그룹을 불러오는데 실패했습니다');
    }
  }

  /// Refresh recruiting groups
  Future<void> refresh() async {
    developer.log(
      'Refreshing recruiting groups...',
      name: 'RecruitingGroupsNotifier',
    );
    await loadRecruitingGroups();
  }
}

/// Provider for recruiting groups state
final recruitingGroupsProvider =
    StateNotifierProvider<RecruitingGroupsNotifier, RecruitingGroupsState>((
      ref,
    ) {
      final recruitmentService = ref.watch(recruitmentServiceProvider);
      return RecruitingGroupsNotifier(recruitmentService);
    });
