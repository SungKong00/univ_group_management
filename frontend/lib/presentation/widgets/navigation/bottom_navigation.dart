import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import '../../../core/theme/app_colors.dart';
import '../../../core/navigation/navigation_config.dart';
import '../../../core/navigation/navigation_utils.dart';
import '../../../core/navigation/navigation_controller.dart';
import '../../../core/navigation/back_button_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/group_service.dart';
import '../../providers/workspace_state_provider.dart';

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

  void _onTap(BuildContext context, WidgetRef ref, int index) async {
    final config = NavigationConfig.items[index];
    final navigationController = ref.read(navigationControllerProvider.notifier);

    if (config.route == AppConstants.workspaceRoute) {
      navigationController.enterWorkspace();

      try {
        developer.log('Workspace tab clicked', name: 'BottomNav');

        // Set loading state
        ref.read(workspaceStateProvider.notifier).setLoadingState(true);

        developer.log('Fetching user groups...', name: 'BottomNav');

        // Fetch top-level group and navigate
        final groupService = GroupService();
        final myGroups = await groupService.getMyGroups();

        developer.log('Groups fetched: ${myGroups.length}', name: 'BottomNav');
        final topGroup = groupService.getTopLevelGroup(myGroups);

        if (topGroup != null && context.mounted) {
          developer.log('Navigating to workspace/${topGroup.id}', name: 'BottomNav');
          ref.read(workspaceStateProvider.notifier).clearError();
          context.go('/workspace/${topGroup.id}');
        } else if (context.mounted) {
          developer.log('No groups available', name: 'BottomNav');
          ref.read(workspaceStateProvider.notifier).setError('소속된 그룹이 없습니다');
          NavigationHelper.navigateWithSync(context, ref, config.route);
        }
      } catch (e, stackTrace) {
        developer.log(
          'Error loading workspace: $e',
          name: 'BottomNav',
          error: e,
          stackTrace: stackTrace,
          level: 900,
        );

        if (context.mounted) {
          ref.read(workspaceStateProvider.notifier).setError('워크스페이스를 불러올 수 없습니다');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('워크스페이스를 불러오는 중 오류가 발생했습니다'),
              backgroundColor: AppColors.error,
              action: SnackBarAction(
                label: '다시 시도',
                textColor: Colors.white,
                onPressed: () => _onTap(context, ref, index),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        ref.read(workspaceStateProvider.notifier).setLoadingState(false);
      }
    } else {
      navigationController.exitWorkspace();
      NavigationHelper.navigateWithSync(context, ref, config.route);
    }
  }
}