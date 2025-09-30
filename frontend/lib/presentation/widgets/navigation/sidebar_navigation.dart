import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/navigation_controller.dart';
import '../../../core/navigation/navigation_config.dart';
import '../../../core/navigation/navigation_utils.dart';
import '../../../core/navigation/back_button_handler.dart';
import '../../providers/auth_provider.dart';
import '../user/user_info_card.dart';

class SidebarNavigation extends ConsumerWidget {
  const SidebarNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationControllerProvider);
    // 레이아웃 모드와 워크스페이스 상태를 모두 고려한 축소 여부
    final isCollapsed = navigationState.shouldCollapseSidebar;
    final currentUser = ref.watch(currentUserProvider);

    return AnimatedContainer(
      duration: AppConstants.animationDuration,
      width: isCollapsed ? AppConstants.sidebarCollapsedWidth : AppConstants.sidebarWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.lightOutline, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          ...NavigationConfig.items.map((config) => _buildNavigationItem(
                context,
                ref,
                config,
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
    NavigationConfig config,
    bool isCollapsed,
  ) {
    final currentLocation = GoRouterState.of(context).uri.path;
    final isSelected = NavigationUtils.isRouteSelected(currentLocation, config.route);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected ? AppColors.action.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _handleItemTap(context, ref, config),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 8 : 16,
              vertical: 12,
            ),
            child: isCollapsed
                ? _buildCollapsedItem(config, isSelected)
                : _buildExpandedItem(config, isSelected),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedItem(NavigationConfig config, bool isSelected) {
    return Center(
      child: Icon(
        config.icon,
        size: 24,
        color: isSelected ? AppColors.action : AppColors.lightSecondary,
      ),
    );
  }

  Widget _buildExpandedItem(NavigationConfig config, bool isSelected) {
    return Row(
      children: [
        Icon(
          config.icon,
          size: 24,
          color: isSelected ? AppColors.action : AppColors.lightSecondary,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.title,
                style: AppTheme.titleMedium.copyWith(
                  color: isSelected ? AppColors.action : AppColors.lightOnSurface,
                ),
              ),
              Text(
                config.description,
                style: AppTheme.bodySmall.copyWith(
                  color: isSelected ? AppColors.action.withValues(alpha: 0.8) : AppColors.lightSecondary,
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
              color: AppColors.action,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  void _handleItemTap(BuildContext context, WidgetRef ref, NavigationConfig config) {
    final navigationController = ref.read(navigationControllerProvider.notifier);

    if (config.route == AppConstants.workspaceRoute) {
      navigationController.enterWorkspace();
    } else {
      navigationController.exitWorkspace();
    }

    NavigationHelper.navigateWithSync(
      context,
      ref,
      config.route,
    );
  }
}
