import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/navigation_controller.dart';
import '../../providers/page_title_provider.dart';
import '../common/breadcrumb_widget.dart';
import '../workspace/workspace_header.dart';

class TopNavigation extends ConsumerWidget {
  const TopNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationControllerProvider);
    final currentRoute = GoRouterState.of(context);

    // 경로(path)를 기반으로 브레드크럼 가져오기
    final routePath = currentRoute.uri.path;

    final breadcrumb = ref.watch(
      pageBreadcrumbFromPathProvider(routePath),
    );

    final canGoBack = navigationState.canGoBackInCurrentTab ||
        navigationState.currentTab != NavigationTab.home;

    // 워크스페이스 여부 확인
    final isWorkspace = routePath.startsWith('/workspace');

    return Container(
      height: AppConstants.topNavigationHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.lightOutline, width: 1),
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
          // 페이지 헤더 영역 (워크스페이스 vs 일반)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: isWorkspace
                  ? WorkspaceHeader(breadcrumb: breadcrumb)
                  : BreadcrumbWidget(breadcrumb: breadcrumb),
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
}
