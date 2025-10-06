import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/navigation_controller.dart';
import '../../../core/navigation/layout_mode.dart';
import '../../providers/page_title_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workspace_state_provider.dart';
import '../common/breadcrumb_widget.dart';
import '../workspace/workspace_header.dart';

class TopNavigation extends ConsumerWidget {
  const TopNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationControllerProvider);
    final currentRoute = GoRouterState.of(context);
    final layoutMode = LayoutModeExtension.fromContext(context);
    final currentUser = ref.watch(currentUserProvider);

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
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                    tooltip: '뒤로가기',
                  )
                : null,
          ),
          // 페이지 헤더 영역 (워크스페이스 vs 일반)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: isWorkspace
                  ? WorkspaceHeader(breadcrumb: breadcrumb)
                  : BreadcrumbWidget(breadcrumb: breadcrumb),
            ),
          ),
          // 모바일 전용: 우측 사용자 아바타
          if (layoutMode == LayoutMode.compact && currentUser != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: _UserAvatarButton(user: currentUser),
            )
          else
            const SizedBox(width: 16),
        ],
      ),
    );
  }

  void _handleBackNavigation(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final isWorkspace = currentRoute.startsWith('/workspace');

    // Workspace navigation handling
    if (isWorkspace) {
      final layoutMode = LayoutModeExtension.fromContext(context);
      final workspaceNotifier = ref.read(workspaceStateProvider.notifier);

      // Web: handle web-specific back navigation
      if (layoutMode.isWide) {
        final handled = workspaceNotifier.handleWebBack();
        if (handled) return; // Internal navigation handled
        // If not handled, continue to normal navigation (go home)
      }
      // Mobile: handle mobile-specific back navigation
      else if (layoutMode.isCompact) {
        final handled = workspaceNotifier.handleMobileBack();
        if (handled) return; // Internal navigation handled
        // If not handled (channelList), continue to normal navigation (go home)
      }
    }

    // Default navigation handling
    final navigationController = ref.read(navigationControllerProvider.notifier);
    final previousRoute = navigationController.goBack();

    if (previousRoute != null) {
      context.go(previousRoute);
    }
  }
}

/// 모바일 전용 사용자 아바타 버튼
/// TODO: 터치 시 사용자 정보 팝업 표시 기능 추가 예정
class _UserAvatarButton extends StatelessWidget {
  final dynamic user;

  const _UserAvatarButton({required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: 사용자 정보 팝업 표시 (아이디, 메일, 학과, 로그아웃 버튼)
        // showDialog 또는 BottomSheet 활용 예정
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brandLight,
          border: Border.all(color: AppColors.brand, width: 1.5),
        ),
        child: Center(
          child: Text(
            _getInitial(user.name ?? ''),
            style: const TextStyle(
              color: AppColors.brand,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _getInitial(String name) {
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }
}
