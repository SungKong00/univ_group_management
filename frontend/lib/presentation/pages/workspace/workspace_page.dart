import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/workspace_state_provider.dart';
import '../../../core/navigation/navigation_controller.dart';

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
        // 채널 네비게이션 바 (좌측)
        if (workspaceState.isInWorkspace)
          _buildChannelSidebar(workspaceState),

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
      return _buildChannelList(workspaceState);
    }
  }

  Widget _buildChannelSidebar(WorkspaceState workspaceState) {
    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.lightOutline, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildGroupHeader(),
          _buildChannelList(workspaceState),
        ],
      ),
    );
  }

  Widget _buildGroupHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '그룹 홈',
            style: AppTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Group ID: ${widget.groupId}',
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelList(WorkspaceState workspaceState) {
    return Expanded(
      child: ListView(
        children: [
          _buildChannelItem('general', '일반', isSelected: workspaceState.selectedChannelId == 'general'),
          _buildChannelItem('announcements', '공지사항', isSelected: workspaceState.selectedChannelId == 'announcements'),
          _buildChannelItem('random', '자유게시판', isSelected: workspaceState.selectedChannelId == 'random'),
        ],
      ),
    );
  }

  Widget _buildChannelItem(String channelId, String name, {bool isSelected = false}) {
    return ListTile(
      leading: const Icon(Icons.tag),
      title: Text(name),
      selected: isSelected,
      onTap: () {
        ref.read(workspaceStateProvider.notifier).selectChannel(channelId);
      },
    );
  }

  Widget _buildMainContent(WorkspaceState workspaceState) {
    if (!workspaceState.isInWorkspace) {
      return _buildEmptyState();
    }

    if (!workspaceState.hasSelectedChannel) {
      return _buildNoChannelSelected();
    }

    return _buildChannelView(workspaceState);
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
