import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/snack_bar_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../core/models/recruitment_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../providers/recruitment_providers.dart';
import '../../providers/workspace_state_provider.dart';
import '../workspace/widgets/workspace_state_view.dart';
import '../../widgets/common/collapsible_content.dart';
import '../../widgets/common/state_view.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/buttons/primary_button.dart';

class RecruitmentManagementPage extends ConsumerStatefulWidget {
  const RecruitmentManagementPage({super.key});

  @override
  ConsumerState<RecruitmentManagementPage> createState() =>
      _RecruitmentManagementPageState();
}

class _RecruitmentManagementPageState
    extends ConsumerState<RecruitmentManagementPage> {
  /// Shows a confirmation dialog for destructive actions
  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Handles recruitment creation with validation and error handling
  Future<void> _handleCreateRecruitment(
    int groupId,
    RecruitmentFormData data,
  ) async {
    try {
      // 1. Validate input
      final validationError = data.validate();
      if (validationError != null) {
        if (!mounted) return;
        AppSnackBar.error(context, validationError);
        return;
      }

      // 2. Convert to DTO
      final request = data.toCreateRequest();

      // 3. Call API via Provider
      final params = CreateRecruitmentParams(groupId: groupId, request: request);
      await ref.read(createRecruitmentProvider(params).future);

      // 4. Success feedback
      if (!mounted) return;
      AppSnackBar.info(context, '모집 공고가 성공적으로 생성되었습니다.');
    } catch (e) {
      // 5. Error handling
      if (!mounted) return;
      AppSnackBar.error(context, '모집 공고 생성 실패: $e');
    }
  }

  /// Handles recruitment update with validation and error handling
  Future<void> _handleUpdateRecruitment(
    RecruitmentResponse recruitment,
    RecruitmentFormData data,
  ) async {
    try {
      // 1. Validate input
      final validationError = data.validate();
      if (validationError != null) {
        if (!mounted) return;
        AppSnackBar.error(context, validationError);
        return;
      }

      // 2. Convert to DTO
      final request = data.toUpdateRequest();

      // 3. Call API via Provider
      final params = UpdateRecruitmentParams(
        recruitmentId: recruitment.id,
        request: request,
      );
      await ref.read(updateRecruitmentProvider(params).future);

      // 4. Success feedback
      if (!mounted) return;
      AppSnackBar.info(context, '모집 공고가 성공적으로 수정되었습니다.');
    } catch (e) {
      // 5. Error handling
      if (!mounted) return;
      AppSnackBar.error(context, '모집 공고 수정 실패: $e');
    }
  }

  /// Handles recruitment closure with confirmation and error handling
  Future<void> _handleCloseRecruitment(RecruitmentResponse recruitment) async {
    // 1. Confirm action
    final confirmed = await _showConfirmationDialog(
      title: '모집 종료',
      message: '정말로 모집을 종료하시겠습니까? 종료 후에는 새로운 지원을 받을 수 없습니다.',
      confirmLabel: '모집 종료',
      confirmColor: AppColors.neutral600,
    );

    if (!confirmed) return;

    try {
      // 2. Call API via Provider
      await ref.read(closeRecruitmentProvider(recruitment.id).future);

      // 3. Success feedback
      if (!mounted) return;
      AppSnackBar.info(context, '모집이 성공적으로 종료되었습니다.');
    } catch (e) {
      // 4. Error handling
      if (!mounted) return;
      AppSnackBar.error(context, '모집 종료 실패: $e');
    }
  }

  /// Handles recruitment deletion with confirmation and error handling
  Future<void> _handleDeleteRecruitment(RecruitmentResponse recruitment) async {
    // 1. Confirm action
    final confirmed = await _showConfirmationDialog(
      title: '모집 삭제',
      message: '정말로 모집 공고를 삭제하시겠습니까? 이 작업은 취소할 수 없으며, 모든 지원서도 함께 삭제됩니다.',
      confirmLabel: '삭제',
      confirmColor: AppColors.error,
    );

    if (!confirmed) return;

    try {
      // 2. Call API via Provider
      await ref.read(deleteRecruitmentProvider(recruitment.id).future);

      // 3. Success feedback
      if (!mounted) return;
      AppSnackBar.info(context, '모집 공고가 성공적으로 삭제되었습니다.');
    } catch (e) {
      // 4. Error handling
      if (!mounted) return;
      AppSnackBar.error(context, '모집 공고 삭제 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupIdStr = ref.watch(currentGroupIdProvider);

    if (groupIdStr == null) {
      return const WorkspaceStateView(type: WorkspaceStateType.noGroup);
    }

    final groupId = int.tryParse(groupIdStr);
    if (groupId == null) {
      return WorkspaceStateView(
        type: WorkspaceStateType.error,
        errorMessage: '그룹 정보를 불러오지 못했습니다.',
      );
    }

    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final paddingHorizontal = isDesktop ? AppSpacing.lg : AppSpacing.sm;
    final paddingVertical = isDesktop ? AppSpacing.lg : AppSpacing.sm;

    final activeRecruitmentAsync = ref.watch(
      activeRecruitmentProvider(groupId),
    );
    final archivedRecruitmentsAsync = ref.watch(
      archivedRecruitmentsProvider(groupId),
    );

    return Container(
      color: AppColors.neutral100,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: paddingHorizontal,
          vertical: paddingVertical,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '모집 공고 관리',
              style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                color: AppColors.neutral900,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              '활성 모집 현황을 확인하고 새 모집 공고를 등록하세요.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            ActiveRecruitmentSection(
              groupId: groupId,
              activeRecruitment: activeRecruitmentAsync,
              onCreate: (data) => _handleCreateRecruitment(groupId, data),
              onUpdate: _handleUpdateRecruitment,
              onClose: _handleCloseRecruitment,
              onDelete: _handleDeleteRecruitment,
            ),
            SizedBox(height: AppSpacing.lg),
            ArchivedRecruitmentSection(
              archivedRecruitments: archivedRecruitmentsAsync,
            ),
          ],
        ),
      ),
    );
  }
}

