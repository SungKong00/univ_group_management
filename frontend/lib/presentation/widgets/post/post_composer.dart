import 'package:flutter/material.dart';
import '../../../core/utils/snack_bar_helper.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// 게시글 작성 입력창 위젯
///
/// - Shift+Enter: 줄바꿈
/// - Enter: 전송
/// - 최대 5줄 자동 높이 조절
/// - 전송 후 입력창 초기화
class PostComposer extends StatefulWidget {
  final bool canWrite;
  final bool canUploadFile;
  final bool isLoading;
  final Future<void> Function(String content) onSubmit;

  const PostComposer({
    super.key,
    required this.canWrite,
    this.canUploadFile = false,
    this.isLoading = false,
    required this.onSubmit,
  });

  @override
  State<PostComposer> createState() => _PostComposerState();
}

class _PostComposerState extends State<PostComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _keyboardListenerFocusNode = FocusNode();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _keyboardListenerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isSending || !widget.canWrite) return;

    _focusNode.unfocus(); // 포커스를 먼저 해제

    setState(() => _isSending = true);

    try {
      await widget.onSubmit(content);
      // 전송 성공 후 입력창 초기화 (composing-related 이슈 방지)
      _controller.value = TextEditingValue.empty;
    } catch (e) {
      // 에러 처리는 부모 컴포넌트에서 처리
      if (mounted) {
        AppSnackBar.error(context, '게시글 전송 실패: ${e.toString()}');
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;
    final hintText = widget.isLoading
        ? '권한 확인 중...'
        : widget.canWrite
        ? (isMobile ? '메시지를 입력하세요...' : '메시지를 입력하세요... (Shift+Enter: 줄바꿈)')
        : '쓰기 권한이 없습니다';

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
          // 파일 첨부 버튼 (FILE_UPLOAD 권한 있을 때만 표시)
          if (widget.canUploadFile)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: IconButton(
                onPressed: isDisabled
                    ? null
                    : () {
                        // TODO: 파일 첨부 기능 (백엔드 구현 후)
                        AppSnackBar.info(context, '파일 첨부 기능은 준비 중입니다');
                      },
                icon: const Icon(Icons.attach_file),
                color: isDisabled ? AppColors.neutral400 : AppColors.neutral600,
                tooltip: '파일 첨부',
              ),
            ),
          // 텍스트 입력 필드
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 120, // 최대 5줄 (24px * 5)
              ),
              child: KeyboardListener(
                focusNode: _keyboardListenerFocusNode,
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
                    // 입력 변경 시 setState 호출 (전송 버튼 활성화 상태 업데이트)
                    setState(() {});
                  },
                  onTapOutside: (event) {
                    _focusNode.unfocus();
                  },
                ),
              ),
            ),
          ),
          // 전송 버튼
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
