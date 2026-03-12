import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/navigation/sidebar_navigation.dart';
import '../../widgets/navigation/bottom_navigation.dart';
import '../../widgets/navigation/top_navigation.dart';
import '../../../core/navigation/navigation_controller.dart';
import '../../../core/navigation/router_listener.dart';
import '../../../core/navigation/back_button_handler.dart';
import '../../../core/navigation/layout_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/auth_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workspace_state_provider.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 첫 빌드 후 상태 복원
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _initializeState();
    });
  }

  /// 앱 시작 시 저장된 상태 복원
  Future<void> _initializeState() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 탭 복원
    final navigationController = ref.read(
      navigationControllerProvider.notifier,
    );
    await navigationController.restoreLastTab();

    if (!mounted) {
      return;
    }

    // 워크스페이스 상태 복원 (워크스페이스 탭인 경우에만)
    final navigationState = ref.read(navigationControllerProvider);
    if (navigationState.currentTab == NavigationTab.workspace) {
      final workspaceNotifier = ref.read(workspaceStateProvider.notifier);
      await workspaceNotifier.restoreFromLocalStorage();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기로부터 레이아웃 모드 계산
    final layoutMode = LayoutModeExtension.fromContext(context);
    final navigationState = ref.watch(navigationControllerProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    // 라우트 리스너 활성화
    ref.watch(routeListenerProvider);

    // 레이아웃 모드 전환 감지 및 상태 동기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _handleLayoutModeTransition(layoutMode);
    });

    return RouterListener(
      child: BackButtonHandler(
        child: Scaffold(
          backgroundColor: AppColors.lightBackground,
          body: Column(
            children: [
              const TopNavigation(),
              Expanded(child: _buildLayoutForMode(layoutMode, navigationState)),
            ],
          ),
          bottomNavigationBar: layoutMode.usesBottomNavigation
              ? _buildMobileBottomSection(currentUser)
              : null,
        ),
      ),
    );
  }

  /// 레이아웃 모드 전환 처리
  void _handleLayoutModeTransition(LayoutMode newMode) {
    final navigationController = ref.read(
      navigationControllerProvider.notifier,
    );
    navigationController.updateLayoutMode(newMode);
  }

  /// 레이아웃 모드에 따른 레이아웃 빌드
  Widget _buildLayoutForMode(LayoutMode mode, NavigationState navigationState) {
    switch (mode) {
      case LayoutMode.compact:
        return _buildCompactLayout();
      case LayoutMode.medium:
      case LayoutMode.wide:
        return _buildSidebarLayout(navigationState);
    }
  }

  /// COMPACT 모드: 모바일 레이아웃 (하단 네비게이션)
  Widget _buildCompactLayout() {
    return Container(color: AppColors.lightBackground, child: widget.child);
  }

  /// MEDIUM/WIDE 모드: 사이드바 레이아웃
  Widget _buildSidebarLayout(NavigationState navigationState) {
    return Row(
      children: [
        const SidebarNavigation(),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              border: navigationState.shouldCollapseSidebar
                  ? null
                  : const Border(
                      left: BorderSide(color: AppColors.lightOutline, width: 1),
                    ),
            ),
            child: ClipRect(child: widget.child),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileBottomSection(UserInfo? currentUser) {
    // 모바일에서는 하단에 네비게이션만 표시 (사용자 정보는 상단바로 이동)
    return const SizedBox(
      height: kBottomNavigationBarHeight,
      child: BottomNavigation(),
    );
  }
}
