import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

/// 네비게이션 항목 정의
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
    if (route.startsWith(AppConstants.workspaceRoute)) {
      return NavigationTab.workspace;
    } else if (route.startsWith(AppConstants.calendarRoute)) {
      return NavigationTab.calendar;
    } else if (route.startsWith(AppConstants.activityRoute)) {
      return NavigationTab.activity;
    } else if (route.startsWith(AppConstants.profileRoute)) {
      return NavigationTab.profile;
    }
    return NavigationTab.home;
  }

  /// 각 탭의 루트 라우트인지 확인
  bool isRootRoute(String route) {
    switch (this) {
      case NavigationTab.home:
        return route == AppConstants.homeRoute;
      case NavigationTab.workspace:
        return route == AppConstants.workspaceRoute;
      case NavigationTab.calendar:
        return route == AppConstants.calendarRoute;
      case NavigationTab.activity:
        return route == AppConstants.activityRoute;
      case NavigationTab.profile:
        return route == AppConstants.profileRoute;
    }
  }
}


/// 통합된 네비게이션 상태
class NavigationState extends Equatable {
  const NavigationState({
    this.currentRoute = AppConstants.homeRoute,
    this.currentTab = NavigationTab.home,
    this.isWorkspaceCollapsed = false,
    this.tabHistories = const {},
  });

  /// 현재 라우트
  final String currentRoute;

  /// 현재 활성 탭
  final NavigationTab currentTab;

  /// 워크스페이스 사이드바 축소 상태
  final bool isWorkspaceCollapsed;

  /// 각 탭별 히스토리 스택
  final Map<NavigationTab, List<String>> tabHistories;

  NavigationState copyWith({
    String? currentRoute,
    NavigationTab? currentTab,
    bool? isWorkspaceCollapsed,
    Map<NavigationTab, List<String>>? tabHistories,
  }) {
    return NavigationState(
      currentRoute: currentRoute ?? this.currentRoute,
      currentTab: currentTab ?? this.currentTab,
      isWorkspaceCollapsed: isWorkspaceCollapsed ?? this.isWorkspaceCollapsed,
      tabHistories: tabHistories ?? this.tabHistories,
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

  @override
  List<Object?> get props => [
        currentRoute,
        currentTab,
        isWorkspaceCollapsed,
        tabHistories,
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
        NavigationTab.home: [AppConstants.homeRoute],
      },
    );
  }

  /// 새로운 라우트로 네비게이션
  void navigateTo(String route, {Map<String, dynamic>? context}) {
    final tab = NavigationTab.fromRoute(route);

    // 탭별 히스토리 업데이트
    final newTabHistories = Map<NavigationTab, List<String>>.from(state.tabHistories);
    final isRootRoute = tab.isRootRoute(route);
    final rootRoute = tab.route;

    if (isRootRoute) {
      newTabHistories[tab] = [route];
    } else {
      final currentTabHistory = List<String>.from(newTabHistories[tab] ?? []);

      // 루트 라우트를 항상 스택의 시작에 유지
      currentTabHistory.removeWhere(tab.isRootRoute);
      currentTabHistory.insert(0, rootRoute);

      if (currentTabHistory.last != route) {
        currentTabHistory.remove(route);
        currentTabHistory.add(route);
      }

      newTabHistories[tab] = currentTabHistory;
    }

    // 워크스페이스 상태 자동 조정
    final shouldCollapse = tab == NavigationTab.workspace && !state.isWorkspaceCollapsed;

    state = state.copyWith(
      currentRoute: route,
      currentTab: tab,
      tabHistories: newTabHistories,
      isWorkspaceCollapsed: shouldCollapse ? true : null,
    );

    if (kDebugMode) {
      developer.log('Navigated to: $route (tab: ${tab.name})', name: 'NavigationController');
    }
  }

  /// 탭별 뒤로가기 (탭 루트에서는 홈으로)
  String? goBack() {
    // 1. 현재 탭에서 뒤로가기 가능한 경우
    if (state.canGoBackInCurrentTab) {
      return _goBackInCurrentTab();
    }

    // 2. 탭 루트에 있고 홈이 아닌 경우 홈으로 이동
    if (state.currentTab != NavigationTab.home) {
      navigateToHome();
      return AppConstants.homeRoute;
    }

    // 3. 이미 홈에 있으면 뒤로갈 수 없음
    return null;
  }

  /// 현재 탭 내에서 뒤로가기
  String? _goBackInCurrentTab() {
    final newTabHistories = Map<NavigationTab, List<String>>.from(state.tabHistories);
    final currentTabHistory = List<String>.from(newTabHistories[state.currentTab] ?? []);

    if (currentTabHistory.length > 1) {
      currentTabHistory.removeLast();
      newTabHistories[state.currentTab] = currentTabHistory;

      final previousRoute = currentTabHistory.last;

      state = state.copyWith(
        currentRoute: previousRoute,
        tabHistories: newTabHistories,
      );

      return previousRoute;
    }

    return null;
  }


  /// 홈으로 이동 (다른 탭 히스토리는 유지)
  void navigateToHome() {
    final newTabHistories = Map<NavigationTab, List<String>>.from(state.tabHistories);
    newTabHistories[NavigationTab.home] = [AppConstants.homeRoute];

    state = state.copyWith(
      currentRoute: AppConstants.homeRoute,
      currentTab: NavigationTab.home,
      tabHistories: newTabHistories,
      isWorkspaceCollapsed: false,
    );

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
    state = state.copyWith(
      isWorkspaceCollapsed: !state.isWorkspaceCollapsed,
    );
  }

  /// 워크스페이스 축소 상태 설정
  void setWorkspaceCollapsed(bool collapsed) {
    state = state.copyWith(
      isWorkspaceCollapsed: collapsed,
    );
  }

  /// 워크스페이스 진입 시 자동 축소
  void enterWorkspace() {
    state = state.copyWith(
      isWorkspaceCollapsed: true,
    );
  }

  /// 워크스페이스 벗어날 시 자동 확장
  void exitWorkspace() {
    state = state.copyWith(
      isWorkspaceCollapsed: false,
    );
  }

  /// 디버그용: 현재 상태 출력
  void printDebugInfo() {
    if (!kDebugMode) return;

    developer.log('=== Navigation Debug Info ===', name: 'NavigationController');
    developer.log('Current Route: ${state.currentRoute}', name: 'NavigationController');
    developer.log('Current Tab: ${state.currentTab.name}', name: 'NavigationController');
    developer.log('Can go back in tab: ${state.canGoBackInCurrentTab}', name: 'NavigationController');
    developer.log('Is at tab root: ${state.isAtTabRoot}', name: 'NavigationController');


    developer.log('Tab Histories:', name: 'NavigationController');
    state.tabHistories.forEach((tab, history) {
      developer.log('  ${tab.name}: $history', name: 'NavigationController');
    });
  }
}

/// Provider 정의
final navigationControllerProvider = StateNotifierProvider<NavigationController, NavigationState>(
  (ref) => NavigationController(),
);
