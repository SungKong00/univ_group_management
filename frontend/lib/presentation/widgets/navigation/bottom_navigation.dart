import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/navigation/navigation_config.dart';
import '../../../core/navigation/navigation_utils.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
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
        onTap: (index) => _onTap(context, index),
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

  void _onTap(BuildContext context, int index) {
    final config = NavigationConfig.items[index];
    context.go(config.route);
  }
}