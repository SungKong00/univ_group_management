import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
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
import '../../../core/models/post_models.dart';
import '../../widgets/common/collapsible_content.dart';
import 'widgets/workspace_empty_state.dart';
import 'providers/post_actions_provider.dart';
import 'providers/comment_actions_provider.dart';

class WorkspacePage extends ConsumerStatefulWidget {
  final String? groupId;
  final String? channelId;

  const WorkspacePage({super.key, this.groupId, this.channelId});

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage>
    with SingleTickerProviderStateMixin {
  int _postListKey = 0;
  int _commentListKey = 0;
  bool _previousIsMobile = false;
  bool _previousIsNarrowDesktop = false; // Narrow desktop 상태 추적
  bool _hasResponsiveLayoutInitialized = false;
  bool _isAnimatingOut = false; // 슬라이드 아웃 애니메이션 진행 중 플래그
  late AnimationController _commentsAnimationController;
  late Animation<double> _backdropFadeAnimation; // 백드롭 페이드 애니메이션
  late Animation<Offset> _commentsSlideAnimation;

  // 스크롤 위치 보존을 위한 ScrollController (선택사항)
  final ScrollController _postScrollController = ScrollController();
  final ScrollController _commentScrollController = ScrollController();

  // 웹 댓글 사이드바용 게시글 데이터 상태
  Post? _selectedPost;
  bool _isLoadingPost = false;
  String? _postErrorMessage;
  String? _previousSelectedPostId; // 중복 로드 방지용 이전 게시글 ID

  @override
  void initState() {
    super.initState();

    // 댓글창 슬라이드 애니메이션 초기화
    _commentsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160), // 디자인 시스템 표준 duration
    );

