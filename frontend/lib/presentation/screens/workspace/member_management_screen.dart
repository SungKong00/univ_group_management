import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workspace_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../../data/models/workspace_models.dart';
import '../../../data/models/admin_models.dart';
import 'member_permission_screen.dart';

/// 멤버 관리 화면 (UI/UX 명세서 G-3 구현)
/// 탭: 현재 멤버 | 가입 대기
class MemberManagementScreen extends StatefulWidget {
  final WorkspaceDetailModel workspace;

  const MemberManagementScreen({
    super.key,
    required this.workspace,
  });

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceProvider>(
      builder: (context, provider, child) {
        return LoadingOverlay(
          isLoading: provider.isLoading,
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              title: const Text(
                '멤버 관리',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: '현재 멤버'),
                  Tab(text: '가입 대기'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildCurrentMembersTab(),
                _buildPendingMembersTab(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 현재 멤버 탭
  Widget _buildCurrentMembersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.workspace.members.length,
      itemBuilder: (context, index) {
        final member = widget.workspace.members[index];
        final isCurrentUser = member.user.id == widget.workspace.myMembership?.user.id;
        final canManageThisMember = widget.workspace.canManageMembers && !isCurrentUser;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                member.user.name.isNotEmpty ? member.user.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              member.user.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor(member.role.name).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getRoleColor(member.role.name).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getRoleDisplayName(member.role.name),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _getRoleColor(member.role.name),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '가입일: ${_formatDate(member.joinedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            trailing: canManageThisMember
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) => _handleMemberAction(value, member),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'change_role',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline),
                            SizedBox(width: 8),
                            Text('역할 변경'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'permissions',
                        child: Row(
                          children: [
                            Icon(Icons.lock_person),
                            SizedBox(width: 8),
                            Text('개인 권한 설정'),
                          ],
                        ),
                      ),
                      if (member.role.name != 'OWNER') ...[
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.person_remove, color: Colors.red),
                              SizedBox(width: 8),
                              Text('강제 탈퇴', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      if (isCurrentUser && member.role.name == 'OWNER') ...[
                        const PopupMenuItem(
                          value: 'delegate_leadership',
                          child: Row(
                            children: [
                              Icon(Icons.transfer_within_a_station),
                              SizedBox(width: 8),
                              Text('그룹장 위임'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  /// 가입 대기 탭
  Widget _buildPendingMembersTab() {
    return FutureBuilder<List<PendingMemberModel>>(
      future: context.read<WorkspaceProvider>().getPendingMembers(widget.workspace.group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
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
                  '가입 대기 목록을 불러올 수 없습니다',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final pendingMembers = snapshot.data ?? [];

        if (pendingMembers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '가입 대기 중인 멤버가 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '새로운 가입 신청이 들어오면 여기에 표시됩니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingMembers.length,
          itemBuilder: (context, index) {
            final pendingMember = pendingMembers[index];
            return _buildPendingMemberCard(pendingMember);
          },
        );
      },
    );
  }

  /// 가입 대기 멤버 카드
  Widget _buildPendingMemberCard(PendingMemberModel pendingMember) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    pendingMember.user.name.isNotEmpty
                        ? pendingMember.user.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pendingMember.user.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '신청일: ${_formatDate(pendingMember.appliedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (pendingMember.message?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '가입 신청 메시지',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pendingMember.message!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRejectDialog(pendingMember),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    child: const Text('거절'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveMember(pendingMember),
                    child: const Text('승인'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 멤버 액션 처리
  void _handleMemberAction(String action, GroupMemberModel member) {
    switch (action) {
      case 'change_role':
        _showRoleChangeDialog(member);
        break;
      case 'permissions':
        _navigateToMemberPermissions(member);
        break;
      case 'remove':
        _showRemoveMemberDialog(member);
        break;
      case 'delegate_leadership':
        _showDelegateLeadershipDialog(member);
        break;
    }
  }

  /// 역할 변경 다이얼로그
  void _showRoleChangeDialog(GroupMemberModel member) async {
    try {
      // 그룹 역할 목록 조회
      final roles = await context.read<WorkspaceProvider>().getGroupRoles(widget.workspace.group.id);

      if (!mounted) return;

      GroupRoleModel? selectedRole = member.role;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('역할 변경 - ${member.user.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('변경할 역할을 선택해주세요:'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<GroupRoleModel>(
                      value: selectedRole,
                      isExpanded: true,
                      hint: const Text('역할 선택'),
                      items: roles.map((role) {
                        return DropdownMenuItem<GroupRoleModel>(
                          value: role,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(role.name).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getRoleColor(role.name).withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  _getRoleDisplayName(role.name),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _getRoleColor(role.name),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  role.name,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (GroupRoleModel? role) {
                        setDialogState(() {
                          selectedRole = role;
                        });
                      },
                    ),
                  ),
                ),
                if (selectedRole != null && selectedRole!.id != member.role.id) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '권한:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedRole!.permissions.join(', '),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: selectedRole != null && selectedRole!.id != member.role.id
                    ? () async {
                        Navigator.of(context).pop();
                        await _changeUserRole(member, selectedRole!);
                      }
                    : null,
                child: const Text('변경'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('역할 목록을 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 멤버 강제 탈퇴 다이얼로그
  void _showRemoveMemberDialog(GroupMemberModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('멤버 강제 탈퇴'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${member.user.name}님을 그룹에서 내보내시겠습니까?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '이 작업은 되돌릴 수 없습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                      ),
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
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeMember(member);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('내보내기'),
          ),
        ],
      ),
    );
  }

  /// 개인 권한 설정 화면으로 이동
  void _navigateToMemberPermissions(GroupMemberModel member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberPermissionScreen(
          workspace: widget.workspace,
          member: member,
        ),
      ),
    );
  }

  /// 그룹장 위임 다이얼로그
  void _showDelegateLeadershipDialog(GroupMemberModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('그룹장 위임'),
        content: const Text('그룹장 위임 기능은 멤버 목록에서 선택해야 합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 실제 역할 변경 실행
  Future<void> _changeUserRole(GroupMemberModel member, GroupRoleModel newRole) async {
    try {
      final success = await context.read<WorkspaceProvider>().updateMemberRole(
        groupId: widget.workspace.group.id,
        userId: member.user.id,
        roleId: newRole.id,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.user.name}님의 역할을 ${_getRoleDisplayName(newRole.name)}(으)로 변경했습니다'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('역할 변경에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('역할 변경에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 멤버 강제 탈퇴 실행
  Future<void> _removeMember(GroupMemberModel member) async {
    try {
      final success = await context.read<WorkspaceProvider>().removeMember(
        groupId: widget.workspace.group.id,
        userId: member.user.id,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.user.name}님을 그룹에서 내보냈습니다'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('멤버 내보내기에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('멤버 내보내기에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 역할 색상 가져오기
  Color _getRoleColor(String roleName) {
    switch (roleName.toUpperCase()) {
      case 'OWNER':
        return Colors.purple;
      case 'ADVISOR':
        return Colors.blue;
      case 'MODERATOR':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// 역할 표시명 가져오기
  String _getRoleDisplayName(String roleName) {
    switch (roleName.toUpperCase()) {
      case 'OWNER':
        return '그룹장';
      case 'ADVISOR':
        return '지도교수';
      case 'MODERATOR':
        return '운영진';
      case 'MEMBER':
        return '멤버';
      default:
        return roleName;
    }
  }

  /// 멤버 승인
  Future<void> _approveMember(PendingMemberModel pendingMember) async {
    try {
      final success = await context.read<WorkspaceProvider>().decideMembership(
        groupId: widget.workspace.group.id,
        userId: pendingMember.user.id,
        approve: true,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${pendingMember.user.name}님의 가입을 승인했어요'),
              backgroundColor: Colors.green,
            ),
          );
          // 페이지 새로고침을 위해 setState 호출
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('가입 승인에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('가입 승인에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 반려 다이얼로그 표시
  void _showRejectDialog(PendingMemberModel pendingMember) {
    String? selectedReason;
    final customReasonController = TextEditingController();

    final rejectReasons = [
      '기준 미달',
      '인원 충원 완료',
      '기타',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('가입 신청 반려 - ${pendingMember.user.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('반려 사유를 선택해주세요:'),
              const SizedBox(height: 16),
              ...rejectReasons.map((reason) {
                return RadioListTile<String>(
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedReason = value;
                    });
                  },
                  title: Text(reason),
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
              if (selectedReason == '기타') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: customReasonController,
                  decoration: const InputDecoration(
                    hintText: '사유를 입력해주세요',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: selectedReason != null
                  ? () {
                      Navigator.of(context).pop();
                      final reason = selectedReason == '기타'
                          ? customReasonController.text.trim()
                          : selectedReason!;
                      _rejectMember(pendingMember, reason);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('반려'),
            ),
          ],
        ),
      ),
    );
  }

  /// 멤버 반려
  Future<void> _rejectMember(PendingMemberModel pendingMember, String reason) async {
    try {
      final success = await context.read<WorkspaceProvider>().decideMembership(
        groupId: widget.workspace.group.id,
        userId: pendingMember.user.id,
        approve: false,
        reason: reason,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${pendingMember.user.name}님의 가입 신청을 반려했어요'),
              backgroundColor: Colors.orange,
            ),
          );
          // 페이지 새로고침을 위해 setState 호출
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('가입 반려에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('가입 반려에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}