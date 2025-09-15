import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../../data/models/workspace_models.dart';

class MembersTab extends StatefulWidget {
  final WorkspaceDetailModel workspace;

  const MembersTab({
    super.key,
    required this.workspace,
  });

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  String _searchQuery = '';
  String? _selectedRoleFilter;

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceProvider>(
      builder: (context, provider, child) {
        final members = _getFilteredMembers(provider.members);
        final roles = _getUniqueRoles(provider.members);

        return CustomScrollView(
          slivers: [
            // 검색 및 필터
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 검색창
                    TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: '멤버 검색...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 역할 필터
                    Row(
                      children: [
                        const Text('역할: '),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('전체', null),
                                const SizedBox(width: 8),
                                ...roles.map((role) =>
                                  _buildFilterChip(role, role),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 멤버 수 표시
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '멤버 ${members.length}명',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // 멤버 목록
            if (members.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(context),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final member = members[index];
                    return _buildMemberTile(context, member);
                  },
                  childCount: members.length,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedRoleFilter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedRoleFilter = selected ? value : null;
        });
      },
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? '검색 결과가 없습니다' : '멤버가 없습니다',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '다른 검색어를 시도해보세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberTile(BuildContext context, GroupMemberModel member) {
    final isOwner = member.role.name.toUpperCase() == 'OWNER';
    final canManageThisMember = widget.workspace.canManageMembers && !isOwner;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(member.role.name),
          child: Text(
            member.user.name.isNotEmpty ? member.user.name[0] : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.user.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isOwner)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 12,
                      color: Colors.amber[800],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '그룹장',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.amber[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(member.role.name).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _roleDisplayName(member.role.name),
                    style: TextStyle(
                      fontSize: 11,
                      color: _getRoleColor(member.role.name),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatJoinDate(member.joinedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              member.user.email,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: canManageThisMember
            ? PopupMenuButton<String>(
                onSelected: (value) => _handleMemberAction(context, member, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'change_role',
                    child: Row(
                      children: [
                        Icon(Icons.person_pin),
                        SizedBox(width: 8),
                        Text('역할 변경'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          '강제 탈퇴',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              )
            : null,
        onTap: () => _showMemberDetail(context, member),
      ),
    );
  }

  Color _getRoleColor(String roleName) {
    switch (roleName) {
      case 'OWNER':
      case 'owner':
        return Colors.amber;
      case 'ADVISOR':
      case 'advisor':
        return Colors.purple;
      case 'STAFF':
      case 'staff':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _roleDisplayName(String roleName) {
    switch (roleName.toUpperCase()) {
      case 'OWNER':
        return '그룹장';
      case 'ADVISOR':
        return '지도교수';
      default:
        return roleName; // custom roles shown as-is
    }
  }

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 30) {
      return '${date.year}년 ${date.month}월 가입';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}일 전 가입';
    } else {
      return '오늘 가입';
    }
  }

  List<GroupMemberModel> _getFilteredMembers(List<GroupMemberModel> members) {
    var filtered = members;

    // 검색어 필터
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((member) {
        return member.user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               member.user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // 역할 필터
    if (_selectedRoleFilter != null) {
      filtered = filtered.where((member) {
        return member.role.name == _selectedRoleFilter;
      }).toList();
    }

    // 정렬: 그룹장 -> 지도교수 -> 기타 역할 -> 가입일순
    filtered.sort((a, b) {
      final aIsOwner = a.role.name == '그룹장';
      final bIsOwner = b.role.name == '그룹장';
      final aIsProfessor = a.role.name == '지도교수';
      final bIsProfessor = b.role.name == '지도교수';

      if (aIsOwner && !bIsOwner) return -1;
      if (!aIsOwner && bIsOwner) return 1;
      if (aIsProfessor && !bIsProfessor) return -1;
      if (!aIsProfessor && bIsProfessor) return 1;

      return a.joinedAt.compareTo(b.joinedAt);
    });

    return filtered;
  }

  List<String> _getUniqueRoles(List<GroupMemberModel> members) {
    final roles = members.map((m) => m.role.name).toSet().toList();
    roles.sort();
    return roles;
  }

  void _showMemberDetail(BuildContext context, GroupMemberModel member) {
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
            // Handle
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

            // Member info
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: _getRoleColor(member.role.name),
                  child: Text(
                    member.user.name.isNotEmpty ? member.user.name[0] : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.user.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(member.role.name).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          member.role.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getRoleColor(member.role.name),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Details
            _buildDetailRow(
              context,
              Icons.email,
              '이메일',
              member.user.email,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.calendar_today,
              '가입일',
              _formatJoinDate(member.joinedAt),
            ),
            const SizedBox(height: 24),

            // Actions
            if (widget.workspace.canManageMembers && member.role.name != '그룹장') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleMemberAction(context, member, 'change_role');
                      },
                      icon: const Icon(Icons.person_pin),
                      label: const Text('역할 변경'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleMemberAction(context, member, 'remove');
                      },
                      icon: const Icon(Icons.person_remove),
                      label: const Text('강제 탈퇴'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  void _handleMemberAction(
    BuildContext context,
    GroupMemberModel member,
    String action,
  ) {
    switch (action) {
      case 'change_role':
        _showChangeRoleDialog(context, member);
        break;
      case 'remove':
        _showRemoveMemberDialog(context, member);
        break;
    }
  }

  void _showChangeRoleDialog(BuildContext context, GroupMemberModel member) {
    // TODO: 역할 변경 다이얼로그 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('역할 변경 기능 구현 예정')),
    );
  }

  void _showRemoveMemberDialog(BuildContext context, GroupMemberModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('멤버 강제 탈퇴'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정말로 "${member.user.name}"님을 그룹에서 내보내시겠습니까?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '이 작업은 되돌릴 수 없습니다.',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
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
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              // TODO: 멤버 강제 탈퇴 API 호출
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${member.user.name}님이 그룹에서 내보내졌습니다')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('내보내기'),
          ),
        ],
      ),
    );
  }
}
