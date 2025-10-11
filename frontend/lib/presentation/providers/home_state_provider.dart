import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../pages/group_explore/providers/group_explore_state_provider.dart';

/// Home View Types
enum HomeView {
  dashboard, // Default home dashboard
  groupExplore, // Group exploration view
}

/// Home State
class HomeState extends Equatable {
  const HomeState({
    this.currentView = HomeView.dashboard,
    this.previousView,
    this.groupExploreInitialTab = 0,
  });

  final HomeView currentView;
  final HomeView? previousView;
  final int groupExploreInitialTab; // 0: List, 1: Tree, 2: Recruitment

  HomeState copyWith({
    HomeView? currentView,
    HomeView? previousView,
    int? groupExploreInitialTab,
  }) {
    return HomeState(
      currentView: currentView ?? this.currentView,
      previousView: previousView,
      groupExploreInitialTab: groupExploreInitialTab ?? this.groupExploreInitialTab,
    );
  }

  @override
  List<Object?> get props => [currentView, previousView, groupExploreInitialTab];
}

/// Home State Notifier
class HomeStateNotifier extends StateNotifier<HomeState> {
  HomeStateNotifier(this._ref) : super(const HomeState());

  final Ref _ref;

  /// Show group explore view
  void showGroupExplore({int initialTab = 0}) {
    state = state.copyWith(
      previousView: state.currentView,
      currentView: HomeView.groupExplore,
      groupExploreInitialTab: initialTab,
    );
  }

  /// Show group explore view with recruiting filter enabled
  void showGroupExploreWithRecruitingFilter() {
    // First, navigate to group explore view (List tab)
    state = state.copyWith(
      previousView: state.currentView,
      currentView: HomeView.groupExplore,
      groupExploreInitialTab: 0, // List tab
    );

    // Then, activate the recruiting filter
    _ref.read(groupExploreStateProvider.notifier).updateFilter('recruiting', true);
  }

  /// Show dashboard view
  void showDashboard() {
    state = state.copyWith(
      previousView: state.currentView,
      currentView: HomeView.dashboard,
    );
  }

  /// Handle back navigation
  /// Returns true if handled internally, false to delegate to external navigation
  bool handleBack() {
    if (state.currentView == HomeView.groupExplore) {
      showDashboard();
      return true; // Handled internally
    }
    return false; // Delegate to external navigation
  }
}

// State Provider
final homeStateProvider = StateNotifierProvider<HomeStateNotifier, HomeState>(
  (ref) => HomeStateNotifier(ref),
);

// Selective Provider (prevent unnecessary rebuilds)
final currentHomeViewProvider = Provider<HomeView>((ref) {
  return ref.watch(homeStateProvider.select((state) => state.currentView));
});