class ActiveRecruitmentSection extends ConsumerStatefulWidget {
  const ActiveRecruitmentSection({
    super.key,
    required this.groupId,
    required this.activeRecruitment,
    required this.onCreate,
    required this.onUpdate,
    required this.onClose,
    required this.onDelete,
  });

  final int groupId;
  final AsyncValue<RecruitmentResponse?> activeRecruitment;
  final Future<void> Function(RecruitmentFormData data) onCreate;
  final Future<void> Function(
    RecruitmentResponse recruitment,
    RecruitmentFormData data,
  ) onUpdate;
  final Future<void> Function(RecruitmentResponse recruitment) onClose;
  final Future<void> Function(RecruitmentResponse recruitment) onDelete;

  @override
  ConsumerState<ActiveRecruitmentSection> createState() =>
      _ActiveRecruitmentSectionState();
}

class _ActiveRecruitmentSectionState
    extends ConsumerState<ActiveRecruitmentSection> {
  bool _isEditing = false;

  void _toggleEditMode(bool value) {
    setState(() {
      _isEditing = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      icon: Icons.campaign_outlined,
      title: '활성 모집 공고',
      description: '현재 진행 중인 모집 공고를 확인하고 관리하세요.',
      isEmphasized: true,
      child: StateView<RecruitmentResponse?>(
        value: widget.activeRecruitment,
        onRetry: () => ref.invalidate(activeRecruitmentProvider(widget.groupId)),
        builder: (context, recruitment) {
          if (recruitment == null || _isEditing) {
            return RecruitmentForm(
              groupId: widget.groupId,
              initialRecruitment: _isEditing ? recruitment : null,
              submitLabel: recruitment == null ? '모집 공고 생성' : '변경 사항 저장',
              onSubmit: recruitment == null
                  ? widget.onCreate
                  : (data) => widget.onUpdate(recruitment, data),
              onCancel: recruitment != null
                  ? () => _toggleEditMode(false)
                  : null,
            );
          }

          return RecruitmentDetailsCard(
            recruitment: recruitment,
            onEdit: () => _toggleEditMode(true),
            onClose: () => widget.onClose(recruitment),
            onDelete: () => widget.onDelete(recruitment),
          );
        },
      ),
    );
  }
}

class RecruitmentDetailsCard extends StatelessWidget {
  const RecruitmentDetailsCard({
    super.key,
    required this.recruitment,
    required this.onEdit,
    required this.onClose,
    required this.onDelete,
  });

  final RecruitmentResponse recruitment;
  final VoidCallback onEdit;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final infoStyle = AppTheme.bodyMedium.copyWith(
      color: AppColors.neutral600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recruitment.title,
          style: AppTheme.headlineMedium.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            _StatusBadge(status: recruitment.status),
            SizedBox(width: AppSpacing.xs),
            Text(
              '작성일 ${_formatDate(recruitment.createdAt)}',
              style: infoStyle,
            ),
          ],
        ),
        if (recruitment.content != null && recruitment.content!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: CollapsibleContent(
              content: recruitment.content!,
              maxLines: 6,
            ),
          ),
        SizedBox(height: AppSpacing.sm),
        _InfoGrid(items: [
          _InfoItem(
            label: '현재 지원자 수',
            value: recruitment.showApplicantCount
                ? '${recruitment.currentApplicantCount}명'
                : '비공개',
          ),
          _InfoItem(
            label: '최대 모집 인원',
            value: recruitment.maxApplicants != null
                ? '${recruitment.maxApplicants}명'
                : '제한 없음',
          ),
          _InfoItem(
            label: '모집 시작일',
            value: _formatDateTime(recruitment.recruitmentStartDate),
          ),
          _InfoItem(
            label: '모집 마감일',
            value: recruitment.recruitmentEndDate != null
                ? _formatDateTime(recruitment.recruitmentEndDate!)
                : '마감일 미설정',
          ),
        ]),
        SizedBox(height: AppSpacing.sm),
        Text(
          '지원서 질문',
          style: AppTheme.titleMedium.copyWith(color: AppColors.neutral800),
        ),
        SizedBox(height: AppSpacing.xs),
        if (recruitment.applicationQuestions.isEmpty)
          Text(
            '등록된 질문이 없습니다. 신규 모집 시 질문을 추가할 수 있습니다.',
            style: AppTheme.bodySmall.copyWith(color: AppColors.neutral600),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < recruitment.applicationQuestions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _QuestionChip(
                    index: i + 1,
                    text: recruitment.applicationQuestions[i],
                  ),
                ),
            ],
          ),
        SizedBox(height: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: onEdit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              child: const Text('모집 공고 수정'),
            ),
            SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClose,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    child: const Text('모집 종료'),
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    child: const Text('모집 삭제'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class RecruitmentFormData {
  RecruitmentFormData({
    required this.title,
    required this.content,
    required this.maxApplicants,
    required this.recruitmentEndDate,
    required this.showApplicantCount,
    required this.applicationQuestions,
  });

  final String title;
  final String? content;
  final int? maxApplicants;
  final DateTime? recruitmentEndDate;
  final bool showApplicantCount;
  final List<String> applicationQuestions;

  /// Validates all fields and returns error message if invalid
  /// Returns null if all validations pass
  String? validate() {
    // 1. Title validation
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return '모집 제목을 입력해주세요.';
    }
    if (trimmedTitle.length < 2) {
      return '모집 제목은 최소 2자 이상이어야 합니다.';
    }
    if (trimmedTitle.length > 100) {
      return '모집 제목은 100자를 초과할 수 없습니다.';
    }

    // 2. Content validation (optional but has max length)
    if (content != null) {
      final trimmedContent = content!.trim();
      if (trimmedContent.isNotEmpty && trimmedContent.length > 2000) {
        return '모집 상세 내용은 2000자를 초과할 수 없습니다.';
      }
    }

    // 3. Max applicants validation (optional but must be positive)
    if (maxApplicants != null) {
      if (maxApplicants! <= 0) {
        return '모집 인원은 1명 이상이어야 합니다.';
      }
      if (maxApplicants! > 10000) {
        return '모집 인원은 10,000명을 초과할 수 없습니다.';
      }
    }

    // 4. Recruitment end date validation (optional but must be in future)
    if (recruitmentEndDate != null) {
      final now = DateTime.now();
      if (recruitmentEndDate!.isBefore(now)) {
        return '모집 마감일은 현재 시각 이후로 설정해야 합니다.';
      }
      final maxEndDate = now.add(const Duration(days: 365 * 2));
      if (recruitmentEndDate!.isAfter(maxEndDate)) {
        return '모집 마감일은 2년 이내로 설정해야 합니다.';
      }
    }

    // 5. Application questions validation
    if (applicationQuestions.length > 20) {
      return '지원서 질문은 최대 20개까지 등록할 수 있습니다.';
    }
    for (var i = 0; i < applicationQuestions.length; i++) {
      final question = applicationQuestions[i].trim();
      if (question.isEmpty) {
        return '질문 ${i + 1}번이 비어있습니다. 빈 질문은 삭제해주세요.';
      }
      if (question.length > 500) {
        return '질문 ${i + 1}번은 500자를 초과할 수 없습니다.';
      }
    }

    // All validations passed
    return null;
  }

  /// Converts validated form data to CreateRecruitmentRequest
  /// IMPORTANT: Call validate() before using this method
  CreateRecruitmentRequest toCreateRequest() {
    final trimmedContent = content?.trim();
    final cleanedQuestions = applicationQuestions
        .map((q) => q.trim())
        .where((q) => q.isNotEmpty)
        .toList();

    return CreateRecruitmentRequest(
      title: title.trim(),
      content: trimmedContent != null && trimmedContent.isNotEmpty
          ? trimmedContent
          : null,
      maxApplicants: maxApplicants,
      recruitmentEndDate: recruitmentEndDate,
      autoApprove: false, // Default to manual approval
      showApplicantCount: showApplicantCount,
      applicationQuestions: cleanedQuestions,
    );
  }

  /// Converts validated form data to UpdateRecruitmentRequest
  /// IMPORTANT: Call validate() before using this method
  UpdateRecruitmentRequest toUpdateRequest() {
    final trimmedContent = content?.trim();
    final cleanedQuestions = applicationQuestions
        .map((q) => q.trim())
        .where((q) => q.isNotEmpty)
        .toList();

    return UpdateRecruitmentRequest(
      title: title.trim(),
      content: trimmedContent != null && trimmedContent.isNotEmpty
          ? trimmedContent
          : null,
      maxApplicants: maxApplicants,
      recruitmentEndDate: recruitmentEndDate,
      showApplicantCount: showApplicantCount,
      applicationQuestions: cleanedQuestions,
    );
  }
}

