import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/editor_colors.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';

// Export editor style for convenience
export '../theme/colors/editor_colors.dart' show EditorType;

/// 이슈 제목 편집 컴포넌트
///
/// **기능**:
/// - 제목 입력 필드
/// - 실시간 자동 저장 (콜백)
/// - 포커스 상태 피드백
/// - 최대 길이 제한
///
/// **사용 예시**:
/// ```dart
/// IssueTitleEditor(
///   initialText: 'Bug: Login failed',
///   onChanged: (text) => saveTitle(text),
/// )
/// ```
class IssueTitleEditor extends StatefulWidget {
  /// 초기 텍스트
  final String initialText;

  /// 텍스트 변경 콜백 (자동 저장용)
  final Function(String) onChanged;

  /// 최대 글자 수
  final int maxLength;

  /// 읽기 전용 모드
  final bool isReadOnly;

  const IssueTitleEditor({
    super.key,
    required this.initialText,
    required this.onChanged,
    this.maxLength = 200,
    this.isReadOnly = false,
  });

  @override
  State<IssueTitleEditor> createState() => _IssueTitleEditorState();
}

class _IssueTitleEditorState extends State<IssueTitleEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
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

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final width = MediaQuery.sizeOf(context).width;

    // ========================================================
    // Step 1: 에디터 스타일에 따른 색상 결정 (Title)
    // ========================================================
    final editorColors = EditorColors.title(colorExt);

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

    // ========================================================
    // Step 3: 입력 필드 빌드
    // ========================================================
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: widget.isReadOnly,
      maxLength: widget.maxLength,
      maxLines: 1,
      onChanged: (text) => widget.onChanged(text),
      style:
          Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: editorColors.text) ??
          const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: 'Issue title',
        hintStyle:
            Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: editorColors.placeholder,
            ) ??
            const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: editorColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: borderColor,
            width: BorderTokens.widthThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: editorColors.border,
            width: BorderTokens.widthThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: editorColors.borderFocus,
            width: BorderTokens.widthFocus,
          ),
        ),
        contentPadding: padding,
        counterText: '',
        isDense: true,
        suffixIcon: _controller.text.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.check_circle,
                  color: editorColors.text,
                  size: ComponentSizeTokens.iconSmall,
                ),
              )
            : null,
      ),
    );
  }
}
