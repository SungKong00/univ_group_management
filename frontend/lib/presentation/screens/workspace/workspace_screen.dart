import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workspace_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../../data/models/workspace_models.dart';
import 'channel_detail_screen.dart';
import 'tabs/announcements_tab.dart';
import 'tabs/channels_tab.dart';
import 'tabs/members_tab.dart';
import 'member_management_screen.dart';
import 'channel_management_screen.dart';
import 'group_info_screen.dart';
import 'admin_home_screen.dart';
import '../groups/group_explorer_screen.dart';
import 'widgets/workspace_sidebar.dart';
import 'widgets/workspace_header.dart';
import 'widgets/announcements_view.dart';

class WorkspaceScreen extends StatefulWidget {
  final int groupId;
  final String? groupName;

  const WorkspaceScreen({
    super.key,
    required this.groupId,
    this.groupName,
  });

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  @override
  void initState() {
    super.initState();

    // 워크스페이스 데이터 로드 및 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WorkspaceProvider>();
      provider.reset();
      provider.loadWorkspace(widget.groupId);
    });
  }

  @override
  void dispose() {
    context.read<WorkspaceProvider>().exitChannel();
    super.dispose();
  }

  void _navigateToGroupExplorer() {
    context.read<WorkspaceProvider>().exitChannel();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GroupExplorerScreen()),
    );
  }

  void _navigateBack() {
    context.read<WorkspaceProvider>().exitChannel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceProvider>(
      builder: (context, workspaceProvider, child) {
        final workspace = workspaceProvider.currentWorkspace;
        final isDesktop = MediaQuery.of(context).size.width >= 900;

        return LoadingOverlay(
          isLoading: workspaceProvider.isLoading,
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            drawer: !isDesktop && workspace != null
                ? _buildMobileDrawer(context, workspaceProvider, workspace)
                : null,
            body: workspace == null
                ? _buildEmptyState(workspaceProvider)
                : isDesktop
                    ? _buildDesktopWorkspace(context, workspaceProvider, workspace)
                    : _buildMobileWorkspace(context, workspaceProvider, workspace),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(WorkspaceProvider provider) {
    if (provider.isAccessDenied) {
      return _buildAccessDeniedState(provider);
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '워크스페이스를 불러올 수 없습니다',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              provider.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.loadWorkspace(widget.groupId),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final ok = await provider.requestJoin(widget.groupId);
                if (!mounted) return;
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('가입 신청이 접수되었습니다')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('가입 신청에 실패했습니다')),
                  );
                }
              },
              icon: const Icon(Icons.login),
              label: const Text('가입 신청하기'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('돌아가기'),
            ),
          ],
        ),
      );
    }

    return const Center(
      child: Text('워크스페이스를 로드 중입니다...'),
    );
  }

  Widget _buildAccessDeniedState(WorkspaceProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '워크스페이스를 불러올 수 없습니다',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? '이 그룹의 워크스페이스는 멤버만 접근할 수 있습니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final ok = await provider.requestJoin(widget.groupId);
                if (!mounted) return;
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('가입 신청이 접수되었습니다')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('가입 신청에 실패했습니다')),
                  );
                }
              },
              icon: const Icon(Icons.login),
              label: const Text('가입 신청하기'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('돌아가기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopWorkspace(
    BuildContext context,
    WorkspaceProvider provider,
    WorkspaceDetailModel workspace,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = provider.isSidebarVisible;
        final isOverlaySidebar = constraints.maxWidth < 900;
        const double sidebarWidth = 280;

        return Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(
                left: !isOverlaySidebar && showSidebar ? sidebarWidth : 0,
              ),
              child: _buildDesktopMainArea(context, provider, workspace),
            ),
            if (showSidebar) ...[
              if (isOverlaySidebar) ...[
                // 작은 화면: 오버레이 배경
                GestureDetector(
                  onTap: () => provider.setSidebarVisible(false),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
                // 작은 화면: 사이드바 본체
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: sidebarWidth,
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(2, 0),
                        ),
                      ],
                    ),
                    child: WorkspaceSidebar(
                      workspace: workspace,
                      onShowAdminHome: () => _showAdminHome(context, workspace),
                      onShowMemberManagement: () => _showMemberManagement(context),
                      onShowChannelManagement: () => _showChannelManagement(context),
                      onShowGroupInfo: () => _showGroupInfo(context),
                    ),
                  ),
                ),
              ] else ...[
                // 큰 화면: 고정 사이드바
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: WorkspaceSidebar(
                    workspace: workspace,
                    onShowAdminHome: () => _showAdminHome(context, workspace),
                    onShowMemberManagement: () => _showMemberManagement(context),
                    onShowChannelManagement: () => _showChannelManagement(context),
                    onShowGroupInfo: () => _showGroupInfo(context),
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }



  Widget _buildDesktopMainArea(
    BuildContext context,
    WorkspaceProvider provider,
    WorkspaceDetailModel workspace,
  ) {
    final channel = provider.currentChannel;
    return Column(
      children: [
        WorkspaceHeader(
          workspace: workspace,
          channel: channel,
          onBack: _navigateBack,
          onShowMembers: () => _showMembersSheet(context, workspace),
          onShowChannelInfo: channel != null ? () => _showChannelInfo(context, channel) : null,
          onShowManagement: () => _showManagementMenu(context, workspace),
        ),
        Expanded(
          child: channel == null
              ? AnnouncementsView(
                  workspace: workspace,
                  announcements: provider.announcements,
                  onCreateAnnouncement: workspace.canCreateAnnouncements ? () => _showCreateAnnouncementDialog(context) : null,
                )
              : ChannelDetailView(
                  channel: channel,
                  autoLoad: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
        ),
      ],
    );
  }



  IconData _channelIconFor(ChannelModel channel) {
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

  Drawer _buildMobileDrawer(
    BuildContext context,
    WorkspaceProvider provider,
    WorkspaceDetailModel workspace,
  ) {
    final selectedChannelId = provider.currentChannel?.id;
    final channels = provider.channels;

    Widget buildTile({
      required IconData icon,
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      final theme = Theme.of(context);
      final color = selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
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

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  workspace.group.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // 공지사항 (기본)
                  buildTile(
                    icon: Icons.campaign,
                    label: '공지사항',
                    selected: selectedChannelId == null,
                    onTap: () => provider.exitChannel(),
                  ),
                  const Divider(),
                  // 채널 목록
                  ...channels.map(
                    (channel) => buildTile(
                      icon: _channelIconFor(channel),
                      label: channel.name,
                      selected: selectedChannelId == channel.id,
                      onTap: () => provider.selectChannel(channel),
                    ),
                  ),
                  const Divider(),
                  if (workspace.canManageMembers)
                    buildTile(
                      icon: Icons.people_outline,
                      label: '멤버 관리',
                      selected: false,
                      onTap: () => _showMemberManagement(context),
                    ),
                  if (workspace.canManageChannels)
                    buildTile(
                      icon: Icons.tag,
                      label: '채널 관리',
                      selected: false,
                      onTap: () => _showChannelManagement(context),
                    ),
                  buildTile(
                    icon: Icons.info_outline,
                    label: '그룹 정보',
                    selected: false,
                    onTap: () => _showGroupInfo(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMembersSheet(BuildContext context, WorkspaceDetailModel workspace) {
    final provider = context.read<WorkspaceProvider>();
    final members = provider.members;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '멤버 ${members.length}명',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: members.isEmpty
                    ? const Center(child: Text('등록된 멤버가 없습니다'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final roleName = member.role.name;
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              child: Text(member.user.name.isNotEmpty ? member.user.name[0] : '?'),
                            ),
                            title: Text(member.user.name),
                            subtitle: Text(roleName),
                            trailing: Text(
                              _formatDate(member.joinedAt),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChannelInfo(BuildContext context, ChannelModel channel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              channel.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text('유형: ${channel.typeDisplayName}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text('생성자: ${channel.createdBy.name}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text('생성일: ${_formatDateTime(channel.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
            if (channel.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              Text(
                channel.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }


  void _showCreateAnnouncementDialog(BuildContext context) {
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공지사항 작성'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: contentController,
            decoration: const InputDecoration(
              labelText: '내용',
              border: OutlineInputBorder(),
            ),
            maxLines: 6,
            maxLength: 1000,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final content = contentController.text.trim();
              if (content.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('내용을 입력해주세요')),
                );
                return;
              }

              Navigator.pop(context);
              final provider = context.read<WorkspaceProvider>();
              final announcementChannel = _findAnnouncementChannel(provider.channels);

              if (announcementChannel == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('공지 채널을 찾을 수 없습니다')),
                );
                return;
              }

              await provider.createPost(
                channelId: announcementChannel.id,
                content: content,
                type: PostType.announcement,
              );
            },
            child: const Text('작성'),
          ),
        ],
      ),
    );
  }

  ChannelModel? _findAnnouncementChannel(List<ChannelModel> channels) {
    for (final channel in channels) {
      if (channel.type == ChannelType.announcement) {
        return channel;
      }
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    final datePart = _formatDate(date);
    final timePart = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$datePart $timePart';
  }

  Widget _buildMobileWorkspace(
    BuildContext context,
    WorkspaceProvider provider,
    WorkspaceDetailModel workspace,
  ) {
    final channel = provider.currentChannel;
    return Scaffold(
      appBar: _buildMobileAppBar(context, workspace),
      drawer: _buildMobileDrawer(context, provider, workspace),
      body: channel == null
          ? AnnouncementsView(
              workspace: workspace,
              announcements: provider.announcements,
              onCreateAnnouncement: workspace.canCreateAnnouncements ? () => _showCreateAnnouncementDialog(context) : null,
            )
          : ChannelDetailView(
              channel: channel,
              autoLoad: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
    );
  }

  AppBar _buildMobileAppBar(BuildContext context, WorkspaceDetailModel workspace) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 1,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          tooltip: '메뉴',
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            workspace.group.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          if (workspace.myMembership != null)
            Text(
              _roleDisplayName(workspace.myMembership!.role.name),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      actions: [
        if (workspace.canManage)
          IconButton(
            onPressed: () => _showManagementMenu(context, workspace),
            icon: const Icon(Icons.settings),
            tooltip: '관리',
          ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: '닫기',
        ),
      ],
    );
  }

  Widget _buildOldAppBar(BuildContext context, WorkspaceDetailModel workspace) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 112, // 두 개의 아이콘을 위한 충분한 공간
      leading: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: '메뉴',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            tooltip: '뒤로가기',
          ),
        ],
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            workspace.group.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          if (workspace.myMembership != null)
            Text(
              _roleDisplayName(workspace.myMembership!.role.name),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      actions: [
        if (workspace.canManage)
          IconButton(
            onPressed: () => _showManagementMenu(context, workspace),
            icon: const Icon(Icons.settings),
            tooltip: '관리',
          ),
      ],
    );
  }


  void _showManagementMenu(
    BuildContext context,
    WorkspaceDetailModel workspace,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '그룹 관리',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (workspace.canManageMembers) ...[
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('멤버 관리'),
                subtitle: const Text('멤버 승인/반려, 역할 변경'),
                onTap: () {
                  Navigator.pop(context);
                  _showMemberManagement(context);
                },
              ),
            ],
            if (workspace.canManageChannels) ...[
              ListTile(
                leading: const Icon(Icons.tag),
                title: const Text('채널 관리'),
                subtitle: const Text('채널 생성, 수정, 삭제'),
                onTap: () {
                  Navigator.pop(context);
                  _showChannelManagement(context);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('그룹 정보'),
              subtitle: const Text('그룹 설정 및 정보 수정'),
              onTap: () {
                Navigator.pop(context);
                _showGroupInfo(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAdminHome(BuildContext context, WorkspaceDetailModel workspace) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminHomeScreen(workspace: workspace),
      ),
    );
  }

  void _showMemberManagement(BuildContext context) {
    final workspace = context.read<WorkspaceProvider>().currentWorkspace;
    if (workspace != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MemberManagementScreen(workspace: workspace),
        ),
      );
    }
  }

  void _showChannelManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChannelManagementScreen(),
      ),
    );
  }

  void _showGroupInfo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GroupInfoScreen(),
      ),
    );
  }

  String _roleDisplayName(String roleName) {
    switch (roleName.toUpperCase()) {
      case 'OWNER':
        return '그룹장';
      case 'ADVISOR':
        return '지도교수';
      default:
        return roleName;
    }
  }
}