class RecruitmentForm extends ConsumerStatefulWidget {
  const RecruitmentForm({
    super.key,
    required this.groupId,
    this.initialRecruitment,
    required this.submitLabel,
    this.onSubmit,
    this.onCancel,
  });

  final int groupId;
  final RecruitmentResponse? initialRecruitment;
  final String submitLabel;
  final Future<void> Function(RecruitmentFormData data)? onSubmit;
  final VoidCallback? onCancel;

  @override
  ConsumerState<RecruitmentForm> createState() => _RecruitmentFormState();
}

class _RecruitmentFormState extends ConsumerState<RecruitmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _maxApplicantsController = TextEditingController();
  final List<TextEditingController> _questionControllers = [];
  late bool _showApplicantCount;
  DateTime? _selectedEndDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initFromRecruitment(widget.initialRecruitment, notify: false);
  }

  @override
  void didUpdateWidget(covariant RecruitmentForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRecruitment != widget.initialRecruitment) {
      _initFromRecruitment(widget.initialRecruitment, notify: true);
    }
  }

  void _initFromRecruitment(
    RecruitmentResponse? recruitment, {
    required bool notify,
  }) {
    _titleController.text = recruitment?.title ?? '';
    _contentController.text = recruitment?.content ?? '';
    _maxApplicantsController.text = recruitment?.maxApplicants?.toString() ?? '';
    _showApplicantCount = recruitment?.showApplicantCount ?? true;
    _selectedEndDate = recruitment?.recruitmentEndDate;

    for (final controller in _questionControllers) {
      controller.dispose();
    }
    _questionControllers.clear();

    final questions = recruitment?.applicationQuestions ?? const <String>[];
    for (final question in questions) {
      _questionControllers.add(TextEditingController(text: question));
    }

    if (notify && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _maxApplicantsController.dispose();
    for (final controller in _questionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final initialDate = _selectedEndDate ?? now.add(const Duration(days: 7));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );

    if (!mounted) return;
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (!mounted) return;

    setState(() {
      if (pickedTime != null) {
        _selectedEndDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      } else {
        _selectedEndDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          23,
          59,
        );
      }
    });
  }

  void _addQuestion() {
    setState(() {
      _questionControllers.add(TextEditingController());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      final controller = _questionControllers.removeAt(index);
      controller.dispose();
    });
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final maxApplicantsText = _maxApplicantsController.text.trim();
    int? maxApplicants;
    if (maxApplicantsText.isNotEmpty) {
      maxApplicants = int.tryParse(maxApplicantsText);
      if (maxApplicants == null || maxApplicants <= 0) {
        if (!mounted) return;
        AppSnackBar.info(context, '모집 인원은 양의 정수로 입력해주세요.');
        return;
      }
    }

    final questions = _questionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final data = RecruitmentFormData(
      title: _titleController.text.trim(),
      content: _contentController.text.trim().isEmpty
          ? null
          : _contentController.text.trim(),
      maxApplicants: maxApplicants,
      recruitmentEndDate: _selectedEndDate,
      showApplicantCount: _showApplicantCount,
      applicationQuestions: questions,
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.onSubmit != null) {
        await widget.onSubmit!(data);
      } else {
        if (mounted) {
          AppSnackBar.info(context, '모집 공고 제출 로직이 준비 중입니다.');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialRecruitment != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? '모집 공고 수정' : '새 모집 공고 작성',
            style: AppTheme.headlineSmall.copyWith(
              color: AppColors.neutral900,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '모집 제목',
              hintText: '예) 2025년 1학기 신입 모집',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '모집 제목을 입력해주세요.';
              }
              return null;
            },
          ),
          SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: '모집 상세 내용',
              hintText: '지원 자격, 활동 내용, 기대 역할 등을 입력하세요.',
              alignLabelWithHint: true,
            ),
            maxLines: 6,
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _maxApplicantsController,
                  decoration: const InputDecoration(
                    labelText: '모집 인원 (선택)',
                    hintText: '숫자만 입력 (미입력 시 제한 없음)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: InkWell(
                  onTap: _pickEndDate,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '모집 마감일 (선택)',
                      hintText: '날짜와 시간을 선택하세요',
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                      suffixIconColor: AppColors.neutral500,
                    ),
                    child: Text(
                      _selectedEndDate != null
                          ? _formatDateTime(_selectedEndDate!)
                          : '날짜와 시간을 선택하세요',
                      style: (_selectedEndDate != null)
                          ? AppTheme.bodyMedium.copyWith(
                              color: AppColors.neutral900,
                            )
                          : AppTheme.bodySmall.copyWith(
                              color: AppColors.neutral500,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedEndDate != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedEndDate = null;
                  });
                },
                child: const Text('마감일 삭제'),
              ),
            ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('지원자 수 공개'),
            subtitle: const Text('활성 모집 동안 현재 지원자 수를 보여줍니다.'),
            value: _showApplicantCount,
            onChanged: (value) {
              setState(() {
                _showApplicantCount = value;
              });
            },
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            '지원서 질문',
            style: AppTheme.titleMedium.copyWith(color: AppColors.neutral800),
          ),
          SizedBox(height: 4),
          Text(
            '지원자에게 물어보고 싶은 질문을 추가할 수 있습니다. (최대 20개)',
            style: AppTheme.bodySmall.copyWith(color: AppColors.neutral600),
          ),
          SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < _questionControllers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _QuestionCard(
                index: i,
                controller: _questionControllers[i],
                onRemove: () => _removeQuestion(i),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _questionControllers.length < 20 ? _addQuestion : null,
            icon: const Icon(Icons.add),
            label: Text('질문 추가 (${_questionControllers.length}/20)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brand,
              side: BorderSide(color: AppColors.brand.withValues(alpha: 0.5)),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (widget.onCancel != null)
                TextButton(
                  onPressed: _isSubmitting ? null : widget.onCancel,
                  child: const Text('취소'),
                ),
              const Spacer(),
              Flexible(
                child: PrimaryButton(
                  text: widget.submitLabel,
                  isLoading: _isSubmitting,
                  onPressed: _handleSubmit,
                  variant: PrimaryButtonVariant.brand,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ArchivedRecruitmentSection extends ConsumerStatefulWidget {
  const ArchivedRecruitmentSection({
    super.key,
    required this.archivedRecruitments,
  });

  final AsyncValue<List<ArchivedRecruitmentResponse>> archivedRecruitments;

  @override
  ConsumerState<ArchivedRecruitmentSection> createState() =>
      _ArchivedRecruitmentSectionState();
}

class _ArchivedRecruitmentSectionState
    extends ConsumerState<ArchivedRecruitmentSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.archive_outlined, color: AppColors.brand),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '아카이브된 모집 공고',
                          style: AppTheme.headlineSmall.copyWith(
                            color: AppColors.neutral900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '마감된 모집 공고의 기록을 확인할 수 있습니다.',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.neutral600,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            SizedBox(height: AppSpacing.md),
            StateView<List<ArchivedRecruitmentResponse>>(
              value: widget.archivedRecruitments,
              emptyChecker: (recruitments) => recruitments.isEmpty,
              emptyIcon: Icons.inbox_outlined,
              emptyTitle: '아직 종료된 모집이 없습니다',
              onRetry: () {
                final groupIdStr = ref.read(currentGroupIdProvider);
                if (groupIdStr != null) {
                  final groupId = int.tryParse(groupIdStr);
                  if (groupId != null) {
                    ref.invalidate(archivedRecruitmentsProvider(groupId));
                  }
                }
              },
              builder: (context, recruitments) => Column(
                children: [
                  for (final recruitment in recruitments)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ArchivedRecruitmentTile(recruitment: recruitment),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArchivedRecruitmentTile extends ConsumerWidget {
  const _ArchivedRecruitmentTile({required this.recruitment});

  final ArchivedRecruitmentResponse recruitment;

  void _showDetailModal(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => RecruitmentDetailModal(recruitmentId: recruitment.id),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _showDetailModal(context, ref),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SectionCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neutral200),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    recruitment.title,
                    style: AppTheme.titleLarge.copyWith(
                      color: AppColors.neutral900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusBadge(status: RecruitmentStatus.closed),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '${recruitment.group.name} · ${_formatDate(recruitment.createdAt)} 시작 · ${_formatDate(recruitment.closedAt)} 종료',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.neutral600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: 4,
              children: [
                _ChipText(
                  icon: Icons.article_outlined,
                  text: '총 ${recruitment.totalApplications}건 지원',
                ),
                _ChipText(
                  icon: Icons.check_circle_outline,
                  text: '승인 ${recruitment.approvedApplications}건',
                ),
                _ChipText(
                  icon: Icons.cancel_outlined,
                  text: '거부 ${recruitment.rejectedApplications}건',
                ),
                _ChipText(
                  icon: Icons.info_outline,
                  text: '자세히 보기',
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class RecruitmentDetailModal extends ConsumerWidget {
  const RecruitmentDetailModal({
    super.key,
    required this.recruitmentId,
  });

  final int recruitmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recruitmentAsync = ref.watch(recruitmentDetailProvider(recruitmentId));

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: recruitmentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              SizedBox(height: AppSpacing.sm),
              Text(
                '모집 공고를 불러올 수 없습니다.',
                style: AppTheme.titleMedium.copyWith(color: AppColors.error),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                '$error',
                style: AppTheme.bodySmall.copyWith(color: AppColors.neutral600),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ],
          ),
          data: (recruitment) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      recruitment.title,
                      style: AppTheme.headlineMedium.copyWith(
                        color: AppColors.neutral900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: '닫기',
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  _StatusBadge(status: recruitment.status),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    '작성일 ${_formatDate(recruitment.createdAt)}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Divider(color: AppColors.neutral300),
              SizedBox(height: AppSpacing.sm),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (recruitment.content != null &&
                          recruitment.content!.trim().isNotEmpty) ...[
                        Text(
                          '모집 공고 상세',
                          style: AppTheme.titleMedium.copyWith(
                            color: AppColors.neutral800,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          recruitment.content!,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.neutral700,
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                      ],
                      Text(
                        '모집 정보',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppColors.neutral800,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      _InfoGrid(items: [
                        _InfoItem(
                          label: '현재 지원자 수',
                          value: recruitment.showApplicantCount
                              ? '${recruitment.currentApplicantCount}명'
                              : '비공개',
                        ),
                        _InfoItem(
                          label: '최대 모집 인원',
                          value: recruitment.maxApplicants != null
                              ? '${recruitment.maxApplicants}명'
                              : '제한 없음',
                        ),
                        _InfoItem(
                          label: '모집 시작일',
                          value: _formatDateTime(recruitment.recruitmentStartDate),
                        ),
                        _InfoItem(
                          label: '모집 마감일',
                          value: recruitment.recruitmentEndDate != null
                              ? _formatDateTime(recruitment.recruitmentEndDate!)
                              : '마감일 미설정',
                        ),
                      ]),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        '지원서 질문',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppColors.neutral800,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      if (recruitment.applicationQuestions.isEmpty)
                        Text(
                          '등록된 질문이 없습니다.',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.neutral600,
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < recruitment.applicationQuestions.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                                child: _QuestionChip(
                                  index: i + 1,
                                  text: recruitment.applicationQuestions[i],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Divider(color: AppColors.neutral300),
              SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
    this.isEmphasized = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        decoration: isEmphasized
            ? BoxDecoration(
                border: Border.all(color: AppColors.brand.withValues(alpha: 0.2), width: 2),
                borderRadius: BorderRadius.circular(AppRadius.card),
              )
            : null,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.brand),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.headlineSmall.copyWith(
                        color: AppColors.neutral900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate number of columns based on screen width
        final int crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);

        // Calculate spacing based on design system
        const spacing = AppSpacing.xs;

        // Calculate item width with minimum/maximum constraints
        final itemWidth = _calculateItemWidth(constraints.maxWidth, crossAxisCount, spacing);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              child: _InfoTile(item: item),
            );
          }).toList(),
        );
      },
    );
  }

  /// Calculate number of columns based on screen width
  /// - Mobile (0-450px): 1 column
  /// - Tablet (451-800px): 2 columns
  /// - Desktop (801px+): 2 or 4 columns
  int _calculateCrossAxisCount(double width) {
    if (width <= 450) {
      return 1; // Mobile: 1 column
    } else if (width <= 800) {
      return 2; // Tablet: 2 columns
    } else if (width <= 1200) {
      return 2; // Small desktop: 2 columns
    } else {
      return 4; // Large desktop: 4 columns
    }
  }

  /// Calculate item width with responsive layout
  /// Ensures proper spacing and minimum/maximum constraints
  double _calculateItemWidth(double totalWidth, int columns, double spacing) {
    if (columns == 1) {
      return totalWidth; // Full width for single column
    }

    // Calculate width: (total - spacing between items) / number of columns
    final totalSpacing = spacing * (columns - 1);
    final calculatedWidth = (totalWidth - totalSpacing) / columns;

    // Apply minimum/maximum constraints for readability
    const minWidth = 160.0;
    const maxWidth = 400.0;

    return calculatedWidth.clamp(minWidth, maxWidth);
  }
}

class _InfoItem {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      backgroundColor: AppColors.brandLight,
      borderRadius: AppRadius.sm,
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.label,
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.neutral600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            item.value,
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.neutral900,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _QuestionChip extends StatelessWidget {
  const _QuestionChip({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      backgroundColor: AppColors.neutral100,
      borderRadius: AppRadius.card / 2,
      showShadow: false,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral200),
          borderRadius: BorderRadius.circular(AppRadius.card / 2),
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q$index',
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: AppColors.brand,
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral800,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.controller,
    required this.onRemove,
  });

  final int index;
  final TextEditingController controller;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral300, width: 1),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SectionCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 6,
                ),
                backgroundColor: AppColors.brandLight,
                borderRadius: AppRadius.button / 2,
                showShadow: false,
                child: Text(
                  '질문 ${index + 1}',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('삭제'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '질문 내용',
              hintText: '지원자에게 물어보고 싶은 질문을 입력하세요.',
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '질문을 입력해주세요.';
              }
              if (value.trim().length > 500) {
                return '질문은 500자를 초과할 수 없습니다.';
              }
              return null;
            },
          ),
        ],
        ),
      ),
    );
  }
}

