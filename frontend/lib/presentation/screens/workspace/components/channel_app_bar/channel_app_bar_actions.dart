import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/channel_provider.dart';
import '../../../../data/models/workspace_models.dart';

class ChannelAppBarActions extends StatelessWidget {
  final ChannelModel channel;

  const ChannelAppBarActions({
    super.key,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChannelProvider>(
      builder: (context, channelProvider, child) {
        final canWrite = channelProvider.canWriteInCurrentChannel;

        return IconButton(
          key: Key('channel_permission_button_${channel.id}'),
          onPressed: () {
            channelProvider.toggleChannelWritePermission(channel.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  canWrite
                    ? '글 작성 권한이 제거되었습니다 (데모용)'
                    : '글 작성 권한이 부여되었습니다 (데모용)',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          icon: Icon(
            canWrite ? Icons.lock_open : Icons.lock,
            color: canWrite ? Colors.green : Colors.red,
          ),
          tooltip: '',
        );
      },
    );
  }
}