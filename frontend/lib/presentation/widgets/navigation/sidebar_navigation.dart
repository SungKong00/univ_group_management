import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/navigation_controller.dart';
import '../../../core/navigation/back_button_handler.dart';
import '../../providers/auth_provider.dart';
import '../user/user_info_card.dart';

class SidebarNavigation extends ConsumerWidget {
  const SidebarNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationControllerProvider);
    final isCollapsed = navigationState.isWorkspaceCollapsed;
    final currentUser = ref.watch(currentUserProvider);

    return AnimatedContainer(
      duration: AppConstants.animationDuration,
      width: isCollapsed ? AppConstants.sidebarCollapsedWidth : AppConstants.sidebarWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppTheme.gray200, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          ...NavigationItem.values.map((item) => _buildNavigationItem(
                context,
                ref,
                item,
                isCollapsed,
              )),
          const Spacer(),
          if (currentUser != null)
            UserInfoCard(
              user: currentUser,
              isCompact: isCollapsed,
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    WidgetRef ref,
    NavigationItem item,
    bool isCollapsed,
  ) {
    final currentLocation = GoRouterState.of(context).uri.path;
    final isSelected = _isRouteSelected(currentLocation, item.route);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected ? AppTheme.brandPrimary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _handleItemTap(context, ref, item),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 8 : 16,
              vertical: 12,
            ),
            child: isCollapsed
                ? _buildCollapsedItem(item, isSelected)
                : _buildExpandedItem(item, isSelected),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedItem(NavigationItem item, bool isSelected) {
    return Center(
      child: Icon(
        item.icon,
        size: 24,
        color: isSelected ? AppTheme.brandPrimary : AppTheme.gray600,
      ),
    );
  }

  Widget _buildExpandedItem(NavigationItem item, bool isSelected) {
    return Row(
      children: [
        Icon(
          item.icon,
          size: 24,
          color: isSelected ? AppTheme.brandPrimary : AppTheme.gray600,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: AppTheme.titleMedium.copyWith(
                  color: isSelected ? AppTheme.brandPrimary : AppTheme.gray900,
                ),
              ),
              Text(
                item.description,
                style: AppTheme.bodySmall.copyWith(
                  color: isSelected ? AppTheme.brandPrimary.withValues(alpha: 0.8) : AppTheme.gray600,
                ),
              ),
            ],
          ),
        ),
        if (isSelected)
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.brandPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  void _handleItemTap(BuildContext context, WidgetRef ref, NavigationItem item) {
    final navigationController = ref.read(navigationControllerProvider.notifier);

    if (item.route == AppConstants.workspaceRoute) {
      navigationController.enterWorkspace();
    } else {
      navigationController.exitWorkspace();
    }

    NavigationHelper.navigateWithSync(
      context,
      ref,
      item.route,
    );
  }

  bool _isRouteSelected(String currentPath, String itemRoute) {
    if (itemRoute == AppConstants.homeRoute) {
      return currentPath == AppConstants.homeRoute;
    }
    return currentPath.startsWith(itemRoute);
  }
}

enum NavigationItem {
  home(
    title: '홈',
    description: '그룹 탐색 및 활동',
    icon: Icons.home_outlined,
    route: AppConstants.homeRoute,
  ),
  workspace(
    title: '워크스페이스',
    description: '그룹 소통 공간',
    icon: Icons.workspaces_outlined,
    route: AppConstants.workspaceRoute,
  ),
  calendar(
    title: '캘린더',
    description: '일정 관리',
    icon: Icons.calendar_today_outlined,
    route: AppConstants.calendarRoute,
  ),
  activity(
    title: '나의 활동',
    description: '내 참여 기록',
    icon: Icons.history_outlined,
    route: AppConstants.activityRoute,
  ),
  profile(
    title: '프로필',
    description: '계정 설정',
    icon: Icons.person_outline,
    route: AppConstants.profileRoute,
  );

  const NavigationItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
  });

  final String title;
  final String description;
  final IconData icon;
  final String route;
}
