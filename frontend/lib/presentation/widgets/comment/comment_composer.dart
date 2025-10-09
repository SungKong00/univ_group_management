import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// 댓글 작성 입력창 위젯
///
/// - Shift+Enter: 줄바꿈
/// - Enter: 전송
/// - 최대 5줄 자동 높이 조절
class CommentComposer extends StatefulWidget {
  final bool canWrite;
  final bool isLoading;
  final Future<void> Function(String content) onSubmit;

  const CommentComposer({
    super.key,
    required this.canWrite,
    this.isLoading = false,
    required this.onSubmit,
  });

  @override
  State<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<CommentComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isSending || !widget.canWrite) return;

    setState(() => _isSending = true);

    try {
      await widget.onSubmit(content);
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('댓글 전송 실패: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.canWrite || widget.isLoading || _isSending;
    final hintText = widget.isLoading
        ? '권한 확인 중...'
        : widget.canWrite
        ? '댓글을 입력하세요...'
        : '댓글 작성 권한이 없습니다';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral300),
        borderRadius: BorderRadius.circular(8),
        color: isDisabled ? AppColors.neutral100 : Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 120, // 최대 5줄
              ),
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  // Enter 키 감지: Shift 없이 Enter만 누른 경우 전송
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter) {
                    if (!HardwareKeyboard.instance.isShiftPressed) {
                      // Enter만 누른 경우 → 전송
                      _handleSubmit();
                    }
                    // Shift+Enter → 기본 동작 (줄바꿈) 유지
                  }
                },
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !isDisabled,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: AppTheme.bodyMedium.copyWith(
                      color: AppColors.neutral500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.neutral900,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                  onTapOutside: (event) {
                    _focusNode.unfocus();
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: _isSending
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.brand,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: _controller.text.trim().isEmpty || isDisabled
                        ? null
                        : _handleSubmit,
                    icon: const Icon(Icons.send),
                    color: _controller.text.trim().isEmpty || isDisabled
                        ? AppColors.neutral400
                        : AppColors.brand,
                    tooltip: '전송',
                  ),
          ),
        ],
      ),
    );
  }
}
