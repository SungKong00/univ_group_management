import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// 통합 네비게이션 설정
///
/// 모든 네비게이션 관련 정보를 중앙에서 관리하여 중복을 제거하고
/// 유지보수성을 향상시킵니다.
///
/// Usage:
/// ```dart
/// // 전체 네비게이션 아이템 가져오기
/// final items = NavigationConfig.items;
///
/// // 특정 라우트로부터 설정 찾기
/// final config = NavigationConfig.fromRoute('/workspace');
/// print(config?.title); // '워크스페이스'
/// ```
class NavigationConfig {
  const NavigationConfig({
    required this.route,
    required this.name,
    required this.title,
    required this.description,
    required this.icon,
    required this.activeIcon,
  });

  /// 라우트 경로 (예: '/home')
  final String route;

  /// 라우트 이름 (예: 'home')
  final String name;

  /// 화면에 표시될 제목 (예: '홈')
  final String title;

  /// 네비게이션 아이템 설명
  final String description;

  /// 비활성 상태 아이콘
  final IconData icon;

  /// 활성 상태 아이콘
  final IconData activeIcon;

  // ===== 네비게이션 아이템 정의 =====

  static const home = NavigationConfig(
    route: AppConstants.homeRoute,
    name: 'home',
    title: '홈',
    description: '그룹 탐색 및 활동',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
  );

  static const workspace = NavigationConfig(
    route: AppConstants.workspaceRoute,
    name: 'workspace',
    title: '워크스페이스',
    description: '그룹 소통 공간',
    icon: Icons.workspaces_outlined,
    activeIcon: Icons.workspaces,
  );

  static const calendar = NavigationConfig(
    route: AppConstants.calendarRoute,
    name: 'calendar',
    title: '캘린더',
    description: '일정 관리',
    icon: Icons.calendar_today_outlined,
    activeIcon: Icons.calendar_today,
  );

  static const activity = NavigationConfig(
    route: AppConstants.activityRoute,
    name: 'activity',
    title: '나의 활동',
    description: '내 참여 기록',
    icon: Icons.history_outlined,
    activeIcon: Icons.history,
  );

  static const profile = NavigationConfig(
    route: AppConstants.profileRoute,
    name: 'profile',
    title: '프로필',
    description: '계정 설정',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
  );

  // ===== 전체 아이템 리스트 =====

  /// 모든 네비게이션 아이템을 순서대로 반환
  static const List<NavigationConfig> items = [
    home,
    workspace,
    calendar,
    activity,
    profile,
  ];

  // ===== 헬퍼 메서드 =====

  /// 라우트 경로로부터 NavigationConfig 찾기
  ///
  /// 예시:
  /// ```dart
  /// NavigationConfig.fromRoute('/workspace') // workspace config
  /// NavigationConfig.fromRoute('/workspace/123') // workspace config (하위 경로도 매칭)
  /// NavigationConfig.fromRoute('/unknown') // null
  /// ```
  static NavigationConfig? fromRoute(String route) {
    for (final item in items) {
      if (route.startsWith(item.route)) {
        return item;
      }
    }
    return null;
  }

  /// 라우트 이름으로부터 NavigationConfig 찾기
  ///
  /// 예시:
  /// ```dart
  /// NavigationConfig.fromName('home') // home config
  /// NavigationConfig.fromName('unknown') // null
  /// ```
  static NavigationConfig? fromName(String name) {
    try {
      return items.firstWhere((item) => item.name == name);
    } catch (_) {
      return null;
    }
  }

  /// 현재 라우트에서 네비게이션 인덱스 계산
  ///
  /// 예시:
  /// ```dart
  /// NavigationConfig.getIndexFromRoute('/home') // 0
  /// NavigationConfig.getIndexFromRoute('/workspace/123') // 1
  /// NavigationConfig.getIndexFromRoute('/unknown') // 0 (기본값: home)
  /// ```
  static int getIndexFromRoute(String route) {
    for (int i = 0; i < items.length; i++) {
      if (route.startsWith(items[i].route)) {
        return i;
      }
    }
    return 0; // 기본값: home
  }

  /// 두 라우트가 동일한 네비게이션 아이템에 속하는지 확인
  ///
  /// 예시:
  /// ```dart
  /// NavigationConfig.isSameNavigation('/workspace', '/workspace/123') // true
  /// NavigationConfig.isSameNavigation('/home', '/workspace') // false
  /// ```
  static bool isSameNavigation(String route1, String route2) {
    final config1 = fromRoute(route1);
    final config2 = fromRoute(route2);
    return config1 != null && config1 == config2;
  }

  /// 특정 라우트가 해당 네비게이션의 루트 경로인지 확인
  ///
  /// 예시:
  /// ```dart
  /// NavigationConfig.home.isRootRoute('/home') // true
  /// NavigationConfig.workspace.isRootRoute('/workspace') // true
  /// NavigationConfig.workspace.isRootRoute('/workspace/123') // false
  /// ```
  bool isRootRoute(String route) {
    return route == this.route;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationConfig &&
          runtimeType == other.runtimeType &&
          route == other.route &&
          name == other.name;

  @override
  int get hashCode => route.hashCode ^ name.hashCode;
}