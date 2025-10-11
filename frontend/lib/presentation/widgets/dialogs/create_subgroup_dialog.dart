import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/group_service.dart';
import '../../../core/models/group_models.dart';
import '../buttons/primary_button.dart';
import '../buttons/neutral_outlined_button.dart';

/// 하위 그룹 생성 요청 다이얼로그
///
/// 토스 디자인 4대 원칙 적용:
/// 1. Simplicity First: 필수 정보만 입력받는 단순한 폼
/// 2. One Thing Per Page: 하위 그룹 생성이라는 단일 목적에 집중
/// 3. Value First: 사용자가 얻는 가치(새로운 하위 조직)를 먼저 강조
/// 4. Easy to Answer: 각 필드의 목적을 명확한 설명과 함께 제공
///
/// 반응형 지원:
/// - 모바일: 풀스크린 다이얼로그
/// - 데스크톱: 중앙 다이얼로그 (최대 너비 600px)
class CreateSubgroupDialog extends ConsumerStatefulWidget {
  const CreateSubgroupDialog({
    super.key,
    required this.groupId,
    required this.parentGroupName,
  });

  final int groupId;
  final String parentGroupName;

  @override
  ConsumerState<CreateSubgroupDialog> createState() =>
      _CreateSubgroupDialogState();
}

