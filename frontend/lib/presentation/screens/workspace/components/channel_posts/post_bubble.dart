import 'package:flutter/material.dart';
import '../../../../data/models/workspace_models.dart';
import '../../../providers/workspace_provider.dart';
import '../../../providers/channel_provider.dart';
import '../../../providers/ui_state_provider.dart';
import '../../utils/channel_helpers.dart';
import '../channel_comments/comments_toggle_button.dart';

class PostBubble extends StatelessWidget {
  final PostModel post;
  final WorkspaceProvider workspaceProvider;
  final ChannelProvider channelProvider;
  final UIStateProvider uiStateProvider;

  const PostBubble({
    super.key,
    required this.post,
    required this.workspaceProvider,
    required this.channelProvider,
    required this.uiStateProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(context),
          const SizedBox(height: 8),
          _buildPostContent(context),
          if (post.attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildAttachments(context),
          ],
          const SizedBox(height: 8),
          _buildPostActions(context),
        ],
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context) {
    return Row(
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
        const Spacer(),
        if (post.isPinned)
          Icon(
            Icons.push_pin,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
      ],
    );
  }

  Widget _buildPostContent(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        post.content,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildAttachments(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: post.attachments.map((attachment) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.attachment,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 4),
              Text(
                'File',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPostActions(BuildContext context) {
    return Row(
      children: [
        if (post.likeCount > 0) ...[
          _buildLikeButton(context),
          const SizedBox(width: 8),
        ],
        CommentsToggleButton(
          post: post,
          workspaceProvider: workspaceProvider,
          channelProvider: channelProvider,
          uiStateProvider: uiStateProvider,
        ),
      ],
    );
  }

  Widget _buildLikeButton(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.thumb_up,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '${post.likeCount}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}