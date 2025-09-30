import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
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
        color: isSelected ? AppTheme.brandPrimary.withValues(alpha: 0.1) : Colors.transparent,
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
        color: isSelected ? AppTheme.brandPrimary : AppTheme.gray600,
      ),
    );
  }

  Widget _buildExpandedItem(NavigationConfig config, bool isSelected) {
    return Row(
      children: [
        Icon(
          config.icon,
          size: 24,
          color: isSelected ? AppTheme.brandPrimary : AppTheme.gray600,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.title,
                style: AppTheme.titleMedium.copyWith(
                  color: isSelected ? AppTheme.brandPrimary : AppTheme.gray900,
                ),
              ),
              Text(
                config.description,
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
