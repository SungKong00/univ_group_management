import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../../data/models/workspace_models.dart';
import '../../../providers/workspace_provider.dart';
import '../../../providers/channel_provider.dart';
import '../../../providers/ui_state_provider.dart';
import '../../utils/channel_helpers.dart';
import 'comment_tile.dart';

class CommentsView extends StatelessWidget {
  final ScrollController scrollController;
  final WorkspaceProvider workspaceProvider;
  final ChannelProvider channelProvider;
  final UIStateProvider uiStateProvider;

  const CommentsView({
    super.key,
    required this.scrollController,
    required this.workspaceProvider,
    required this.channelProvider,
    required this.uiStateProvider,
  });

  @override
  Widget build(BuildContext context) {
    final post = uiStateProvider.selectedPostForComments!;
    final comments = channelProvider.getCommentsForPost(post.id);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (comments.isEmpty) {
        channelProvider.loadPostComments(post.id);
      }
    });

    final scrollView = CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(child: PostPreview(post: post)),
        const SliverToBoxAdapter(child: Divider(height: 1)),
        if (comments.isEmpty)
          SliverFillRemaining(child: EmptyCommentsState())
        else
          SliverCommentsList(
            comments: comments,
            workspaceProvider: workspaceProvider,
            channelProvider: channelProvider,
            uiStateProvider: uiStateProvider,
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const double minContentWidth = 320;
        const double maxContentWidth = 640;
        final double effectiveMaxWidth =
            math.min(constraints.maxWidth, maxContentWidth);
        final double effectiveMinWidth =
            math.min(constraints.maxWidth, minContentWidth);

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: effectiveMinWidth,
              maxWidth: effectiveMaxWidth,
            ),
            child: scrollView,
          ),
        );
      },
    );
  }
}

class PostPreview extends StatelessWidget {
  final PostModel post;

  const PostPreview({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  post.author.name.isNotEmpty ? post.author.name[0] : '?',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                post.author.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                ChannelHelpers.formatTimestamp(post.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 60.0,
              maxHeight: 200.0,
            ),
            child: SingleChildScrollView(
              child: Text(
                post.content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SliverCommentsList extends StatelessWidget {
  final List<CommentModel> comments;
  final WorkspaceProvider workspaceProvider;
  final ChannelProvider channelProvider;
  final UIStateProvider uiStateProvider;

  const SliverCommentsList({
    super.key,
    required this.comments,
    required this.workspaceProvider,
    required this.channelProvider,
    required this.uiStateProvider,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final comment = comments[index];
            return CommentTile(
              comment: comment,
              workspaceProvider: workspaceProvider,
              channelProvider: channelProvider,
              uiStateProvider: uiStateProvider,
            );
          },
          childCount: comments.length,
        ),
      ),
    );
  }
}

class EmptyCommentsState extends StatelessWidget {
  const EmptyCommentsState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            '아직 댓글이 없습니다',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '첫 번째 댓글을 작성해보세요!',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}