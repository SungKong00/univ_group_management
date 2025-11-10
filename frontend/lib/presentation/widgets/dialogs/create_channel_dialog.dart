import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/channel_models.dart';
import '../../../core/models/member_models.dart';
import '../../../core/services/channel_service.dart';
import '../../../core/repositories/role_repository.dart';
import '../../../core/utils/dialog_helpers.dart';
import '../../../core/components/app_info_banner.dart';
import '../../../core/components/app_dialog_title.dart';
import '../../../core/mixins/dialog_animation_mixin.dart';
import 'confirm_cancel_actions.dart';

/// 채널 생성 다이얼로그 (권한 설정 통합)
///
/// 토스 디자인 4대 원칙 적용:
/// 1. 단순함: 채널 정보 + 권한 설정을 하나의 다이얼로그로
/// 2. 위계: 제목 > 채널 정보 > 권한 설정 > 버튼
/// 3. 여백: 24px 내부 패딩, 16px 필드 간격
/// 4. 피드백: 120ms 진입 애니메이션, 로딩 상태 표시, 에러 메시지
class CreateChannelDialog extends ConsumerStatefulWidget {
  final int workspaceId;
  final int groupId;

  const CreateChannelDialog({
    super.key,
    required this.workspaceId,
    required this.groupId,
  });

  @override
  ConsumerState<CreateChannelDialog> createState() =>
      _CreateChannelDialogState();
}

