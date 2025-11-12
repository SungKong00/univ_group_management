import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../services/local_storage.dart';
import 'navigation_config.dart';
import 'layout_mode.dart';

/// 네비게이션 탭 정의
///
/// NavigationConfig와 함께 사용되는 간소화된 탭 식별자
enum NavigationTab {
  home(AppConstants.homeRoute, 'home'),
  workspace(AppConstants.workspaceRoute, 'workspace'),
  calendar(AppConstants.calendarRoute, 'calendar'),
  activity(AppConstants.activityRoute, 'activity'),
  profile(AppConstants.profileRoute, 'profile');

  const NavigationTab(this.route, this.name);

  final String route;
  final String name;

  /// 라우트로부터 네비게이션 탭 결정
  static NavigationTab fromRoute(String route) {
    final config = NavigationConfig.fromRoute(route);
    if (config == null) return NavigationTab.home;

    // NavigationConfig의 route와 매칭되는 NavigationTab 반환
    for (final tab in NavigationTab.values) {
      if (tab.route == config.route) {
        return tab;
      }
    }
    return NavigationTab.home;
  }

  /// 각 탭의 루트 라우트인지 확인
  bool isRootRoute(String route) {
    final config = NavigationConfig.fromRoute(this.route);
    return config?.isRootRoute(route) ?? false;
  }
}

/// 단일 네비게이션 히스토리 항목
class NavigationEntry extends Equatable {
  const NavigationEntry({required this.route, this.context});

  /// 이동한 라우트 경로
  final String route;

  /// 페이지 복원에 필요한 추가 컨텍스트
  final Map<String, dynamic>? context;

  NavigationEntry copyWith({String? route, Map<String, dynamic>? context}) {
    return NavigationEntry(
      route: route ?? this.route,
      context: context ?? this.context,
    );
  }

  @override
  List<Object?> get props => [route, context];
}

/// 통합된 네비게이션 상태
class NavigationState extends Equatable {
  const NavigationState({
    this.currentRoute = AppConstants.homeRoute,
    this.currentTab = NavigationTab.home,
    this.isWorkspaceCollapsed = false,
    this.tabHistories = const {},
    this.layoutMode = LayoutMode.wide,
  });

  /// 현재 라우트
  final String currentRoute;

  /// 현재 활성 탭
  final NavigationTab currentTab;

  /// 워크스페이스 사이드바 축소 상태
  final bool isWorkspaceCollapsed;

  /// 각 탭별 히스토리 스택
  final Map<NavigationTab, List<NavigationEntry>> tabHistories;

  /// 현재 레이아웃 모드 (COMPACT/MEDIUM/WIDE)
  final LayoutMode layoutMode;

  NavigationState copyWith({
    String? currentRoute,
    NavigationTab? currentTab,
    bool? isWorkspaceCollapsed,
    Map<NavigationTab, List<NavigationEntry>>? tabHistories,
    LayoutMode? layoutMode,
  }) {
    return NavigationState(
      currentRoute: currentRoute ?? this.currentRoute,
      currentTab: currentTab ?? this.currentTab,
      isWorkspaceCollapsed: isWorkspaceCollapsed ?? this.isWorkspaceCollapsed,
      tabHistories: tabHistories ?? this.tabHistories,
      layoutMode: layoutMode ?? this.layoutMode,
    );
  }

  /// 현재 탭에서 뒤로가기 가능 여부
  bool get canGoBackInCurrentTab {
    final currentTabHistory = tabHistories[currentTab] ?? [];
    return currentTabHistory.length > 1;
  }

  /// 현재 탭의 루트 페이지인지 확인
  bool get isAtTabRoot {
    return currentTab.isRootRoute(currentRoute);
  }

  /// Check if user has returned to global home (app-level home, not tab-level)
  ///
  /// Returns true when:
  /// - Current tab is HOME
  /// - At the root of HOME tab (no navigation history)
  ///
  /// This is used to determine when to clear workspace snapshots
  /// (user pressed back repeatedly until reaching the global home screen)
  bool get isAtGlobalHome {
    return currentTab == NavigationTab.home && isAtTabRoot;
  }

  /// 사이드바를 강제로 축소해야 하는지 확인
  /// - MEDIUM 모드: 항상 축소
  /// - WIDE 모드 + 워크스페이스: 워크스페이스 상태에 따라 축소
  /// - COMPACT 모드: 사이드바 없음
  bool get shouldCollapseSidebar {
    if (layoutMode == LayoutMode.medium) {
      return true; // 태블릿은 항상 축소
    }
    if (layoutMode == LayoutMode.wide && isWorkspaceCollapsed) {
      return true; // 데스크톱에서 워크스페이스 축소 상태
    }
    return false;
  }

