import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/member_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../pages/member_management/providers/role_management_provider.dart';
import '../buttons/primary_button.dart';
import '../buttons/neutral_outlined_button.dart';

/// 역할 수정 다이얼로그
///
/// 토스 디자인 4대 원칙 적용:
/// 1. 단순함: 필수 정보만 수정, 명확한 라벨
/// 2. 위계: 제목 > 폼 필드 > 권한 체크박스 > 버튼
/// 3. 여백: 24px 내부 패딩, 16px 필드 간격
/// 4. 피드백: 120ms 진입 애니메이션, 로딩 상태 표시, 에러 메시지
///
/// 시스템 역할 수정 방지:
/// - isSystemRole이 true인 역할은 수정 불가
class EditRoleDialog extends ConsumerStatefulWidget {
  final int groupId;
  final GroupRole role;

  const EditRoleDialog({super.key, required this.groupId, required this.role});

  @override
  ConsumerState<EditRoleDialog> createState() => _EditRoleDialogState();
}

class _EditRoleDialogState extends ConsumerState<EditRoleDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  // 권한 체크박스 상태
  late Map<String, bool> _permissions;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // 시스템 역할 체크
    if (widget.role.isSystemRole) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('시스템 역할은 수정할 수 없습니다'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      });
      // 초기화는 해야 dispose 시 에러 방지
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _permissions = {};
      _animationController = AnimationController(
        duration: AppMotion.quick,
        vsync: this,
      );
      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(_animationController);
      _scaleAnimation = Tween<double>(
        begin: 0.95,
        end: 1.0,
      ).animate(_animationController);
      return;
    }

    // 기존 값으로 초기화
    _nameController = TextEditingController(text: widget.role.name);
    _descriptionController = TextEditingController(
      text: widget.role.description,
    );

    // 기존 권한으로 초기화
    _permissions = {
      'GROUP_MANAGE': widget.role.permissions.contains('GROUP_MANAGE'),
      'MEMBER_MANAGE': widget.role.permissions.contains('MEMBER_MANAGE'),
      'CHANNEL_MANAGE': widget.role.permissions.contains('CHANNEL_MANAGE'),
      'RECRUITMENT_MANAGE': widget.role.permissions.contains(
        'RECRUITMENT_MANAGE',
      ),
    };

    // 진입 애니메이션
    _animationController = AnimationController(
      duration: AppMotion.quick,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: AppMotion.easing),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: AppMotion.easing),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 선택된 권한 수집 (0개도 허용)
    final selectedPermissions = _permissions.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final params = UpdateRoleParams(
        groupId: widget.groupId,
        roleId: widget.role.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        permissions: selectedPermissions,
      );

      // API 호출
      await ref.read(updateRoleProvider(params).future);

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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 시스템 역할인 경우 빈 위젯 반환 (이미 pop 됨)
    if (widget.role.isSystemRole) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              elevation: AppElevation.dialog,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.dialog),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppComponents.dialogMaxWidth,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTitle(),
                          const SizedBox(height: AppSpacing.md),
                          _buildNameField(),
                          const SizedBox(height: AppSpacing.sm),
                          _buildDescriptionField(),
                          const SizedBox(height: AppSpacing.md),
                          _buildPermissionsSection(),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _buildErrorMessage(),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          _buildActions(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Semantics(
      header: true,
      child: const Text(
        '역할 수정',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '역할 이름',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nameController,
          enabled: !_isLoading,
          decoration: const InputDecoration(
            hintText: '역할 이름을 입력하세요',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '역할 이름을 입력해주세요';
            }
            if (value.trim().length > 50) {
              return '역할 이름은 50자 이하로 입력해주세요';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '설명',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _descriptionController,
          enabled: !_isLoading,
          maxLines: 2,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: '역할 설명을 입력하세요 (선택)',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value != null && value.length > 200) {
              return '설명은 200자 이하로 입력해주세요';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPermissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '권한',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        _buildPermissionCheckbox('GROUP_MANAGE', '그룹 관리', '그룹 정보 수정, 그룹 설정 변경'),
        _buildPermissionCheckbox('MEMBER_MANAGE', '멤버 관리', '멤버 역할 변경, 멤버 추방'),
        _buildPermissionCheckbox('CHANNEL_MANAGE', '채널 관리', '채널 생성, 수정, 삭제'),
        _buildPermissionCheckbox('RECRUITMENT_MANAGE', '모집 관리', '가입 신청 승인/거부'),
      ],
    );
  }

  Widget _buildPermissionCheckbox(
    String key,
    String label,
    String description,
  ) {
    return CheckboxListTile(
      value: _permissions[key],
      onChanged: _isLoading
          ? null
          : (bool? value) {
              setState(() {
                _permissions[key] = value ?? false;
              });
            },
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.onSurface.withValues(alpha: 0.6),
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Text(
        _errorMessage!,
        style: const TextStyle(fontSize: 13, color: AppColors.error),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: NeutralOutlinedButton(
            text: '취소',
            onPressed: _isLoading
                ? null
                : () => Navigator.of(context).pop(false),
            semanticsLabel: '역할 수정 취소',
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: PrimaryButton(
            text: '저장',
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _handleUpdate,
            semanticsLabel: '역할 저장',
          ),
        ),
      ],
    );
  }
}

/// 역할 수정 다이얼로그를 표시하는 헬퍼 함수
///
/// Returns: true if role was updated successfully, false otherwise
Future<bool> showEditRoleDialog(
  BuildContext context, {
  required int groupId,
  required GroupRole role,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) =>
        EditRoleDialog(groupId: groupId, role: role),
  );

  return result ?? false;
}
