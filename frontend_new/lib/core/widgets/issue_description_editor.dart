import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/editor_colors.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';

/// 이슈 설명 편집 컴포넌트
///
/// **기능**:
/// - 다중 라인 텍스트 입력
/// - 마크다운 포맷팅 도구바 (Bold, Italic, Code, Link)
/// - 실시간 자동 저장
/// - 프리뷰 모드 (옵션)
///
/// **사용 예시**:
/// ```dart
/// IssueDescriptionEditor(
///   initialText: '## Description\nThis is a bug...',
///   onChanged: (text) => saveDescription(text),
/// )
/// ```
class IssueDescriptionEditor extends StatefulWidget {
  /// 초기 텍스트
  final String initialText;

  /// 텍스트 변경 콜백
  final Function(String) onChanged;

  /// 최대 글자 수
  final int maxLength;

  /// 읽기 전용 모드
  final bool isReadOnly;

  /// 포매팅 도구바 표시 여부
  final bool showToolbar;

  const IssueDescriptionEditor({
    super.key,
    required this.initialText,
    required this.onChanged,
    this.maxLength = 5000,
    this.isReadOnly = false,
    this.showToolbar = true,
  });

  @override
  State<IssueDescriptionEditor> createState() => _IssueDescriptionEditorState();
}

class _IssueDescriptionEditorState extends State<IssueDescriptionEditor> {
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

  void _insertMarkdown(String prefix, String suffix) {
    final text = _controller.text;
    final selection = _controller.selection;

    if (selection.start >= 0 && selection.end >= 0) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );

      _controller.text = newText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(
          offset: selection.start + prefix.length + selectedText.length,
        ),
      );

      widget.onChanged(newText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final width = MediaQuery.sizeOf(context).width;

    // ========================================================
    // Step 1: 에디터 스타일에 따른 색상 결정 (Default)
    // ========================================================
    final editorColors = EditorColors.default_(colorExt);

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
    // Step 3: 포매팅 도구바
    // ========================================================
    final toolbar = widget.showToolbar
        ? Container(
            decoration: BoxDecoration(
              color: editorColors.toolbarBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                topRight: Radius.circular(borderRadius),
              ),
              border: Border(
                bottom: BorderSide(
                  color: editorColors.border,
                  width: BorderTokens.widthThin,
                ),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveTokens.cardPadding(width),
              vertical: ResponsiveTokens.cardPadding(width),
            ),
            child: Row(
              children: [
                // Bold
                IconButton(
                  onPressed: () => _insertMarkdown('**', '**'),
                  icon: const Icon(Icons.format_bold),
                  tooltip: 'Bold (Ctrl+B)',
                  iconSize: 18,
                  padding: EdgeInsets.all(
                    ResponsiveTokens.buttonSmallPaddingH(width) / 2,
                  ),
                  color: editorColors.toolbarButtonDefault,
                ),
                // Italic
                IconButton(
                  onPressed: () => _insertMarkdown('*', '*'),
                  icon: const Icon(Icons.format_italic),
                  tooltip: 'Italic (Ctrl+I)',
                  iconSize: 18,
                  padding: EdgeInsets.all(
                    ResponsiveTokens.buttonSmallPaddingH(width) / 2,
                  ),
                  color: editorColors.toolbarButtonDefault,
                ),
                // Code
                IconButton(
                  onPressed: () => _insertMarkdown('`', '`'),
                  icon: const Icon(Icons.code),
                  tooltip: 'Code',
                  iconSize: 18,
                  padding: EdgeInsets.all(
                    ResponsiveTokens.buttonSmallPaddingH(width) / 2,
                  ),
                  color: editorColors.toolbarButtonDefault,
                ),
                const Spacer(),
                // Link
                IconButton(
                  onPressed: () => _insertMarkdown('[', '](url)'),
                  icon: const Icon(Icons.link),
                  tooltip: 'Link',
                  iconSize: 18,
                  padding: EdgeInsets.all(
                    ResponsiveTokens.buttonSmallPaddingH(width) / 2,
                  ),
                  color: editorColors.toolbarButtonDefault,
                ),
              ],
            ),
          )
        : null;

    // ========================================================
    // Step 4: 입력 필드 빌드
    // ========================================================
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (toolbar != null) toolbar,
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          readOnly: widget.isReadOnly,
          maxLength: widget.maxLength,
          maxLines: null,
          minLines: 6,
          onChanged: (text) => widget.onChanged(text),
          style:
              Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: editorColors.text) ??
              const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Describe the issue...',
            hintStyle:
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: editorColors.placeholder,
                ) ??
                const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: editorColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(borderRadius),
                bottomRight: Radius.circular(borderRadius),
                topLeft: widget.showToolbar
                    ? Radius.zero
                    : Radius.circular(borderRadius),
                topRight: widget.showToolbar
                    ? Radius.zero
                    : Radius.circular(borderRadius),
              ),
              borderSide: BorderSide(
                color: borderColor,
                width: BorderTokens.widthThin,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(borderRadius),
                bottomRight: Radius.circular(borderRadius),
                topLeft: widget.showToolbar
                    ? Radius.zero
                    : Radius.circular(borderRadius),
                topRight: widget.showToolbar
                    ? Radius.zero
                    : Radius.circular(borderRadius),
              ),
              borderSide: BorderSide(
                color: editorColors.border,
                width: BorderTokens.widthThin,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(borderRadius),
                bottomRight: Radius.circular(borderRadius),
                topLeft: widget.showToolbar
                    ? Radius.zero
                    : Radius.circular(borderRadius),
                topRight: widget.showToolbar
                    ? Radius.zero
                    : Radius.circular(borderRadius),
              ),
              borderSide: BorderSide(
                color: editorColors.borderFocus,
                width: BorderTokens.widthFocus,
              ),
            ),
            contentPadding: padding,
            counterText: '',
            isDense: false,
          ),
        ),
      ],
    );
  }
}
