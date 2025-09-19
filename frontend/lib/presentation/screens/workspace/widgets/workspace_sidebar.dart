import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../../data/models/workspace_models.dart';

class WorkspaceSidebar extends StatelessWidget {
  final WorkspaceDetailModel workspace;
  final double width;
  final VoidCallback? onShowAdminHome;
  final VoidCallback? onShowMemberManagement;
  final VoidCallback? onShowChannelManagement;
  final VoidCallback? onShowGroupInfo;
  final VoidCallback? onShowGroupHome;
  final VoidCallback? onShowGroupCalendar;

  const WorkspaceSidebar({
    super.key,
    required this.workspace,
    this.width = 280,
    this.onShowAdminHome,
    this.onShowMemberManagement,
    this.onShowChannelManagement,
    this.onShowGroupInfo,
    this.onShowGroupHome,
    this.onShowGroupCalendar,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceProvider>(
      builder: (context, provider, child) {
        final selectedChannelId = provider.currentChannel?.id;
        final channels = provider.channels;

        return Container(
          width: width,
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(
              right: BorderSide(color: AppTheme.border),
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
            children: [
              _buildSection(
                context,
                title: '그룹 메뉴',
                children: [
                  _buildSidebarItem(
                    context,
                    icon: Icons.home_outlined,
                    label: '그룹 홈',
                    selected: false,
                    onTap: onShowGroupHome ?? () => _showComingSoon(context),
                  ),
                  _buildSidebarItem(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: '그룹 캘린더',
                    selected: false,
                    onTap: onShowGroupCalendar ?? () => _showComingSoon(context),
                  ),
                ],
              ),
              _buildSection(
                context,
                title: 'Channels',
                children: [
                  ...channels.map(
                    (channel) => _buildSidebarItem(
                      context,
                      icon: _getChannelIcon(channel),
                      label: channel.name,
                      selected: selectedChannelId == channel.id,
                      onTap: () => provider.selectChannel(channel),
                    ),
                  ),
                ],
              ),
              if (workspace.canManageMembers || workspace.canManageChannels)
                _buildSection(
                  context,
                  title: '관리자 기능',
                  children: [
                    _buildSidebarItem(
                      context,
                      icon: Icons.admin_panel_settings,
                      label: '관리자 홈',
                      selected: false,
                      onTap: onShowAdminHome ?? () {},
                    ),
                    if (workspace.canManageMembers)
                      _buildSidebarItem(
                        context,
                        icon: Icons.people_outline,
                        label: '멤버 관리',
                        selected: false,
                        onTap: onShowMemberManagement ?? () {},
                      ),
                    if (workspace.canManageChannels)
                      _buildSidebarItem(
                        context,
                        icon: Icons.tag,
                        label: '채널 관리',
                        selected: false,
                        onTap: onShowChannelManagement ?? () {},
                      ),
                    _buildSidebarItem(
                      context,
                      icon: Icons.info_outline,
                      label: '그룹 정보',
                      selected: false,
                      onTap: onShowGroupInfo ?? () {},
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildSection(
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

  Widget _buildSidebarItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final highlightColor = selected ? AppTheme.background : Colors.transparent;
    final iconColor = selected ? AppTheme.primary : AppTheme.onTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: highlightColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getChannelIcon(ChannelModel channel) {
    switch (channel.type) {
      case ChannelType.text:
        return Icons.chat_bubble_outline;
      case ChannelType.voice:
        return Icons.mic_none;
      case ChannelType.announcement:
        return Icons.campaign;
      case ChannelType.fileShare:
        return Icons.folder_copy_outlined;
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('구현 예정입니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

}