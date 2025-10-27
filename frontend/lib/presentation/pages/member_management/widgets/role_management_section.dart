import 'package:flutter/material.dart';
import '../../../../core/utils/snack_bar_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/models/member_models.dart';
import '../providers/role_management_provider.dart';
import '../../../widgets/dialogs/create_role_dialog.dart';
import '../../../widgets/dialogs/edit_role_dialog.dart';
import '../../../widgets/common/state_view.dart';
import '../../../widgets/common/section_card.dart';

/// 역할 관리 섹션
///
/// 그룹 역할 목록 표시 및 커스텀 역할 생성/수정/삭제
class RoleManagementSection extends ConsumerWidget {
  final int groupId;
  final bool isDesktop;

  const RoleManagementSection({
    super.key,
    required this.groupId,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(roleListProvider(groupId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 역할 목록
        StateView<List<GroupRole>>(
          value: rolesAsync,
          builder: (context, roles) => _buildRoleList(context, ref, roles),
        ),
        const SizedBox(height: 16),
        // 커스텀 역할 추가 버튼
        OutlinedButton.icon(
          onPressed: () => _showCreateRoleDialog(context, ref),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('커스텀 역할 추가'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            side: BorderSide(color: AppColors.brand),
            foregroundColor: AppColors.brand,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleList(
    BuildContext context,
    WidgetRef ref,
    List<GroupRole> roles,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: roles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final role = roles[index];
        return _RoleCard(
          role: role,
          groupId: groupId,
          onEdit: role.isSystemRole
              ? null
              : () => _showEditRoleDialog(context, ref, role),
          onDelete: role.isSystemRole
              ? null
              : () => _confirmDeleteRole(context, ref, role),
        );
      },
    );
  }

  void _showCreateRoleDialog(BuildContext context, WidgetRef ref) async {
    final success = await showCreateRoleDialog(context, groupId: groupId);

    if (success && context.mounted) {
      AppSnackBar.success(context, '역할이 생성되었습니다');
      // Provider가 자동으로 새로고침됨
    }
  }

  void _showEditRoleDialog(
    BuildContext context,
    WidgetRef ref,
    GroupRole role,
  ) async {
    final success = await showEditRoleDialog(
      context,
      groupId: groupId,
      role: role,
    );

    if (success && context.mounted) {
      AppSnackBar.success(context, '역할이 수정되었습니다');
      // Provider가 자동으로 새로고침됨
    }
  }

  void _confirmDeleteRole(BuildContext context, WidgetRef ref, GroupRole role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('역할 삭제'),
        content: Text('${role.name} 역할을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(
                  deleteRoleProvider(
                    DeleteRoleParams(groupId: groupId, roleId: role.id),
                  ).future,
                );

                if (context.mounted) {
                  AppSnackBar.success(context, '역할이 삭제되었습니다');
                }
              } catch (e) {
                if (context.mounted) {
                  AppSnackBar.error(
                    context,
                    '역할 삭제 실패: ${e.toString().replaceAll('Exception: ', '')}',
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

/// 역할 카드
class _RoleCard extends StatelessWidget {
  final GroupRole role;
  final int groupId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _RoleCard({
    required this.role,
    required this.groupId,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral300),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          role.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (role.isSystemRole)
                          SectionCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            backgroundColor: AppColors.neutral200,
                            borderRadius: 4,
                            showShadow: false,
                            child: const Text(
                              '시스템',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutral600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!role.isSystemRole) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                  color: AppColors.neutral600,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  color: AppColors.error,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...role.permissions.map(
                (permission) => _PermissionChip(permission: permission),
              ),
              _InfoChip(label: '멤버 ${role.memberCount}명'),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  final String permission;

  const _PermissionChip({required this.permission});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      backgroundColor: AppColors.brand.withValues(alpha: 0.1),
      borderRadius: 6,
      showShadow: false,
      child: Text(
        _formatPermissionName(permission),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.brand,
        ),
      ),
    );
  }

  String _formatPermissionName(String permission) {
    final names = {
      'GROUP_MANAGE': '그룹 관리',
      'MEMBER_MANAGE': '멤버 관리',
      'CHANNEL_MANAGE': '채널 관리',
      'RECRUITMENT_MANAGE': '모집 관리',
    };
    return names[permission] ?? permission;
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      backgroundColor: AppColors.neutral100,
      borderRadius: 6,
      showShadow: false,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.neutral700,
        ),
      ),
    );
  }
}
