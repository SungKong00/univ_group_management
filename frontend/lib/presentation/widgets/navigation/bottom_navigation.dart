import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/navigation/navigation_config.dart';
import '../../../core/navigation/navigation_utils.dart';
import '../../../core/navigation/navigation_controller.dart';
import '../../../core/navigation/back_button_handler.dart';
import '../../../core/constants/app_constants.dart';

class BottomNavigation extends ConsumerWidget {
  const BottomNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouterState.of(context).uri.path;
    final currentIndex = NavigationUtils.getTabIndex(currentLocation);

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.lightOutline, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.brand,
        unselectedItemColor: AppColors.neutral600,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        onTap: (index) => _onTap(context, ref, index),
        items: NavigationConfig.items
            .map(
              (config) => BottomNavigationBarItem(
                icon: Icon(config.icon),
                activeIcon: Icon(config.activeIcon),
                label: config.title,
              ),
            )
            .toList(),
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    final config = NavigationConfig.items[index];
    final navigationController = ref.read(navigationControllerProvider.notifier);

    // 워크스페이스 상태 관리
    if (config.route == AppConstants.workspaceRoute) {
      navigationController.enterWorkspace();
    } else {
      navigationController.exitWorkspace();
    }

    // 네비게이션 동기화
    NavigationHelper.navigateWithSync(context, ref, config.route);
  }
}