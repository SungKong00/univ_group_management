import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import '../../../core/theme/theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/navigation_controller.dart';
import '../../../core/navigation/navigation_config.dart';
import '../../../core/navigation/navigation_utils.dart';
import '../../../core/navigation/back_button_handler.dart';
import '../../../core/services/group_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workspace_state_provider.dart';
import '../user/user_info_card.dart';

// 기존 ConsumerWidget -> 애니메이션(AnimatedSize 등) 제어 위해 Stateful 로 변경
class SidebarNavigation extends ConsumerStatefulWidget {
  const SidebarNavigation({super.key});

  @override
  ConsumerState<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends ConsumerState<SidebarNavigation> with TickerProviderStateMixin {
  late AnimationController _collapseAnim; // 0 = expanded, 1 = collapsed
  bool _targetCollapsed = false;
  bool _firstSyncDone = false;

  @override
  void initState() {
    super.initState();
    _collapseAnim = AnimationController(vsync: this, duration: AppConstants.animationDuration);
  }

  @override
  void dispose() {
    _collapseAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationState = ref.watch(navigationControllerProvider);
    final isCollapsed = navigationState.shouldCollapseSidebar;
    final currentUser = ref.watch(currentUserProvider);

    // 최초 동기화 (애니메이션 없이 상태 맞춤)
    if (!_firstSyncDone) {
      _collapseAnim.value = isCollapsed ? 1.0 : 0.0;
      _targetCollapsed = isCollapsed;
      _firstSyncDone = true;
    } else if (isCollapsed != _targetCollapsed) {
      _targetCollapsed = isCollapsed;
      if (isCollapsed) {
        _collapseAnim.forward();
      } else {
        _collapseAnim.reverse();
      }
    }

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
    const double gapFull = 16;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW = constraints.maxWidth; // 패딩 제외 내부 너비
        final double centerShift = (maxW - iconSize) / 2; // 아이콘이 중앙에 오기 위한 이동량

        return AnimatedBuilder(
          animation: _collapseAnim,
          builder: (context, _) {
            final double t = _collapseAnim.value; // 0 -> 1 (확장 -> 축소)
            // 두 단계 스태거
            const double phaseSplit = 0.55; // 55% 구간까지 텍스트/갭 축소, 이후 아이콘 이동

            // 텍스트/갭 수축 진행도 (0=없음 1=완료)
            final double shrinkProgress = (t <= phaseSplit) ? (t / phaseSplit) : 1.0;
            // 아이콘 이동 진행도 (0=왼쪽 1=중앙)
            final double moveProgress = (t <= phaseSplit) ? 0.0 : ((t - phaseSplit) / (1 - phaseSplit));

            final double currentGap = gapFull * (1 - shrinkProgress); // 16 -> 0
            final double textOpacity = (1 - shrinkProgress).clamp(0, 1); // 1 -> 0
            final double textWidthFactor = (1 - shrinkProgress).clamp(0, 1); // 1 -> 0
            final double iconDx = centerShift * moveProgress; // 0 -> centerShift

            final bool showSelectionBar = isSelected && (textOpacity > 0.05); // 텍스트 거의 사라질 때 제거

            return Stack(
              children: [
                // 아이콘 + 갭 + 텍스트 (확장 상태 전용 레이어)
                Opacity(
                  // 텍스트 숨김 이후(축소 단계 완료)에는 이 레이어 유지하되 텍스트 width 0
                  opacity: 1.0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 실제로 이동되는 아이콘 (Transform)
                      Transform.translate(
                        offset: Offset(iconDx, 0),
                        child: Icon(
                          config.icon,
                          size: iconSize,
                          color: isSelected ? AppColors.action : AppColors.lightSecondary,
                        ),
                      ),
                      SizedBox(width: currentGap),
                      // 텍스트 영역
                      Expanded(
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: textWidthFactor,
                            child: AnimatedOpacity(
                              // 내부 페이드 (부드러운 감쇠)
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOut,
                              opacity: textOpacity,
                              child: (textWidthFactor <= 0)
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
                      if (showSelectionBar)
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.action,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleItemTap(BuildContext context, WidgetRef ref, NavigationConfig config) async {
    final navigationController = ref.read(navigationControllerProvider.notifier);

    if (config.route == AppConstants.workspaceRoute) {
      navigationController.enterWorkspace();

      try {
        developer.log('Workspace tab clicked', name: 'SidebarNav');

        // Set loading state
        ref.read(workspaceStateProvider.notifier).setLoadingState(true);

        developer.log('Fetching user groups...', name: 'SidebarNav');

        // Fetch top-level group and navigate
        final groupService = GroupService();
        final myGroups = await groupService.getMyGroups();

        developer.log('Groups fetched: ${myGroups.length}', name: 'SidebarNav');
        final topGroup = groupService.getTopLevelGroup(myGroups);

        if (topGroup != null && context.mounted) {
          developer.log('Navigating to workspace/${topGroup.id}', name: 'SidebarNav');
          ref.read(workspaceStateProvider.notifier).clearError();
          context.go('/workspace/${topGroup.id}');
        } else if (context.mounted) {
          developer.log('No groups available', name: 'SidebarNav');
          ref.read(workspaceStateProvider.notifier).setError('소속된 그룹이 없습니다');
          NavigationHelper.navigateWithSync(context, ref, config.route);
        }
      } catch (e, stackTrace) {
        developer.log(
          'Error loading workspace: $e',
          name: 'SidebarNav',
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
                onPressed: () => _handleItemTap(context, ref, config),
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
