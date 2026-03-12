import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/rich_text_editor_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/enums.dart';

// Export enums for convenience
export '../theme/enums.dart' show RichTextFormat, AppRichTextEditorSize;

/// 리치 텍스트 에디터 컴포넌트
///
/// **용도**: 서식 있는 텍스트 입력, 게시글 작성
/// **접근성**: 키보드 단축키 지원
///
/// ```dart
/// // 기본 사용
/// AppRichTextEditor(
///   controller: controller,
///   placeholder: '내용을 입력하세요...',
/// )
///
/// // 제한된 포맷
/// AppRichTextEditor(
///   controller: controller,
///   enabledFormats: [
///     RichTextFormat.bold,
///     RichTextFormat.italic,
///     RichTextFormat.link,
///   ],
/// )
/// ```
class AppRichTextEditor extends StatefulWidget {
  /// 에디터 컨트롤러
  final RichTextEditorController? controller;

  /// 플레이스홀더
  final String? placeholder;

  /// 크기
  final AppRichTextEditorSize size;

  /// 활성화된 포맷
  final List<RichTextFormat>? enabledFormats;

  /// 읽기 전용
  final bool readOnly;

  /// 자동 포커스
  final bool autofocus;

  /// 최소 높이
  final double? minHeight;

  /// 최대 높이
  final double? maxHeight;

  /// 툴바 표시 여부
  final bool showToolbar;

  /// 테두리 표시 여부
  final bool showBorder;

  /// 변경 콜백
  final ValueChanged<String>? onChanged;

  /// 포커스 변경 콜백
  final ValueChanged<bool>? onFocusChanged;

  /// 비활성화 여부
  final bool isDisabled;

  const AppRichTextEditor({
    super.key,
    this.controller,
    this.placeholder,
    this.size = AppRichTextEditorSize.medium,
    this.enabledFormats,
    this.readOnly = false,
    this.autofocus = false,
    this.minHeight,
    this.maxHeight,
    this.showToolbar = true,
    this.showBorder = true,
    this.onChanged,
    this.onFocusChanged,
    this.isDisabled = false,
  });

  @override
  State<AppRichTextEditor> createState() => _AppRichTextEditorState();
}

class _AppRichTextEditorState extends State<AppRichTextEditor> {
  late RichTextEditorController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;
  Set<RichTextFormat> _activeFormats = {};

  static const List<RichTextFormat> _defaultFormats = [
    RichTextFormat.bold,
    RichTextFormat.italic,
    RichTextFormat.underline,
    RichTextFormat.strikethrough,
    RichTextFormat.heading1,
    RichTextFormat.heading2,
    RichTextFormat.bulletList,
    RichTextFormat.numberedList,
    RichTextFormat.blockquote,
    RichTextFormat.code,
    RichTextFormat.link,
  ];

