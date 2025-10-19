import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/recruitment_models.dart';
import '../providers/recruitment_detail_provider.dart';

/// Application Submit Dialog
///
/// Modal bottom sheet for submitting an application to a recruitment.
class ApplicationSubmitDialog extends ConsumerStatefulWidget {
  const ApplicationSubmitDialog({
    required this.recruitment,
    required this.onSubmitSuccess,
    super.key,
  });

  final RecruitmentResponse recruitment;
  final VoidCallback onSubmitSuccess;

  @override
  ConsumerState<ApplicationSubmitDialog> createState() =>
      _ApplicationSubmitDialogState();
}

class _ApplicationSubmitDialogState
    extends ConsumerState<ApplicationSubmitDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, TextEditingController> _answerControllers = {};
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each question
    for (int i = 0; i < widget.recruitment.applicationQuestions.length; i++) {
      _answerControllers[i] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.8;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context),
          const Divider(height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.input),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Recruitment title (context)
                    Text(
                      widget.recruitment.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutral900,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.recruitment.group.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.neutral600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Questions (required)
                    if (widget.recruitment.applicationQuestions.isNotEmpty) ...[
                      Text(
                        '질문 답변 (필수)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.neutral900,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...widget.recruitment.applicationQuestions
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final question = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.brand,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      question,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.neutral800,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              TextFormField(
                                controller: _answerControllers[index],
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: '답변을 입력해주세요',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '답변을 입력해주세요';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Footer buttons
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '지원서 작성',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('제출하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Start submitting
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare question answers
      final questionAnswers = <int, String>{};
      for (final entry in _answerControllers.entries) {
        final answer = entry.value.text.trim();
        if (answer.isNotEmpty) {
          questionAnswers[entry.key] = answer;
        }
      }

      // Create params
      final params = SubmitApplicationParams(
        recruitmentId: widget.recruitment.id,
        motivation: null,
        questionAnswers: questionAnswers,
      );

      // Submit application
      await ref.read(submitApplicationProvider(params).future);

      // Success
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSubmitSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('지원이 완료되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // Error handling
      setState(() {
        _isSubmitting = false;
        _errorMessage = _parseErrorMessage(e.toString());
      });
    }
  }

  String _parseErrorMessage(String error) {
    // Extract meaningful error messages
    if (error.contains('이미 지원')) {
      return '이미 지원하셨습니다';
    } else if (error.contains('마감')) {
      return '모집이 마감되었습니다';
    } else if (error.contains('정원')) {
      return '모집 정원이 초과되었습니다';
    } else if (error.contains('네트워크') || error.contains('connection')) {
      return '네트워크 오류가 발생했습니다. 다시 시도해주세요.';
    } else {
      return '지원서 제출에 실패했습니다. 다시 시도해주세요.';
    }
  }
}
