import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

import '../../providers/workspace_state_provider.dart' hide MobileWorkspaceView;
import '../../../core/navigation/navigation_controller.dart';
import '../../../core/navigation/layout_mode.dart';

import '../../widgets/workspace/comments_sidebar_view.dart';

import '../../utils/responsive_layout_helper.dart';
import 'widgets/desktop_workspace_layout.dart';
import 'widgets/mobile_workspace_view.dart';
import 'widgets/desktop_main_content.dart';
import 'providers/post_preview_notifier.dart';
import 'mixins/workspace_back_navigation_mixin.dart';
import 'mixins/workspace_responsive_mixin.dart';
import 'helpers/post_comment_actions.dart';

class WorkspacePage extends ConsumerStatefulWidget {
  final String? groupId;
  final String? channelId;

  const WorkspacePage({super.key, this.groupId, this.channelId});

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage>
    with
        WidgetsBindingObserver,
        WorkspaceBackNavigationMixin,
        WorkspaceResponsiveMixin {
  int _postListKey = 0;
  int _commentListKey = 0;
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
    _navigationController = ref.read(navigationControllerProvider.notifier);

    // Add lifecycle observer for app state changes
    WidgetsBinding.instance.addObserver(this);

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
    // GroupDropdown이나 다른 곳에서 이미 enterWorkspace()를 호출했는지 확인
    final currentGroupId = ref.read(currentGroupIdProvider);
    final isAlreadyInitialized = currentGroupId == widget.groupId;

    if (!isAlreadyInitialized) {
      // 워크스페이스 상태 설정 (URL 직접 접근 시에만)
      _workspaceNotifier.enterWorkspace(
        widget.groupId!,
        channelId: widget.channelId,
      );
    }

    // 워크스페이스 진입 시 사이드바를 즉시 축소
    _navigationController.enterWorkspace();
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    _workspaceNotifier.cacheCurrentWorkspaceState();
    _postScrollController.dispose();
    _commentScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save read position when app goes to background or terminates
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveCurrentReadPosition();
    }
    // Restore session when app returns from background (T103)
    else if (state == AppLifecycleState.resumed) {
      _restoreSessionAfterInterruption();
    }
  }

  /// Restore session after app returns from background or after interruption
  ///
  /// Handles:
  /// - Workspace state validation
  /// - Permission context refresh
  /// - Network reconnection
  void _restoreSessionAfterInterruption() {
    if (!mounted) return;

    final workspaceState = ref.read(workspaceStateProvider);
    final currentGroupId = workspaceState.currentGroupId;

    // If workspace is active, validate and refresh
    if (currentGroupId != null) {
      // Refresh workspace state to ensure consistency
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // Re-initialize workspace to refresh permissions and data
        _workspaceNotifier.enterWorkspace(
          currentGroupId,
          channelId: workspaceState.selectedChannelId,
        );
      });
    }
  }

  Future<void> _saveCurrentReadPosition() async {
    final workspaceState = ref.read(workspaceStateProvider);
    final channelId = workspaceState.selectedChannelId;
    final postId = workspaceState.currentVisiblePostId;

    if (channelId != null && postId != null) {
      final channelIdInt = int.tryParse(channelId);
      if (channelIdInt != null) {
        try {
          await ref
              .read(workspaceStateProvider.notifier)
              .saveReadPosition(channelIdInt, postId);
        } catch (e) {
          // Silently ignore errors (Best-Effort)
        }
      }
    }
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

          handleResponsiveTransition(
            isMobile,
            isNarrowDesktop,
            _workspaceNotifier,
          );

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
        final canHandleBack = canHandleBackForMode(layoutMode);

        return PopScope(
          canPop: !canHandleBack,
          // onPopInvoked was deprecated; use onPopInvokedWithResult which provides the pop result as well.
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              handleBackPressForMode(layoutMode, _workspaceNotifier);
            }
          },
          child: Container(
            color: AppColors.lightBackground,
            child: isDesktop
                ? _buildDesktopWorkspace(isNarrowDesktop: isNarrowDesktop)
                : MobileWorkspaceView(
                    onRetryLoadWorkspace: _retryLoadWorkspace,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopWorkspace({bool isNarrowDesktop = false}) {
    return DesktopWorkspaceLayout(
      isNarrowDesktop: isNarrowDesktop,
      mainContent: DesktopMainContent(
        onRetryLoadWorkspace: _retryLoadWorkspace,
        onSubmitPost: (content) => PostCommentActions.handleSubmitPost(
          context: context,
          ref: ref,
          content: content,
          onSuccess: () => setState(() {
            _postListKey++;
          }),
        ),
        postReloadTick: _postListKey,
      ),
      commentsView: CommentsSidebarView(
        onClose: _workspaceNotifier.hideComments,
        commentListKey: _commentListKey,
        onCommentSubmitted: () => setState(() {
          _commentListKey++; // 댓글 목록 새로고침
          _postListKey++; // 게시글 목록도 새로고침하여 댓글 개수/시간 업데이트
        }),
      ),
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
