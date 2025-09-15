import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workspace_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../../data/models/workspace_models.dart';
import 'tabs/announcements_tab.dart';
import 'tabs/channels_tab.dart';
import 'tabs/members_tab.dart';

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

class _WorkspaceScreenState extends State<WorkspaceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Provider에 탭 컨트롤러 동기화
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<WorkspaceProvider>().setTabIndex(_tabController.index);
      }
    });

    // 워크스페이스 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkspaceProvider>().loadWorkspace(widget.groupId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceProvider>(
      builder: (context, workspaceProvider, child) {
        final workspace = workspaceProvider.currentWorkspace;

        return LoadingOverlay(
          isLoading: workspaceProvider.isLoading,
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            body: workspace == null
                ? _buildEmptyState(workspaceProvider)
                : _buildWorkspaceContent(context, workspace),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(WorkspaceProvider provider) {
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

  Widget _buildWorkspaceContent(
    BuildContext context,
    WorkspaceDetailModel workspace,
  ) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        _buildAppBar(context, workspace),
        _buildTabBar(),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          AnnouncementsTab(workspace: workspace),
          ChannelsTab(workspace: workspace),
          MembersTab(workspace: workspace),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WorkspaceDetailModel workspace) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
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

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: '공지'),
            Tab(text: '채널'),
            Tab(text: '멤버'),
          ],
        ),
      ),
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

  void _showMemberManagement(BuildContext context) {
    // TODO: 멤버 관리 화면으로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('멤버 관리 화면 (구현 예정)')),
    );
  }

  void _showChannelManagement(BuildContext context) {
    // TODO: 채널 관리 화면으로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('채널 관리 화면 (구현 예정)')),
    );
  }

  void _showGroupInfo(BuildContext context) {
    // TODO: 그룹 정보 화면으로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('그룹 정보 화면 (구현 예정)')),
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

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
