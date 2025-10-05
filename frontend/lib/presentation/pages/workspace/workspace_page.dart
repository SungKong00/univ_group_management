import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/channel_models.dart';
import '../../providers/workspace_state_provider.dart';
import '../../providers/my_groups_provider.dart';
import '../../../core/navigation/navigation_controller.dart';
import '../../widgets/workspace/channel_navigation.dart';
import '../../widgets/workspace/mobile_channel_list.dart';
import '../../widgets/workspace/mobile_channel_posts_view.dart';
import '../../widgets/workspace/mobile_post_comments_view.dart';
import '../../widgets/post/post_list.dart';
import '../../widgets/post/post_composer.dart';
import '../../widgets/comment/comment_list.dart';
import '../../widgets/comment/comment_composer.dart';
import '../../../core/services/post_service.dart';
import '../../../core/services/comment_service.dart';

class WorkspacePage extends ConsumerStatefulWidget {
  final String? groupId;
  final String? channelId;

  const WorkspacePage({super.key, this.groupId, this.channelId});

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage> {
  int _postListKey = 0;
  int _commentListKey = 0;
  bool _previousIsMobile = false;

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

  @override
  void didUpdateWidget(WorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // groupId가 변경되면 워크스페이스 재초기화
    if (widget.groupId != oldWidget.groupId && widget.groupId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeWorkspace();
      });
    }
  }

  void _initializeWorkspace() {
    final workspaceNotifier = ref.read(workspaceStateProvider.notifier);
    final navigationController = ref.read(
      navigationControllerProvider.notifier,
    );

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

    return LayoutBuilder(
      builder: (context, constraints) {
        // 문서 스펙: TABLET(451px) 이상을 데스크톱 레이아웃으로 간주
        // largerThan(MOBILE) = 451px 이상 = TABLET, DESKTOP, 4K
        final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
        final isMobile = !isDesktop;

        // 반응형 전환 감지 및 상태 보존
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleResponsiveTransition(isMobile);
        });

        // 모바일에서 뒤로가기 핸들링 추가
        return PopScope(
          canPop: !isMobile || !_canHandleMobileBack(),
          onPopInvoked: (didPop) {
            if (!didPop && isMobile) {
              _handleMobileBackPress();
            }
          },
          child: Container(
            color: AppColors.lightBackground,
            child: isDesktop
                ? _buildDesktopWorkspace(workspaceState)
                : _buildMobileWorkspace(workspaceState),
          ),
        );
      },
    );
  }

  /// 반응형 전환 핸들러: 웹 ↔ 모바일 전환 시 상태 보존
  void _handleResponsiveTransition(bool isMobile) {
    // 전환이 발생했는지 확인
    if (_previousIsMobile != isMobile) {
      final workspaceNotifier = ref.read(workspaceStateProvider.notifier);

      if (isMobile) {
        // 웹 → 모바일 전환
        workspaceNotifier.handleWebToMobileTransition();
      } else {
        // 모바일 → 웹 전환
        workspaceNotifier.handleMobileToWebTransition();
      }

      _previousIsMobile = isMobile;
    }
  }

  /// 모바일 뒤로가기 가능 여부 확인
  bool _canHandleMobileBack() {
    final workspaceState = ref.read(workspaceStateProvider);
    // channelList 상태에서는 뒤로가기를 허용 (홈으로 이동)
    // 나머지 상태에서는 내부적으로 처리
    return workspaceState.mobileView != MobileWorkspaceView.channelList;
  }

  /// 모바일 뒤로가기 처리
  void _handleMobileBackPress() {
    final workspaceNotifier = ref.read(workspaceStateProvider.notifier);
    // handleMobileBack()이 true를 반환하면 내부적으로 처리됨
    // false를 반환하면 시스템 뒤로가기 허용
    workspaceNotifier.handleMobileBack();
  }

  Widget _buildDesktopWorkspace(WorkspaceState workspaceState) {
    final bool showChannelNavigation = workspaceState.isInWorkspace;
    final bool showComments = workspaceState.isCommentsVisible;

    return LayoutBuilder(
      builder: (context, _) {
        final double leftInset = showChannelNavigation
            ? AppConstants.sidebarWidth
            : 0;
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
                child: Consumer(
                  builder: (context, ref, _) {
                    // 그룹 정보 가져오기
                    final groupsAsync = ref.watch(myGroupsProvider);
                    final currentGroupName = groupsAsync.maybeWhen(
                      data: (groups) {
                        final currentGroup = groups.firstWhere(
                          (g) =>
                              g.id.toString() == workspaceState.selectedGroupId,
                          orElse: () => groups.first,
                        );
                        return currentGroup.name;
                      },
                      orElse: () => null,
                    );

                    return ChannelNavigation(
                      channels: workspaceState.channels,
                      selectedChannelId: workspaceState.selectedChannelId,
                      hasAnyGroupPermission:
                          workspaceState.hasAnyGroupPermission,
                      unreadCounts: workspaceState.unreadCounts,
                      isVisible: true,
                      currentGroupId: workspaceState.selectedGroupId,
                      currentGroupName: currentGroupName,
                    );
                  },
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
    // 1. 로딩 상태 체크
    if (workspaceState.isLoadingWorkspace) {
      return _buildLoadingState();
    }

    // 2. 에러 상태 체크
    if (workspaceState.errorMessage != null) {
      return _buildErrorState(workspaceState.errorMessage!);
    }

    // 3. 워크스페이스 미진입 체크
    if (!workspaceState.isInWorkspace) {
      return _buildEmptyState();
    }

    // 4. 모바일 3단계 플로우에 따른 뷰 전환
    switch (workspaceState.mobileView) {
      case MobileWorkspaceView.channelList:
        // Step 1: 채널 목록
        return _buildMobileChannelList(workspaceState);

      case MobileWorkspaceView.channelPosts:
        // Step 2: 선택된 채널의 게시글 목록
        if (workspaceState.selectedChannelId == null) {
          // 채널이 선택되지 않았다면 채널 목록으로 폴백
          return _buildMobileChannelList(workspaceState);
        }
        return MobileChannelPostsView(
          channelId: workspaceState.selectedChannelId!,
          groupId: workspaceState.selectedGroupId!,
          permissions: workspaceState.channelPermissions,
        );

      case MobileWorkspaceView.postComments:
        // Step 3: 선택된 게시글의 댓글
        if (workspaceState.selectedPostId == null ||
            workspaceState.selectedChannelId == null) {
          // 게시글이나 채널이 선택되지 않았다면 게시글 목록으로 폴백
          if (workspaceState.selectedChannelId != null) {
            return MobileChannelPostsView(
              channelId: workspaceState.selectedChannelId!,
              groupId: workspaceState.selectedGroupId!,
              permissions: workspaceState.channelPermissions,
            );
          }
          return _buildMobileChannelList(workspaceState);
        }
        return MobilePostCommentsView(
          postId: workspaceState.selectedPostId!,
          channelId: workspaceState.selectedChannelId!,
          groupId: workspaceState.selectedGroupId!,
          permissions: workspaceState.channelPermissions,
        );
    }
  }

  Widget _buildMobileChannelList(WorkspaceState workspaceState) {
    return Consumer(
      builder: (context, ref, _) {
        // 그룹 정보 가져오기
        final groupsAsync = ref.watch(myGroupsProvider);
        final currentGroupName = groupsAsync.maybeWhen(
          data: (groups) {
            final currentGroup = groups.firstWhere(
              (g) => g.id.toString() == workspaceState.selectedGroupId,
              orElse: () => groups.first,
            );
            return currentGroup.name;
          },
          orElse: () => null,
        );

        return MobileChannelList(
          channels: workspaceState.channels,
          selectedChannelId: workspaceState.selectedChannelId,
          hasAnyGroupPermission: workspaceState.hasAnyGroupPermission,
          unreadCounts: workspaceState.unreadCounts,
          currentGroupId: workspaceState.selectedGroupId,
          currentGroupName: currentGroupName,
        );
      },
    );
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
    // 선택된 채널 찾기
    Channel? selectedChannel;
    try {
      selectedChannel = workspaceState.channels.firstWhere(
        (channel) => channel.id.toString() == workspaceState.selectedChannelId,
      );
    } catch (e) {
      selectedChannel = null;
    }

    // 채널을 찾지 못한 경우 fallback
    final channelName = selectedChannel?.name ?? '채널을 불러올 수 없습니다';
    final channelPermissions = workspaceState.channelPermissions;
    final canWritePost = channelPermissions?.canWritePost ?? false;

    // 권한이 없는 경우 권한 에러 표시
    if (channelPermissions != null && !channelPermissions.canViewChannel) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: AppColors.neutral400,
              ),
              const SizedBox(height: 16),
              Text(
                '이 채널을 볼 권한이 없습니다',
                style: AppTheme.headlineMedium.copyWith(
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '권한 관리자에게 문의하세요',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(channelName, style: AppTheme.headlineMedium),
          const SizedBox(height: 16),
          Expanded(
            child: PostList(
              key: ValueKey('post_list_${workspaceState.selectedChannelId}_$_postListKey'),
              channelId: workspaceState.selectedChannelId!,
              canWrite: canWritePost,
              onTapComment: (postId) {
                ref.read(workspaceStateProvider.notifier).showComments(postId.toString());
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Consumer(
      builder: (context, ref, child) {
        final workspaceState = ref.watch(workspaceStateProvider);
        final channelPermissions = workspaceState.channelPermissions;
        final isLoadingPermissions = workspaceState.isLoadingPermissions;

        // Determine if user can write posts
        final canWritePost = channelPermissions?.canWritePost ?? false;
        final canUploadFile = channelPermissions?.canUploadFile ?? false;

        return PostComposer(
          canWrite: canWritePost,
          canUploadFile: canUploadFile,
          isLoading: isLoadingPermissions,
          onSubmit: (content) => _handleSubmitPost(context, ref, content),
        );
      },
    );
  }

  Future<void> _handleSubmitPost(
    BuildContext context,
    WidgetRef ref,
    String content,
  ) async {
    final workspaceState = ref.read(workspaceStateProvider);
    final channelId = workspaceState.selectedChannelId;

    if (channelId == null) {
      throw Exception('채널을 선택해주세요');
    }

    final postService = PostService();
    await postService.createPost(channelId, content);

    // 게시글 작성 성공 후 목록 새로고침
    setState(() {
      _postListKey++;
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('게시글이 작성되었습니다'),
           duration: Duration(milliseconds: 500),
         ),
       );
     }
  }

  Future<void> _handleSubmitComment(
    BuildContext context,
    WidgetRef ref,
    String content,
  ) async {
    final workspaceState = ref.read(workspaceStateProvider);
    final postIdStr = workspaceState.selectedPostId;

    if (postIdStr == null) {
      throw Exception('게시글을 선택해주세요');
    }

    final postId = int.parse(postIdStr);
    final commentService = CommentService();
    await commentService.createComment(postId, content);

    // 댓글 작성 성공 후 목록 새로고침
    setState(() {
      _commentListKey++;
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('댓글이 작성되었습니다'),
          duration: Duration(milliseconds: 500),
        ),
      );
    }
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
    final postIdStr = workspaceState.selectedPostId;
    final postId = postIdStr != null ? int.tryParse(postIdStr) : null;
    final canWrite = workspaceState.channelPermissions?.canWriteComment ?? false;

    return Column(
      children: [
        // 댓글 헤더
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.neutral200, width: 1),
            ),
          ),
          child: Row(
            children: [
              Text('댓글', style: AppTheme.titleLarge),
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
        // 댓글 목록
        if (postId != null)
          Expanded(
            child: CommentList(
              key: ValueKey('comment_list_${postId}_$_commentListKey'),
              postId: postId,
            ),
          )
        else
          Expanded(
            child: Center(
              child: Text(
                '게시글을 선택해주세요',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ),
          ),
        // 댓글 입력창
        if (postId != null)
          CommentComposer(
            canWrite: canWrite,
            isLoading: workspaceState.channelPermissions == null,
            onSubmit: (content) => _handleSubmitComment(context, ref, content),
          ),
      ],
    );
  }

  Widget _buildGroupHomeView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.home_outlined, size: 64, color: AppColors.brand),
          const SizedBox(height: 16),
          Text('그룹 홈', style: AppTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            '그룹 홈 (준비 중)',
            style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral600),
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
          Text('캘린더', style: AppTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            '캘린더 (준비 중)',
            style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral600),
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
              style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral700),
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
                style: AppTheme.titleMedium.copyWith(color: Colors.white),
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
          const Icon(Icons.tag, size: 48, color: AppColors.brand),
          const SizedBox(height: 16),
          Text('채널을 선택하세요', style: AppTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '좌측에서 참여할 채널을 선택해주세요',
            style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral600),
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
            style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral700),
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
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
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
              style: AppTheme.bodyMedium.copyWith(color: AppColors.neutral600),
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
                    style: AppTheme.titleMedium.copyWith(color: Colors.white),
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
