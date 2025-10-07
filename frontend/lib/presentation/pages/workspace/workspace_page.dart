import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/channel_models.dart';
import '../../providers/workspace_state_provider.dart';
import '../../providers/current_group_provider.dart';
import '../../../core/navigation/navigation_controller.dart';
import '../../widgets/workspace/channel_navigation.dart';
import '../../widgets/workspace/mobile_channel_list.dart';
import '../../widgets/workspace/mobile_channel_posts_view.dart';
import '../../widgets/workspace/mobile_post_comments_view.dart';
import '../../widgets/post/post_list.dart';
import '../../widgets/post/post_composer.dart';
import '../../widgets/comment/comment_list.dart';
import '../../widgets/comment/comment_composer.dart';
import '../../widgets/common/slide_panel.dart';
import '../../utils/responsive_layout_helper.dart';
import 'widgets/workspace_empty_state.dart';
import 'widgets/workspace_state_view.dart';
import 'widgets/desktop_workspace_layout.dart';
import 'widgets/channel_content_view.dart';
import 'widgets/post_preview_widget.dart';
import 'providers/post_preview_notifier.dart';
import 'providers/post_actions_provider.dart';
import 'providers/comment_actions_provider.dart';

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

  // 스크롤 위치 보존을 위한 ScrollController (선택사항)
  final ScrollController _postScrollController = ScrollController();
  final ScrollController _commentScrollController = ScrollController();

  // 중복 로드 방지용 이전 게시글 ID
  String? _previousSelectedPostId;

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

    // groupId 변경 감지 및 상태 관리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.groupId != oldWidget.groupId) {
        // groupId가 변경된 경우
        if (widget.groupId != null) {
          _initializeWorkspace();
        } else {
          // groupId가 null로 변경된 경우 상태 초기화
          ref.read(workspaceStateProvider.notifier).exitWorkspace();
        }
      }
    });
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
  void dispose() {
    _postScrollController.dispose();
    _commentScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceStateProvider);

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
          _handleResponsiveTransition(isMobile, isNarrowDesktop);

          // 데스크톱에서 댓글창이 열릴 때 게시글 로드
          if (isDesktop && workspaceState.isCommentsVisible) {
            final currentPostId = workspaceState.selectedPostId;
            if (currentPostId != null && currentPostId != _previousSelectedPostId) {
              ref.read(postPreviewProvider.notifier).loadPost(currentPostId);
              _previousSelectedPostId = currentPostId;
            }
          } else if (isDesktop && !workspaceState.isCommentsVisible) {
            // 댓글창 닫힐 때 상태 초기화
            _previousSelectedPostId = null;
          }
        });

        // 뒤로가기 핸들링: 모바일 + Narrow Desktop
        final canHandleBack = isMobile && _canHandleMobileBack() ||
            (isNarrowDesktop && workspaceState.isNarrowDesktopCommentsFullscreen);

        return PopScope(
          canPop: !canHandleBack,
          // onPopInvoked was deprecated; use onPopInvokedWithResult which provides the pop result as well.
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              if (isMobile) {
                _handleMobileBackPress();
              } else if (isNarrowDesktop && workspaceState.isNarrowDesktopCommentsFullscreen) {
                // Narrow desktop에서 댓글 전체 화면 모드일 때 뒤로가기로 닫기
                ref.read(workspaceStateProvider.notifier).hideComments();
              }
            }
          },
          child: Container(
            color: AppColors.lightBackground,
            child: isDesktop
                ? _buildDesktopWorkspace(workspaceState, isNarrowDesktop: isNarrowDesktop)
                : _buildMobileWorkspace(workspaceState),
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

    final workspaceNotifier = ref.read(workspaceStateProvider.notifier);
    final workspaceState = ref.read(workspaceStateProvider);

    // 모바일 ↔ 웹 전환 처리
    if (_previousIsMobile != isMobile) {
      if (isMobile) {
        // 웹 → 모바일 전환
        workspaceNotifier.handleWebToMobileTransition();
      } else {
        // 모바일 → 웹 전환
        workspaceNotifier.handleMobileToWebTransition();
      }

      _previousIsMobile = isMobile;
    }

    // Narrow Desktop ↔ Wide Desktop 전환 처리
    if (!isMobile && _previousIsNarrowDesktop != isNarrowDesktop) {
      // 댓글이 열려있는 경우 narrow desktop 상태 동기화
      if (workspaceState.isCommentsVisible) {
        if (isNarrowDesktop && !workspaceState.isNarrowDesktopCommentsFullscreen) {
          // Wide → Narrow: 댓글을 전체 화면 모드로 전환
          workspaceNotifier.showComments(
            workspaceState.selectedPostId!,
            isNarrowDesktop: true,
          );
        } else if (!isNarrowDesktop && workspaceState.isNarrowDesktopCommentsFullscreen) {
          // Narrow → Wide: 댓글을 사이드바 모드로 전환
          workspaceNotifier.showComments(
            workspaceState.selectedPostId!,
            isNarrowDesktop: false,
          );
        }
      }

      _previousIsNarrowDesktop = isNarrowDesktop;
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

  Widget _buildDesktopWorkspace(WorkspaceState workspaceState, {bool isNarrowDesktop = false}) {
    return DesktopWorkspaceLayout(
      workspaceState: workspaceState,
      isNarrowDesktop: isNarrowDesktop,
      mainContent: _buildMainContent(workspaceState),
      commentsView: _buildCommentsView(workspaceState),
    );
  }

  Widget _buildMobileWorkspace(WorkspaceState workspaceState) {
    // 1. 로딩 상태 체크
    if (workspaceState.isLoadingWorkspace) {
      return const WorkspaceStateView(type: WorkspaceStateType.loading);
    }

    // 2. 에러 상태 체크
    if (workspaceState.errorMessage != null) {
      return WorkspaceStateView(
        type: WorkspaceStateType.error,
        errorMessage: workspaceState.errorMessage,
        onRetry: _retryLoadWorkspace,
      );
    }

    // 3. 워크스페이스 미진입 체크
    if (!workspaceState.isInWorkspace) {
      return const WorkspaceStateView(type: WorkspaceStateType.noGroup);
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
        // currentGroupNameProvider로 그룹 이름 가져오기
        final currentGroupName = ref.watch(currentGroupNameProvider);

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
      return const WorkspaceStateView(type: WorkspaceStateType.loading);
    }

    // Show error state
    if (workspaceState.errorMessage != null) {
      return WorkspaceStateView(
        type: WorkspaceStateType.error,
        errorMessage: workspaceState.errorMessage,
        onRetry: _retryLoadWorkspace,
      );
    }

    if (!workspaceState.isInWorkspace) {
      return const WorkspaceStateView(type: WorkspaceStateType.noGroup);
    }

    // Switch view based on currentView
    switch (workspaceState.currentView) {
      case WorkspaceView.groupHome:
        return const WorkspaceEmptyState(type: WorkspaceEmptyType.groupHome);
      case WorkspaceView.calendar:
        return const WorkspaceEmptyState(type: WorkspaceEmptyType.calendar);
      case WorkspaceView.groupAdmin:
        return const WorkspaceEmptyState(type: WorkspaceEmptyType.groupAdmin);
      case WorkspaceView.channel:
        if (!workspaceState.hasSelectedChannel) {
          return const WorkspaceEmptyState(type: WorkspaceEmptyType.noChannelSelected);
        }
        return ChannelContentView(
          workspaceState: workspaceState,
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
    final workspaceState = ref.read(workspaceStateProvider);
    final channelId = workspaceState.selectedChannelId;

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
    final workspaceState = ref.read(workspaceStateProvider);
    final postIdStr = workspaceState.selectedPostId;

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


  Widget _buildCommentsView(WorkspaceState workspaceState) {
    final postIdStr = workspaceState.selectedPostId;
    final postId = postIdStr != null ? int.tryParse(postIdStr) : null;
    final canWrite = workspaceState.channelPermissions?.canWriteComment ?? false;

    return Stack(
      children: [
        Column(
          children: [
            // 게시글 미리보기
            PostPreviewWidget(
              onClose: () => ref.read(workspaceStateProvider.notifier).hideComments(),
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
                  isLoading: workspaceState.channelPermissions == null,
                  onSubmit: (content) => _handleSubmitComment(context, ref, content),
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
            onPressed: () => ref.read(workspaceStateProvider.notifier).hideComments(),
            icon: const Icon(Icons.close),
          ),
        ),
      ],
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
