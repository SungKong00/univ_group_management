import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workspace_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/global_sidebar.dart';
import '../../theme/app_theme.dart';
import '../../../data/models/workspace_models.dart';
import 'channel_detail_screen.dart';
import 'tabs/channels_tab.dart';
import 'tabs/members_tab.dart';
import 'member_management_screen.dart';
import 'channel_management_screen.dart';
import 'group_info_screen.dart';
import 'admin_home_screen.dart';
import 'widgets/workspace_sidebar.dart';

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
  bool _hasInitialized = false;
  double? _previousWidth;
  WorkspaceProvider? _workspaceProvider;

  @override
  void initState() {
    super.initState();

    // 워크스페이스 데이터 로드 및 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<WorkspaceProvider>();
      _workspaceProvider = provider; // Provider 인스턴스 저장
      provider.reset();

      final isDesktop = MediaQuery.of(context).size.width >= 900;

      provider.loadWorkspace(
        widget.groupId,
        autoSelectFirstChannel: isDesktop,
        mobileNavigatorVisible: !isDesktop,
      ).then((_) {
        if (mounted) {
          provider.markAsInitialLoadComplete();
          _hasInitialized = true;
        }
      });
    });
  }

  @override
  void dispose() {
    // 안전한 dispose: 저장된 provider 인스턴스 사용
    _workspaceProvider?.exitChannel();
    super.dispose();
  }

  void _handleScreenSizeChange(double currentWidth, WorkspaceProvider provider) {
    // 초기 설정: 이전 너비가 없으면 현재 너비로 설정하고 종료
    if (_previousWidth == null) {
      _previousWidth = currentWidth;
      if (kDebugMode) {
        print('[반응형] 초기 화면 너비 설정: ${currentWidth.toInt()}px');
      }
      return;
    }

    final wasDesktop = _previousWidth! >= 900;
    final isNowDesktop = currentWidth >= 900;
    final isNowMobile = !isNowDesktop;

    // 화면 크기가 실제로 변경되었고, 데스크톱 ↔ 모바일 간 전환이 일어났을 때만 처리
    if (wasDesktop != isNowDesktop) {
      if (kDebugMode) {
        print('[반응형] 화면 전환 감지: ${wasDesktop ? "데스크톱" : "모바일"} → ${isNowDesktop ? "데스크톱" : "모바일"} (${currentWidth.toInt()}px)');
      }

      // 초기화가 완료된 경우에만 실제 반응형 전환 수행
      if (_hasInitialized) {
        provider.handleResponsiveTransition(isNowMobile);
        if (kDebugMode) {
          print('[반응형] handleResponsiveTransition 호출됨: isNowMobile=$isNowMobile');
        }
      } else {
        if (kDebugMode) {
          print('[반응형] 초기화 미완료로 인해 전환 스킵');
        }
      }
    }

    _previousWidth = currentWidth;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Consumer<WorkspaceProvider>(
          builder: (context, provider, child) {
            final workspace = provider.currentWorkspace;
            final currentWidth = constraints.maxWidth;
            final isDesktop = currentWidth >= 900;

            // 화면 크기 변경 감지 및 처리
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleScreenSizeChange(currentWidth, provider);
            });

            Widget body;
            if (workspace == null) {
              body = _buildEmptyState(provider);
            } else if (isDesktop) {
              body = _buildDesktopWorkspace(context, provider, workspace);
            } else {
              body = _buildMobileWorkspace(context, provider, workspace);
            }

            final scaffold = Scaffold(
              backgroundColor: Theme.of(context).colorScheme.background,
              drawer: !isDesktop && workspace != null
                  ? _buildMobileDrawer(context, provider, workspace)
                  : null,
              body: LoadingOverlay(
                isLoading: provider.isLoading,
                child: body,
              ),
            );

            if (isDesktop) {
              return scaffold;
            }

            // Mobile view uses WillPopScope for custom back navigation
            return WillPopScope(
              onWillPop: () async {
                // 1. If comment view is active, hide it.
                if (provider.selectedPostForComments != null) {
                  provider.hideCommentsSidebar();
                  return false; // Prevent app from closing
                }
                // 2. If in a channel, go back to the channel navigator.
                if (!provider.isMobileNavigatorVisible) {
                  provider.showMobileNavigator();
                  return false; // Prevent app from closing
                }
                // 3. If in channel navigator, allow app to close/pop route.
                return true;
              },
              child: scaffold,
            );
          },
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
              onPressed: () {
                final isDesktop =
                    MediaQuery.of(context).size.width >= 900;
                provider.loadWorkspace(
                  widget.groupId,
                  autoSelectFirstChannel: isDesktop,
                  mobileNavigatorVisible: !isDesktop,
                );
              },
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
    const double workspaceSidebarWidth = 200;
    final channel = provider.currentChannel;

    return Row(
      children: [
        const GlobalSidebar(),
        SizedBox(
          width: workspaceSidebarWidth,
          child: WorkspaceSidebar(
            workspace: workspace,
            width: workspaceSidebarWidth,
            onShowAdminHome: () => _showAdminHome(context, workspace),
            onShowMemberManagement: () => _showMemberManagement(context),
            onShowChannelManagement: () => _showChannelManagement(context),
            onShowGroupInfo: () => _showGroupInfo(context),
          ),
        ),
        Expanded(
          child: channel == null
              ? const Center(child: Text('채널을 선택해주세요'))
              : ChannelDetailView(
                  channel: channel,
                  autoLoad: false,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                ),
        ),
      ],
    );
  }

  Widget _buildDesktopMainArea(
    BuildContext context,
    WorkspaceProvider provider,
    WorkspaceDetailModel workspace,
  ) {
    final channel = provider.currentChannel;
    if (channel == null) {
      return const Center(
        child: Text('채널을 선택해주세요'),
      );
    }

    return ChannelDetailView(
      channel: channel,
      autoLoad: false,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
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
                              child: Text(member.user.name.isNotEmpty
                                  ? member.user.name[0]
                                  : '?'),
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
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text('유형: ${channel.typeDisplayName}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text('생성자: ${channel.createdBy.name}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text('생성일: ${_formatDateTime(channel.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall),
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
              final announcementChannel =
                  _findAnnouncementChannel(provider.channels);

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
    final timePart =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$datePart $timePart';
  }

  Widget _buildMobileWorkspace(
    BuildContext context,
    WorkspaceProvider provider,
    WorkspaceDetailModel workspace,
  ) {
    final channel = provider.currentChannel;
    final showNavigator = provider.isMobileNavigatorVisible;

    Widget body;
    if (showNavigator) {
      body = KeyedSubtree(
        key: const ValueKey('workspace-mobile-nav'),
        child: _buildMobileChannelNavigator(context, provider, workspace),
      );
    } else if (channel != null) {
      body = KeyedSubtree(
        key: ValueKey('workspace-mobile-channel-${channel.id}'),
        child: ChannelDetailView(
          channel: channel,
          autoLoad: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          forceMobileLayout: true,
        ),
      );
    } else {
      // Fallback to navigator if no channel is selected
      body = KeyedSubtree(
        key: const ValueKey('workspace-mobile-nav-fallback'),
        child: _buildMobileChannelNavigator(context, provider, workspace),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: body,
    );
  }

  void _openMobileNavigator(WorkspaceProvider provider) {
    provider.showMobileNavigator();
  }


  Future<void> _openMobileChannel(
    WorkspaceProvider provider,
    ChannelModel channel,
  ) async {
    await provider.selectChannel(channel);
  }

  Widget _buildMobileChannelNavigator(
    BuildContext context,
    WorkspaceProvider provider,
    WorkspaceDetailModel workspace,
  ) {
    final channels = provider.channels;
    final theme = Theme.of(context);
    final showNavigator = provider.isMobileNavigatorVisible;

    return SafeArea(
      bottom: false,
      child: Container(
        color: AppTheme.surface,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          children: [
            Padding(
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
                        _roleDisplayName(workspace.myMembership!.role.name),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _buildMobileNavigatorSection(
              context,
              title: '그룹 메뉴',
              children: [
                _buildMobileNavigatorItem(
                  context,
                  icon: Icons.home_outlined,
                  label: '그룹 홈',
                  selected: false,
                  onTap: () => _showComingSoon(context),
                ),
                _buildMobileNavigatorItem(
                  context,
                  icon: Icons.calendar_today_outlined,
                  label: '그룹 캘린더',
                  selected: false,
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
            _buildMobileNavigatorSection(
              context,
              title: 'Channels',
              children: [
                ...channels.map(
                  (channel) => _buildMobileNavigatorItem(
                    context,
                    icon: _channelIconFor(channel),
                    label: channel.name,
                    selected: !showNavigator &&
                        provider.currentChannel?.id == channel.id,
                    onTap: () => _openMobileChannel(provider, channel),
                  ),
                ),
              ],
            ),
            if (workspace.canManageMembers || workspace.canManageChannels)
              _buildMobileNavigatorSection(
                context,
                title: '관리자 기능',
                children: [
                  _buildMobileNavigatorItem(
                    context,
                    icon: Icons.admin_panel_settings,
                    label: '관리자 홈',
                    selected: false,
                    onTap: () => _showAdminHome(context, workspace),
                  ),
                  if (workspace.canManageMembers)
                    _buildMobileNavigatorItem(
                      context,
                      icon: Icons.people_outline,
                      label: '멤버 관리',
                      selected: false,
                      onTap: () => _showMemberManagement(context),
                    ),
                  if (workspace.canManageChannels)
                    _buildMobileNavigatorItem(
                      context,
                      icon: Icons.tag,
                      label: '채널 관리',
                      selected: false,
                      onTap: () => _showChannelManagement(context),
                    ),
                  _buildMobileNavigatorItem(
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
    );
  }

  Widget _buildMobileNavigatorSection(
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

  Widget _buildMobileNavigatorItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final highlightColor =
        selected ? AppTheme.background : Colors.transparent;
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

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('준비 중인 기능입니다.')),
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

// 워크스페이스 콘텐츠만을 담당하는 위젯 (Scaffold 없이)
class WorkspaceContent extends StatefulWidget {
  final int groupId;
  final String? groupName;
  final VoidCallback? onBack;

  const WorkspaceContent({
    super.key,
    required this.groupId,
    this.groupName,
    this.onBack,
  });

  @override
  State<WorkspaceContent> createState() => _WorkspaceContentState();
}

class _WorkspaceContentState extends State<WorkspaceContent> {
  WorkspaceProvider? _workspaceProvider;

  @override
  void initState() {
    super.initState();

    // 워크스페이스 데이터 로드 및 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<WorkspaceProvider>();
      _workspaceProvider = provider; // Provider 인스턴스 저장
      provider.reset();

      final isDesktop = MediaQuery.of(context).size.width >= 900;
      provider.loadWorkspace(
        widget.groupId,
        autoSelectFirstChannel: isDesktop,
        mobileNavigatorVisible: !isDesktop,
      );
    });
  }

  @override
  void dispose() {
    // 안전한 dispose: 저장된 provider 인스턴스 사용
    _workspaceProvider?.exitChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceProvider>(
      builder: (context, workspaceProvider, child) {
        final workspace = workspaceProvider.currentWorkspace;
        final isDesktop = MediaQuery.of(context).size.width >= 900;

        return LoadingOverlay(
          isLoading: workspaceProvider.isLoading,
          child: workspace == null
              ? _buildEmptyState(workspaceProvider)
              : isDesktop
                  ? _buildDesktopWorkspaceContent(
                      context, workspaceProvider, workspace)
                  : _buildMobileWorkspaceContent(
                      context, workspaceProvider, workspace),
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
              onPressed: () {
                final isDesktop =
                    MediaQuery.of(context).size.width >= 900;
                provider.loadWorkspace(
                  widget.groupId,
                  autoSelectFirstChannel: isDesktop,
                  mobileNavigatorVisible: !isDesktop,
                );
              },
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
              onPressed: widget.onBack,
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
              onPressed: widget.onBack,
              child: const Text('돌아가기'),
            ),
          ],
        ),
      ),
    );
  }

  // 데스크톱용 워크스페이스 콘텐츠 (글로벌 사이드바와 워크스페이스 사이드바가 함께 표시)
  Widget _buildDesktopWorkspaceContent(
    BuildContext context,
    WorkspaceProvider provider,
    WorkspaceDetailModel workspace,
  ) {
    const double workspaceSidebarWidth = 200;

    return Row(
      children: [
        // 워크스페이스 사이드바
        SizedBox(
          width: workspaceSidebarWidth,
          child: WorkspaceSidebar(
            workspace: workspace,
            width: workspaceSidebarWidth,
            onShowAdminHome: () => _showAdminHome(context, workspace),
            onShowMemberManagement: () => _showMemberManagement(context),
            onShowChannelManagement: () => _showChannelManagement(context),
            onShowGroupInfo: () => _showGroupInfo(context),
          ),
        ),
        // 메인 컨텐츠 영역
        Expanded(
          child: _buildWorkspaceMainArea(context, provider, workspace),
        ),
      ],
    );
  }

  Widget _buildWorkspaceMainArea(
    BuildContext context,
    WorkspaceProvider provider,
    WorkspaceDetailModel workspace,
  ) {
    final channel = provider.currentChannel;
    return channel == null
? const Center(
            child: Text('채널을 선택해주세요'),
          )
        : ChannelDetailView(
            channel: channel,
            autoLoad: false,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          );
  }

  Widget _buildMobileWorkspaceContent(
    BuildContext context,
    WorkspaceProvider provider,
    WorkspaceDetailModel workspace,
  ) {
    final channel = provider.currentChannel;
    final showNavigator = provider.isMobileNavigatorVisible;

    Widget body;
    if (showNavigator) {
      body = KeyedSubtree(
        key: const ValueKey('workspace-mobile-nav'),
        child: _buildMobileChannelNavigator(context, provider, workspace),
      );
    } else if (channel != null) {
      body = KeyedSubtree(
        key: ValueKey('workspace-mobile-channel-${channel.id}'),
        child: ChannelDetailView(
          channel: channel,
          autoLoad: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          forceMobileLayout: true,
        ),
      );
    } else {
      body = KeyedSubtree(
        key: const ValueKey('workspace-mobile-nav-fallback'),
        child: _buildMobileChannelNavigator(context, provider, workspace),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (!provider.isMobileNavigatorVisible) {
          _openMobileNavigator(provider);
          return false;
        }
        if (widget.onBack != null) {
          widget.onBack!();
          return false;
        }
        return true;
      },
      child: Scaffold(
        drawer: _buildMobileDrawer(context, provider, workspace),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: body,
        ),
      ),
    );
  }

  // 나머지 헬퍼 메서드들은 기존 WorkspaceScreen에서 복사
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
              final announcementChannel =
                  _findAnnouncementChannel(provider.channels);

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

  void _openMobileNavigator(WorkspaceProvider provider) {
    provider.showMobileNavigator();
  }


  Future<void> _openMobileChannel(
    WorkspaceProvider provider,
    ChannelModel channel,
  ) async {
    await provider.selectChannel(channel);
  }

  Widget _buildMobileChannelNavigator(
    BuildContext context,
    WorkspaceProvider provider,
    WorkspaceDetailModel workspace,
  ) {
    final channels = provider.channels;
    final theme = Theme.of(context);
    final showNavigator = provider.isMobileNavigatorVisible;

    return SafeArea(
      bottom: false,
      child: Container(
        color: AppTheme.surface,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          children: [
            Padding(
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
                        _roleDisplayName(workspace.myMembership!.role.name),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _buildMobileNavigatorSection(
              context,
              title: '그룹 메뉴',
              children: [
                _buildMobileNavigatorItem(
                  context,
                  icon: Icons.home_outlined,
                  label: '그룹 홈',
                  selected: false,
                  onTap: () => _showComingSoon(context),
                ),
                _buildMobileNavigatorItem(
                  context,
                  icon: Icons.calendar_today_outlined,
                  label: '그룹 캘린더',
                  selected: false,
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
            _buildMobileNavigatorSection(
              context,
              title: 'Channels',
              children: [
                ...channels.map(
                  (channel) => _buildMobileNavigatorItem(
                    context,
                    icon: _channelIconFor(channel),
                    label: channel.name,
                    selected: !showNavigator &&
                        provider.currentChannel?.id == channel.id,
                    onTap: () => _openMobileChannel(provider, channel),
                  ),
                ),
              ],
            ),
            if (workspace.canManageMembers || workspace.canManageChannels)
              _buildMobileNavigatorSection(
                context,
                title: '관리자 기능',
                children: [
                  _buildMobileNavigatorItem(
                    context,
                    icon: Icons.admin_panel_settings,
                    label: '관리자 홈',
                    selected: false,
                    onTap: () => _showAdminHome(context, workspace),
                  ),
                  if (workspace.canManageMembers)
                    _buildMobileNavigatorItem(
                      context,
                      icon: Icons.people_outline,
                      label: '멤버 관리',
                      selected: false,
                      onTap: () => _showMemberManagement(context),
                    ),
                  if (workspace.canManageChannels)
                    _buildMobileNavigatorItem(
                      context,
                      icon: Icons.tag,
                      label: '채널 관리',
                      selected: false,
                      onTap: () => _showChannelManagement(context),
                    ),
                  _buildMobileNavigatorItem(
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
    );
  }

  Widget _buildMobileNavigatorSection(
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

  Widget _buildMobileNavigatorItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final highlightColor =
        selected ? AppTheme.background : Colors.transparent;
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

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('준비 중인 기능입니다.')),
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
