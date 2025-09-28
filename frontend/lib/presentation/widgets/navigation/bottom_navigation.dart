import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;
    final currentIndex = _getCurrentIndex(currentLocation);

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.gray200, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.brandPrimary,
        unselectedItemColor: AppTheme.gray600,
        backgroundColor: Colors.white,
        elevation: 0,
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.workspaces_outlined),
            activeIcon: Icon(Icons.workspaces),
            label: '워크스페이스',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: '캘린더',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: '활동',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }

  int _getCurrentIndex(String currentPath) {
    if (currentPath.startsWith(AppConstants.workspaceRoute)) return 1;
    if (currentPath.startsWith(AppConstants.calendarRoute)) return 2;
    if (currentPath.startsWith(AppConstants.activityRoute)) return 3;
    if (currentPath.startsWith(AppConstants.profileRoute)) return 4;
    return 0; // home
  }

  void _onTap(BuildContext context, int index) {
    final routes = [
      AppConstants.homeRoute,
      AppConstants.workspaceRoute,
      AppConstants.calendarRoute,
      AppConstants.activityRoute,
      AppConstants.profileRoute,
    ];

    context.go(routes[index]);
  }
}