    _commentsSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // 오른쪽 밖에서 시작
      end: Offset.zero, // 제자리로 이동
    ).animate(CurvedAnimation(
      parent: _commentsAnimationController,
      curve: Curves.easeOutCubic, // 디자인 시스템 표준 easing
    ));

    _backdropFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _commentsAnimationController,
      curve: Curves.easeOutCubic, // 슬라이드와 동일한 easing
    ));

    // 애니메이션 상태 리스너: 슬라이드 아웃 완료 감지
    _commentsAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && _isAnimatingOut) {
        // 애니메이션이 완전히 종료되면 플래그 해제하고 상태 동기화
        setState(() {
          _isAnimatingOut = false;
        });
        // ✅ 상태 동기화: 애니메이션 완료 후 workspaceState.isCommentsVisible를 false로 설정
        ref.read(workspaceStateProvider.notifier).hideComments();
      }
    });

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
    _commentsAnimationController.dispose();
    _postScrollController.dispose();
    _commentScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceStateProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 문서 스펙: MOBILE(0-600px), TABLET(601-800px), DESKTOP(801px+)
        // largerThan(MOBILE) = 601px 이상 = TABLET, DESKTOP, 4K
        final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
        final isMobile = !isDesktop;

        // Narrow Desktop: 게시글 + 댓글 충돌 발생 구간 (601px~850px)
        // 채널바(200px) + 여유있는 콘텐츠(350px) + 댓글바(300px) = 850px
        // 사용자 요청: 850px 미만을 narrow desktop으로 간주
        final isNarrowDesktop = isDesktop && constraints.maxWidth < 850;

        // 반응형 전환 감지 및 상태 보존
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleResponsiveTransition(isMobile, isNarrowDesktop);

          // 데스크톱에서 댓글 가시성 변화에 따라 애니메이션 트리거
          // ✅ _isAnimatingOut이 아닐 때만 forward 허용 (중복 실행 방지)
          if (isDesktop) {
            if (workspaceState.isCommentsVisible && !_isAnimatingOut) {
              _commentsAnimationController.forward();

              // 웹 댓글 사이드바가 열릴 때 게시글 로드 (중복 방지)
              final currentPostId = workspaceState.selectedPostId;
              if (currentPostId != null && currentPostId != _previousSelectedPostId) {
                _loadSelectedPost(currentPostId);
                _previousSelectedPostId = currentPostId;
              }
            } else if (!workspaceState.isCommentsVisible && !_isAnimatingOut) {
              _commentsAnimationController.reverse();
              // 댓글창 닫힐 때 상태 초기화
              _previousSelectedPostId = null;
            }
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
    final bool showChannelNavigation = workspaceState.isInWorkspace;
    final bool showComments = workspaceState.isCommentsVisible || _isAnimatingOut;

    // Narrow desktop + 댓글 전체 화면 모드: 게시글 숨기고 댓글만 표시
    final bool isNarrowCommentFullscreen = isNarrowDesktop && workspaceState.isNarrowDesktopCommentsFullscreen;

    return LayoutBuilder(
      builder: (context, constraints) {
        // MediaQuery를 한 번만 호출하여 성능 최적화
        final double screenWidth = MediaQuery.of(context).size.width;
        final double channelBarWidth = screenWidth >= 1200 ? 256.0 : 200.0;
        final double commentBarWidth = screenWidth >= 1200 ? 390.0 : 300.0;

        // Narrow desktop 댓글 전체 화면: 채널바만 표시, 우측은 전체 화면
        final double leftInset = showChannelNavigation ? channelBarWidth : 0;
        final double rightInset = (showComments && !isNarrowCommentFullscreen) ? commentBarWidth : 0;

        return Stack(
          children: [
            // Narrow desktop 댓글 전체 화면: 게시글 숨김 (Visibility로 깜빡임 방지)
            Positioned.fill(
              left: leftInset,
              right: rightInset,
              child: Visibility(
                visible: !isNarrowCommentFullscreen,
                maintainState: true,
                child: _buildMainContent(workspaceState),
              ),
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
                      width: channelBarWidth,
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

            // 백드롭 레이어: Wide desktop에서만 전체 영역 어둡게 처리
            // Narrow desktop 전체 화면 모드에서는 백드롭 불필요 (댓글창이 전체 화면)
            if (showComments && !isNarrowCommentFullscreen)
              Positioned(
                top: 0,
                bottom: 0,
                left: leftInset, // 채널바 제외
                right: 0, // 전체 화면 커버 (댓글창은 상위 레이어에 렌더링됨)
                child: FadeTransition(
                  opacity: _backdropFadeAnimation,
                  child: GestureDetector(
                    onTap: () {
                      // 백드롭 클릭 시 댓글창 닫기 (슬라이드 아웃 애니메이션)
                      setState(() {
                        _isAnimatingOut = true;
                      });
                      _commentsAnimationController.reverse();
                    },
                    child: Container(
                      color: const Color.fromRGBO(0, 0, 0, 0.12),
                    ),
                  ),
                ),
              ),

            // 댓글 사이드바 (백드롭 위에 렌더링하여 Z-index 최상위)
            if (showComments)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                // Narrow desktop: 전체 너비 사용, Wide desktop: commentBarWidth
                width: isNarrowCommentFullscreen ? null : commentBarWidth,
                // Narrow desktop 전체 화면: 채널바 옆에서 시작
                left: isNarrowCommentFullscreen ? leftInset : null,
                child: RepaintBoundary(
                  child: SlideTransition(
                    position: _commentsSlideAnimation,
                    child: _buildCommentsSidebar(
                      workspaceState,
                      isNarrowCommentFullscreen ? null : commentBarWidth,
                    ),
                  ),
                ),
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
        return const WorkspaceEmptyState(type: WorkspaceEmptyType.groupHome);
      case WorkspaceView.calendar:
        return const WorkspaceEmptyState(type: WorkspaceEmptyType.calendar);
      case WorkspaceView.groupAdmin:
        return const WorkspaceEmptyState(type: WorkspaceEmptyType.groupAdmin);
      case WorkspaceView.channel:
        if (!workspaceState.hasSelectedChannel) {
          return const WorkspaceEmptyState(type: WorkspaceEmptyType.noChannelSelected);
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
      // 상단 패딩을 4px 줄여(16 -> 12) SizedBox와 합쳐 총 20px 감소
      // 추가로 1px 더 줄여 상단 패딩을 11px로 설정 (총 21px 감소에 해당)
      padding: const EdgeInsets.fromLTRB(16.0, 13.0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(channelName, style: AppTheme.headlineMedium),
          // 하단 패딩을 20px 줄임 (원래 16px -> 0px)
          const SizedBox(height: 0),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 반응형 기준과 동일하게 constraints.maxWidth 사용
                final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
                final isNarrowDesktop = isDesktop && constraints.maxWidth < 850;

                return PostList(
                  key: ValueKey('post_list_${workspaceState.selectedChannelId}_$_postListKey'),
                  channelId: workspaceState.selectedChannelId!,
                  canWrite: canWritePost,
                  onTapComment: (postId) {
                    ref.read(workspaceStateProvider.notifier).showComments(
                      postId.toString(),
                      isNarrowDesktop: isNarrowDesktop,
                    );
                  },
                );
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

  Widget _buildCommentsSidebar(WorkspaceState workspaceState, double? width) {
    return Container(
      width: width, // null이면 전체 너비 사용
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

    return Stack(
      children: [
        Column(
          children: [
            // 게시글 미리보기
            _buildPostPreview(),

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
            onPressed: () {
              // 1. 슬라이드 아웃 애니메이션 시작
              setState(() {
                _isAnimatingOut = true;
              });

              // 2. reverse() 애니메이션 실행 (AnimationStatus 리스너가 완료 후 hideComments() 자동 호출)
              _commentsAnimationController.reverse();
            },
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }

  /// 웹 댓글 사이드바 게시글 미리보기 빌드
  Widget _buildPostPreview() {
    // 로딩 중
    if (_isLoadingPost) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 에러 발생
    if (_postErrorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Color.fromRGBO(244, 67, 54, 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _postErrorMessage!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 게시글 로드 성공 - 박스 없이 요소만 표시
    if (_selectedPost != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 프로필 + 작성자 + 시간 (X 버튼 공간 확보를 위해 우측 패딩 추가)
            Padding(
              padding: const EdgeInsets.only(right: 40), // X 버튼 영역 확보
              child: _buildPostHeader(_selectedPost!),
            ),
            const SizedBox(height: 12),
            // 본문 (펼치기/접기 가능)
            Padding(
              padding: const EdgeInsets.only(left: 52), // 프로필(40) + 간격(12) = 52
              child: CollapsibleContent(
                content: _selectedPost!.content,
                maxLines: 5,
                style: AppTheme.bodyMedium,
                expandedScrollable: true,
                expandedMaxLines: 10,
              ),
            ),
          ],
        ),
      );
    }

    // 예상치 못한 상태 (빈 화면)
    return const SizedBox.shrink();
  }

  Widget _buildPostHeader(Post post) {
    return Row(
      children: [
        // 프로필 이미지
        _buildPostProfileImage(post),
        const SizedBox(width: 12),
        // 작성자 + 시간
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorName,
                style: AppTheme.titleMedium.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormatter.formatRelativeTime(post.createdAt),
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostProfileImage(Post post) {
    final hasImage = post.authorProfileUrl != null && post.authorProfileUrl!.isNotEmpty;

    if (hasImage) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(post.authorProfileUrl!),
        backgroundColor: AppColors.neutral200,
      );
    }

    // 기본 아바타 (이니셜)
    final initial = post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.brand,
      child: Text(
        initial,
        style: AppTheme.titleMedium.copyWith(
          color: Colors.white,
        ),
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

  /// 웹 댓글 사이드바용 게시글 로드
  Future<void> _loadSelectedPost(String postId) async {
    setState(() {
      _isLoadingPost = true;
      _postErrorMessage = null;
      _selectedPost = null;
    });

    try {
      final postIdInt = int.parse(postId);
      final postService = PostService();
      final post = await postService.getPost(postIdInt);

      setState(() {
        _selectedPost = post;
        _isLoadingPost = false;
      });
    } catch (e) {
      setState(() {
        _postErrorMessage = '게시글을 불러올 수 없습니다.';
        _isLoadingPost = false;
      });
    }
  }
}