class _CreateChannelDialogState extends ConsumerState<CreateChannelDialog>
    with SingleTickerProviderStateMixin, DialogAnimationMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  // 역할 목록
  List<GroupRole> _roles = [];
  bool _isLoadingRoles = false;

  // 채널 생성 상태
  bool _isCreating = false;
  String? _errorMessage;

  // 권한 매트릭스: 권한 -> 역할 ID 집합
  final Map<String, Set<int>> _permissionMatrix = {
    'POST_READ': {},
    'POST_WRITE': {},
    'COMMENT_WRITE': {},
    'FILE_UPLOAD': {},
  };

  // 권한 정보
  final Map<String, Map<String, dynamic>> _permissionInfo = {
    'POST_READ': {
      'name': '게시글 읽기',
      'description': '채널의 게시글을 볼 수 있습니다',
      'required': true,
    },
    'POST_WRITE': {
      'name': '게시글 작성',
      'description': '새로운 게시글을 작성할 수 있습니다',
      'required': false,
    },
    'COMMENT_WRITE': {
      'name': '댓글 작성',
      'description': '게시글에 댓글을 작성할 수 있습니다',
      'required': false,
    },
    'FILE_UPLOAD': {
      'name': '파일 첨부',
      'description': '게시글에 파일을 첨부할 수 있습니다',
      'required': false,
    },
  };

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _descriptionController = TextEditingController();

    // 진입 애니메이션
    initDialogAnimation();

    // 역할 목록 로드
    _loadRoles();
  }

  @override
  void dispose() {
    disposeDialogAnimation();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 역할 목록 로드
  Future<void> _loadRoles() async {
    print(
      '[DEBUG] CreateChannelDialog: Loading roles for group ${widget.groupId}',
    );
    setState(() {
      _isLoadingRoles = true;
      _errorMessage = null;
    });

    try {
      final roleRepository = ApiRoleRepository();
      final roles = await roleRepository.getGroupRoles(widget.groupId);
      print('[DEBUG] CreateChannelDialog: Loaded ${roles.length} roles');

      setState(() {
        _roles = roles;
        _isLoadingRoles = false;
      });
    } catch (e) {
      print('[DEBUG] CreateChannelDialog: Failed to load roles: $e');
      setState(() {
        _isLoadingRoles = false;
        _errorMessage = '역할 목록을 불러올 수 없습니다';
      });
    }
  }

  /// 권한 토글
  void _togglePermission(String permission, int roleId) {
    setState(() {
      if (_permissionMatrix[permission]!.contains(roleId)) {
        _permissionMatrix[permission]!.remove(roleId);
      } else {
        _permissionMatrix[permission]!.add(roleId);
      }
    });
  }

  /// POST_READ 권한 검증
  bool get _hasPostReadPermission {
    return _permissionMatrix['POST_READ']!.isNotEmpty;
  }

  /// 채널 생성 처리
  Future<void> _handleCreate() async {
    print('[DEBUG] CreateChannelDialog: _handleCreate called');

    // 폼 검증
    if (!_formKey.currentState!.validate()) {
      print('[DEBUG] CreateChannelDialog: Form validation failed');
      return;
    }

    // POST_READ 권한 검증
    if (!_hasPostReadPermission) {
      print('[DEBUG] CreateChannelDialog: POST_READ permission not granted');
      setState(() {
        _errorMessage = '최소 1개 역할에 "게시글 읽기" 권한을 부여해야 합니다';
      });
      return;
    }

    print('[DEBUG] CreateChannelDialog: Starting channel creation');
    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      // rolePermissions 맵 구성
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

      print(
        '[DEBUG] CreateChannelDialog: Calling API with rolePermissions: $rolePermissions',
      );

      // API 호출
      final channelService = ChannelService();
      final channel = await channelService.createChannelWithPermissions(
        workspaceId: widget.workspaceId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        type: 'TEXT',
        rolePermissions: rolePermissions,
      );

      print(
        '[DEBUG] CreateChannelDialog: API returned channel: ${channel?.name ?? 'null'}',
      );

      if (channel != null && mounted) {
        // 성공 시 채널 객체 반환
        print('[DEBUG] CreateChannelDialog: Closing dialog with channel');
        Navigator.of(context).pop(channel);
      } else {
        print(
          '[DEBUG] CreateChannelDialog: Channel creation failed or context not mounted',
        );
        setState(() {
          _errorMessage = '채널 생성에 실패했습니다';
        });
      }
    } catch (e) {
      print('[DEBUG] CreateChannelDialog: Exception during creation: $e');
      setState(() {
        if (e.toString().contains('권한')) {
          _errorMessage = '채널 관리 권한이 없습니다';
        } else if (e.toString().contains('네트워크')) {
          _errorMessage = '네트워크 오류가 발생했습니다';
        } else {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
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
            maxWidth: AppComponents.dialogMaxWidth,
            maxHeight: 700, // 스크롤 가능하도록 최대 높이 설정
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 타이틀 (고정)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                ),
                child: _buildTitle(),
              ),
              const SizedBox(height: AppSpacing.md),
              // 스크롤 영역
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildNameField(),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDescriptionField(),
                        const SizedBox(height: AppSpacing.md),
                        _buildPermissionsSection(),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _buildErrorMessage(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // 액션 버튼 (고정)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _buildActions(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const AppDialogTitle(title: '새 채널 만들기');
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '채널 이름',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nameController,
          enabled: !_isCreating,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '예: 개발-논의',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '채널 이름을 입력해주세요';
            }
            if (value.trim().length > 100) {
              return '채널 이름은 100자 이하로 입력해주세요';
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
          '채널 설명',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _descriptionController,
          enabled: !_isCreating,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: '이 채널의 용도를 설명하세요 (선택)',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value != null && value.length > 500) {
              return '설명은 500자 이하로 입력해주세요';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPermissionsSection() {
    if (_isLoadingRoles) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_roles.isEmpty) {
      return AppInfoBanner.error(message: '역할 목록을 불러올 수 없습니다');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '권한 설정',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppInfoBanner.warning(message: '최소 1개 역할에 "게시글 읽기" 권한을 부여해야 합니다'),
        const SizedBox(height: AppSpacing.sm),
        ..._permissionMatrix.keys.map((permission) {
          return _buildPermissionSection(permission);
        }),
      ],
    );
  }

  Widget _buildPermissionSection(String permission) {
    final info = _permissionInfo[permission]!;
    final selectedCount = _permissionMatrix[permission]!.length;
    final isRequired = info['required'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ExpansionTile(
        initiallyExpanded: permission == 'POST_READ',
        title: Row(
          children: [
            Expanded(
              child: Text(
                info['name'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isRequired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: const Text(
                  '필수',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: selectedCount > 0
                    ? AppColors.brand.withValues(alpha: 0.1)
                    : AppColors.neutral200,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                '$selectedCount개 선택',
                style: TextStyle(
                  fontSize: 11,
                  color: selectedCount > 0
                      ? AppColors.brand
                      : AppColors.neutral600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            info['description'] as String,
            style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
          ),
        ),
        children: _roles.map((role) {
          final isSelected = _permissionMatrix[permission]!.contains(role.id);
          return CheckboxListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(role.name, style: const TextStyle(fontSize: 14)),
                ),
                if (role.isSystemRole)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: const Text(
                      '시스템 역할',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ),
              ],
            ),
            value: isSelected,
            onChanged: _isCreating
                ? null
                : (value) {
                    _togglePermission(permission, role.id);
                  },
            dense: true,
            activeColor: AppColors.brand,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return AppInfoBanner.error(message: _errorMessage!);
  }

  Widget _buildActions() {
    return ConfirmCancelActions(
      confirmText: '채널 만들기',
      onConfirm: (_isCreating || !_hasPostReadPermission)
          ? null
          : _handleCreate,
      isConfirmLoading: _isCreating,
      confirmSemanticsLabel: '채널 생성',
      confirmVariant: PrimaryButtonVariant.brand,
      onCancel: _isCreating ? null : () => Navigator.of(context).pop(null),
      cancelSemanticsLabel: '채널 생성 취소',
    );
  }
}

/// 채널 생성 다이얼로그를 표시하는 헬퍼 함수
///
/// Returns: Channel 객체 (생성 성공 시) 또는 null (취소/실패 시)
Future<Channel?> showCreateChannelDialog(
  BuildContext context, {
  required int workspaceId,
  required int groupId,
}) {
  return AppDialogHelpers.show<Channel>(
    context,
    dialog: CreateChannelDialog(workspaceId: workspaceId, groupId: groupId),
  );
}
