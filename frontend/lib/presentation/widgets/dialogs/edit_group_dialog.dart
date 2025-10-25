import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/group_models.dart';
import '../../../core/services/group_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/dialog_helpers.dart';
import '../../../core/components/app_info_banner.dart';
import '../../../core/components/app_dialog_title.dart';
import '../../../core/mixins/dialog_animation_mixin.dart';
import '../buttons/primary_button.dart';
import '../buttons/neutral_outlined_button.dart';

/// 그룹 정보 수정 다이얼로그
///
/// 토스 디자인 4대 원칙 적용:
/// 1. 단순함: 필수 정보만 수정, 명확한 라벨
/// 2. 위계: 제목 > 폼 필드 > 버튼
/// 3. 여백: 24px 내부 패딩, 16px 필드 간격
/// 4. 피드백: 120ms 진입 애니메이션, 로딩 상태 표시, 에러 메시지
class EditGroupDialog extends ConsumerStatefulWidget {
  final int groupId;
  final String currentName;
  final String? currentDescription;
  final bool currentIsRecruiting;
  final Set<String>? currentTags;

  const EditGroupDialog({
    super.key,
    required this.groupId,
    required this.currentName,
    this.currentDescription,
    required this.currentIsRecruiting,
    this.currentTags,
  });

  @override
  ConsumerState<EditGroupDialog> createState() => _EditGroupDialogState();
}

class _EditGroupDialogState extends ConsumerState<EditGroupDialog>
    with SingleTickerProviderStateMixin, DialogAnimationMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  late bool _isRecruiting;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // 초기 값 설정
    _nameController = TextEditingController(text: widget.currentName);
    _descriptionController = TextEditingController(
      text: widget.currentDescription ?? '',
    );
    _tagsController = TextEditingController(
      text: widget.currentTags?.join(', ') ?? '',
    );
    _isRecruiting = widget.currentIsRecruiting;

    // 진입 애니메이션
    initDialogAnimation();
  }

  @override
  void dispose() {
    disposeDialogAnimation();
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final trimmedName = _nameController.text.trim();
      final trimmedDescription = _descriptionController.text.trim();
      final tagsText = _tagsController.text.trim();
      final tags = tagsText.isEmpty
          ? <String>{}
          : tagsText
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toSet();

      final request = UpdateGroupRequest(
        name: trimmedName != widget.currentName ? trimmedName : null,
        description: trimmedDescription != (widget.currentDescription ?? '')
            ? (trimmedDescription.isEmpty ? null : trimmedDescription)
            : null,
        isRecruiting: _isRecruiting != widget.currentIsRecruiting
            ? _isRecruiting
            : null,
        tags: tags != widget.currentTags ? tags : null,
      );

      await GroupService().updateGroup(widget.groupId, request);

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
                    const SizedBox(height: AppSpacing.sm),
                    _buildTagsField(),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRecruitingSwitch(),
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
      title: '그룹 정보 수정',
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '그룹명',
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
            hintText: '그룹명을 입력하세요',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '그룹명을 입력해주세요';
            }
            if (value.trim().length > 100) {
              return '그룹명은 100자 이하로 입력해주세요';
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
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: '그룹 설명을 입력하세요 (선택)',
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

  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '태그',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _tagsController,
          enabled: !_isLoading,
          decoration: const InputDecoration(
            hintText: '태그를 쉼표로 구분하여 입력하세요 (예: 개발, 디자인)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecruitingSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '모집 중',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
        Switch(
          value: _isRecruiting,
          onChanged: _isLoading
              ? null
              : (bool value) {
                  setState(() {
                    _isRecruiting = value;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return AppInfoBanner.error(
      message: _errorMessage!,
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
            semanticsLabel: '그룹 정보 수정 취소',
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: PrimaryButton(
            text: '저장',
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _handleSave,
            semanticsLabel: '그룹 정보 저장',
          ),
        ),
      ],
    );
  }
}

/// 그룹 정보 수정 다이얼로그를 표시하는 헬퍼 함수
///
/// Returns: true if group was updated successfully, false otherwise
Future<bool> showEditGroupDialog(
  BuildContext context, {
  required int groupId,
  required String currentName,
  String? currentDescription,
  required bool currentIsRecruiting,
  Set<String>? currentTags,
}) {
  return AppDialogHelpers.showConfirm(
    context,
    dialog: EditGroupDialog(
      groupId: groupId,
      currentName: currentName,
      currentDescription: currentDescription,
      currentIsRecruiting: currentIsRecruiting,
      currentTags: currentTags,
    ),
  );
}
