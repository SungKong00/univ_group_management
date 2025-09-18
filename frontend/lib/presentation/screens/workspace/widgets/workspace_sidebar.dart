import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../../data/models/workspace_models.dart';

class WorkspaceSidebar extends StatelessWidget {
  final WorkspaceDetailModel workspace;
  final double width;

  const WorkspaceSidebar({
    super.key,
    required this.workspace,
    this.width = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceProvider>(
      builder: (context, provider, child) {
        final selectedChannelId = provider.currentChannel?.id;
        final channels = provider.channels;

        return Container(
          width: width,
          color: AppTheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, provider),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
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
                              onTap: () => _showAdminHome(context),
                            ),
                            if (workspace.canManageMembers)
                              _buildSidebarItem(
                                context,
                                icon: Icons.people_outline,
                                label: '멤버 관리',
                                selected: false,
                                onTap: () => _showMemberManagement(context),
                              ),
                            if (workspace.canManageChannels)
                              _buildSidebarItem(
                                context,
                                icon: Icons.tag,
                                label: '채널 관리',
                                selected: false,
                                onTap: () => _showChannelManagement(context),
                              ),
                            _buildSidebarItem(
                              context,
                              icon: Icons.info_outline,
                              label: '그룹 정보',
                              selected: false,
                              onTap: () => _showGroupInfo(context),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, WorkspaceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppTheme.border),
          bottom: BorderSide(color: AppTheme.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              workspace.group.name,
              style: Theme.of(context).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: provider.toggleSidebar,
            icon: const Icon(Icons.close, size: 20),
            tooltip: '사이드바 닫기',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: highlightColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  void _showAdminHome(BuildContext context) {
    // 관리자 홈으로 이동 (구현 필요)
  }

  void _showMemberManagement(BuildContext context) {
    // 멤버 관리 화면으로 이동 (구현 필요)
  }

  void _showChannelManagement(BuildContext context) {
    // 채널 관리 화면으로 이동 (구현 필요)
  }

  void _showGroupInfo(BuildContext context) {
    // 그룹 정보 화면으로 이동 (구현 필요)
  }
}