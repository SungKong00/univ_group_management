import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';

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
  });

  final HomeView currentView;
  final HomeView? previousView;

  HomeState copyWith({
    HomeView? currentView,
    HomeView? previousView,
  }) {
    return HomeState(
      currentView: currentView ?? this.currentView,
      previousView: previousView,
    );
  }

  @override
  List<Object?> get props => [currentView, previousView];
}

/// Home State Notifier
class HomeStateNotifier extends StateNotifier<HomeState> {
  HomeStateNotifier() : super(const HomeState());

  /// Show group explore view
  void showGroupExplore() {
    state = state.copyWith(
      previousView: state.currentView,
      currentView: HomeView.groupExplore,
    );
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
  (ref) => HomeStateNotifier(),
);

// Selective Provider (prevent unnecessary rebuilds)
final currentHomeViewProvider = Provider<HomeView>((ref) {
  return ref.watch(homeStateProvider.select((state) => state.currentView));
});