  List<RichTextFormat> get _enabledFormats =>
      widget.enabledFormats ?? _defaultFormats;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? RichTextEditorController();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleSelectionChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_handleSelectionChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      widget.onFocusChanged?.call(_isFocused);
    }
  }

  void _handleSelectionChange() {
    final formats = _controller.getActiveFormats();
    if (formats != _activeFormats) {
      setState(() {
        _activeFormats = formats;
      });
    }
    widget.onChanged?.call(_controller.toPlainText());
  }

  void _toggleFormat(RichTextFormat format) {
    if (widget.readOnly || widget.isDisabled) return;

    setState(() {
      if (_activeFormats.contains(format)) {
        _activeFormats.remove(format);
        _controller.removeFormat(format);
      } else {
        // 헤딩은 상호 배타적
        if (format == RichTextFormat.heading1 ||
            format == RichTextFormat.heading2 ||
            format == RichTextFormat.heading3) {
          _activeFormats.removeAll([
            RichTextFormat.heading1,
            RichTextFormat.heading2,
            RichTextFormat.heading3,
          ]);
        }
        _activeFormats.add(format);
        _controller.applyFormat(format);
      }
    });
  }

  double get _editorHeight {
    return switch (widget.size) {
      AppRichTextEditorSize.small => widget.minHeight ?? 120,
      AppRichTextEditorSize.medium => widget.minHeight ?? 200,
      AppRichTextEditorSize.large => widget.minHeight ?? 300,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = RichTextEditorColors.from(colorExt);

    final isDisabled = widget.isDisabled || widget.readOnly;

    return Semantics(
      label: '리치 텍스트 에디터',
      textField: true,
      child: AnimatedContainer(
        duration: AnimationTokens.durationQuick,
        decoration: widget.showBorder
            ? BoxDecoration(
                border: Border.all(
                  color: _isFocused ? colors.borderFocus : colors.border,
                  width: BorderTokens.widthThin,
                ),
                borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showToolbar && !widget.readOnly) ...[
              _Toolbar(
                enabledFormats: _enabledFormats,
                activeFormats: _activeFormats,
                colors: colors,
                isDisabled: widget.isDisabled,
                onFormatPressed: _toggleFormat,
              ),
              Container(height: 1, color: colors.border),
            ],
            Container(
              constraints: BoxConstraints(
                minHeight: _editorHeight,
                maxHeight:
                    widget.maxHeight ?? 500, // double.infinity 대신 기본 최대 높이 설정
              ),
              child: Container(
                color: isDisabled
                    ? colors.background.withValues(alpha: 0.5)
                    : colors.background,
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        HardwareKeyboard.instance.isControlPressed) {
                      if (event.logicalKey == LogicalKeyboardKey.keyB) {
                        _toggleFormat(RichTextFormat.bold);
                      } else if (event.logicalKey == LogicalKeyboardKey.keyI) {
                        _toggleFormat(RichTextFormat.italic);
                      } else if (event.logicalKey == LogicalKeyboardKey.keyU) {
                        _toggleFormat(RichTextFormat.underline);
                      }
                    }
                  },
                  child: TextField(
                    controller: _controller._textController,
                    focusNode: _focusNode,
                    autofocus: widget.autofocus,
                    readOnly: widget.readOnly,
                    enabled: !widget.isDisabled,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: _getTextStyle(colors),
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: TextStyle(color: colors.placeholder),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(spacingExt.medium),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _getTextStyle(RichTextEditorColors colors) {
    var style = TextStyle(
      color: colors.text,
      fontSize: switch (widget.size) {
        AppRichTextEditorSize.small => 14,
        AppRichTextEditorSize.medium => 16,
        AppRichTextEditorSize.large => 18,
      },
    );

    if (_activeFormats.contains(RichTextFormat.bold)) {
      style = style.copyWith(fontWeight: FontWeight.bold);
    }
    if (_activeFormats.contains(RichTextFormat.italic)) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }
    if (_activeFormats.contains(RichTextFormat.underline)) {
      style = style.copyWith(decoration: TextDecoration.underline);
    }
    if (_activeFormats.contains(RichTextFormat.strikethrough)) {
      style = style.copyWith(decoration: TextDecoration.lineThrough);
    }
    if (_activeFormats.contains(RichTextFormat.heading1)) {
      style = style.copyWith(fontSize: 28, fontWeight: FontWeight.bold);
    }
    if (_activeFormats.contains(RichTextFormat.heading2)) {
      style = style.copyWith(fontSize: 24, fontWeight: FontWeight.bold);
    }
    if (_activeFormats.contains(RichTextFormat.heading3)) {
      style = style.copyWith(fontSize: 20, fontWeight: FontWeight.w600);
    }

    return style;
  }
}

/// 리치 텍스트 에디터 컨트롤러
class RichTextEditorController extends ChangeNotifier {
  final TextEditingController _textController;
  final Map<TextRange, Set<RichTextFormat>> _formatRanges = {};

  RichTextEditorController({String? initialText})
    : _textController = TextEditingController(text: initialText) {
    _textController.addListener(notifyListeners);
  }

  /// 현재 텍스트
  String get text => _textController.text;

  /// 텍스트 설정
  set text(String value) {
    _textController.text = value;
  }

  /// 현재 선택 범위
  TextSelection get selection => _textController.selection;

  /// 선택 범위 설정
  set selection(TextSelection value) {
    _textController.selection = value;
  }

  /// 플레인 텍스트 반환
  String toPlainText() => _textController.text;

  /// 현재 선택 위치의 활성 포맷 반환
  Set<RichTextFormat> getActiveFormats() {
    if (_textController.selection.isCollapsed) {
      return {};
    }

    final Set<RichTextFormat> active = {};
    final selection = _textController.selection;

    for (final entry in _formatRanges.entries) {
      if (entry.key.start <= selection.start &&
          entry.key.end >= selection.end) {
        active.addAll(entry.value);
      }
    }

    return active;
  }

  /// 포맷 적용
  void applyFormat(RichTextFormat format) {
    if (_textController.selection.isCollapsed) return;

    final selection = _textController.selection;
    final range = TextRange(start: selection.start, end: selection.end);

    if (_formatRanges.containsKey(range)) {
      _formatRanges[range]!.add(format);
    } else {
      _formatRanges[range] = {format};
    }

    notifyListeners();
  }

  /// 포맷 제거
  void removeFormat(RichTextFormat format) {
    if (_textController.selection.isCollapsed) return;

    final selection = _textController.selection;
    final range = TextRange(start: selection.start, end: selection.end);

    if (_formatRanges.containsKey(range)) {
      _formatRanges[range]!.remove(format);
      if (_formatRanges[range]!.isEmpty) {
        _formatRanges.remove(range);
      }
    }

    notifyListeners();
  }

  /// 모든 포맷 초기화
  void clearFormatting() {
    _formatRanges.clear();
    notifyListeners();
  }

  /// 텍스트 삽입
  void insertText(String text) {
    final selection = _textController.selection;
    final newText = _textController.text.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(
      offset: selection.start + text.length,
    );
  }

  /// 텍스트 초기화
  void clear() {
    _textController.clear();
    _formatRanges.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

/// 툴바 위젯
class _Toolbar extends StatelessWidget {
  final List<RichTextFormat> enabledFormats;
  final Set<RichTextFormat> activeFormats;
  final RichTextEditorColors colors;
  final bool isDisabled;
  final ValueChanged<RichTextFormat> onFormatPressed;

  const _Toolbar({
    required this.enabledFormats,
    required this.activeFormats,
    required this.colors,
    required this.isDisabled,
    required this.onFormatPressed,
  });

  static const Map<RichTextFormat, IconData> _formatIcons = {
    RichTextFormat.bold: Icons.format_bold,
    RichTextFormat.italic: Icons.format_italic,
    RichTextFormat.underline: Icons.format_underlined,
    RichTextFormat.strikethrough: Icons.format_strikethrough,
    RichTextFormat.heading1: Icons.looks_one,
    RichTextFormat.heading2: Icons.looks_two,
    RichTextFormat.heading3: Icons.looks_3,
    RichTextFormat.bulletList: Icons.format_list_bulleted,
    RichTextFormat.numberedList: Icons.format_list_numbered,
    RichTextFormat.blockquote: Icons.format_quote,
    RichTextFormat.code: Icons.code,
    RichTextFormat.link: Icons.link,
  };

  static const Map<RichTextFormat, String> _formatTooltips = {
    RichTextFormat.bold: '굵게 (Ctrl+B)',
    RichTextFormat.italic: '기울임 (Ctrl+I)',
    RichTextFormat.underline: '밑줄 (Ctrl+U)',
    RichTextFormat.strikethrough: '취소선',
    RichTextFormat.heading1: '제목 1',
    RichTextFormat.heading2: '제목 2',
    RichTextFormat.heading3: '제목 3',
    RichTextFormat.bulletList: '글머리 기호 목록',
    RichTextFormat.numberedList: '번호 매기기 목록',
    RichTextFormat.blockquote: '인용구',
    RichTextFormat.code: '코드',
    RichTextFormat.link: '링크 삽입',
  };

  // 포맷 그룹 정의
  static const List<List<RichTextFormat>> _formatGroups = [
    [
      RichTextFormat.bold,
      RichTextFormat.italic,
      RichTextFormat.underline,
      RichTextFormat.strikethrough,
    ],
    [RichTextFormat.heading1, RichTextFormat.heading2, RichTextFormat.heading3],
    [RichTextFormat.bulletList, RichTextFormat.numberedList],
    [RichTextFormat.blockquote, RichTextFormat.code, RichTextFormat.link],
  ];

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    return Container(
      color: colors.toolbarBackground,
      padding: EdgeInsets.symmetric(
        horizontal: spacingExt.small,
        vertical: spacingExt.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _formatGroups.map((group) {
            final enabledInGroup = group
                .where((f) => enabledFormats.contains(f))
                .toList();
            if (enabledInGroup.isEmpty) return const SizedBox.shrink();

            return Row(
              children: [
                ...enabledInGroup.map((format) {
                  final isActive = activeFormats.contains(format);
                  return _ToolbarButton(
                    icon: _formatIcons[format]!,
                    tooltip: _formatTooltips[format]!,
                    isActive: isActive,
                    isDisabled: isDisabled,
                    colors: colors,
                    onPressed: () => onFormatPressed(format),
                  );
                }),
                Container(
                  width: 1,
                  height: 24,
                  margin: EdgeInsets.symmetric(horizontal: spacingExt.xs),
                  color: colors.border,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 툴바 버튼
class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final bool isDisabled;
  final RichTextEditorColors colors;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.isDisabled,
    required this.colors,
    required this.onPressed,
  });

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.transparent;
    if (widget.isActive) {
      backgroundColor = widget.colors.toolbarButtonActive.withValues(
        alpha: 0.15,
      );
    } else if (_isHovered && !widget.isDisabled) {
      backgroundColor = widget.colors.toolbarButtonHover;
    }

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.isDisabled ? null : widget.onPressed,
          child: AnimatedContainer(
            duration: AnimationTokens.durationQuick,
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: widget.isDisabled
                  ? widget.colors.toolbarButton.withValues(alpha: 0.4)
                  : widget.isActive
                  ? widget.colors.toolbarButtonActive
                  : widget.colors.toolbarButton,
            ),
          ),
        ),
      ),
    );
  }
}
