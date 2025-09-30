import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
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
  final Map<NavigationTab, List<String>> tabHistories;

  /// 현재 레이아웃 모드 (COMPACT/MEDIUM/WIDE)
  final LayoutMode layoutMode;

  NavigationState copyWith({
    String? currentRoute,
    NavigationTab? currentTab,
    bool? isWorkspaceCollapsed,
    Map<NavigationTab, List<String>>? tabHistories,
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

  /// 레이아웃 모드 업데이트
  /// 화면 크기 변경 시 MainLayout에서 호출
  void updateLayoutMode(LayoutMode newMode) {
    if (state.layoutMode == newMode) return;

    // MEDIUM 모드로 전환 시: 워크스페이스 상태 무시하고 항상 축소
    // WIDE 모드로 전환 시: 워크스페이스가 아니면 확장
    final shouldUpdateWorkspaceState = newMode == LayoutMode.wide &&
                                       state.currentTab != NavigationTab.workspace;

    state = state.copyWith(
      layoutMode: newMode,
      isWorkspaceCollapsed: shouldUpdateWorkspaceState ? false : null,
    );

    if (kDebugMode) {
      developer.log('Layout mode changed: ${newMode.displayName}', name: 'NavigationController');
    }
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
