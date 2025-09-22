import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../providers/channel_provider.dart';
import '../../../providers/ui_state_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../../data/models/workspace_models.dart';
import '../utils/workspace_helpers.dart';

class WorkspaceMobileNavigator extends StatelessWidget {
  final WorkspaceDetailModel workspace;
  final VoidCallback onShowAdminHome;
  final VoidCallback onShowMemberManagement;
  final VoidCallback onShowChannelManagement;
  final VoidCallback onShowGroupInfo;

  const WorkspaceMobileNavigator({
    super.key,
    required this.workspace,
    required this.onShowAdminHome,
    required this.onShowMemberManagement,
    required this.onShowChannelManagement,
    required this.onShowGroupInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<WorkspaceProvider, ChannelProvider, UIStateProvider>(
      builder: (context, workspaceProvider, channelProvider, uiStateProvider, child) {
        final channels = workspaceProvider.channels;
        final theme = Theme.of(context);
        final showNavigator = uiStateProvider.isMobileNavigatorVisible;

        return SafeArea(
          bottom: false,
          child: Container(
            color: AppTheme.surface,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              children: [
                _buildHeader(context, theme),
                _buildGroupMenuSection(context),
                _buildChannelsSection(context, channels, channelProvider, uiStateProvider, showNavigator),
                if (workspace.canManageMembers || workspace.canManageChannels)
                  _buildAdminSection(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workspace.group.name,
            style: theme.textTheme.titleLarge,
          ),
          if (workspace.myMembership != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                WorkspaceHelpers.roleDisplayName(workspace.myMembership!.role.name),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupMenuSection(BuildContext context) {
    return _buildNavigatorSection(
      context,
      title: '그룹 메뉴',
      children: [
        _buildNavigatorItem(
          context,
          icon: Icons.home_outlined,
          label: '그룹 홈',
          selected: false,
          onTap: () => _showComingSoon(context),
        ),
        _buildNavigatorItem(
          context,
          icon: Icons.calendar_today_outlined,
          label: '그룹 캘린더',
          selected: false,
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }

  Widget _buildChannelsSection(
    BuildContext context,
    List<ChannelModel> channels,
    ChannelProvider channelProvider,
    UIStateProvider uiStateProvider,
    bool showNavigator,
  ) {
    return _buildNavigatorSection(
      context,
      title: 'Channels',
      children: [
        ...channels.map(
          (channel) => _buildNavigatorItem(
            context,
            icon: WorkspaceHelpers.channelIconFor(channel),
            label: channel.name,
            selected: !showNavigator &&
                channelProvider.currentChannel?.id == channel.id,
            onTap: () => _openMobileChannel(channelProvider, channel, context),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return _buildNavigatorSection(
      context,
      title: '관리자 기능',
      children: [
        _buildNavigatorItem(
          context,
          icon: Icons.admin_panel_settings,
          label: '관리자 홈',
          selected: false,
          onTap: onShowAdminHome,
        ),
        if (workspace.canManageMembers)
          _buildNavigatorItem(
            context,
            icon: Icons.people_outline,
            label: '멤버 관리',
            selected: false,
            onTap: onShowMemberManagement,
          ),
        if (workspace.canManageChannels)
          _buildNavigatorItem(
            context,
            icon: Icons.tag,
            label: '채널 관리',
            selected: false,
            onTap: onShowChannelManagement,
          ),
        _buildNavigatorItem(
          context,
          icon: Icons.info_outline,
          label: '그룹 정보',
          selected: false,
          onTap: onShowGroupInfo,
        ),
      ],
    );
  }

  Widget _buildNavigatorSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNavigatorItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final highlightColor = selected ? AppTheme.background : Colors.transparent;
    final iconColor = selected ? AppTheme.primary : AppTheme.onTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: highlightColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selected)
                  Icon(Icons.chevron_right,
                      size: 18, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMobileChannel(
    ChannelProvider channelProvider,
    ChannelModel channel,
    BuildContext context,
  ) async {
    await channelProvider.selectChannel(channel);
    if (!context.mounted) return;
    context.read<UIStateProvider>().setMobileNavigatorVisible(false);
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('준비 중인 기능입니다.')),
    );
  }
}