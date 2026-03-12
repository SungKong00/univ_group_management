import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snack_bar_helper.dart';
import '../dialogs/confirm_cancel_actions.dart';
import '../../pages/workspace/providers/post_actions_provider.dart';

/// 게시글 수정 다이얼로그
///
/// 작성자 본인만 수정 가능
class EditPostDialog extends ConsumerStatefulWidget {
  final int postId;
  final String initialContent;
  final VoidCallback? onSuccess;

  const EditPostDialog({
    super.key,
    required this.postId,
    required this.initialContent,
    this.onSuccess,
  });

  @override
  ConsumerState<EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends ConsumerState<EditPostDialog> {
  late final TextEditingController _contentController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      setState(() {
        _errorMessage = '내용을 입력해주세요.';
      });
      return;
    }

    if (content == widget.initialContent) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final params = UpdatePostParams(postId: widget.postId, content: content);

      await ref.read(updatePostProvider(params).future);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
        AppSnackBar.success(context, '게시글이 수정되었습니다.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '게시글 수정에 실패했습니다: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 900;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: isMobile ? screenWidth * 0.9 : 600,
        constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타이틀
              Text(
                '게시글 수정',
                style: AppTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 20),

              // 내용 입력 필드
              TextField(
                controller: _contentController,
                maxLines: 20,
                decoration: InputDecoration(
                  hintText: '수정할 내용을 입력하세요...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.neutral300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.neutral300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.brand,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.neutral100,
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: AppTheme.bodyMedium,
                autofocus: true,
              ),

              // 에러 메시지
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: AppTheme.bodySmall.copyWith(color: AppColors.error),
                ),
              ],

              const SizedBox(height: 24),

              // 액션 버튼
              ConfirmCancelActions(
                confirmText: '수정',
                onConfirm: _isLoading ? null : _handleUpdate,
                isConfirmLoading: _isLoading,
                onCancel: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
