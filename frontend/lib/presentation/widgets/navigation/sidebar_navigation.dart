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
          // 상단 여백도 축소/확장 애니메이션
          AnimatedContainer(
            duration: AppConstants.animationDuration,
            curve: Curves.easeInOutCubic,
            height: isCollapsed ? 16 : 24,
          ),
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

    return AnimatedContainer(
      duration: AppConstants.animationDuration,
      curve: Curves.easeInOutCubic,
      margin: EdgeInsets.symmetric(
        horizontal: 12,
        // 접힐 때 아이템 사이 간격 압축, 펼칠 때 여유 있게
        vertical: isCollapsed ? 2 : 8,
      ),
      child: Material(
        color: isSelected ? AppColors.action.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _handleItemTap(context, ref, config),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: AppConstants.animationDuration,
            curve: Curves.easeInOutCubic,
            // 내부 패딩은 탭 영역 확보를 위해 크게 유지
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
    const double iconSize = 24;
    const double gapWidthExpanded = 16;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW = constraints.maxWidth; // 패딩 적용 이후 콘텐츠 영역 폭
        // collapsed 시 아이콘을 가운데 두기 위한 leading spacer 계산
        final double targetLeading = isCollapsed ? (maxW - iconSize) / 2 : 0;
        final double leading = targetLeading.clamp(0, maxW).toDouble();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 아이콘 앞 공간 (좌->중앙 이동 경로) 최소화된 애니메이션
            AnimatedContainer(
              duration: AppConstants.animationDuration,
              curve: Curves.easeInOutCubic,
              width: leading,
            ),
            Icon(
              config.icon,
              size: iconSize,
              color: isSelected ? AppColors.action : AppColors.lightSecondary,
            ),
            // 아이콘-텍스트 간 간격
            AnimatedContainer(
              duration: AppConstants.animationDuration,
              curve: Curves.easeInOutCubic,
              width: isCollapsed ? 0 : gapWidthExpanded,
            ),
            // 텍스트 블록 (폭 + 투명도 애니메이션)
            Expanded(
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: isCollapsed ? 0 : 1,
                  child: AnimatedOpacity(
                    duration: AppConstants.animationDuration,
                    curve: Curves.easeInOutCubic,
                    opacity: isCollapsed ? 0 : 1,
                    child: AnimatedSize(
                      duration: AppConstants.animationDuration,
                      curve: Curves.easeInOutCubic,
                      alignment: Alignment.topLeft,
                      child: isCollapsed
                          ? const SizedBox.shrink()
                          : Column(
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
      },
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