class _CreateSubgroupDialogState extends ConsumerState<CreateSubgroupDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'OFFICIAL'; // 기본값: 공식
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // 진입 애니메이션: 페이드인 120ms + 스케일 0.95 → 1.0
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = CreateSubgroupRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        groupType: _selectedType,
      );

      await GroupService().createSubgroup(widget.groupId, request);

      if (!mounted) return;

      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '하위 그룹 생성 요청이 완료되었습니다.\n관리자 승인 후 그룹이 생성됩니다.',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      String errorMessage = '하위 그룹 생성 요청에 실패했습니다.';

      // 에러 타입별 사용자 친화적 메시지
      if (e.toString().contains('403') || e.toString().contains('FORBIDDEN')) {
        errorMessage = '권한이 없습니다. 그룹 관리자만 하위 그룹을 생성할 수 있습니다.';
      } else if (e.toString().contains('409') ||
          e.toString().contains('DUPLICATE')) {
        errorMessage = '이미 동일한 이름의 그룹이 존재합니다. 다른 이름을 사용해주세요.';
      } else if (e.toString().contains('500')) {
        errorMessage = '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: isWide ? _buildDesktopDialog() : _buildMobileDialog(),
          ),
        );
      },
    );
  }

  /// 데스크톱: 중앙 다이얼로그 (최대 너비 600px)
  Widget _buildDesktopDialog() {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.dialog,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildFormContent(),
          ),
        ),
      ),
    );
  }

  /// 모바일: 풀스크린 다이얼로그
  Widget _buildMobileDialog() {
    return Dialog.fullscreen(
      backgroundColor: AppColors.surface,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('하위 그룹 만들기'),
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: _buildFormContent(),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 (데스크톱용)
          if (MediaQuery.of(context).size.width > 900) ...[
            _buildHeader(),
            const SizedBox(height: AppSpacing.md),
          ],

          // 부모 그룹 정보
          _buildParentGroupInfo(),
          const SizedBox(height: AppSpacing.md),

          // 그룹 이름
          _buildNameField(),
          const SizedBox(height: AppSpacing.sm),

          // 그룹 설명
          _buildDescriptionField(),
          const SizedBox(height: AppSpacing.sm),

          // 그룹 종류
          _buildGroupTypeField(),
          const SizedBox(height: AppSpacing.md),

          // 태그 (비활성화)
          _buildTagsField(),
          const SizedBox(height: AppSpacing.md),

          // 액션 버튼
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '하위 그룹 만들기',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '새로운 하위 조직을 만들어 팀을 확장하세요',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.neutral600,
          ),
        ),
      ],
    );
  }

  Widget _buildParentGroupInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: AppColors.brand.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 20,
            color: AppColors.brand,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '상위 그룹',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.neutral600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.parentGroupName,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '그룹 이름',
          style: AppTheme.titleMedium.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: '예: AI 연구팀, 디자인 동아리',
            filled: true,
            fillColor: AppColors.lightBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(color: AppColors.lightOutline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(color: AppColors.lightOutline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(color: AppColors.brand, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(color: AppColors.error, width: 1),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '그룹 이름을 입력해주세요';
            }
            if (value.trim().length > 50) {
              return '그룹 이름은 50자 이내로 입력해주세요';
            }
            return null;
          },
          maxLength: 50,
          enabled: !_isSubmitting,
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '그룹 설명 (선택)',
          style: AppTheme.titleMedium.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: '그룹의 활동이나 목표를 간단히 설명해주세요',
            filled: true,
            fillColor: AppColors.lightBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(color: AppColors.lightOutline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(color: AppColors.lightOutline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(color: AppColors.brand, width: 2),
            ),
          ),
          maxLines: 3,
          maxLength: 200,
          enabled: !_isSubmitting,
        ),
      ],
    );
  }

  Widget _buildGroupTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '그룹 종류',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: '공식: 학회·학생회·승인된 스터디\n자율: 친구들과 자유롭게 만든 모임',
              child: Icon(
                Icons.help_outline,
                size: 16,
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildRadioOption(
          value: 'OFFICIAL',
          title: '공식 그룹',
          description: '학회, 학생회처럼 체계적으로 운영되는 조직이에요.\n학교 프로그램 참여 스터디도 여기에 해당해요.',
        ),
        const SizedBox(height: 8),
        _buildRadioOption(
          value: 'AUTONOMOUS',
          title: '자율 그룹',
          description: '친구들과 자유롭게 만든 모임이에요.\n토이 프로젝트팀, 취미 스터디 등이 여기에 속해요.',
        ),
      ],
    );
  }

  Widget _buildRadioOption({
    required String value,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedType == value;

    return InkWell(
      onTap: _isSubmitting
          ? null
          : () {
              setState(() {
                _selectedType = value;
              });
            },
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandLight : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(
            color: isSelected
                ? AppColors.brand
                : AppColors.lightOutline.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedType,
              onChanged: _isSubmitting
                  ? null
                  : (val) {
                      setState(() {
                        _selectedType = val!;
                      });
                    },
              activeColor: AppColors.brand,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.neutral600,
                      height: 1.4,
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

  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '태그',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.neutral500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '준비 중',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.neutral600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['개발', '디자인', '기획', '마케팅', '학술', '친목']
              .map(
                (tag) => FilterChip(
                  label: Text(tag),
                  selected: false,
                  onSelected: null, // 비활성화
                  backgroundColor: AppColors.neutral200,
                  disabledColor: AppColors.neutral200,
                  labelStyle: AppTheme.bodySmall.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        Text(
          '// TODO: 백엔드 tags 필드 구현 후 활성화',
          style: AppTheme.bodySmall.copyWith(
            color: AppColors.neutral500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Row(
      mainAxisAlignment:
          isWide ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (isWide) ...[
          Flexible(
            child: NeutralOutlinedButton(
              text: '취소',
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(false),
              semanticsLabel: '하위 그룹 생성 취소',
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: PrimaryButton(
              text: _isSubmitting ? '생성 중...' : '생성 요청',
              onPressed: _isSubmitting ? null : _handleSubmit,
              semanticsLabel: '하위 그룹 생성 요청 제출',
            ),
          ),
        ] else ...[
          Expanded(
            child: NeutralOutlinedButton(
              text: '취소',
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(false),
              semanticsLabel: '하위 그룹 생성 취소',
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: PrimaryButton(
              text: _isSubmitting ? '생성 중...' : '생성 요청',
              onPressed: _isSubmitting ? null : _handleSubmit,
              semanticsLabel: '하위 그룹 생성 요청 제출',
            ),
          ),
        ],
      ],
    );
  }
}

/// 하위 그룹 생성 다이얼로그를 표시하는 헬퍼 함수
///
/// Usage:
/// ```dart
/// final success = await showCreateSubgroupDialog(
///   context,
///   groupId: 1,
///   parentGroupName: '컴퓨터공학과',
/// );
/// if (success == true) {
///   // 생성 성공 처리
/// }
/// ```
Future<bool?> showCreateSubgroupDialog(
  BuildContext context, {
  required int groupId,
  required String parentGroupName,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => CreateSubgroupDialog(
      groupId: groupId,
      parentGroupName: parentGroupName,
    ),
  );

  return result;
}
