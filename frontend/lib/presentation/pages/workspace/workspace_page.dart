import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/workspace_state_provider.dart';
import '../../../core/navigation/navigation_controller.dart';
import '../../widgets/workspace/channel_navigation.dart';

class WorkspacePage extends ConsumerStatefulWidget {
  final String? groupId;
  final String? channelId;

  const WorkspacePage({
    super.key,
    this.groupId,
    this.channelId,
  });

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage> {
  @override
  void initState() {
    super.initState();

    // 워크스페이스 진입 시 상태 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.groupId != null) {
        _initializeWorkspace();
      }
    });
  }

  void _initializeWorkspace() {
    final workspaceNotifier = ref.read(workspaceStateProvider.notifier);
    final navigationController = ref.read(navigationControllerProvider.notifier);

    // 워크스페이스 상태 설정
    workspaceNotifier.enterWorkspace(
      widget.groupId!,
      channelId: widget.channelId,
    );

    // 워크스페이스 진입 시 사이드바를 즉시 축소
    navigationController.enterWorkspace();
  }

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceStateProvider);
    // 문서 스펙: TABLET(451px) 이상을 데스크톱 레이아웃으로 간주
    // largerThan(MOBILE) = 451px 이상 = TABLET, DESKTOP, 4K
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Container(
      color: AppColors.lightBackground,
      child: isDesktop
          ? _buildDesktopWorkspace(workspaceState)
          : _buildMobileWorkspace(workspaceState),
    );
  }

  Widget _buildDesktopWorkspace(WorkspaceState workspaceState) {
    final bool showChannelNavigation = workspaceState.isInWorkspace;
    final bool showComments = workspaceState.isCommentsVisible;

    return LayoutBuilder(
      builder: (context, _) {
        final double leftInset = showChannelNavigation ? AppConstants.sidebarWidth : 0;
        final double rightInset = showComments ? _commentsSidebarWidth : 0;

        return Stack(
          children: [
            // 메인 콘텐츠 영역은 좌측 채널 바와 우측 댓글 바 폭만큼 여백을 둔다.
            Positioned.fill(
              left: leftInset,
              right: rightInset,
              child: _buildMainContent(workspaceState),
            ),

            if (showChannelNavigation)
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: ChannelNavigation(
                  channels: workspaceState.channels,
                  selectedChannelId: workspaceState.selectedChannelId,
                  hasAnyGroupPermission: workspaceState.hasAnyGroupPermission,
                  unreadCounts: workspaceState.unreadCounts,
                  isVisible: true,
                ),
              ),

            if (showComments)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: _buildCommentsSidebar(workspaceState),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMobileWorkspace(WorkspaceState workspaceState) {
    // 모바일에서는 단계별 전체 화면 전환
    if (workspaceState.isViewingComments) {
      return _buildCommentsView(workspaceState);
    } else if (workspaceState.hasSelectedChannel) {
      return _buildChannelView(workspaceState);
    } else {
      // Show channel list with navigation
      return Center(
        child: Text(
          '모바일 채널 목록 (준비 중)',
          style: AppTheme.bodyLarge.copyWith(
            color: AppColors.neutral600,
          ),
        ),
      );
    }
  }


  Widget _buildMainContent(WorkspaceState workspaceState) {
    // Show loading state
    if (workspaceState.isLoadingWorkspace) {
      return _buildLoadingState();
    }

    // Show error state
    if (workspaceState.errorMessage != null) {
      return _buildErrorState(workspaceState.errorMessage!);
    }

    if (!workspaceState.isInWorkspace) {
      return _buildEmptyState();
    }

    // Switch view based on currentView
    switch (workspaceState.currentView) {
      case WorkspaceView.groupHome:
        return _buildGroupHomeView();
      case WorkspaceView.calendar:
        return _buildCalendarView();
      case WorkspaceView.channel:
        if (!workspaceState.hasSelectedChannel) {
          return _buildNoChannelSelected();
        }
        return _buildChannelView(workspaceState);
    }
  }

  Widget _buildChannelView(WorkspaceState workspaceState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '채널: ${workspaceState.selectedChannelId}',
            style: AppTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Text(
                '게시글 목록이 여기에 표시됩니다',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: '메시지를 입력하세요...',
                border: InputBorder.none,
              ),
              maxLines: null,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  static const double _commentsSidebarWidth = 300;

  Widget _buildCommentsSidebar(WorkspaceState workspaceState) {
    return Container(
      width: _commentsSidebarWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: AppColors.lightOutline, width: 1),
        ),
      ),
      child: _buildCommentsView(workspaceState),
    );
  }

  Widget _buildCommentsView(WorkspaceState workspaceState) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '댓글',
                style: AppTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  ref.read(workspaceStateProvider.notifier).hideComments();
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              '댓글이 여기에 표시됩니다',
              style: AppTheme.bodyLarge.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupHomeView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.home_outlined,
            size: 64,
            color: AppColors.brand,
          ),
          const SizedBox(height: 16),
          Text(
            '그룹 홈',
            style: AppTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            '그룹 홈 (준비 중)',
            style: AppTheme.bodyLarge.copyWith(
              color: AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: AppColors.brand,
          ),
          const SizedBox(height: 16),
          Text(
            '캘린더',
            style: AppTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            '캘린더 (준비 중)',
            style: AppTheme.bodyLarge.copyWith(
              color: AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add_outlined,
              size: 64,
              color: AppColors.neutral600,
            ),
            const SizedBox(height: 24),
            Text(
              '소속된 그룹이 없습니다',
              style: AppTheme.displaySmall.copyWith(
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '홈에서 그룹을 탐색하고 가입해보세요',
              style: AppTheme.bodyLarge.copyWith(
                color: AppColors.neutral700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go(AppConstants.homeRoute),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.action,
                foregroundColor: Colors.white,
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '그룹 탐색하기',
                style: AppTheme.titleMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoChannelSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.tag,
            size: 48,
            color: AppColors.brand,
          ),
          const SizedBox(height: 16),
          Text(
            '채널을 선택하세요',
            style: AppTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '좌측에서 참여할 채널을 선택해주세요',
            style: AppTheme.bodyLarge.copyWith(
              color: AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.brand),
          ),
          const SizedBox(height: 24),
          Text(
            '워크스페이스를 불러오는 중...',
            style: AppTheme.bodyLarge.copyWith(
              color: AppColors.neutral700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 24),
            Text(
              errorMessage,
              style: AppTheme.displaySmall.copyWith(
                color: AppColors.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '문제가 지속되면 관리자에게 문의하세요',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _retryLoadWorkspace(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.action,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '다시 시도',
                    style: AppTheme.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => context.go(AppConstants.homeRoute),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.action,
                    side: const BorderSide(color: AppColors.action),
                    minimumSize: const Size(120, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '홈으로',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppColors.action,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _retryLoadWorkspace() {
    // Clear error and try again
    ref.read(workspaceStateProvider.notifier).clearError();

    // If we have a groupId, re-initialize workspace
    if (widget.groupId != null) {
      _initializeWorkspace();
    } else {
      // Otherwise, just trigger workspace navigation again
      // by navigating back and forth (simulating a fresh workspace tab click)
      context.go(AppConstants.homeRoute);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          context.go(AppConstants.workspaceRoute);
        }
      });
    }
  }
}
