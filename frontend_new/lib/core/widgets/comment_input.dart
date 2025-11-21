import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_typography_extension.dart';
import '../theme/colors/editor_colors.dart';
import '../theme/responsive_tokens.dart';

/// 댓글 입력 컴포넌트
///
/// **기능**:
/// - 댓글 입력 필드
/// - 제출 버튼 (자동 활성화/비활성화)
/// - 간단한 포매팅 지원
/// - 실시간 유효성 검사
///
/// **사용 예시**:
/// ```dart
/// CommentInput(
///   onSubmit: (text) => submitComment(text),
/// )
/// ```
class CommentInput extends StatefulWidget {
  /// 댓글 제출 콜백
  final Function(String) onSubmit;

  /// 제출 후 입력 필드 초기화 여부
  final bool clearOnSubmit;

  /// 최대 글자 수
  final int maxLength;

  /// 로딩 상태
  final bool isLoading;

  const CommentInput({
    super.key,
    required this.onSubmit,
    this.clearOnSubmit = true,
    this.maxLength = 2000,
    this.isLoading = false,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSubmit(text);

    if (widget.clearOnSubmit) {
      _controller.clear();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final typographyExt = context.appTypography;
    final width = MediaQuery.sizeOf(context).width;

    // ========================================================
    // Step 1: 에디터 스타일에 따른 색상 결정 (Comment)
    // ========================================================
    final editorColors = EditorColors.comment(colorExt);

    final borderRadius = ResponsiveTokens.componentBorderRadius(width);
    final padding = EdgeInsets.symmetric(
      horizontal: ResponsiveTokens.inputPaddingH(width),
      vertical: ResponsiveTokens.inputPaddingV(width),
    );

    // ========================================================
    // Step 2: 포커스 상태에 따른 색상 결정
    // ========================================================
    final borderColor = _isFocused
        ? editorColors.borderFocus
        : editorColors.border;
    final isSubmitEnabled =
        _controller.text.trim().isNotEmpty && !widget.isLoading;

    // ========================================================
    // Step 3: 입력 필드 빌드
    // ========================================================
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1),
        color: editorColors.background,
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 입력 필드
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLength: widget.maxLength,
            maxLines: null,
            minLines: 3,
            onChanged: (_) => setState(() {}),
            style:
                Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: editorColors.text) ??
                const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              hintStyle:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: editorColors.placeholder,
                  ) ??
                  const TextStyle(color: Colors.grey),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              counterText: '',
              isDense: true,
            ),
          ),

          // ========================================================
          // 푸터: 제출 버튼 및 카운터
          // ========================================================
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 문자 수 카운터
              Text(
                '${_controller.text.length} / ${widget.maxLength}',
                style:
                    Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _controller.text.length >= widget.maxLength * 0.9
                          ? colorExt.stateWarningText
                          : editorColors.text,
                    ) ??
                    const TextStyle(color: Colors.grey),
              ),

              // 제출 버튼
              if (isSubmitEnabled)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleSubmit,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isLoading)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  editorColors.text,
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.send,
                              size: 16,
                              color: editorColors.text,
                            ),
                          const SizedBox(width: 6.0),
                          Text(
                            'Comment',
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.labelMedium?.copyWith(
                                  color: editorColors.text,
                                  fontWeight: FontWeight.w600,
                                ) ??
                                const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Text(
                  'Add text to comment',
                  style:
                      Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: editorColors.placeholder,
                      ) ??
                      const TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
