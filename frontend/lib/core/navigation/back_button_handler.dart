import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'navigation_controller.dart';

/// 스마트 뒤로가기를 처리하는 위젯
class BackButtonHandler extends ConsumerWidget {
  final Widget child;

  const BackButtonHandler({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false, // 기본 뒤로가기 동작을 비활성화
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final handled = await _handleBackButton(context, ref);
        if (!handled) {
          // 앱 종료 확인 다이얼로그 표시
          if (context.mounted) {
            _showExitConfirmDialog(context);
          }
        }
      },
      child: child,
    );
  }

  /// 뒤로가기 버튼 처리
  /// 성공적으로 뒤로가기를 처리했으면 true, 더 이상 뒤로갈 수 없으면 false 반환
  Future<bool> _handleBackButton(BuildContext context, WidgetRef ref) async {
    final navigationController = ref.read(navigationControllerProvider.notifier);
    final navigationState = ref.read(navigationControllerProvider);

    if (kDebugMode) {
      developer.log(
        'Back button pressed - Current: ${navigationState.currentRoute}, Tab: ${navigationState.currentTab.name}',
        name: 'BackButtonHandler',
      );
      navigationController.printDebugInfo();
    }

    // NavigationController의 스마트 뒤로가기 로직 사용
    final targetRoute = navigationController.goBack();

    if (targetRoute != null && targetRoute != navigationState.currentRoute) {
      // Go Router로 실제 네비게이션 수행
      if (context.mounted) {
        context.go(targetRoute);

        if (kDebugMode) {
          developer.log(
            'Smart back navigation: ${navigationState.currentRoute} → $targetRoute',
            name: 'BackButtonHandler',
          );
        }
      }
      return true;
    }

    // 더 이상 뒤로갈 수 없음
    return false;
  }

  /// 앱 종료 확인 다이얼로그
  void _showExitConfirmDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 종료'),
        content: const Text('앱을 종료하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              // 시스템 뒤로가기 수행 (앱 종료)
              _exitApp(context);
            },
            child: const Text('종료'),
          ),
        ],
      ),
    );
  }

  /// 앱 종료 처리
  void _exitApp(BuildContext context) {
    // Android의 경우 시스템 뒤로가기로 앱 종료
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // 웹이나 기타 플랫폼에서는 창 닫기
      // 실제 구현은 플랫폼에 따라 다를 수 있음
      if (kDebugMode) {
        developer.log('App exit requested', name: 'BackButtonHandler');
      }
    }
  }
}

/// 네비게이션 관련 헬퍼 함수들
class NavigationHelper {
  /// Go Router를 통한 안전한 네비게이션
  static void safePush(BuildContext context, String route, {Object? extra}) {
    if (context.mounted) {
      context.push(route, extra: extra);
    }
  }

  /// Go Router를 통한 안전한 대체 네비게이션
  static void safeGo(BuildContext context, String route, {Object? extra}) {
    if (context.mounted) {
      context.go(route, extra: extra);
    }
  }

  /// NavigationController와 Go Router를 동기화하여 네비게이션
  static void navigateWithSync(
    BuildContext context,
    WidgetRef ref,
    String route, {
    Map<String, dynamic>? navigationContext,
    Object? routerExtra,
  }) {
    // NavigationController 업데이트
    final navigationController = ref.read(navigationControllerProvider.notifier);
    navigationController.navigateTo(route);

    // Go Router로 실제 네비게이션
    safeGo(context, route, extra: routerExtra);

    if (kDebugMode) {
      developer.log(
        'Synchronized navigation to: $route',
        name: 'NavigationHelper',
      );
    }
  }

  /// 홈으로 안전하게 이동
  static void goHome(BuildContext context, WidgetRef ref) {
    final navigationController = ref.read(navigationControllerProvider.notifier);
    navigationController.navigateToHome();
    safeGo(context, '/home');
  }

  /// 특정 탭의 루트로 이동
  static void goToTabRoot(BuildContext context, WidgetRef ref, NavigationTab tab) {
    final navigationController = ref.read(navigationControllerProvider.notifier);
    navigationController.navigateToTabRoot(tab);
    safeGo(context, tab.route);
  }

  /// 워크스페이스로 이동 (자동 탭 변경 포함)
  static void goToWorkspace(
    BuildContext context,
    WidgetRef ref,
    String groupId, {
    String? channelId,
  }) {
    final route = channelId != null
        ? '/workspace/$groupId/channel/$channelId'
        : '/workspace/$groupId';

    navigateWithSync(
      context,
      ref,
      route,
    );
  }
}