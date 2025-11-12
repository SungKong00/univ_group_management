import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'navigation_controller.dart';
import '../../presentation/providers/workspace_state_provider.dart';

/// Go Router와 NavigationController 동기화를 위한 리스너
class RouterListener extends ConsumerStatefulWidget {
  final Widget child;

  const RouterListener({super.key, required this.child});

  @override
  ConsumerState<RouterListener> createState() => _RouterListenerState();
}

class _RouterListenerState extends ConsumerState<RouterListener> {
  String? _previousRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleRouteChange();
  }

  void _handleRouteChange() {
    final currentRoute = GoRouterState.of(context).uri.path;

    // 라우트가 실제로 변경된 경우에만 처리
    if (_previousRoute != currentRoute) {
      _previousRoute = currentRoute;

      // NavigationController에 라우트 변경 알림
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncNavigationState(currentRoute);
        }
      });
    }
  }

  void _syncNavigationState(String route) {
    final navigationController = ref.read(
      navigationControllerProvider.notifier,
    );
    final currentState = ref.read(navigationControllerProvider);

    // 현재 NavigationController의 라우트와 다른 경우에만 업데이트
    if (currentState.currentRoute != route) {
      // 라우트 변경을 NavigationController에 반영
      navigationController.navigateTo(route);

      if (kDebugMode) {
        developer.log(
          'Route sync: $route → ${NavigationTab.fromRoute(route).name}',
          name: 'RouterListener',
        );
      }
    }

    // 워크스페이스 관련 자동 상태 조정
    _handleWorkspaceStateTransition(route, navigationController);
  }

  void _handleWorkspaceStateTransition(
    String route,
    NavigationController navigationController,
  ) {
    final isWorkspaceRoute = route.startsWith('/workspace');
    final previousRoute = _previousRoute;

    // 워크스페이스 진입 시 자동 축소
    if (isWorkspaceRoute) {
      final currentState = ref.read(navigationControllerProvider);
      if (!currentState.isWorkspaceCollapsed) {
        navigationController.enterWorkspace();
      }
    }
    // 워크스페이스 벗어날 시 자동 확장 및 읽음 위치 저장
    else if (previousRoute != null && previousRoute.startsWith('/workspace')) {
      // ✅ FIX: 이전 라우트가 워크스페이스였다면 무조건 exitWorkspace() 호출
      // (사이드바 상태와 관계없이 읽음 위치 저장 필요)
      ref.read(workspaceStateProvider.notifier).exitWorkspace();
      navigationController.exitWorkspace();

      if (kDebugMode) {
        developer.log(
          '🔄 Workspace exit: $previousRoute → $route',
          name: 'RouterListener',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Go Router의 라우트 변경을 감지하는 Provider
final routeListenerProvider = Provider<void>((ref) {
  // NavigationController 상태를 감시하여 디버그 정보 출력
  ref.listen<NavigationState>(navigationControllerProvider, (previous, next) {
    if (kDebugMode && previous?.currentRoute != next.currentRoute) {
      developer.log(
        'Navigation State Changed: ${previous?.currentRoute} → ${next.currentRoute}',
        name: 'RouteListener',
      );
    }
  });
});

/// 라우트 정보를 제공하는 Provider
final currentRouteProvider = Provider<String>((ref) {
  // RouterDelegate에서 현재 라우트 감지
  return ref.watch(navigationControllerProvider).currentRoute;
});

/// 현재 네비게이션 탭을 제공하는 Provider
final currentTabProvider = Provider<NavigationTab>((ref) {
  return ref.watch(navigationControllerProvider).currentTab;
});

/// 뒤로가기 가능 여부를 제공하는 Provider
final canGoBackProvider = Provider<bool>((ref) {
  final state = ref.watch(navigationControllerProvider);
  return state.canGoBackInCurrentTab;
});

/// 워크스페이스 축소 상태를 제공하는 Provider
final isWorkspaceCollapsedProvider = Provider<bool>((ref) {
  return ref.watch(navigationControllerProvider).isWorkspaceCollapsed;
});
