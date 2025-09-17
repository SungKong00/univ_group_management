import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workspace_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../../data/models/workspace_models.dart';

/// 역할 관리 화면 (UI/UX 명세서 적용)
/// 단일 화면에서 역할명 + 권한 설정, 삭제 시 영향 요약 모달
class RoleManagementScreen extends StatefulWidget {
  final WorkspaceDetailModel workspace;

  const RoleManagementScreen({
    super.key,
    required this.workspace,
  });

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  List<GroupRoleModel> _roles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final roles = await context.read<WorkspaceProvider>().getGroupRoles(widget.workspace.group.id);

      if (mounted) {
        setState(() {
          _roles = roles;
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
                '역할 관리',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showCreateRoleDialog(),
                ),
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

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _roles.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _roles.length,
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    return _buildRoleItem(role);
                  },
                ),
        ),
      ],
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
            '역할 정보를 불러오지 못했어요',
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
            onPressed: _loadRoles,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '역할 ${_roles.length}개',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateRoleDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('역할 생성'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '그룹의 역할과 권한을 설정할 수 있습니다',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '아직 생성된 커스텀 역할이 없습니다',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 역할을 생성해보세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateRoleDialog(),
            icon: const Icon(Icons.add),
            label: const Text('역할 생성'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleItem(GroupRoleModel role) {
    final isSystemRole = _isSystemRole(role.name);
    final memberCount = _getMemberCountForRole(role.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getRoleColor(role.name),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getRoleIcon(role.name),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _getRoleDisplayName(role.name),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSystemRole) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '시스템',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '멤버 ${memberCount}명',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: role.permissions.map((permission) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getPermissionDisplayName(permission),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        trailing: !isSystemRole ? PopupMenuButton<String>(
          onSelected: (action) {
            switch (action) {
              case 'edit':
                _showEditRoleDialog(role);
                break;
              case 'delete':
                _showDeleteRoleDialog(role);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, size: 20),
                title: Text('수정'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, size: 20),
                title: Text('삭제'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ) : null,
      ),
    );
  }

  bool _isSystemRole(String roleName) {
    return ['OWNER', 'MEMBER'].contains(roleName.toUpperCase());
  }

  int _getMemberCountForRole(int roleId) {
    return widget.workspace.members.where((member) => member.role.id == roleId).length;
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

  IconData _getRoleIcon(String roleName) {
    switch (roleName.toUpperCase()) {
      case 'OWNER':
        return Icons.star_border;
      case 'ADVISOR':
        return Icons.school;
      case 'MODERATOR':
        return Icons.shield;
      default:
        return Icons.person;
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

  void _showCreateRoleDialog() {
    showDialog(
      context: context,
      builder: (context) => _RoleEditorDialog(
        title: '새 역할 생성',
        onSave: (name, permissions) async {
          final success = await context.read<WorkspaceProvider>().createRole(
            groupId: widget.workspace.group.id,
            name: name,
            permissions: permissions,
          );

          if (success && mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('역할을 생성했어요')),
            );
            await _loadRoles();
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('역할 생성에 실패했습니다'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditRoleDialog(GroupRoleModel role) {
    showDialog(
      context: context,
      builder: (context) => _RoleEditorDialog(
        title: '역할 수정',
        initialName: role.name,
        initialPermissions: role.permissions,
        onSave: (name, permissions) async {
          final success = await context.read<WorkspaceProvider>().updateRole(
            groupId: widget.workspace.group.id,
            roleId: role.id,
            name: name,
            permissions: permissions,
          );

          if (success && mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('역할을 수정했어요')),
            );
            await _loadRoles();
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('역할 수정에 실패했습니다'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showDeleteRoleDialog(GroupRoleModel role) {
    final memberCount = _getMemberCountForRole(role.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('역할 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정말로 "${_getRoleDisplayName(role.name)}" 역할을 삭제하시겠습니까?'),
            const SizedBox(height: 16),
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
                        '영향 요약',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• 이 역할 보유자 ${memberCount}명이 일반 멤버로 변경됩니다\n• 이 작업은 되돌릴 수 없습니다',
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
            onPressed: () async {
              Navigator.of(context).pop();

              final success = await context.read<WorkspaceProvider>().deleteRole(
                groupId: widget.workspace.group.id,
                roleId: role.id,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('역할을 삭제했어요'),
                    action: SnackBarAction(
                      label: '되돌리기',
                      onPressed: () {
                        // TODO: Undo 기능 구현
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('되돌리기 기능은 추후 구현 예정입니다')),
                        );
                      },
                    ),
                  ),
                );
                await _loadRoles();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('역할 삭제에 실패했습니다'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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

class _RoleEditorDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final List<String>? initialPermissions;
  final Function(String name, List<String> permissions) onSave;

  const _RoleEditorDialog({
    required this.title,
    this.initialName,
    this.initialPermissions,
    required this.onSave,
  });

  @override
  State<_RoleEditorDialog> createState() => _RoleEditorDialogState();
}

class _RoleEditorDialogState extends State<_RoleEditorDialog> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Set<String> _selectedPermissions = {};

  final List<String> _availablePermissions = [
    'MANAGE_RECRUITMENT',
    'MANAGE_MEMBERS',
    'MANAGE_CHANNELS',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    if (widget.initialPermissions != null) {
      _selectedPermissions.addAll(widget.initialPermissions!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '역할 이름',
                hintText: '역할 이름을 입력하세요',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.trim().isEmpty == true) {
                  return '역할 이름은 필수입니다';
                }
                if (value!.length > 30) {
                  return '역할 이름은 30자를 초과할 수 없습니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '권한',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ..._availablePermissions.map((permission) {
              return CheckboxListTile(
                value: _selectedPermissions.contains(permission),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedPermissions.add(permission);
                    } else {
                      _selectedPermissions.remove(permission);
                    }
                  });
                },
                title: Text(_getPermissionDisplayName(permission)),
                subtitle: Text(_getPermissionDescription(permission)),
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _nameController.text.trim(),
                _selectedPermissions.toList(),
              );
            }
          },
          child: const Text('저장'),
        ),
      ],
    );
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
}