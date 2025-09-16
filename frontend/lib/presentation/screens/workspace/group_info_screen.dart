import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workspace_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../../data/models/workspace_models.dart';
import '../../../data/models/group_model.dart';

class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen({super.key});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('그룹 정보'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Consumer<WorkspaceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingOverlay(
              isLoading: true,
              child: SizedBox.shrink(),
            );
          }

          if (provider.error != null) {
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
                    '그룹 정보를 불러올 수 없습니다',
                    style: Theme.of(context).textTheme.titleMedium,
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
                  CommonButton(
                    onPressed: () => provider.clearError(),
                    text: '다시 시도',
                    type: ButtonType.text,
                  ),
                ],
              ),
            );
          }

          final workspace = provider.currentWorkspace;
          if (workspace == null) {
            return const Center(
              child: Text('워크스페이스 정보가 없습니다.'),
            );
          }

          final group = workspace.group;
          final canManage = provider.canManage;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 그룹 기본 정보 카드
                _buildGroupBasicInfoCard(context, group, canManage),
                const SizedBox(height: 20),

                // 그룹 상세 정보 카드
                _buildGroupDetailsCard(context, group),
                const SizedBox(height: 20),

                // 그룹 멤버십 정보 카드
                _buildMembershipInfoCard(context, workspace),
                const SizedBox(height: 20),

                // 그룹 통계 카드
                _buildGroupStatsCard(context, workspace),
                const SizedBox(height: 20),

                // 관리 액션 버튼들 (권한이 있는 경우)
                if (canManage) ...[
                  _buildManagementActionsCard(context, group),
                  const SizedBox(height: 20),
                ],

                // 위험 영역 (그룹 탈퇴/삭제)
                _buildDangerZoneCard(context, workspace, canManage),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupBasicInfoCard(
    BuildContext context,
    GroupModel group,
    bool canManage,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 그룹 아바타
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: group.profileImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          group.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildGroupInitials(context, group.name),
                        ),
                      )
                    : _buildGroupInitials(context, group.name),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (canManage) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _showEditGroupDialog(context, group),
                              icon: const Icon(Icons.edit, size: 20),
                              tooltip: '그룹 정보 수정',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildGroupTypeChip(context, group),
                      if (group.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text(
                          group.description!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 그룹 태그들
            if (group.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: group.tags.map((tag) => Chip(
                  label: Text(
                    '#$tag',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 모집 상태
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: group.isRecruiting ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  group.isRecruiting ? '모집 중' : '모집 종료',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(group.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInitials(BuildContext context, String groupName) {
    return Center(
      child: Text(
        groupName.isNotEmpty ? groupName[0].toUpperCase() : 'G',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGroupTypeChip(BuildContext context, GroupModel group) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getGroupTypeColor(context, group.groupType),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _getGroupTypeDisplayName(group.groupType),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getGroupTypeColor(BuildContext context, GroupType groupType) {
    switch (groupType) {
      case GroupType.official:
        return Colors.blue;
      case GroupType.university:
        return Colors.purple;
      case GroupType.college:
        return Colors.indigo;
      case GroupType.department:
        return Colors.teal;
      case GroupType.lab:
        return Colors.orange;
      case GroupType.autonomous:
        return Theme.of(context).colorScheme.primary;
      case GroupType.unknown:
        return Colors.grey;
    }
  }

  String _getGroupTypeDisplayName(GroupType groupType) {
    switch (groupType) {
      case GroupType.official:
        return '공식';
      case GroupType.university:
        return '대학';
      case GroupType.college:
        return '단과대';
      case GroupType.department:
        return '학과';
      case GroupType.lab:
        return '연구실';
      case GroupType.autonomous:
        return '자율';
      case GroupType.unknown:
        return '알 수 없음';
    }
  }

  Widget _buildGroupDetailsCard(BuildContext context, GroupModel group) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '상세 정보',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, '그룹장', group.owner.name),
            const SizedBox(height: 12),
            _buildInfoRow(context, '공개 범위', _getVisibilityDisplayName(group.visibility)),
            if (group.university != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(context, '소속 대학', group.university!),
            ],
            if (group.college != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(context, '소속 단과대', group.college!),
            ],
            if (group.department != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(context, '소속 학과', group.department!),
            ],
            if (group.maxMembers != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(context, '최대 인원', '${group.maxMembers}명'),
            ],
          ],
        ),
      ),
    );
  }

  String _getVisibilityDisplayName(GroupVisibility visibility) {
    switch (visibility) {
      case GroupVisibility.public:
        return '공개';
      case GroupVisibility.private:
        return '비공개';
      case GroupVisibility.inviteOnly:
        return '초대 전용';
    }
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipInfoCard(BuildContext context, WorkspaceDetailModel workspace) {
    final membership = workspace.myMembership;
    if (membership == null) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '내 멤버십',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, '역할', membership.role.name),
            const SizedBox(height: 12),
            _buildInfoRow(context, '가입일', _formatDate(membership.joinedAt)),
            const SizedBox(height: 16),

            // 권한 목록
            if (membership.role.permissions.isNotEmpty) ...[
              Text(
                '보유 권한',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: membership.role.permissions.map((permission) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getPermissionDisplayName(permission),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 10,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPermissionDisplayName(String permission) {
    switch (permission) {
      case 'GROUP_MANAGE':
        return '그룹 관리';
      case 'MEMBER_APPROVE':
        return '멤버 승인';
      case 'MEMBER_KICK':
        return '멤버 추방';
      case 'MEMBER_READ':
        return '멤버 조회';
      case 'CHANNEL_MANAGE':
        return '채널 관리';
      case 'POST_CREATE':
        return '게시글 작성';
      case 'POST_DELETE_ANY':
        return '게시글 삭제';
      case 'ROLE_MANAGE':
        return '역할 관리';
      default:
        return permission.replaceAll('_', ' ').toLowerCase();
    }
  }

  Widget _buildGroupStatsCard(BuildContext context, WorkspaceDetailModel workspace) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '그룹 통계',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    '멤버',
                    '${workspace.members.length}명',
                    Icons.people,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    '채널',
                    '${workspace.channels.length}개',
                    Icons.tag,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    '공지',
                    '${workspace.announcements.length}개',
                    Icons.campaign,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildManagementActionsCard(BuildContext context, GroupModel group) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '관리 작업',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            CommonButton(
              onPressed: () => _toggleRecruitment(context, group),
              text: group.isRecruiting ? '모집 종료' : '모집 시작',
              type: group.isRecruiting ? ButtonType.text : ButtonType.primary,
              icon: group.isRecruiting ? Icons.stop : Icons.play_arrow,
              width: double.infinity,
            ),
            const SizedBox(height: 12),
            CommonButton(
              onPressed: () => _showEditGroupDialog(context, group),
              text: '그룹 정보 수정',
              type: ButtonType.text,
              icon: Icons.edit,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneCard(
    BuildContext context,
    WorkspaceDetailModel workspace,
    bool canManage,
  ) {
    final isOwner = workspace.myMembership?.role.name == 'OWNER' ||
                   workspace.group.owner.id == workspace.myMembership?.user.id;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '위험 영역',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!isOwner) ...[
              TextButton.icon(
                onPressed: () => _showLeaveGroupDialog(context, workspace.group),
                icon: const Icon(Icons.exit_to_app),
                label: const Text('그룹 탈퇴'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],

            if (isOwner) ...[
              TextButton.icon(
                onPressed: () => _showTransferOwnershipDialog(context, workspace),
                icon: const Icon(Icons.transfer_within_a_station),
                label: const Text('그룹장 위임'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _showDeleteGroupDialog(context, workspace.group),
                icon: const Icon(Icons.delete_forever),
                label: const Text('그룹 삭제'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  void _showEditGroupDialog(BuildContext context, GroupModel group) {
    // TODO: 그룹 수정 기능 구현 예정
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('그룹 정보 수정 기능은 추후 구현 예정입니다')),
    );
  }

  void _toggleRecruitment(BuildContext context, GroupModel group) {
    // TODO: 모집 상태 토글 기능 구현 예정
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(group.isRecruiting ? '모집을 종료했습니다' : '모집을 시작했습니다')),
    );
  }

  void _showLeaveGroupDialog(BuildContext context, GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('그룹 탈퇴'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정말로 "${group.name}" 그룹에서 탈퇴하시겠습니까?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Text(
                '탈퇴 후 다시 가입하려면 새로 승인을 받아야 합니다.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 실제 탈퇴 로직 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('그룹 탈퇴 기능은 추후 구현 예정입니다')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
  }

  void _showTransferOwnershipDialog(BuildContext context, WorkspaceDetailModel workspace) {
    // TODO: 그룹장 위임 기능 구현 예정
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('그룹장 위임 기능은 추후 구현 예정입니다')),
    );
  }

  void _showDeleteGroupDialog(BuildContext context, GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('그룹 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정말로 "${group.name}" 그룹을 완전히 삭제하시겠습니까?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning,
                        size: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '주의사항',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• 모든 멤버, 채널, 게시글이 함께 삭제됩니다\n• 이 작업은 되돌릴 수 없습니다',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 실제 그룹 삭제 로직 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('그룹 삭제 기능은 추후 구현 예정입니다')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}