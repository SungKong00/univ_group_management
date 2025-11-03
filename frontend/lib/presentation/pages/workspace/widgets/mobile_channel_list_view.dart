import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/workspace_state_provider.dart';
import '../../../providers/current_group_provider.dart';
import '../../../widgets/workspace/mobile_channel_list.dart';

/// Mobile channel list view wrapper
///
/// Wraps MobileChannelList with necessary provider watches
class MobileChannelListView extends ConsumerWidget {
  const MobileChannelListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(workspaceChannelsProvider);
    final selectedChannelId = ref.watch(currentChannelIdProvider);
    final hasAnyGroupPermission = ref.watch(
      workspaceHasAnyGroupPermissionProvider,
    );
    final unreadCounts = ref.watch(workspaceUnreadCountsProvider);
    final currentGroupId = ref.watch(currentGroupIdProvider);
    final currentGroupName = ref.watch(currentGroupNameProvider);

    return MobileChannelList(
      channels: channels,
      selectedChannelId: selectedChannelId,
      hasAnyGroupPermission: hasAnyGroupPermission,
      unreadCounts: unreadCounts,
      currentGroupId: currentGroupId,
      currentGroupName: currentGroupName,
    );
  }
}
