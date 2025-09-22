import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../providers/channel_provider.dart';
import '../../../../data/models/workspace_models.dart';
import '../utils/workspace_helpers.dart';

class WorkspaceMobileDrawer extends StatelessWidget {
  final WorkspaceDetailModel workspace;
  final VoidCallback onShowMemberManagement;
  final VoidCallback onShowChannelManagement;
  final VoidCallback onShowGroupInfo;

  const WorkspaceMobileDrawer({
    super.key,
    required this.workspace,
    required this.onShowMemberManagement,
    required this.onShowChannelManagement,
    required this.onShowGroupInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<WorkspaceProvider, ChannelProvider>(
      builder: (context, workspaceProvider, channelProvider, child) {
        final selectedChannelId = channelProvider.currentChannel?.id;
        final channels = workspaceProvider.channels;

        return Drawer(
          child: SafeArea(
            child: Column(
              children: [
                _buildDrawerHeader(context),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // 채널 목록
                      ...channels.map(
                        (channel) => _buildDrawerTile(
                          context,
                          icon: WorkspaceHelpers.channelIconFor(channel),
                          label: channel.name,
                          selected: selectedChannelId == channel.id,
                          onTap: () => channelProvider.selectChannel(channel),
                        ),
                      ),
                      const Divider(),
                      if (workspace.canManageMembers)
                        _buildDrawerTile(
                          context,
                          icon: Icons.people_outline,
                          label: '멤버 관리',
                          selected: false,
                          onTap: onShowMemberManagement,
                        ),
                      if (workspace.canManageChannels)
                        _buildDrawerTile(
                          context,
                          icon: Icons.tag,
                          label: '채널 관리',
                          selected: false,
                          onTap: onShowChannelManagement,
                        ),
                      _buildDrawerTile(
                        context,
                        icon: Icons.info_outline,
                        label: '그룹 정보',
                        selected: false,
                        onTap: onShowGroupInfo,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          workspace.group.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: selected ? theme.colorScheme.primary : null,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: selected,
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }
}