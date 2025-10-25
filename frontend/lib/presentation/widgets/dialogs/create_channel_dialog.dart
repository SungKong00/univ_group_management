import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/channel_models.dart';
import '../../../core/services/channel_service.dart';
import '../../../core/utils/dialog_helpers.dart';
import '../../../core/components/app_info_banner.dart';
import '../../../core/components/app_dialog_title.dart';
import '../../../core/mixins/dialog_animation_mixin.dart';
import 'confirm_cancel_actions.dart';

/// 채널 생성 다이얼로그
///
/// 토스 디자인 4대 원칙 적용:
/// 1. 단순함: 필수 정보만 입력 (채널 이름), TEXT 타입 고정
/// 2. 위계: 제목 > 폼 필드 > 안내 > 버튼
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

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _descriptionController = TextEditingController();

    // 진입 애니메이션
    initDialogAnimation();
  }

  @override
  void dispose() {
    disposeDialogAnimation();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final channelService = ChannelService();
      final channel = await channelService.createChannel(
        workspaceId: widget.workspaceId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        type: 'TEXT', // TEXT 타입 고정
      );

      if (channel != null && mounted) {
        // 생성된 채널 정보를 반환하여 권한 설정 플로우로 이동
        Navigator.of(context).pop(channel);
      } else {
        setState(() {
          _errorMessage = '채널 생성에 실패했습니다';
        });
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
                    _buildWarningBanner(),
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
    );
  }

  Widget _buildTitle() {
    return const AppDialogTitle(
      title: '새 채널 만들기',
    );
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
          enabled: !_isLoading,
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
          enabled: !_isLoading,
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

  Widget _buildWarningBanner() {
    return AppInfoBanner.warning(
      message: '채널 생성 후 권한 설정이 필요합니다. 권한을 설정하기 전까지는 아무도 이 채널을 볼 수 없습니다.',
    );
  }

  Widget _buildErrorMessage() {
    return AppInfoBanner.error(
      message: _errorMessage!,
    );
  }

  Widget _buildActions() {
    return ConfirmCancelActions(
      confirmText: '채널 만들기',
      onConfirm: _isLoading ? null : _handleCreate,
      isConfirmLoading: _isLoading,
      confirmSemanticsLabel: '채널 생성',
      confirmVariant: PrimaryButtonVariant.brand,
      onCancel:
          _isLoading ? null : () => Navigator.of(context).pop(null),
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
    dialog: CreateChannelDialog(
      workspaceId: workspaceId,
      groupId: groupId,
    ),
  );
}
