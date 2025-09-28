import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

class NavigationEntry extends Equatable {
  const NavigationEntry(this.route, [this.context]);

  final String route;
  final Map<String, dynamic>? context;

  @override
  List<Object?> get props => [route, context];
}

class NavigationHistoryService {
  static final List<NavigationEntry> _history = [
    const NavigationEntry(AppConstants.homeRoute)
  ];

  static List<NavigationEntry> get history => List.unmodifiable(_history);

  /// 새로운 라우트를 히스토리에 추가
  static void pushRoute(String route, [Map<String, dynamic>? context]) {
    // 연속으로 같은 페이지로 이동하는 경우 중복 방지
    if (_history.isEmpty || _history.last.route != route) {
      _history.add(NavigationEntry(route, context));
    }
  }

  /// 뒤로가기: 히스토리 스택에서 이전 페이지로 이동
  /// 최종 도착지는 항상 홈
  static NavigationEntry? goBack() {
    if (_history.length > 1) {
      _history.removeLast();
      return _history.last;
    }

    // 더 이상 뒤로갈 수 없으면 홈으로 초기화
    resetToHome();
    return const NavigationEntry(AppConstants.homeRoute);
  }

  /// 홈으로 이동 시 히스토리 초기화
  static void resetToHome() {
    _history.clear();
    _history.add(const NavigationEntry(AppConstants.homeRoute));
  }

  /// 현재 뒤로가기 가능 여부
  static bool get canGoBack => _history.length > 1;

  /// 현재 라우트
  static String get currentRoute =>
      _history.isEmpty ? AppConstants.homeRoute : _history.last.route;

  /// 특정 라우트로 직접 이동 (새로고침, 북마크 등)
  static void replaceRoute(String route, [Map<String, dynamic>? context]) {
    if (_history.isNotEmpty) {
      _history.removeLast();
    }
    _history.add(NavigationEntry(route, context));
  }

  /// 히스토리에서 특정 라우트까지 되돌아가기
  static NavigationEntry? popUntilRoute(String targetRoute) {
    while (_history.length > 1 && _history.last.route != targetRoute) {
      _history.removeLast();
    }

    if (_history.isNotEmpty && _history.last.route == targetRoute) {
      return _history.last;
    }

    // 찾지 못하면 홈으로
    resetToHome();
    return const NavigationEntry(AppConstants.homeRoute);
  }

  /// 워크스페이스 관련 라우트 확인
  static bool get isInWorkspace =>
      currentRoute.startsWith(AppConstants.workspaceRoute);

  /// 디버그용: 현재 히스토리 출력
  static void printHistory() {
    print('Navigation History:');
    for (int i = 0; i < _history.length; i++) {
      final entry = _history[i];
      final marker = i == _history.length - 1 ? '-> ' : '   ';
      print('$marker$i: ${entry.route}');
    }
  }

  /// 히스토리 클리어 (테스트용)
  static void clear() {
    _history.clear();
    _history.add(const NavigationEntry(AppConstants.homeRoute));
  }
}