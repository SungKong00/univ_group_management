import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../providers/comment_list_notifier.dart';

/// 댓글 입력 위젯
///
/// 댓글 작성 입력 필드와 버튼을 제공합니다.
/// - TextField 또는 AppFormField 사용
/// - 입력 검증 (빈 댓글 방지)
/// - CommentListNotifier.createComment 호출
/// - 로딩 상태 표시 (버튼 비활성화)
/// - 작성 완료 시 입력 필드 초기화
/// - 에러 처리 (SnackBar)
/// - 100줄 원칙 준수
class CommentInput extends ConsumerStatefulWidget {
  final int postId;
  final int? parentCommentId;

  const CommentInput({super.key, required this.postId, this.parentCommentId});

  @override
  ConsumerState<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends ConsumerState<CommentInput> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                hintText: '댓글을 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSubmit(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('작성'),
          ),
        ],
      ),
    );
  }

  /// 댓글 작성 핸들러
  Future<void> _handleSubmit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(commentListProvider(widget.postId).notifier);
      await notifier.createComment(
        content,
        parentCommentId: widget.parentCommentId,
      );
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