class _ChipText extends StatelessWidget {
  const _ChipText({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      backgroundColor: AppColors.brandLight,
      borderRadius: AppRadius.card / 2,
      showShadow: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.brand),
          SizedBox(width: 4),
          Text(
            text,
            style: AppTheme.bodySmall.copyWith(color: AppColors.brand),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final RecruitmentStatus status;

  @override
  Widget build(BuildContext context) {
    final label = _statusLabel(status);
    final color = _statusColor(status);

    return SectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 6,
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      borderRadius: AppRadius.card / 2,
      showShadow: false,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
          color: color,
        ),
      ),
    );
  }
}

String _statusLabel(RecruitmentStatus status) {
  switch (status) {
    case RecruitmentStatus.draft:
      return '작성 중';
    case RecruitmentStatus.open:
      return '모집 중';
    case RecruitmentStatus.closed:
      return '모집 종료';
    case RecruitmentStatus.cancelled:
      return '취소됨';
  }
}

Color _statusColor(RecruitmentStatus status) {
  switch (status) {
    case RecruitmentStatus.draft:
      return AppColors.neutral500;
    case RecruitmentStatus.open:
      return AppColors.brand;
    case RecruitmentStatus.closed:
      return AppColors.neutral600;
    case RecruitmentStatus.cancelled:
      return AppColors.error;
  }
}

String _formatDate(DateTime dateTime) {
  final formatter = DateFormat('yyyy.MM.dd');
  return formatter.format(dateTime);
}

String _formatDateTime(DateTime dateTime) {
  final formatter = DateFormat('yyyy.MM.dd HH:mm');
  return formatter.format(dateTime);
}
