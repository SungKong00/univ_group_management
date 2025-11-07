import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/workspace_state_provider.dart';
import '../../../providers/current_group_provider.dart';
import '../../../widgets/workspace/channel_navigation.dart';
import '../../../widgets/common/slide_panel.dart';
import '../../../utils/responsive_layout_helper.dart';

/// 데스크톱 워크스페이스 레이아웃
///
/// Stack 기반으로 채널 네비게이션, 메인 콘텐츠, 댓글 패널을 조합합니다.
/// Narrow/Wide desktop 모드를 처리합니다.
class DesktopWorkspaceLayout extends ConsumerWidget {
  final bool isNarrowDesktop;
  final Widget mainContent;
  final Widget commentsView;

  const DesktopWorkspaceLayout({
    super.key,
    required this.isNarrowDesktop,
    required this.mainContent,
    required this.commentsView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool showChannelNavigation = ref.watch(isInWorkspaceProvider);
    final bool showComments = ref.watch(isCommentsVisibleProvider);
    final bool isCommentFullscreen = ref.watch(
      workspaceIsNarrowDesktopCommentsFullscreenProvider,
    );

    // Narrow desktop + 댓글 전체 화면 모드: 게시글 숨기고 댓글만 표시
    final bool isNarrowCommentFullscreen =
        isNarrowDesktop && showComments && isCommentFullscreen;

    return LayoutBuilder(
      builder: (context, constraints) {
        // ResponsiveLayoutHelper로 레이아웃 계산
        final responsive = ResponsiveLayoutHelper(
          context: context,
          constraints: constraints,
        );
        final layout = responsive.calculateLayout(
          showChannelNavigation: showChannelNavigation,
          showComments: showComments,
          isNarrowCommentFullscreen: isNarrowCommentFullscreen,
        );

        final double channelBarWidth = layout.channelBarWidth;
        final double commentBarWidth = layout.commentBarWidth;
        final double leftInset = layout.leftInset;
        final double rightInset = layout.rightInset;

        return Stack(
          children: [
            // Narrow desktop 댓글 전체 화면: 게시글 숨김 (Visibility로 깜빡임 방지)
            Positioned.fill(
              left: leftInset,
              right: rightInset,
              child: Visibility(
                visible: !isNarrowCommentFullscreen,
                maintainState: true,
                child: mainContent,
              ),
            ),

            // 채널 네비게이션 (좌측)
            if (showChannelNavigation)
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: _buildChannelNavigation(
                  ref: ref,
                  channelBarWidth: channelBarWidth,
                ),
              ),

            // 댓글 슬라이드 패널 (우측)
            if (showComments)
              Positioned.fill(
                left: leftInset, // 채널바 제외
                child: SlidePanel(
                  isVisible: showComments,
                  onDismiss: () =>
                      ref.read(workspaceStateProvider.notifier).hideComments(),
                  showBackdrop:
                      !isNarrowCommentFullscreen, // Narrow desktop 전체 화면에서는 백드롭 없음
                  width: isNarrowCommentFullscreen ? null : commentBarWidth,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        left: BorderSide(
                          color: AppColors.lightOutline,
                          width: 1,
                        ),
                      ),
                    ),
                    child: commentsView,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// 채널 네비게이션 빌드
  Widget _buildChannelNavigation({
    required WidgetRef ref,
    required double channelBarWidth,
  }) {
    // currentGroupNameProvider로 그룹 이름 가져오기
    final currentGroupName = ref.watch(currentGroupNameProvider);
    final channels = ref.watch(workspaceChannelsProvider);
    final selectedChannelId = ref.watch(currentChannelIdProvider);
    final hasAnyGroupPermission = ref.watch(
      workspaceHasAnyGroupPermissionProvider,
    );
    final unreadCounts = ref.watch(workspaceUnreadCountsProvider);
    final currentGroupId = ref.watch(currentGroupIdProvider);

    return ChannelNavigation(
      width: channelBarWidth,
      channels: channels,
      selectedChannelId: selectedChannelId,
      hasAnyGroupPermission: hasAnyGroupPermission,
      unreadCounts: unreadCounts,
      isVisible: true,
      currentGroupId: currentGroupId,
      currentGroupName: currentGroupName,
    );
  }
}
