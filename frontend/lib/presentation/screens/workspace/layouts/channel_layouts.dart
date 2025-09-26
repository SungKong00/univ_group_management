import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import '../components/channel_app_bar/channel_app_bar_title.dart';

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
    void handleCommentsTap(PostModel post) {
      uiStateProvider.showCommentsSidebar(post);
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (context) => ChannelMobileCommentPage(
            channel: channel,
            showLoadingOverlay: showLoadingOverlay,
          ),
        ),
      )
          .then((_) {
        final selected = uiStateProvider.selectedPostForComments;
        if (selected != null && selected.id == post.id) {
          uiStateProvider.hideCommentsSidebar();
        }
      });
    }

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
                  onCommentsTap: handleCommentsTap,
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

class ChannelMobileCommentPage extends StatefulWidget {
  final ChannelModel channel;
  final bool showLoadingOverlay;

  const ChannelMobileCommentPage({
    super.key,
    required this.channel,
    this.showLoadingOverlay = false,
  });

  @override
  State<ChannelMobileCommentPage> createState() => _ChannelMobileCommentPageState();
}

class _ChannelMobileCommentPageState extends State<ChannelMobileCommentPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<WorkspaceProvider, ChannelProvider, UIStateProvider>(
      builder: (context, workspaceProvider, channelProvider, uiStateProvider, child) {
        return WillPopScope(
          onWillPop: () async {
            if (uiStateProvider.selectedPostForComments != null) {
              uiStateProvider.hideCommentsSidebar();
            }
            return true;
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                key: const Key('comment_back_button'),
                icon: const Icon(Icons.arrow_back),
                tooltip: '',
                onPressed: () {
                  if (uiStateProvider.selectedPostForComments != null) {
                    uiStateProvider.hideCommentsSidebar();
                  }
                  Navigator.of(context).pop();
                },
              ),
              title: const CommentsAppBarTitle(),
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              elevation: 1,
            ),
            body: ChannelMobileCommentLayout(
              channel: widget.channel,
              workspaceProvider: workspaceProvider,
              channelProvider: channelProvider,
              uiStateProvider: uiStateProvider,
              scrollController: _scrollController,
              showLoadingOverlay: widget.showLoadingOverlay,
            ),
          ),
        );
      },
    );
  }
}
