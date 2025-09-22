import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../../data/models/workspace_models.dart';
import '../../../providers/workspace_provider.dart';
import '../../../providers/channel_provider.dart';
import '../../../providers/ui_state_provider.dart';
import '../../../widgets/loading_overlay.dart';
import '../widgets/comments_sidebar.dart';
import '../components/channel_posts/post_list.dart';
import '../components/channel_posts/post_empty_state.dart';
import '../components/channel_composer/message_composer.dart';
import '../components/channel_comments/comments_view.dart';

class ChannelDesktopLayout extends StatelessWidget {
  final ChannelModel channel;
  final List<PostModel> posts;
  final WorkspaceProvider workspaceProvider;
  final ChannelProvider channelProvider;
  final UIStateProvider uiStateProvider;
  final ScrollController scrollController;
  final EdgeInsets contentPadding;
  final bool showLoadingOverlay;

  const ChannelDesktopLayout({
    super.key,
    required this.channel,
    required this.posts,
    required this.workspaceProvider,
    required this.channelProvider,
    required this.uiStateProvider,
    required this.scrollController,
    this.contentPadding = const EdgeInsets.all(16),
    this.showLoadingOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCommentsSidebarVisible = uiStateProvider.isCommentsSidebarVisible;

    final mainContent = Column(
      children: [
        Expanded(
          child: posts.isEmpty
              ? PostEmptyState(channel: channel)
              : PostList(
                  posts: posts,
                  workspaceProvider: workspaceProvider,
                  channelProvider: channelProvider,
                  uiStateProvider: uiStateProvider,
                  scrollController: scrollController,
                  contentPadding: contentPadding,
                ),
        ),
        MessageComposer(
          channel: channel,
          workspaceProvider: workspaceProvider,
          channelProvider: channelProvider,
          uiStateProvider: uiStateProvider,
          scrollController: scrollController,
          isCommentComposer: false,
        ),
      ],
    );

    Widget content;
    if (isCommentsSidebarVisible) {
      content = Row(
        children: [
          Expanded(child: mainContent),
          TapRegion(
            onTapOutside: (_) => uiStateProvider.hideCommentsSidebar(),
            child: const CommentsSidebar(),
          ),
        ],
      );
    } else {
      content = mainContent;
    }

    if (showLoadingOverlay) {
      return LoadingOverlay(
        isLoading: workspaceProvider.isLoading,
        child: content,
      );
    }
    return content;
  }
}

class ChannelMobilePostLayout extends StatelessWidget {
  final ChannelModel channel;
  final List<PostModel> posts;
  final WorkspaceProvider workspaceProvider;
  final ChannelProvider channelProvider;
  final UIStateProvider uiStateProvider;
  final ScrollController scrollController;
  final EdgeInsets contentPadding;
  final bool showLoadingOverlay;

  const ChannelMobilePostLayout({
    super.key,
    required this.channel,
    required this.posts,
    required this.workspaceProvider,
    required this.channelProvider,
    required this.uiStateProvider,
    required this.scrollController,
    this.contentPadding = const EdgeInsets.all(16),
    this.showLoadingOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Expanded(
          child: posts.isEmpty
              ? PostEmptyState(channel: channel)
              : PostList(
                  posts: posts,
                  workspaceProvider: workspaceProvider,
                  channelProvider: channelProvider,
                  uiStateProvider: uiStateProvider,
                  scrollController: scrollController,
                  contentPadding: contentPadding,
                ),
        ),
        MessageComposer(
          channel: channel,
          workspaceProvider: workspaceProvider,
          channelProvider: channelProvider,
          uiStateProvider: uiStateProvider,
          scrollController: scrollController,
          isCommentComposer: false,
        ),
      ],
    );

    if (showLoadingOverlay) {
      return LoadingOverlay(
        isLoading: workspaceProvider.isLoading,
        child: content,
      );
    }
    return content;
  }
}

class ChannelMobileCommentLayout extends StatelessWidget {
  final ChannelModel channel;
  final WorkspaceProvider workspaceProvider;
  final ChannelProvider channelProvider;
  final UIStateProvider uiStateProvider;
  final ScrollController scrollController;
  final bool showLoadingOverlay;

  const ChannelMobileCommentLayout({
    super.key,
    required this.channel,
    required this.workspaceProvider,
    required this.channelProvider,
    required this.uiStateProvider,
    required this.scrollController,
    this.showLoadingOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Expanded(
          child: CommentsView(
            scrollController: scrollController,
            workspaceProvider: workspaceProvider,
            channelProvider: channelProvider,
            uiStateProvider: uiStateProvider,
          ),
        ),
        MessageComposer(
          channel: channel,
          workspaceProvider: workspaceProvider,
          channelProvider: channelProvider,
          uiStateProvider: uiStateProvider,
          scrollController: scrollController,
          isCommentComposer: true,
        ),
      ],
    );

    if (showLoadingOverlay) {
      return LoadingOverlay(
        isLoading: workspaceProvider.isLoading,
        child: content,
      );
    }
    return content;
  }
}