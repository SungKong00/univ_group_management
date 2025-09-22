import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workspace_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../../data/models/workspace_models.dart';
import '../../../data/models/admin_models.dart';

/// 관리자 홈 화면 (UI/UX 명세서 적용)
/// Toss 디자인 철학: 한 화면 = 한 목표, 가치 먼저, 가드레일
class AdminHomeScreen extends StatefulWidget {
  final WorkspaceDetailModel workspace;

  const AdminHomeScreen({
    super.key,
    required this.workspace,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  AdminStatsModel? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdminStats();
  }

  Future<void> _loadAdminStats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final stats = await context.read<WorkspaceProvider>().getAdminStats(widget.workspace.group.id);

      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceProvider>(
      builder: (context, provider, child) {
        return LoadingOverlay(
          isLoading: _isLoading,
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              title: const Text(
                '그룹 관리',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
            ),
            body: _buildBody(),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildAdminCards(),
          const SizedBox(height: 32),
          _buildDangerZone(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '관리 정보를 불러오지 못했어요',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAdminStats,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '어떤 관리를 도와드릴까요?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.workspace.group.name} 그룹의 관리 기능입니다',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminCards() {
    return Column(
      children: [
        // 멤버 관리
        if (widget.workspace.canManageMembers) ...[
          _buildAdminCard(
            icon: Icons.people,
            title: '멤버 관리',
            subtitle: _stats?.pendingCount != null && _stats!.pendingCount > 0
                ? '${_stats!.pendingCount}명이 가입을 기다리고 있어요'
                : '그룹 멤버를 승인/반려하고 역할을 바꿔요',
            badgeText: _stats?.pendingCount != null && _stats!.pendingCount > 0
                ? '대기 ${_stats!.pendingCount}'
                : null,
            onTap: () => _navigateToMemberManagement(),
          ),
          const SizedBox(height: 16),
        ],

        // 역할 관리
        if (widget.workspace.canManageRoles) ...[
          _buildAdminCard(
            icon: Icons.security,
            title: '역할 관리',
            subtitle: '그룹의 역할과 권한을 설정해요',
            onTap: () => _navigateToRoleManagement(),
          ),
          const SizedBox(height: 16),
        ],

        // 채널 관리
        if (widget.workspace.canManageChannels) ...[
          _buildAdminCard(
            icon: Icons.tag,
            title: '채널 관리',
            subtitle: '멤버들이 대화할 채널을 만들고 설정해요',
            onTap: () => _navigateToChannelManagement(),
          ),
          const SizedBox(height: 16),
        ],

        // 지도교수 관리 (그룹장만)
        if (widget.workspace.myMembership?.role.name == 'OWNER') ...[
          _buildAdminCard(
            icon: Icons.school,
            title: '지도교수 관리',
            subtitle: '지도교수님을 추가/해제해요',
            onTap: () => _navigateToAdvisorManagement(),
          ),
          const SizedBox(height: 16),
        ],

        // 그룹 정보 수정
        if (widget.workspace.myMembership?.role.name == 'OWNER') ...[
          _buildAdminCard(
            icon: Icons.settings,
            title: '그룹 정보 수정',
            subtitle: '그룹 이름·설명·태그를 바꿔요',
            onTap: () => _navigateToGroupSettings(),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildAdminCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onError,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    if (widget.workspace.myMembership?.role.name != 'OWNER') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '위험 영역',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.error.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: _showGroupDeleteDialog,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_forever,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '그룹 삭제',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '삭제하면 되돌릴 수 없어요',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToMemberManagement() {
    // 기존 멤버 관리 화면으로 이동 (대기 탭으로 딥링크)
    Navigator.pushNamed(
      context,
      '/workspace/${widget.workspace.group.id}/admin/members',
      arguments: {
        'workspace': widget.workspace,
        'initialTab': _stats?.pendingCount != null && _stats!.pendingCount > 0 ? 1 : 0,
      },
    );
  }

  void _navigateToRoleManagement() {
    Navigator.pushNamed(
      context,
      '/workspace/${widget.workspace.group.id}/admin/roles',
      arguments: {'workspace': widget.workspace},
    );
  }

  void _navigateToChannelManagement() {
    Navigator.pushNamed(
      context,
      '/workspace/${widget.workspace.group.id}/admin/channels',
      arguments: {'workspace': widget.workspace},
    );
  }

  void _navigateToAdvisorManagement() {
    // TODO: 지도교수 관리 화면 구현 필요
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('지도교수 관리 기능은 추후 구현 예정입니다')),
    );
  }

  void _navigateToGroupSettings() {
    Navigator.pushNamed(
      context,
      '/workspace/${widget.workspace.group.id}/admin/settings',
      arguments: {'workspace': widget.workspace},
    );
  }

  void _showGroupDeleteDialog() {
    // TODO: 그룹 삭제 바텀 시트 구현 필요
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('그룹 삭제'),
        content: const Text('그룹 삭제 기능은 추후 구현 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

