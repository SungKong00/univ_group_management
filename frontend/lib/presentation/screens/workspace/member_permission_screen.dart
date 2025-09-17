import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workspace_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../../data/models/workspace_models.dart';

/// 개인 권한 오버라이드 설정 화면
/// 특정 멤버에게 개별적으로 권한을 허용/차단/상속할 수 있는 화면
class MemberPermissionScreen extends StatefulWidget {
  final WorkspaceDetailModel workspace;
  final GroupMemberModel member;

  const MemberPermissionScreen({
    super.key,
    required this.workspace,
    required this.member,
  });

  @override
  State<MemberPermissionScreen> createState() => _MemberPermissionScreenState();
}

class _MemberPermissionScreenState extends State<MemberPermissionScreen> {
  Map<String, String> _permissionOverrides = {};
  bool _isLoading = true;
  String? _error;
  bool _hasChanges = false;

  final List<String> _availablePermissions = [
    'MANAGE_RECRUITMENT',
    'MANAGE_MEMBERS',
    'MANAGE_CHANNELS',
  ];

  @override
  void initState() {
    super.initState();
    _loadMemberPermissions();
  }

  Future<void> _loadMemberPermissions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final permissions = await context.read<WorkspaceProvider>().getMemberPermissions(
        groupId: widget.workspace.group.id,
        userId: widget.member.user.id,
      );

      if (mounted) {
        setState(() {
          _permissionOverrides = Map<String, String>.from(permissions['overrides'] ?? {});
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
              title: Text(
                '${widget.member.user.name} 권한 설정',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
              actions: [
                if (_hasChanges) ...[
                  TextButton(
                    onPressed: _saveChanges,
                    child: const Text('저장'),
                  ),
                ],
              ],
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
          _buildMemberInfo(),
          const SizedBox(height: 24),
          _buildPermissionOverrides(),
          const SizedBox(height: 32),
          _buildSaveButton(),
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
            '권한 정보를 불러오지 못했어요',
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
            onPressed: _loadMemberPermissions,
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
          '개인 권한 설정',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '역할 권한과 별도로 개인별 권한을 미세 조정할 수 있습니다',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberInfo() {
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                widget.member.user.name.isNotEmpty
                    ? widget.member.user.name[0].toUpperCase()
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
                    widget.member.user.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRoleColor(widget.member.role.name).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getRoleColor(widget.member.role.name).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getRoleDisplayName(widget.member.role.name),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _getRoleColor(widget.member.role.name),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionOverrides() {
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '권한 오버라이드',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '각 권한에 대해 허용, 차단, 또는 역할 기본값 상속을 선택할 수 있습니다',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ..._availablePermissions.map((permission) {
              return _buildPermissionOverrideItem(permission);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionOverrideItem(String permission) {
    final currentValue = _permissionOverrides[permission] ?? 'INHERIT';
    final hasRolePermission = widget.member.role.permissions.contains(permission);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _getPermissionDisplayName(permission),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hasRolePermission
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hasRolePermission ? '역할 허용' : '역할 차단',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: hasRolePermission ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getPermissionDescription(permission),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPermissionOption(permission, 'INHERIT', '상속', Icons.sync),
              const SizedBox(width: 8),
              _buildPermissionOption(permission, 'ALLOW', '허용', Icons.check_circle),
              const SizedBox(width: 8),
              _buildPermissionOption(permission, 'DENY', '차단', Icons.block),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionOption(String permission, String value, String label, IconData icon) {
    final isSelected = _permissionOverrides[permission] == value;
    final color = _getPermissionOptionColor(value);

    return Expanded(
      child: InkWell(
        onTap: () => _setPermissionOverride(permission, value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Theme.of(context).colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _hasChanges ? _saveChanges : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          '변경사항 저장',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _setPermissionOverride(String permission, String value) {
    setState(() {
      if (value == 'INHERIT') {
        _permissionOverrides.remove(permission);
      } else {
        _permissionOverrides[permission] = value;
      }
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final success = await context.read<WorkspaceProvider>().setMemberPermissions(
        groupId: widget.workspace.group.id,
        userId: widget.member.user.id,
        overrides: _permissionOverrides,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('권한 설정을 저장했어요'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _hasChanges = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('권한 설정 저장에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('권한 설정 저장에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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

  String _getRoleDisplayName(String roleName) {
    switch (roleName.toUpperCase()) {
      case 'OWNER':
        return '그룹장';
      case 'ADVISOR':
        return '지도교수';
      case 'MODERATOR':
        return '운영진';
      case 'MEMBER':
        return '일반 멤버';
      default:
        return roleName;
    }
  }

  String _getPermissionDisplayName(String permission) {
    switch (permission) {
      case 'MANAGE_RECRUITMENT':
        return '모집 관리';
      case 'MANAGE_MEMBERS':
        return '멤버 관리';
      case 'MANAGE_CHANNELS':
        return '채널 관리';
      default:
        return permission;
    }
  }

  String _getPermissionDescription(String permission) {
    switch (permission) {
      case 'MANAGE_RECRUITMENT':
        return '가입 신청 승인/반려, 모집 공고 관리';
      case 'MANAGE_MEMBERS':
        return '멤버 역할 변경, 강제 탈퇴';
      case 'MANAGE_CHANNELS':
        return '채널 생성/수정/삭제, 게시물 관리';
      default:
        return '';
    }
  }

  Color _getPermissionOptionColor(String value) {
    switch (value) {
      case 'ALLOW':
        return Colors.green;
      case 'DENY':
        return Colors.red;
      case 'INHERIT':
      default:
        return Colors.blue;
    }
  }
}