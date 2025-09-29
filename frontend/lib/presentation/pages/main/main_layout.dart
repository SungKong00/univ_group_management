import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../widgets/navigation/sidebar_navigation.dart';
import '../../widgets/navigation/bottom_navigation.dart';
import '../../widgets/navigation/top_navigation.dart';
import '../../../core/navigation/navigation_controller.dart';
import '../../../core/navigation/router_listener.dart';
import '../../../core/navigation/back_button_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final navigationState = ref.watch(navigationControllerProvider);

    // 라우트 리스너 활성화
    ref.watch(routeListenerProvider);

    // 반응형 전환 감지 및 상태 동기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleResponsiveTransition(ref, isDesktop, navigationState);
    });

    return RouterListener(
      child: BackButtonHandler(
        child: Scaffold(
          backgroundColor: AppTheme.background,
          body: Column(
            children: [
              const TopNavigation(),
              Expanded(
                child: isDesktop
                    ? _buildDesktopLayout(navigationState)
                    : _buildMobileLayout(),
              ),
            ],
          ),
          bottomNavigationBar: isDesktop ? null : const BottomNavigation(),
        ),
      ),
    );
  }

  void _handleResponsiveTransition(
    WidgetRef ref,
    bool isDesktop,
    NavigationState navigationState,
  ) {
    final navigationController = ref.read(navigationControllerProvider.notifier);

    // 모바일 → 웹 전환 시: 워크스페이스에 있으면 사이드바 축소 유지
    if (isDesktop && navigationState.currentRoute.startsWith(AppConstants.workspaceRoute)) {
      if (!navigationState.isWorkspaceCollapsed) {
        navigationController.enterWorkspace();
      }
    }

    // 웹 → 모바일 전환 시: 별도 처리 없음 (모바일은 하단 네비게이션 사용)
  }

  Widget _buildDesktopLayout(NavigationState navigationState) {
    return Row(
      children: [
        const SidebarNavigation(),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              border: navigationState.isWorkspaceCollapsed
                  ? null
                  : const Border(
                      left: BorderSide(color: AppTheme.gray200, width: 1),
                    ),
            ),
            child: ClipRect(child: child),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      color: AppTheme.background,
      child: child,
    );
  }
}