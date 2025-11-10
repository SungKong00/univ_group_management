import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/member_models.dart';
import '../../../core/repositories/role_repository.dart';
import '../../../core/services/channel_service.dart';
import '../../../core/components/app_dialog_title.dart';
import '../../../core/mixins/dialog_animation_mixin.dart';
import '../buttons/neutral_outlined_button.dart';
import 'confirm_cancel_actions.dart';

/// 채널 권한 설정 다이얼로그
///
/// 토스 디자인 4대 원칙 적용:
/// 1. 단순함: 권한별 역할 선택 (간소화된 매트릭스)
/// 2. 위계: 제목 > 권한 섹션 > 버튼
/// 3. 여백: 24px 내부 패딩, 16px 섹션 간격
/// 4. 피드백: 진입 애니메이션, 로딩 상태, 에러 메시지
class ChannelPermissionsDialog extends ConsumerStatefulWidget {
  final int channelId;
  final String channelName;
  final int groupId;
  final bool isRequired; // 권한 설정 필수 여부

  const ChannelPermissionsDialog({
    super.key,
    required this.channelId,
    required this.channelName,
    required this.groupId,
    this.isRequired = true,
  });

  @override
  ConsumerState<ChannelPermissionsDialog> createState() =>
      _ChannelPermissionsDialogState();
}

