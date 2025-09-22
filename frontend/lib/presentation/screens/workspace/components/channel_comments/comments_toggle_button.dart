import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../../data/models/workspace_models.dart';
import '../../../providers/workspace_provider.dart';
import '../../../providers/channel_provider.dart';
import '../../../providers/ui_state_provider.dart';
import '../../utils/channel_helpers.dart';

class CommentsToggleButton extends StatelessWidget {
  final PostModel post;
  final WorkspaceProvider workspaceProvider;
  final ChannelProvider channelProvider;
  final UIStateProvider uiStateProvider;

  const CommentsToggleButton({
    super.key,
    required this.post,
    required this.workspaceProvider,
    required this.channelProvider,
    required this.uiStateProvider,
  });

  @override
  Widget build(BuildContext context) {
    final comments = channelProvider.getCommentsForPost(post.id);
    final commentCount =
        comments.isNotEmpty ? comments.length : post.commentCount;

    String? lastCommentTime;
    if (comments.isNotEmpty) {
      lastCommentTime = ChannelHelpers.formatTimestamp(comments.last.createdAt);
    } else if (post.lastCommentedAt != null) {
      lastCommentTime = ChannelHelpers.formatTimestamp(post.lastCommentedAt!);
    }

    return Flexible(
      fit: FlexFit.loose,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mediaQuery = MediaQuery.of(context);
          final screenWidth = mediaQuery.size.width;
          final bool isMobile = screenWidth < ResponsiveBreakpoints.mobile;
          final bool isSidebarVisible =
              uiStateProvider.isCommentsSidebarVisible;

          double sidebarWidth = ResponsiveBreakpoints.commentsSidebarWidth;
          if (kIsWeb) {
            sidebarWidth = math.min(
              ResponsiveBreakpoints.commentsSidebarWidth,
              screenWidth * 0.4,
            );
          }

          double availableWidth = constraints.maxWidth;
          if (!availableWidth.isFinite) {
            availableWidth = screenWidth;
          }

          const double edgePadding = UIConstants.defaultPadding;
          if (availableWidth > edgePadding * 2) {
            availableWidth -= edgePadding;
          }

          final double desktopMinWidth = 200;
          final double mobileMinWidth = 160;
          final double mobileFixedWidth = 230;
          final double desktopMaxWidth =
              sidebarWidth + 200;

          double targetWidth;

          if (isMobile) {
            targetWidth = math.min(availableWidth, mobileFixedWidth);
            if (targetWidth < mobileMinWidth &&
                availableWidth >= mobileMinWidth) {
              targetWidth = mobileMinWidth;
            }
          } else {
            targetWidth = math.min(availableWidth, desktopMaxWidth);
            if (targetWidth < desktopMinWidth &&
                availableWidth >= desktopMinWidth) {
              targetWidth = desktopMinWidth;
            }

            if (availableWidth < desktopMinWidth) {
              targetWidth = availableWidth;
            }

            final double comfortableWidth =
                screenWidth - sidebarWidth - (edgePadding * 2);
            if (comfortableWidth.isFinite && comfortableWidth > 0) {
              targetWidth = math.min(targetWidth, comfortableWidth);
            }

            if (isSidebarVisible) {
              final double sidebarAdjustedWidth =
                  constraints.maxWidth - edgePadding;
              if (sidebarAdjustedWidth.isFinite && sidebarAdjustedWidth > 0) {
                targetWidth = math.min(targetWidth, sidebarAdjustedWidth);
              }
            }
          }

          if (targetWidth <= 0) {
            targetWidth = isMobile ? mobileMinWidth : desktopMinWidth;
          }

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: StatefulBuilder(
              builder: (context, setState) {
                bool isHovered = false;

                return Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: targetWidth,
                    child: InkWell(
                      onTap: () => _handleCommentsAction(context),
                      onHover: (hovered) => setState(() => isHovered = hovered),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: isHovered
                              ? Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.3),
                                )
                              : null,
                          color: isHovered
                              ? Theme.of(context)
                                  .colorScheme
                                  .surfaceVariant
                                  .withOpacity(0.5)
                              : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                commentCount > 0
                                    ? '$commentCount개의 댓글${lastCommentTime != null ? (isHovered ? ' • 펼치기' : ' • $lastCommentTime') : ''}'
                                    : (isHovered ? '댓글 펼치기' : '댓글 작성하기'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleCommentsAction(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final useSidebar = screenWidth >= ResponsiveBreakpoints.mobile;

    if (useSidebar) {
      uiStateProvider.showCommentsSidebar(post);
    } else {
      uiStateProvider.showCommentsSidebar(post);
    }
  }
}