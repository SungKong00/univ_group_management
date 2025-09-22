import 'package:flutter/material.dart';
import '../../../../data/models/workspace_models.dart';
import '../../utils/channel_helpers.dart';

class PostEmptyState extends StatelessWidget {
  final ChannelModel channel;

  const PostEmptyState({
    super.key,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            ChannelHelpers.getChannelIcon(channel.type),
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 메시지가 없습니다',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 메시지를 남겨보세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}