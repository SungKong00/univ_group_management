import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/navigation_controller.dart';
import '../../../core/navigation/layout_mode.dart';
import '../../providers/page_title_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_state_provider.dart';
import '../../providers/workspace_state_provider.dart';
import '../common/breadcrumb_widget.dart';
import '../workspace/workspace_header.dart';
import '../user/avatar_popup_menu.dart';
import '../dialogs/logout_dialog.dart';

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
      pageBreadcrumbFromPathProvider(
        PageBreadcrumbRequest(routePath: routePath, layoutMode: layoutMode),
      ),
    );

    // 홈 페이지의 경우, 현재 뷰가 그룹 탐색이면 뒤로가기 표시
    final isHome = routePath == '/home';
    final homeView = isHome ? ref.watch(currentHomeViewProvider) : null;

    final canGoBack = isHome
        ? (homeView == HomeView.groupExplore) // 홈: 그룹 탐색일 때만
        : (navigationState.canGoBackInCurrentTab ||
            navigationState.currentTab != NavigationTab.home);

    // 워크스페이스 여부 확인
    final isWorkspace = routePath.startsWith('/workspace');

    // 워크스페이스 상태에서 그룹 역할 가져오기
    final currentGroupRole = isWorkspace
        ? ref.watch(workspaceCurrentGroupRoleProvider)
        : null;

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
                  ? WorkspaceHeader(
                      breadcrumb: breadcrumb,
                      currentGroupRole: currentGroupRole,
                    )
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

    // Home navigation handling (priority)
    if (currentRoute == '/home') {
      final homeNotifier = ref.read(homeStateProvider.notifier);
      final handled = homeNotifier.handleBack();
      if (handled) return; // Internal navigation handled
      // If not handled (dashboard), continue to normal navigation
    }

    // Workspace navigation handling
    if (currentRoute.startsWith('/workspace')) {
      final layoutMode = LayoutModeExtension.fromContext(context);
      final workspaceNotifier = ref.read(workspaceStateProvider.notifier);

      // Web: handle web-specific back navigation
      if (layoutMode.isWide || layoutMode.isMedium) {
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
    final navigationController = ref.read(
      navigationControllerProvider.notifier,
    );
    final previousRoute = navigationController.goBack();

    if (previousRoute != null) {
      context.go(previousRoute);
    }
  }
}

/// 모바일 전용 사용자 아바타 버튼
/// 터치 시 계정 정보 팝업(이름, 이메일, 학과, 로그아웃)을 표시합니다.
class _UserAvatarButton extends ConsumerStatefulWidget {
  final dynamic user;

  const _UserAvatarButton({required this.user});

  @override
  ConsumerState<_UserAvatarButton> createState() => _UserAvatarButtonState();
}

class _UserAvatarButtonState extends ConsumerState<_UserAvatarButton> {
  OverlayEntry? _popupOverlay;
  final LayerLink _layerLink = LayerLink();

  @override
  void dispose() {
    _removePopup();
    super.dispose();
  }

  void _showPopup() {
    if (_popupOverlay != null) return;

    _popupOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 외부 클릭 시 팝업 닫기
          Positioned.fill(
            child: GestureDetector(
              onTap: _removePopup,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          // 팝업 메뉴 (아바타 아래 8px, 우측 정렬)
          Positioned(
            width: 240,
            child: CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, AppSpacing.xxs), // 8px 아래
              child: AvatarPopupMenu(
                user: widget.user,
                onLogout: () {
                  _removePopup();
                  _handleLogout();
                },
                onClose: _removePopup,
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_popupOverlay!);
  }

  void _removePopup() {
    _popupOverlay?.remove();
    _popupOverlay = null;
  }

  Future<void> _handleLogout() async {
    // 확인 다이얼로그
    final confirmed = await showLogoutDialog(context);
    if (!confirmed) return;

    try {
      await ref.read(authProvider.notifier).logout();
      // 로그아웃 성공 시 AuthProvider가 자동으로 로그인 페이지로 리디렉션
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그아웃 실패: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Semantics(
        label: '계정 메뉴',
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showPopup,
            borderRadius: BorderRadius.circular(22), // 44px / 2
            splashColor: AppColors.brand.withValues(alpha: 0.1),
            highlightColor: AppColors.brand.withValues(alpha: 0.05),
            child: Container(
              // 터치 영역 44px 확보
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Container(
                // 시각적 크기는 24px 유지
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandLight,
                  border: Border.all(color: AppColors.brand, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    _getInitial(widget.user.name ?? ''),
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
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
