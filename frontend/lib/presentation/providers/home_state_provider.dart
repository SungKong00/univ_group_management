import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../../core/services/local_storage.dart';
import '../../core/providers/group_explore/group_explore_filter_provider.dart';

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
      groupExploreInitialTab:
          groupExploreInitialTab ?? this.groupExploreInitialTab,
    );
  }

  @override
  List<Object?> get props => [
    currentView,
    previousView,
    groupExploreInitialTab,
  ];
}

/// Home Snapshot - 홈 페이지 상태를 메모리에 캐싱하기 위한 스냅샷
class HomeSnapshot {
  const HomeSnapshot({
    required this.view,
    this.previousView,
    this.groupExploreInitialTab = 0,
  });

  final HomeView view;
  final HomeView? previousView;
  final int groupExploreInitialTab;

  /// JSON으로 직렬화 (LocalStorage 저장용)
  Map<String, dynamic> toJson() {
    return {
      'view': view.name,
      'previousView': previousView?.name,
      'groupExploreInitialTab': groupExploreInitialTab,
    };
  }

  /// JSON에서 복원
  factory HomeSnapshot.fromJson(Map<String, dynamic> json) {
    return HomeSnapshot(
      view: HomeView.values.firstWhere(
        (v) => v.name == json['view'],
        orElse: () => HomeView.dashboard,
      ),
      previousView: json['previousView'] != null
          ? HomeView.values.firstWhere(
              (v) => v.name == json['previousView'],
              orElse: () => HomeView.dashboard,
            )
          : null,
      groupExploreInitialTab: json['groupExploreInitialTab'] ?? 0,
    );
  }
}

/// Home State Notifier
class HomeStateNotifier extends StateNotifier<HomeState> {
  HomeStateNotifier(this._ref) : super(const HomeState());

  final Ref _ref;

  /// 메모리 캐시: 홈 페이지 상태 스냅샷 (탭 전환 시 복원용)
  static HomeSnapshot? _cachedSnapshot;

  /// 초기화 플래그 (중복 초기화 방지)
  bool _hasInitialized = false;

  /// 홈 페이지 초기화 (앱 시작 시 또는 홈 탭 진입 시 호출)
  Future<void> initialize() async {
    if (_hasInitialized) return;

    try {
      // 1. 메모리 스냅샷 확인 (최우선)
      if (_cachedSnapshot != null) {
        loadSnapshot();
        _hasInitialized = true;
        return;
      }

      // 2. LocalStorage에서 복원
      final localStorage = LocalStorage.instance;
      final lastView = await localStorage.getLastHomeView();
      final lastTab = await localStorage.getLastGroupExploreTab();

      if (lastView != null || lastTab != null) {
        // 뷰 복원
        HomeView? restoredView;
        if (lastView != null) {
          try {
            restoredView = HomeView.values.firstWhere(
              (v) => v.name == lastView,
            );
          } catch (_) {
            restoredView = HomeView.dashboard;
          }
        }

        state = state.copyWith(
          currentView: restoredView ?? state.currentView,
          groupExploreInitialTab: lastTab ?? state.groupExploreInitialTab,
        );
      }

      _hasInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Failed to restore home state: $e',
          name: 'HomeStateNotifier',
          level: 900,
        );
      }
      _hasInitialized = true;
    }
  }

  /// 현재 상태를 스냅샷으로 저장 (메모리 캐싱)
  void saveSnapshot() {
    _cachedSnapshot = HomeSnapshot(
      view: state.currentView,
      previousView: state.previousView,
      groupExploreInitialTab: state.groupExploreInitialTab,
    );
  }

  /// Clears any cached state so the next login starts fresh
  void clearSnapshots() {
    _cachedSnapshot = null;
    _hasInitialized = false;
    state = const HomeState();
  }

  /// 스냅샷에서 상태 복원
  void loadSnapshot() {
    if (_cachedSnapshot != null) {
      state = state.copyWith(
        currentView: _cachedSnapshot!.view,
        previousView: _cachedSnapshot!.previousView,
        groupExploreInitialTab: _cachedSnapshot!.groupExploreInitialTab,
      );
    }
  }

  /// LocalStorage에 현재 상태 저장
  void _saveToLocalStorage() {
    final localStorage = LocalStorage.instance;
    localStorage.saveLastHomeView(state.currentView.name);
    if (state.currentView == HomeView.groupExplore) {
      localStorage.saveLastGroupExploreTab(state.groupExploreInitialTab);
    }
  }

  /// dispose 시 자동 저장
  @override
  void dispose() {
    saveSnapshot();
    _saveToLocalStorage();
    super.dispose();
  }

  /// Show group explore view
  void showGroupExplore({int initialTab = 0}) {
    state = state.copyWith(
      previousView: state.currentView,
      currentView: HomeView.groupExplore,
      groupExploreInitialTab: initialTab,
    );

    // LocalStorage에 자동 저장
    _saveToLocalStorage();
  }

  /// Show group explore view with recruiting filter enabled
  void showGroupExploreWithRecruitingFilter() {
    // First, navigate to group explore view (List tab)
    state = state.copyWith(
      previousView: state.currentView,
      currentView: HomeView.groupExplore,
      groupExploreInitialTab: 0, // List tab
    );

    // LocalStorage에 자동 저장
    _saveToLocalStorage();

    // Then, activate the recruiting filter
    _ref.read(groupExploreFilterProvider.notifier).toggleRecruiting();
  }

  /// Show dashboard view
  void showDashboard() {
    state = state.copyWith(
      previousView: state.currentView,
      currentView: HomeView.dashboard,
    );

    // LocalStorage에 자동 저장
    _saveToLocalStorage();
  }

  /// 그룹 탐색 탭 변경 (사용자가 탭을 전환할 때 호출)
  void setGroupExploreTab(int tabIndex) {
    if (state.groupExploreInitialTab == tabIndex) return; // 중복 방지

    state = state.copyWith(groupExploreInitialTab: tabIndex);

    // LocalStorage에 즉시 저장
    _saveToLocalStorage();
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
