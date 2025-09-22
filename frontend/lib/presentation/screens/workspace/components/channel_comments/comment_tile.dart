import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../../data/models/workspace_models.dart';
import '../../../providers/workspace_provider.dart';
import '../../../providers/channel_provider.dart';
import '../../../providers/ui_state_provider.dart';
import '../../utils/channel_helpers.dart';

class CommentTile extends StatelessWidget {
  final CommentModel comment;
  final WorkspaceProvider workspaceProvider;
  final ChannelProvider channelProvider;
  final UIStateProvider uiStateProvider;

  const CommentTile({
    super.key,
    required this.comment,
    required this.workspaceProvider,
    required this.channelProvider,
    required this.uiStateProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.commentSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommentHeader(context),
          const SizedBox(height: 12),
          _buildCommentContent(context),
        ],
      ),
    );
  }

  Widget _buildCommentHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: ResponsiveBreakpoints.commentAvatarSize / 2,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            comment.author.name.isNotEmpty ? comment.author.name[0] : '?',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.author.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                ChannelHelpers.formatTimestamp(comment.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        _buildCommentMenu(context),
      ],
    );
  }

  Widget _buildCommentContent(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(UIConstants.commentBorderRadius),
      ),
      child: Text(
        comment.content,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildCommentMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit),
              SizedBox(width: 8),
              Text('수정'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete),
              SizedBox(width: 8),
              Text('삭제'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'delete') {
          _deleteComment(context);
        } else if (value == 'edit') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('댓글 수정 기능은 준비 중입니다')),
          );
        }
      },
    );
  }

  void _deleteComment(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('정말로 이 댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final postId = uiStateProvider.selectedPostForComments?.id;
              if (postId == null) return;
              try {
                await channelProvider.deleteComment(comment.id, postId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('댓글이 삭제되었습니다')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('댓글 삭제 실패: $e')),
                  );
                }
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}