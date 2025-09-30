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

// 기존 ConsumerWidget -> 애니메이션(AnimatedSize 등) 제어 위해 Stateful 로 변경
class SidebarNavigation extends ConsumerStatefulWidget {
  const SidebarNavigation({super.key});

  @override
  ConsumerState<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends ConsumerState<SidebarNavigation> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final navigationState = ref.watch(navigationControllerProvider);
    final isCollapsed = navigationState.shouldCollapseSidebar;
    final currentUser = ref.watch(currentUserProvider);

    return AnimatedContainer(
      duration: AppConstants.animationDuration,
      curve: Curves.easeInOutCubic,
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
          // 네비게이션 아이템들
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
          child: AnimatedContainer(
            duration: AppConstants.animationDuration,
            curve: Curves.easeInOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 8 : 16,
              vertical: 12,
            ),
            child: _buildItemContent(config, isSelected, isCollapsed),
          ),
        ),
      ),
    );
  }

  Widget _buildItemContent(NavigationConfig config, bool isSelected, bool isCollapsed) {
    final icon = Icon(
      config.icon,
      size: 24,
      color: isSelected ? AppColors.action : AppColors.lightSecondary,
    );

    // collapsed 상태에서도 Row 구조 유지 -> 높이/레이아웃 점프 감소
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        icon,
        // 아이콘과 텍스트 사이 간격 애니메이션 (폭 0 -> 16)
        AnimatedContainer(
          duration: AppConstants.animationDuration,
            curve: Curves.easeInOutCubic,
          width: isCollapsed ? 0 : 16,
        ),
        // 텍스트 영역 (collapsed 시 width=0 으로 clip, opacity 페이드)
        Expanded(
          child: ClipRect(
            child: AnimatedSize(
              duration: AppConstants.animationDuration,
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topLeft,
              child: isCollapsed
                  ? const SizedBox.shrink()
                  : AnimatedOpacity(
                      duration: AppConstants.animationDuration,
                      curve: Curves.easeInOutCubic,
                      opacity: 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.title,
                            style: AppTheme.titleMedium.copyWith(
                              color: isSelected ? AppColors.action : AppColors.lightOnSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            config.description,
                            style: AppTheme.bodySmall.copyWith(
                              color: isSelected ? AppColors.action.withValues(alpha: 0.8) : AppColors.lightSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        if (isSelected && !isCollapsed)
          AnimatedOpacity(
            duration: AppConstants.animationDuration,
            opacity: 1,
            child: Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.action,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCollapsedItem(NavigationConfig config, bool isSelected) {
    // 기존 메서드는 호출되지 않음 (구조 단순화). 유지 혹은 추후 제거 가능.
    return Center(
      child: Icon(
        config.icon,
        size: 24,
        color: isSelected ? AppColors.action : AppColors.lightSecondary,
      ),
    );
  }

  Widget _buildExpandedItem(NavigationConfig config, bool isSelected) {
    // 기존 메서드는 호출되지 않음 (구조 단순화). 유지 혹은 추후 제거 가능.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          config.icon,
          size: 24,
          color: isSelected ? AppColors.action : AppColors.lightSecondary,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.title,
                style: AppTheme.titleMedium.copyWith(
                  color: isSelected ? AppColors.action : AppColors.lightOnSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                config.description,
                style: AppTheme.bodySmall.copyWith(
                  color: isSelected ? AppColors.action.withValues(alpha: 0.8) : AppColors.lightSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
