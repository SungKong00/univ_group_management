import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

import '../../providers/workspace_state_provider.dart';
import '../../providers/current_group_provider.dart';
import '../../../core/navigation/navigation_controller.dart';
import '../../../core/navigation/layout_mode.dart';

import '../../widgets/workspace/mobile_channel_list.dart';
import '../../widgets/workspace/mobile_channel_posts_view.dart';
import '../../widgets/workspace/mobile_post_comments_view.dart';

import '../../widgets/comment/comment_list.dart';
import '../../widgets/comment/comment_composer.dart';

import '../../utils/responsive_layout_helper.dart';
import 'widgets/workspace_empty_state.dart';
import 'widgets/workspace_state_view.dart';
import 'widgets/desktop_workspace_layout.dart';
import 'widgets/channel_content_view.dart';
import 'widgets/post_preview_widget.dart';
import 'widgets/group_home_view.dart';
import 'providers/post_preview_notifier.dart';
import 'providers/post_actions_provider.dart';
import 'providers/comment_actions_provider.dart';
import '../group/group_admin_page.dart';
import '../member_management/member_management_page.dart';
import '../recruitment_management/recruitment_management_page.dart';
import 'calendar/group_calendar_page.dart';

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
  bool _previousIsNarrowDesktop = false; // Narrow desktop 상태 추적
  bool _hasResponsiveLayoutInitialized = false;
  late final WorkspaceStateNotifier _workspaceNotifier;
  late final NavigationController _navigationController;

  // 스크롤 위치 보존을 위한 ScrollController (선택사항)
  final ScrollController _postScrollController = ScrollController();
  final ScrollController _commentScrollController = ScrollController();

  // 중복 로드 방지용 이전 게시글 ID
  String? _previousSelectedPostId;

  @override
  void initState() {
    super.initState();
    _workspaceNotifier = ref.read(workspaceStateProvider.notifier);
    _navigationController = ref.read(
      navigationControllerProvider.notifier,
    );

    // 워크스페이스 진입 시 상태 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (widget.groupId != null) {
        _initializeWorkspace();
      }
    });
  }

  @override
  void didUpdateWidget(WorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // groupId 변경 감지 및 상태 관리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (widget.groupId != oldWidget.groupId) {
        // groupId가 변경된 경우
        if (widget.groupId != null) {
          _initializeWorkspace();
        } else {
          // groupId가 null로 변경된 경우 상태 초기화
          _workspaceNotifier.exitWorkspace();
        }
      }
    });
  }

  void _initializeWorkspace() {
    // 워크스페이스 상태 설정
    _workspaceNotifier.enterWorkspace(
      widget.groupId!,
      channelId: widget.channelId,
    );

    // 워크스페이스 진입 시 사이드바를 즉시 축소
    _navigationController.enterWorkspace();
  }

  @override
  void dispose() {
    _workspaceNotifier.cacheCurrentWorkspaceState();
    _postScrollController.dispose();
    _commentScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCommentsVisible = ref.watch(isCommentsVisibleProvider);
    final selectedPostId = ref.watch(workspaceSelectedPostIdProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // ResponsiveLayoutHelper로 반응형 계산 로직 중앙화
        final responsive = ResponsiveLayoutHelper(
          context: context,
          constraints: constraints,
        );
        final isDesktop = responsive.isDesktop;
        final isMobile = responsive.isMobile;
        final isNarrowDesktop = responsive.isNarrowDesktop;

        // 반응형 전환 감지 및 상태 보존
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }

          _handleResponsiveTransition(isMobile, isNarrowDesktop);

          // 데스크톱에서 댓글창이 열릴 때 게시글 로드
          if (isDesktop && isCommentsVisible) {
            final currentPostId = selectedPostId;
            if (currentPostId != null &&
                currentPostId != _previousSelectedPostId) {
              ref.read(postPreviewProvider.notifier).loadPost(currentPostId);
              _previousSelectedPostId = currentPostId;
            }
          } else if (isDesktop && !isCommentsVisible) {
            // 댓글창 닫힐 때 상태 초기화
            _previousSelectedPostId = null;
          }
        });

        // 뒤로가기 핸들링: LayoutMode 기반 통합 처리
        final layoutMode = LayoutModeExtension.fromContext(context);
        final canHandleBack = _canHandleBackForMode(layoutMode);

        return PopScope(
          canPop: !canHandleBack,
          // onPopInvoked was deprecated; use onPopInvokedWithResult which provides the pop result as well.
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _handleBackPressForMode(layoutMode);
            }
          },
          child: Container(
            color: AppColors.lightBackground,
            child: isDesktop
                ? _buildDesktopWorkspace(isNarrowDesktop: isNarrowDesktop)
                : _buildMobileWorkspace(),
          ),
        );
      },
    );
  }

  /// 반응형 전환 핸들러: 웹 ↔ 모바일 + Narrow Desktop 전환 시 상태 보존
  void _handleResponsiveTransition(bool isMobile, bool isNarrowDesktop) {
    // 초회 빌드에서는 전환이 아닌 초기 상태 설정만 수행한다.
    if (!_hasResponsiveLayoutInitialized) {
      _previousIsMobile = isMobile;
      _previousIsNarrowDesktop = isNarrowDesktop;
      _hasResponsiveLayoutInitialized = true;
      return;
    }

    final isCommentsVisible = ref.read(isCommentsVisibleProvider);
    final isNarrowFullscreen = ref.read(
      workspaceIsNarrowDesktopCommentsFullscreenProvider,
    );
    final selectedPostId = ref.read(workspaceSelectedPostIdProvider);

    // 모바일 ↔ 웹 전환 처리
    if (_previousIsMobile != isMobile) {
      if (isMobile) {
        // 웹 → 모바일 전환
        _workspaceNotifier.handleWebToMobileTransition();
      } else {
        // 모바일 → 웹 전환
        _workspaceNotifier.handleMobileToWebTransition();
      }

      _previousIsMobile = isMobile;
    }

    // Narrow Desktop ↔ Wide Desktop 전환 처리
    if (!isMobile && _previousIsNarrowDesktop != isNarrowDesktop) {
      // 댓글이 열려있는 경우 narrow desktop 상태 동기화
      if (isCommentsVisible) {
        if (isNarrowDesktop && !isNarrowFullscreen) {
          // Wide → Narrow: 댓글을 전체 화면 모드로 전환
          if (selectedPostId != null) {
            _workspaceNotifier.showComments(
              selectedPostId,
              isNarrowDesktop: true,
            );
          }
        } else if (!isNarrowDesktop && isNarrowFullscreen) {
          // Narrow → Wide: 댓글을 사이드바 모드로 전환
          if (selectedPostId != null) {
            _workspaceNotifier.showComments(
              selectedPostId,
              isNarrowDesktop: false,
            );
          }
        }
      }

      _previousIsNarrowDesktop = isNarrowDesktop;
    }
  }

  /// 모바일 뒤로가기 가능 여부 확인
  bool _canHandleMobileBack() {
    final currentView = ref.read(workspaceCurrentViewProvider);
    final mobileView = ref.read(workspaceMobileViewProvider);
    // 특수 뷰(그룹 관리자, 멤버관리, 그룹 홈, 캘린더 등)에서는 내부적으로 뒤로가기를 처리
    if (currentView != WorkspaceView.channel) {
      return true;
    }
    // channelList 상태에서는 뒤로가기를 허용 (홈으로 이동)
    // 나머지 상태에서는 내부적으로 처리
    return mobileView != MobileWorkspaceView.channelList;
  }

  /// 모바일 뒤로가기 처리
  void _handleMobileBackPress() {
    // handleMobileBack()이 true를 반환하면 내부적으로 처리됨
    // false를 반환하면 시스템 뒤로가기 허용
    _workspaceNotifier.handleMobileBack();
  }

  /// Narrow Desktop 뒤로가기 가능 여부 확인
  bool _canHandleNarrowDesktopBack() {
    final isCommentFullscreen = ref.read(
      workspaceIsNarrowDesktopCommentsFullscreenProvider,
    );
    final currentView = ref.read(workspaceCurrentViewProvider);
    final previousView = ref.read(workspacePreviousViewProvider);

    // 1. 댓글 전체화면일 때
    if (isCommentFullscreen) {
      return true;
    }

    // 2. 특수 뷰(groupAdmin, memberManagement 등)일 때
    if (currentView != WorkspaceView.channel && previousView != null) {
      return true;
    }

    return false;
  }

  /// Narrow Desktop 뒤로가기 처리
  void _handleNarrowDesktopBackPress() {
    final currentView = ref.read(workspaceCurrentViewProvider);
    final isCommentFullscreen = ref.read(
      workspaceIsNarrowDesktopCommentsFullscreenProvider,
    );

    // 특수 뷰에서는 handleWebBack() 호출
    if (currentView != WorkspaceView.channel) {
      _workspaceNotifier.handleWebBack();
      return;
    }

    // 댓글 전체화면에서는 댓글 닫기
    if (isCommentFullscreen) {
      _workspaceNotifier.hideComments();
    }
  }

  /// Wide Desktop 뒤로가기 가능 여부 확인
  bool _canHandleWideDesktopBack() {
    final currentView = ref.read(workspaceCurrentViewProvider);
    final previousView = ref.read(workspacePreviousViewProvider);
    final isCommentsVisible = ref.read(isCommentsVisibleProvider);
    final channelHistory = ref.read(workspaceChannelHistoryProvider);

    // 1. 특수 뷰(groupAdmin, memberManagement 등)일 때
    if (currentView != WorkspaceView.channel && previousView != null) {
      return true;
    }

    // 2. 댓글이 열려있을 때
    if (isCommentsVisible) {
      return true;
    }

    // 3. 채널 히스토리가 있을 때
    if (channelHistory.isNotEmpty) {
      return true;
    }

    return false;
  }

  /// Wide Desktop 뒤로가기 처리
  void _handleWideDesktopBackPress() {
    // handleWebBack()이 모든 뒤로가기 로직을 처리함
    // (특수 뷰 → 댓글 → 채널 히스토리 순서)
    _workspaceNotifier.handleWebBack();
  }

  /// Tablet (MEDIUM) 뒤로가기 가능 여부 확인
  bool _canHandleTabletBack() {
    final currentView = ref.read(workspaceCurrentViewProvider);
    final previousView = ref.read(workspacePreviousViewProvider);
    final isCommentsVisible = ref.read(isCommentsVisibleProvider);
    final channelHistory = ref.read(workspaceChannelHistoryProvider);

    // 1. 특수 뷰(groupAdmin, memberManagement 등)일 때
    if (currentView != WorkspaceView.channel && previousView != null) {
      return true;
    }

    // 2. 댓글이 열려있을 때
    if (isCommentsVisible) {
      return true;
    }

    // 3. 채널 히스토리가 있을 때
    if (channelHistory.isNotEmpty) {
      return true;
    }

    return false;
  }

  /// Tablet (MEDIUM) 뒤로가기 처리
  void _handleTabletBackPress() {
    // Wide Desktop과 동일한 로직 (사이드바는 항상 축소 상태)
    _workspaceNotifier.handleWebBack();
  }

  /// LayoutMode 기반 뒤로가기 가능 여부 확인
  bool _canHandleBackForMode(LayoutMode mode) {
    switch (mode) {
      case LayoutMode.compact:
        return _canHandleMobileBack();
      case LayoutMode.medium:
        return _canHandleTabletBack();
      case LayoutMode.wide:
        // Wide 모드 내에서는 ResponsiveLayoutHelper로 Narrow/Wide 구분
        final responsive = ResponsiveLayoutHelper(
          context: context,
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width,
          ),
        );
        return responsive.isNarrowDesktop
            ? _canHandleNarrowDesktopBack()
            : _canHandleWideDesktopBack();
    }
  }

  /// LayoutMode 기반 뒤로가기 처리
  void _handleBackPressForMode(LayoutMode mode) {
    switch (mode) {
      case LayoutMode.compact:
        _handleMobileBackPress();
        break;
      case LayoutMode.medium:
        _handleTabletBackPress();
        break;
      case LayoutMode.wide:
        // Wide 모드 내에서는 ResponsiveLayoutHelper로 Narrow/Wide 구분
        final responsive = ResponsiveLayoutHelper(
          context: context,
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width,
          ),
        );
        if (responsive.isNarrowDesktop) {
          _handleNarrowDesktopBackPress();
        } else {
          _handleWideDesktopBackPress();
        }
        break;
    }
  }

  Widget _buildDesktopWorkspace({bool isNarrowDesktop = false}) {
    return DesktopWorkspaceLayout(
      isNarrowDesktop: isNarrowDesktop,
      mainContent: _buildMainContent(),
      commentsView: _buildCommentsView(),
    );
  }

  Widget _buildMobileWorkspace() {
    final isLoadingWorkspace = ref.watch(workspaceIsLoadingProvider);
    final errorMessage = ref.watch(workspaceErrorMessageProvider);
    final isInWorkspace = ref.watch(isInWorkspaceProvider);
    final currentView = ref.watch(workspaceCurrentViewProvider);
    final mobileView = ref.watch(workspaceMobileViewProvider);
    final selectedChannelId = ref.watch(currentChannelIdProvider);
    final selectedGroupId = ref.watch(currentGroupIdProvider);
    final channelPermissions = ref.watch(workspaceChannelPermissionsProvider);
    final selectedPostId = ref.watch(workspaceSelectedPostIdProvider);

    // 1. 로딩 상태 체크
    if (isLoadingWorkspace) {
      return const WorkspaceStateView(type: WorkspaceStateType.loading);
    }

    // 2. 에러 상태 체크
    if (errorMessage != null) {
      return WorkspaceStateView(
        type: WorkspaceStateType.error,
        errorMessage: errorMessage,
        onRetry: _retryLoadWorkspace,
      );
    }

    // 3. 워크스페이스 미진입 체크
    if (!isInWorkspace) {
      return const WorkspaceStateView(type: WorkspaceStateType.noGroup);
    }

    // 4. 특수 뷰 우선 처리 (groupAdmin, memberManagement 등)
    if (currentView != WorkspaceView.channel) {
      switch (currentView) {
        case WorkspaceView.groupHome:
          return const GroupHomeView();
        case WorkspaceView.calendar:
          if (selectedGroupId == null) {
            return const WorkspaceStateView(type: WorkspaceStateType.noGroup);
          }
          return GroupCalendarPage(groupId: int.parse(selectedGroupId));
        case WorkspaceView.groupAdmin:
          return const GroupAdminPage();
        case WorkspaceView.memberManagement:
          return const MemberManagementPage();
        case WorkspaceView.recruitmentManagement:
          return const RecruitmentManagementPage();
        case WorkspaceView.channel:
          // Fall through to mobile view switch below
          break;
      }
    }

    // 5. 모바일 3단계 플로우에 따른 뷰 전환 (채널 관련)
    switch (mobileView) {
      case MobileWorkspaceView.channelList:
        // Step 1: 채널 목록
        return _buildMobileChannelList();

      case MobileWorkspaceView.channelPosts:
        // Step 2: 선택된 채널의 게시글 목록
        if (selectedChannelId == null) {
          // 채널이 선택되지 않았다면 채널 목록으로 폴백
          return _buildMobileChannelList();
        }
        return MobileChannelPostsView(
          channelId: selectedChannelId,
          groupId: selectedGroupId!,
          permissions: channelPermissions,
        );

      case MobileWorkspaceView.postComments:
        // Step 3: 선택된 게시글의 댓글
        if (selectedPostId == null || selectedChannelId == null) {
          // 게시글이나 채널이 선택되지 않았다면 게시글 목록으로 폴백
          if (selectedChannelId != null) {
            return MobileChannelPostsView(
              channelId: selectedChannelId,
              groupId: selectedGroupId!,
              permissions: channelPermissions,
            );
          }
          return _buildMobileChannelList();
        }
        return MobilePostCommentsView(
          postId: selectedPostId,
          channelId: selectedChannelId,
          groupId: selectedGroupId!,
          permissions: channelPermissions,
        );
    }
  }

  Widget _buildMobileChannelList() {
    final channels = ref.watch(workspaceChannelsProvider);
    final selectedChannelId = ref.watch(currentChannelIdProvider);
    final hasAnyGroupPermission = ref.watch(
      workspaceHasAnyGroupPermissionProvider,
    );
    final unreadCounts = ref.watch(workspaceUnreadCountsProvider);
    final currentGroupId = ref.watch(currentGroupIdProvider);
    return Consumer(
      builder: (context, ref, _) {
        // currentGroupNameProvider로 그룹 이름 가져오기
        final currentGroupName = ref.watch(currentGroupNameProvider);

        return MobileChannelList(
          channels: channels,
          selectedChannelId: selectedChannelId,
          hasAnyGroupPermission: hasAnyGroupPermission,
          unreadCounts: unreadCounts,
          currentGroupId: currentGroupId,
          currentGroupName: currentGroupName,
        );
      },
    );
  }

  Widget _buildMainContent() {
    final isLoadingWorkspace = ref.watch(workspaceIsLoadingProvider);
    final errorMessage = ref.watch(workspaceErrorMessageProvider);
    final isInWorkspace = ref.watch(isInWorkspaceProvider);
    final currentView = ref.watch(workspaceCurrentViewProvider);
    final hasSelectedChannel = ref.watch(workspaceHasSelectedChannelProvider);
    final channels = ref.watch(workspaceChannelsProvider);
    final selectedChannelId = ref.watch(currentChannelIdProvider);
    final channelPermissions = ref.watch(workspaceChannelPermissionsProvider);
    final isLoadingPermissions = ref.watch(
      workspaceIsLoadingPermissionsProvider,
    );

    // Show loading state
    if (isLoadingWorkspace) {
      return const WorkspaceStateView(type: WorkspaceStateType.loading);
    }

    // Show error state
    if (errorMessage != null) {
      return WorkspaceStateView(
        type: WorkspaceStateType.error,
        errorMessage: errorMessage,
        onRetry: _retryLoadWorkspace,
      );
    }

    if (!isInWorkspace) {
      return const WorkspaceStateView(type: WorkspaceStateType.noGroup);
    }

    // Switch view based on currentView
    switch (currentView) {
      case WorkspaceView.groupHome:
        return const GroupHomeView();
      case WorkspaceView.calendar:
        final currentGroupId = ref.watch(currentGroupIdProvider);
        if (currentGroupId == null) {
          return const WorkspaceStateView(type: WorkspaceStateType.noGroup);
        }
        return GroupCalendarPage(groupId: int.parse(currentGroupId));
      case WorkspaceView.groupAdmin:
        return const GroupAdminPage();
      case WorkspaceView.memberManagement:
        return const MemberManagementPage();
      case WorkspaceView.recruitmentManagement:
        return const RecruitmentManagementPage();
      case WorkspaceView.channel:
        if (!hasSelectedChannel) {
          return const WorkspaceEmptyState(
            type: WorkspaceEmptyType.noChannelSelected,
          );
        }
        return ChannelContentView(
          channels: channels,
          selectedChannelId: selectedChannelId!,
          channelPermissions: channelPermissions,
          isLoadingPermissions: isLoadingPermissions,
          onSubmitPost: (content) => _handleSubmitPost(context, ref, content),
          postReloadTick: _postListKey,
        );
    }
  }

  Future<void> _handleSubmitPost(
    BuildContext context,
    WidgetRef ref,
    String content,
  ) async {
    final channelId = ref.read(currentChannelIdProvider);

    if (channelId == null) {
      throw Exception('채널을 선택해주세요');
    }

    final params = CreatePostParams(channelId: channelId, content: content);
    await ref.read(createPostProvider(params).future);

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
    final postIdStr = ref.read(workspaceSelectedPostIdProvider);

    if (postIdStr == null) {
      throw Exception('게시글을 선택해주세요');
    }

    final postId = int.parse(postIdStr);
    final params = CreateCommentParams(postId: postId, content: content);
    await ref.read(createCommentProvider(params).future);

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

  Widget _buildCommentsView() {
    final postIdStr = ref.watch(workspaceSelectedPostIdProvider);
    final postId = postIdStr != null ? int.tryParse(postIdStr) : null;
    final channelPermissions = ref.watch(workspaceChannelPermissionsProvider);
    final canWrite = channelPermissions?.canWriteComment ?? false;
    final isLoadingPermissions = ref.watch(
      workspaceIsLoadingPermissionsProvider,
    );

    return Stack(
      children: [
        Column(
          children: [
            // 게시글 미리보기
            PostPreviewWidget(
              onClose: _workspaceNotifier.hideComments,
            ),

            const Divider(height: 1, thickness: 1),

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
              Padding(
                padding: EdgeInsets.all(AppSpacing.xs),
                child: CommentComposer(
                  canWrite: canWrite,
                  isLoading: isLoadingPermissions,
                  onSubmit: (content) =>
                      _handleSubmitComment(context, ref, content),
                ),
              ),
          ],
        ),
        // X 버튼 (우측 상단)
        Positioned(
          top: 12,
          right: 12,
          child: IconButton(
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            iconSize: 20,
            onPressed: _workspaceNotifier.hideComments,
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }

  void _retryLoadWorkspace() {
    // Clear error and try again
    _workspaceNotifier.clearError();

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
