import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/navigation_state_provider.dart';
import '../../services/navigation_history_service.dart';

class TopNavigation extends ConsumerWidget {
  const TopNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationStateProvider);
    final currentRoute = GoRouterState.of(context);
    final pageTitle = _getPageTitle(currentRoute.name ?? '');

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
            child: navigationState.canGoBack
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
    final navigationNotifier = ref.read(navigationStateProvider.notifier);
    final previousRoute = navigationNotifier.goBack();

    if (previousRoute != null) {
      // 워크스페이스를 벗어나는 경우 사이드바 확장
      if (NavigationHistoryService.isInWorkspace &&
          !previousRoute.startsWith(AppConstants.workspaceRoute)) {
        navigationNotifier.exitWorkspace();
      }

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
      default:
        return '대학 그룹 관리';
    }
  }
}