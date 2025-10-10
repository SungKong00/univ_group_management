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
import '../../../core/models/group_models.dart';
import '../../providers/my_groups_provider.dart';

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
    final navigationController = ref.read(
      navigationControllerProvider.notifier,
    );
    final navigationState = ref.read(navigationControllerProvider);

    if (config.route == AppConstants.workspaceRoute) {
      navigationController.enterWorkspace();

      final workspaceNotifier = ref.read(workspaceStateProvider.notifier);
      final targetGroupId = _resolveLastWorkspaceGroupId(
        navigationState,
        workspaceNotifier.lastGroupId,
      );

      if (targetGroupId != null) {
        workspaceNotifier.clearError();
        NavigationHelper.navigateWithSync(
          context,
          ref,
          '/workspace/$targetGroupId',
        );
        return;
      }

      try {
        ref.read(workspaceStateProvider.notifier).setLoadingState(true);

        final groupsAsync = ref.read(myGroupsProvider);
        final groupService = GroupService();
        GroupMembership? topGroup;

        groupsAsync.whenOrNull(
          data: (groups) {
            topGroup = groupService.getTopLevelGroup(groups);
          },
        );

        topGroup ??= groupService.getTopLevelGroup(
          await groupService.getMyGroups(),
        );

        if (topGroup != null && context.mounted) {
          workspaceNotifier.clearError();
          NavigationHelper.navigateWithSync(
            context,
            ref,
            '/workspace/${topGroup!.id}',
          );
        } else if (context.mounted) {
          workspaceNotifier.setError('소속된 그룹이 없습니다');
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
          ref
              .read(workspaceStateProvider.notifier)
              .setError('워크스페이스를 불러올 수 없습니다');

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

  String? _resolveLastWorkspaceGroupId(
    NavigationState navigationState,
    String? cachedGroupId,
  ) {
    final history = navigationState.tabHistories[NavigationTab.workspace] ?? [];
    if (history.isNotEmpty) {
      final groupId = _parseGroupId(history.last.route);
      if (groupId != null) {
        return groupId;
      }
    }

    if (navigationState.currentTab == NavigationTab.workspace) {
      final groupId = _parseGroupId(navigationState.currentRoute);
      if (groupId != null) {
        return groupId;
      }
    }

    return cachedGroupId;
  }

  String? _parseGroupId(String route) {
    final segments = Uri.parse(route).pathSegments;
    if (segments.length >= 2 && segments.first == 'workspace') {
      return segments[1];
    }
    return null;
  }
}
