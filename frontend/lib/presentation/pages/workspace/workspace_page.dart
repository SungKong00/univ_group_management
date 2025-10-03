import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
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
    return Row(
      children: [
        // 채널 네비게이션 바 (좌측) - with slide animation
        if (workspaceState.isInWorkspace)
          ChannelNavigation(
            channels: workspaceState.channels,
            selectedChannelId: workspaceState.selectedChannelId,
            hasAnyGroupPermission: workspaceState.hasAnyGroupPermission,
            unreadCounts: workspaceState.unreadCounts,
            isVisible: true,
          ),

        // 메인 콘텐츠 영역
        Expanded(
          child: _buildMainContent(workspaceState),
        ),

        // 댓글 사이드바 (우측)
        if (workspaceState.isCommentsVisible)
          _buildCommentsSidebar(workspaceState),
      ],
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

  Widget _buildCommentsSidebar(WorkspaceState workspaceState) {
    return Container(
      width: 300,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.workspaces_outlined,
            size: 64,
            color: AppColors.brand,
          ),
          const SizedBox(height: 16),
          Text(
            '워크스페이스',
            style: AppTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            '그룹을 선택하여 워크스페이스에 참여하세요',
            style: AppTheme.bodyLarge.copyWith(
              color: AppColors.neutral600,
            ),
          ),
        ],
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
}
