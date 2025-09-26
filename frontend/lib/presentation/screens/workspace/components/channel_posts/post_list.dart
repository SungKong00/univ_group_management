import 'package:flutter/material.dart';
import '../../../../data/models/workspace_models.dart';
import '../../../providers/workspace_provider.dart';
import '../../../providers/channel_provider.dart';
import '../../../providers/ui_state_provider.dart';
import '../../utils/channel_helpers.dart';
import 'post_bubble.dart';

class PostList extends StatelessWidget {
  final List<PostModel> posts;
  final WorkspaceProvider workspaceProvider;
  final ChannelProvider channelProvider;
  final UIStateProvider uiStateProvider;
  final ScrollController scrollController;
  final EdgeInsets contentPadding;
  final void Function(PostModel post)? onCommentsTap;

  const PostList({
    super.key,
    required this.posts,
    required this.workspaceProvider,
    required this.channelProvider,
    required this.uiStateProvider,
    required this.scrollController,
    this.contentPadding = const EdgeInsets.all(16),
    this.onCommentsTap,
  });

  @override
  Widget build(BuildContext context) {
    final groupedPosts = ChannelHelpers.groupPostsByDate(posts);

    return ListView.builder(
      controller: scrollController,
      padding: contentPadding,
      itemCount: groupedPosts.length,
      itemBuilder: (context, index) {
        final group = groupedPosts[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DateHeader(date: group.date),
            ...group.posts.map((post) => PostBubble(
                  post: post,
                  workspaceProvider: workspaceProvider,
                  channelProvider: channelProvider,
                  uiStateProvider: uiStateProvider,
                  onCommentsTap: onCommentsTap,
                )),
          ],
        );
      },
    );
  }
}

class DateHeader extends StatelessWidget {
  final String date;

  const DateHeader({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              date,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}
