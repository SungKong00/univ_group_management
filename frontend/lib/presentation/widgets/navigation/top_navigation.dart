import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/navigation_controller.dart';

class TopNavigation extends ConsumerWidget {
  const TopNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationControllerProvider);
    final currentRoute = GoRouterState.of(context);
    final pageTitle = _getPageTitle(currentRoute.name ?? '');
    final canGoBack = navigationState.canGoBackInCurrentTab ||
        navigationState.currentTab != NavigationTab.home;

    return Container(
      height: AppConstants.topNavigationHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.gray200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 뒤로가기 버튼 영역 (항상 표시, 사이드바 축소 시 너비와 정렬)
          SizedBox(
            width: navigationState.isWorkspaceCollapsed
                ? AppConstants.sidebarCollapsedWidth
                : AppConstants.backButtonWidth,
            child: canGoBack
                ? IconButton(
                    onPressed: () => _handleBackNavigation(context, ref),
                    icon: const Icon(Icons.arrow_back),
                    iconSize: 24,
                    tooltip: '뒤로가기',
                  )
                : null,
          ),
          // 페이지 제목 영역
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                pageTitle,
                style: AppTheme.headlineMedium,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  void _handleBackNavigation(BuildContext context, WidgetRef ref) {
    final navigationController = ref.read(navigationControllerProvider.notifier);
    final previousRoute = navigationController.goBack();

    if (previousRoute != null) {
      context.go(previousRoute);
    }
  }

  String _getPageTitle(String routeName) {
    switch (routeName) {
      case 'home':
        return '홈';
      case 'workspace':
      case 'group-workspace':
      case 'channel':
        return '워크스페이스';
      case 'calendar':
        return '캘린더';
      case 'activity':
        return '나의 활동';
      case 'profile':
        return '프로필';
      case 'login':
        return '로그인';
      case 'profile-setup':
        return '프로필 설정';
      default:
        return '대학 그룹 관리';
    }
  }
}
