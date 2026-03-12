import 'navigation_config.dart';

/// 네비게이션 관련 유틸리티 함수 모음
///
/// 중복된 로직을 제거하고 재사용성을 높이기 위한 헬퍼 함수들
class NavigationUtils {
  NavigationUtils._(); // 인스턴스 생성 방지

  /// 현재 라우트에서 NavigationConfig 가져오기
  ///
  /// 예시:
  /// ```dart
  /// final config = NavigationUtils.getConfigFromRoute('/workspace/123');
  /// print(config?.title); // '워크스페이스'
  /// ```
  static NavigationConfig? getConfigFromRoute(String route) {
    return NavigationConfig.fromRoute(route);
  }

  /// 현재 라우트에서 네비게이션 인덱스 가져오기
  ///
  /// Bottom Navigation Bar의 currentIndex 계산에 사용
  ///
  /// 예시:
  /// ```dart
  /// final index = NavigationUtils.getTabIndex('/workspace');
  /// // index = 1
  /// ```
  static int getTabIndex(String route) {
    return NavigationConfig.getIndexFromRoute(route);
  }

  /// 라우트가 선택된 상태인지 확인
  ///
  /// 예시:
  /// ```dart
  /// NavigationUtils.isRouteSelected('/workspace/123', '/workspace') // true
  /// NavigationUtils.isRouteSelected('/home', '/workspace') // false
  /// ```
  static bool isRouteSelected(String currentRoute, String targetRoute) {
    // Home은 정확히 일치해야 선택된 것으로 간주
    if (targetRoute == NavigationConfig.home.route) {
      return currentRoute == targetRoute;
    }
    // 다른 라우트는 시작 경로로 매칭
    return currentRoute.startsWith(targetRoute);
  }

  /// 페이지 제목 가져오기
  ///
  /// 라우트 이름 또는 경로로부터 페이지 제목 반환
  ///
  /// 예시:
  /// ```dart
  /// NavigationUtils.getPageTitle(routeName: 'workspace') // '워크스페이스'
  /// NavigationUtils.getPageTitle(routePath: '/workspace/123') // '워크스페이스'
  /// NavigationUtils.getPageTitle(routeName: 'unknown') // '대학 그룹 관리' (기본값)
  /// ```
  static String getPageTitle({String? routeName, String? routePath}) {
    NavigationConfig? config;

    if (routeName != null) {
      // 특수 케이스 처리
      if (routeName == 'group-workspace' || routeName == 'channel') {
        config = NavigationConfig.workspace;
      } else if (routeName == 'login') {
        return '로그인';
      } else if (routeName == 'profile-setup') {
        return '프로필 설정';
      } else {
        config = NavigationConfig.fromName(routeName);
      }
    } else if (routePath != null) {
      config = NavigationConfig.fromRoute(routePath);
    }

    return config?.title ?? '대학 그룹 관리';
  }

  /// 전체 네비게이션 아이템 리스트
  static List<NavigationConfig> get allItems => NavigationConfig.items;
}