  @override
  List<Object?> get props => [
    currentRoute,
    currentTab,
    isWorkspaceCollapsed,
    tabHistories,
    layoutMode,
  ];
}

/// 통합된 네비게이션 컨트롤러
class NavigationController extends StateNotifier<NavigationState> {
  NavigationController() : super(const NavigationState()) {
    _initializeWithHome();
  }

  /// 홈으로 초기화
  void _initializeWithHome() {
    state = state.copyWith(
      currentRoute: AppConstants.homeRoute,
      currentTab: NavigationTab.home,
      tabHistories: {
        NavigationTab.home: [NavigationEntry(route: AppConstants.homeRoute)],
      },
    );
  }

  /// 저장된 탭 상태 복원
  Future<void> restoreLastTab() async {
    try {
      final lastTabIndex = await LocalStorage.instance.getLastTabIndex();
      if (lastTabIndex != null &&
          lastTabIndex >= 0 &&
          lastTabIndex < NavigationTab.values.length) {
        final tab = NavigationTab.values[lastTabIndex];
        navigateToTabRoot(tab);

        if (kDebugMode) {
          developer.log(
            'Restored last tab: ${tab.name} (index: $lastTabIndex)',
            name: 'NavigationController',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Failed to restore last tab: $e',
          name: 'NavigationController',
          level: 900,
        );
      }
    }
  }

  /// 새로운 라우트로 네비게이션
  void navigateTo(String route, {Map<String, dynamic>? context}) {
    final tab = NavigationTab.fromRoute(route);

    // 탭별 히스토리 업데이트
    final isRootRoute = tab.isRootRoute(route);
    final rootRoute = tab.route;
    final normalizedContext = _normalizeContext(context);
    final newTabHistories = Map<NavigationTab, List<NavigationEntry>>.from(
      state.tabHistories,
    );

    if (isRootRoute) {
      newTabHistories[tab] = [
        NavigationEntry(route: route, context: normalizedContext),
      ];
    } else {
      final currentTabHistory = List<NavigationEntry>.from(
        newTabHistories[tab] ?? [],
      );

      NavigationEntry? existingRoot;
      for (final entry in currentTabHistory) {
        if (tab.isRootRoute(entry.route)) {
          existingRoot = entry;
          break;
        }
      }

      // 루트 라우트를 항상 스택의 시작에 유지
      currentTabHistory.removeWhere((entry) => tab.isRootRoute(entry.route));
      currentTabHistory.insert(
        0,
        existingRoot ?? NavigationEntry(route: rootRoute),
      );

      final newEntry = NavigationEntry(
        route: route,
        context: normalizedContext,
      );

      if (currentTabHistory.isEmpty || currentTabHistory.last.route != route) {
        currentTabHistory.removeWhere((entry) => entry.route == route);
        currentTabHistory.add(newEntry);
      } else {
        currentTabHistory[currentTabHistory.length - 1] = newEntry;
      }

      newTabHistories[tab] = currentTabHistory;
    }

    // 워크스페이스 상태 자동 조정
    final shouldCollapse =
        tab == NavigationTab.workspace && !state.isWorkspaceCollapsed;

    state = state.copyWith(
      currentRoute: route,
      currentTab: tab,
      tabHistories: newTabHistories,
      isWorkspaceCollapsed: shouldCollapse ? true : null,
    );

    // 탭 변경 시 LocalStorage에 저장
    _saveCurrentTabIndex();

    if (kDebugMode) {
      developer.log(
        'Navigated to: $route (tab: ${tab.name})',
        name: 'NavigationController',
      );
    }
  }

  /// 현재 탭 인덱스를 LocalStorage에 저장
  void _saveCurrentTabIndex() {
    final tabIndex = NavigationTab.values.indexOf(state.currentTab);
    LocalStorage.instance.saveLastTabIndex(tabIndex);
  }

  Map<String, dynamic>? _normalizeContext(Map<String, dynamic>? context) {
    if (context == null) {
      return null;
    }
    return Map.unmodifiable(Map<String, dynamic>.from(context));
  }

  /// 탭별 뒤로가기 (탭 루트에서는 홈으로)
  String? goBack() {
    final currentTab = state.currentTab;
    final currentHistory = List<NavigationEntry>.from(
      state.tabHistories[currentTab] ?? const [],
    );

    if (currentHistory.length <= 1) {
      return _handleTabRootExit();
    }

    final newTabHistories = Map<NavigationTab, List<NavigationEntry>>.from(
      state.tabHistories,
    );
    currentHistory.removeLast();

    final previousEntry = currentHistory.last;
    newTabHistories[currentTab] = currentHistory;

    final isAtRootAfterPop =
        currentHistory.length == 1 &&
        currentHistory.last.route == currentTab.route;

    // 워크스페이스의 루트 페이지는 시각적으로 비어 있으므로 홈으로 이동시킨다.
    if (currentTab == NavigationTab.workspace && isAtRootAfterPop) {
      state = state.copyWith(tabHistories: newTabHistories);
      return _handleTabRootExit();
    }

    state = state.copyWith(
      currentRoute: previousEntry.route,
      tabHistories: newTabHistories,
    );

    return previousEntry.route;
  }

  String? _handleTabRootExit() {
    if (state.currentTab != NavigationTab.home) {
      navigateToHome();
      return AppConstants.homeRoute;
    }
    return null;
  }

  /// 홈으로 이동 (다른 탭 히스토리는 유지)
  void navigateToHome() {
    final newTabHistories = Map<NavigationTab, List<NavigationEntry>>.from(
      state.tabHistories,
    );
    newTabHistories[NavigationTab.home] = [
      NavigationEntry(route: AppConstants.homeRoute),
    ];

    state = state.copyWith(
      currentRoute: AppConstants.homeRoute,
      currentTab: NavigationTab.home,
      tabHistories: newTabHistories,
      isWorkspaceCollapsed: false,
    );

    // 탭 변경 시 LocalStorage에 저장
    _saveCurrentTabIndex();

    if (kDebugMode) {
      developer.log('Navigate to home', name: 'NavigationController');
    }
  }

  /// 홈으로 리셋 (전체 히스토리 초기화)
  void resetToHome() {
    _initializeWithHome();

    if (kDebugMode) {
      developer.log('Reset to home', name: 'NavigationController');
    }
  }

  /// 특정 탭의 루트로 이동
  void navigateToTabRoot(NavigationTab tab) {
    navigateTo(tab.route);
  }

  /// 워크스페이스 축소/확장 토글
  void toggleWorkspaceCollapse() {
    state = state.copyWith(isWorkspaceCollapsed: !state.isWorkspaceCollapsed);
  }

  /// 워크스페이스 축소 상태 설정
  void setWorkspaceCollapsed(bool collapsed) {
    state = state.copyWith(isWorkspaceCollapsed: collapsed);
  }

  /// 워크스페이스 진입 시 자동 축소
  void enterWorkspace() {
    state = state.copyWith(isWorkspaceCollapsed: true);
  }

  /// 워크스페이스 벗어날 시 자동 확장
  void exitWorkspace() {
    state = state.copyWith(isWorkspaceCollapsed: false);
  }

  /// 레이아웃 모드 업데이트
  /// 화면 크기 변경 시 MainLayout에서 호출
  void updateLayoutMode(LayoutMode newMode) {
    if (state.layoutMode == newMode) return;

    // MEDIUM 모드로 전환 시: 워크스페이스 상태 무시하고 항상 축소
    // WIDE 모드로 전환 시: 워크스페이스가 아니면 확장
    final shouldUpdateWorkspaceState =
        newMode == LayoutMode.wide &&
        state.currentTab != NavigationTab.workspace;

    state = state.copyWith(
      layoutMode: newMode,
      isWorkspaceCollapsed: shouldUpdateWorkspaceState ? false : null,
    );

    if (kDebugMode) {
      developer.log(
        'Layout mode changed: ${newMode.displayName}',
        name: 'NavigationController',
      );
    }
  }

  /// 디버그용: 현재 상태 출력
  void printDebugInfo() {
    if (!kDebugMode) return;

    developer.log(
      '=== Navigation Debug Info ===',
      name: 'NavigationController',
    );
    developer.log(
      'Current Route: ${state.currentRoute}',
      name: 'NavigationController',
    );
    developer.log(
      'Current Tab: ${state.currentTab.name}',
      name: 'NavigationController',
    );
    developer.log(
      'Can go back in tab: ${state.canGoBackInCurrentTab}',
      name: 'NavigationController',
    );
    developer.log(
      'Is at tab root: ${state.isAtTabRoot}',
      name: 'NavigationController',
    );

    developer.log('Tab Histories:', name: 'NavigationController');
    state.tabHistories.forEach((tab, history) {
      final routes = history.map((entry) => entry.route).toList();
      developer.log('  ${tab.name}: $routes', name: 'NavigationController');
    });
  }
}

/// Provider 정의
final navigationControllerProvider =
    StateNotifierProvider<NavigationController, NavigationState>(
      (ref) => NavigationController(),
    );
