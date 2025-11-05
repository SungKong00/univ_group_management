import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/workspace_state_provider.dart' as provider;
import '../../../widgets/workspace/mobile_channel_posts_view.dart';
import '../../../widgets/workspace/mobile_post_comments_view.dart';
import '../helpers/workspace_view_builder.dart';
import 'workspace_state_view.dart';
import 'mobile_channel_list_view.dart';

/// Mobile workspace view container widget
///
/// Handles 3-step mobile navigation flow: channelList → channelPosts → postComments
class MobileWorkspaceView extends ConsumerWidget {
  final VoidCallback? onRetryLoadWorkspace;

  const MobileWorkspaceView({
    super.key,
    this.onRetryLoadWorkspace,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoadingWorkspace = ref.watch(provider.workspaceIsLoadingProvider);
    final errorMessage = ref.watch(provider.workspaceErrorMessageProvider);
    final isInWorkspace = ref.watch(provider.isInWorkspaceProvider);
    final currentView = ref.watch(provider.workspaceCurrentViewProvider);
    final mobileView = ref.watch(provider.workspaceMobileViewProvider);
    final selectedChannelId = ref.watch(provider.currentChannelIdProvider);
    final selectedGroupId = ref.watch(provider.currentGroupIdProvider);
    final channelPermissions = ref.watch(provider.workspaceChannelPermissionsProvider);
    final selectedPostId = ref.watch(provider.workspaceSelectedPostIdProvider);

    // 1. 로딩 상태 체크
    if (isLoadingWorkspace) {
      return const WorkspaceStateView(type: WorkspaceStateType.loading);
    }

    // 2. 에러 상태 체크
    if (errorMessage != null) {
      return WorkspaceStateView(
        type: WorkspaceStateType.error,
        errorMessage: errorMessage,
        onRetry: onRetryLoadWorkspace,
      );
    }

    // 3. 워크스페이스 미진입 체크
    if (!isInWorkspace) {
      return const WorkspaceStateView(type: WorkspaceStateType.noGroup);
    }

    // 4. 모바일 3단계 플로우에 따른 뷰 전환 (채널 관련) - 우선 처리
    // 모바일에서는 mobileView가 주 네비게이션을 제어합니다
    if (currentView == WorkspaceView.channel) {
      switch (mobileView) {
        case provider.MobileWorkspaceView.channelList:
          // Step 1: 채널 목록
          return const MobileChannelListView();

        case provider.MobileWorkspaceView.channelPosts:
          // Step 2: 선택된 채널의 게시글 목록
          if (selectedChannelId == null) {
            // 채널이 선택되지 않았다면 채널 목록으로 폴백
            return const MobileChannelListView();
          }
          return MobileChannelPostsView(
            channelId: selectedChannelId,
            groupId: selectedGroupId!,
            permissions: channelPermissions,
          );

        case provider.MobileWorkspaceView.postComments:
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
            return const MobileChannelListView();
          }
          return MobilePostCommentsView(
            postId: selectedPostId,
            channelId: selectedChannelId,
            groupId: selectedGroupId!,
            permissions: channelPermissions,
          );
      }
    }

    // 5. 특수 뷰 처리 (groupAdmin, memberManagement, calendar, groupHome 등)
    final specialView = WorkspaceViewBuilder.buildSpecialView(ref, currentView);
    if (specialView != null) {
      return specialView;
    }

    // 6. 기본값: 채널 리스트 (모바일에서는 항상 리턴되어야 함)
    return const MobileChannelListView();
  }
}
