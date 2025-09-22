import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../providers/channel_provider.dart';
import '../../../providers/ui_state_provider.dart';
import '../../../../data/models/workspace_models.dart';
import '../../utils/channel_helpers.dart';

class ChannelAppBarTitle extends StatelessWidget {
  final ChannelModel channel;

  const ChannelAppBarTitle({
    super.key,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              ChannelHelpers.getChannelIcon(channel.type),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                channel.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        if (channel.description != null)
          Text(
            channel.description!,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class CommentsAppBarTitle extends StatelessWidget {
  const CommentsAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<WorkspaceProvider, ChannelProvider, UIStateProvider>(
      builder: (context, workspaceProvider, channelProvider, uiStateProvider, child) {
        final groupName = workspaceProvider.currentWorkspace?.group.name ?? '그룹';
        final channelName = channelProvider.currentChannel?.name ?? '채널';
        final comments = channelProvider
            .getCommentsForPost(uiStateProvider.selectedPostForComments!.id);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$groupName > $channelName',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              '댓글 ${comments.length}개',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        );
      },
    );
  }
}