import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snack_bar_helper.dart';
import '../dialogs/confirm_cancel_actions.dart';
import '../../pages/workspace/providers/post_actions_provider.dart';

/// 게시글 삭제 확인 다이얼로그
///
/// 작성자 본인 또는 MEMBER_MANAGE 권한자만 삭제 가능
class DeletePostDialog extends ConsumerStatefulWidget {
  final int postId;
  final VoidCallback? onSuccess;

  const DeletePostDialog({super.key, required this.postId, this.onSuccess});

  @override
  ConsumerState<DeletePostDialog> createState() => _DeletePostDialogState();
}

class _DeletePostDialogState extends ConsumerState<DeletePostDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleDelete() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(deletePostProvider(widget.postId).future);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
        AppSnackBar.success(context, '게시글이 삭제되었습니다.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '게시글 삭제에 실패했습니다: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 타이틀
            Text(
              '게시글 삭제',
              style: AppTheme.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 16),

            // 설명
            Text(
              '이 게시글을 삭제하시겠습니까?\n삭제된 게시글은 복구할 수 없습니다.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral700,
                height: 1.5,
              ),
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
              confirmText: '삭제',
              onConfirm: _isLoading ? null : _handleDelete,
              isConfirmLoading: _isLoading,
              confirmVariant: PrimaryButtonVariant.error,
              onCancel: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