class _ChannelPermissionsDialogState
    extends ConsumerState<ChannelPermissionsDialog>
    with SingleTickerProviderStateMixin, DialogAnimationMixin {
  List<GroupRole> _roles = [];
  bool _isLoadingRoles = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  // 권한별 선택된 역할 ID Set
  final Map<String, Set<int>> _permissionMatrix = {
    'POST_READ': {},
    'POST_WRITE': {},
    'COMMENT_WRITE': {},
    'FILE_UPLOAD': {},
  };

  @override
  void initState() {
    super.initState();
    initDialogAnimation();
    _loadRoles();
  }

  @override
  void dispose() {
    disposeDialogAnimation();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    setState(() {
      _isLoadingRoles = true;
      _errorMessage = null;
    });

    try {
      // 1. 역할 목록 로드
      final roleRepository = ApiRoleRepository();
      final roles = await roleRepository.getGroupRoles(widget.groupId);

      // 2. 기존 권한 바인딩 로드
      final channelService = ChannelService();
      final bindings = await channelService.getChannelRoleBindings(
        widget.channelId,
      );

      // 3. 바인딩을 _permissionMatrix로 변환 (기존 권한을 체크박스에 표시)
      for (final binding in bindings) {
        final roleId = binding['groupRoleId'] as int;
        final permissions = (binding['permissions'] as List).cast<String>();

        for (final permission in permissions) {
          // POST_READ, POST_WRITE 등 권한을 해당 역할의 Set에 추가
          _permissionMatrix[permission]?.add(roleId);
        }
      }

      setState(() {
        _roles = roles;
        _isLoadingRoles = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '역할 및 권한 정보를 불러올 수 없습니다: $e';
        _isLoadingRoles = false;
      });
    }
  }

  Future<void> _handleSave() async {
    // 최소 1개 역할에 POST_READ 권한 검증 (채널 접근의 기본 권한)
    if (_permissionMatrix['POST_READ']!.isEmpty) {
      setState(() {
        _errorMessage = '최소 1개 역할에 "게시글 읽기" 권한을 부여해야 합니다';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final channelService = ChannelService();

      // 권한 매트릭스를 역할별 권한 목록으로 변환
      // roleId -> permissions 맵 생성
      final Map<int, List<String>> rolePermissions = {};

      for (final role in _roles) {
        final permissions = <String>[];
        for (final entry in _permissionMatrix.entries) {
          if (entry.value.contains(role.id)) {
            permissions.add(entry.key);
          }
        }
        if (permissions.isNotEmpty) {
          rolePermissions[role.id] = permissions;
        }
      }

      // 각 역할별로 바인딩 생성
      for (final entry in rolePermissions.entries) {
        await channelService.createChannelRoleBinding(
          channelId: widget.channelId,
          roleId: entry.key,
          permissions: entry.value,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _togglePermission(String permission, int roleId) {
    setState(() {
      if (_permissionMatrix[permission]!.contains(roleId)) {
        _permissionMatrix[permission]!.remove(roleId);
      } else {
        _permissionMatrix[permission]!.add(roleId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return buildAnimatedDialog(
      Dialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.dialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600, // 권한 매트릭스를 위해 더 넓게
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppDialogTitle(
                    title: '채널 권한 설정',
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_isLoadingRoles)
                    _buildLoadingState()
                  else if (_errorMessage != null)
                    _buildErrorState()
                  else
                    _buildPermissionMatrix(),
                  const SizedBox(height: AppSpacing.md),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Column(
        children: [
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 13, color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.sm),
          NeutralOutlinedButton(
            text: '다시 시도',
            onPressed: _loadRoles,
            width: 120,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionMatrix() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 안내 메시지
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.action.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.action.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.action, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '최소 1개 역할에 "게시글 읽기" 권한을 부여해야 합니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 권한별 역할 선택
        _buildPermissionSection(
          'POST_READ',
          '게시글 읽기',
          '게시글과 댓글 조회 (채널 접근 필수)',
          isRequired: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildPermissionSection('POST_WRITE', '게시글 쓰기', '새 게시글 작성'),
        const SizedBox(height: AppSpacing.sm),
        _buildPermissionSection('COMMENT_WRITE', '댓글 쓰기', '댓글 작성'),
        const SizedBox(height: AppSpacing.sm),
        _buildPermissionSection('FILE_UPLOAD', '파일 업로드', '파일 첨부'),

        // 에러 메시지
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 13, color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPermissionSection(
    String permission,
    String label,
    String description, {
    bool isRequired = false,
  }) {
    final selectedRoleIds = _permissionMatrix[permission]!;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral300),
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          childrenPadding: const EdgeInsets.only(
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          title: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(color: AppColors.error, fontSize: 14),
                ),
              ],
              const SizedBox(width: 8),
              Text(
                '(${selectedRoleIds.length}개 역할)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          subtitle: Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          children: _roles.map((role) {
            final isSelected = selectedRoleIds.contains(role.id);
            return CheckboxListTile(
              value: isSelected,
              onChanged: _isSubmitting
                  ? null
                  : (value) => _togglePermission(permission, role.id),
              title: Text(
                role.name,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
              ),
              subtitle: role.isSystemRole
                  ? const Text('시스템 역할', style: TextStyle(fontSize: 12))
                  : null,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return ConfirmCancelActions(
      confirmText: '저장',
      onConfirm: _isLoadingRoles || _isSubmitting ? null : _handleSave,
      isConfirmLoading: _isSubmitting,
      confirmSemanticsLabel: '권한 설정 저장',
      confirmVariant: PrimaryButtonVariant.brand,
      onCancel: widget.isRequired
          ? null // 필수 모드에서는 취소 불가
          : (_isSubmitting ? null : () => Navigator.of(context).pop(false)),
      cancelSemanticsLabel: '권한 설정 취소',
    );
  }
}

/// 채널 권한 설정 다이얼로그를 표시하는 헬퍼 함수
///
/// Returns: true if permissions were set successfully, false otherwise
Future<bool> showChannelPermissionsDialog(
  BuildContext context, {
  required int channelId,
  required String channelName,
  required int groupId,
  bool isRequired = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: !isRequired, // 필수 모드에서는 밖 클릭 불가
    builder: (BuildContext context) => ChannelPermissionsDialog(
      channelId: channelId,
      channelName: channelName,
      groupId: groupId,
      isRequired: isRequired,
    ),
  );

  return result ?? false;
}
