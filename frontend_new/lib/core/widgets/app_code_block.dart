import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/code_block_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';
import '../theme/enums.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppCodeBlockLanguage, AppCodeBlockTheme;

/// 코드 블록 컴포넌트
///
/// **용도**: 코드 스니펫 표시, 구문 강조, 복사 기능
/// **접근성**: Semantics 지원
///
/// ```dart
/// // 기본 사용
/// AppCodeBlock(
///   code: 'print("Hello, World!");',
///   language: AppCodeBlockLanguage.dart,
/// )
///
/// // 라인 번호 표시
/// AppCodeBlock(
///   code: myCode,
///   language: AppCodeBlockLanguage.python,
///   showLineNumbers: true,
/// )
/// ```
class AppCodeBlock extends StatefulWidget {
  /// 코드 문자열
  final String code;

  /// 프로그래밍 언어
  final AppCodeBlockLanguage language;

  /// 테마
  final AppCodeBlockTheme theme;

  /// 라인 번호 표시
  final bool showLineNumbers;

  /// 헤더 표시
  final bool showHeader;

  /// 복사 버튼 표시
  final bool showCopyButton;

  /// 파일명 (헤더에 표시)
  final String? filename;

  /// 최대 높이 (스크롤 가능)
  final double? maxHeight;

  /// 하이라이트할 라인 번호들
  final List<int>? highlightLines;

  /// 복사 성공 콜백
  final VoidCallback? onCopy;

  const AppCodeBlock({
    super.key,
    required this.code,
    this.language = AppCodeBlockLanguage.plaintext,
    this.theme = AppCodeBlockTheme.auto,
    this.showLineNumbers = false,
    this.showHeader = true,
    this.showCopyButton = true,
    this.filename,
    this.maxHeight,
    this.highlightLines,
    this.onCopy,
  });

  @override
  State<AppCodeBlock> createState() => _AppCodeBlockState();
}

class _AppCodeBlockState extends State<AppCodeBlock> {
  bool _copied = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    widget.onCopy?.call();

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  String get _languageLabel {
    return switch (widget.language) {
      AppCodeBlockLanguage.dart => 'Dart',
      AppCodeBlockLanguage.javascript => 'JavaScript',
      AppCodeBlockLanguage.typescript => 'TypeScript',
      AppCodeBlockLanguage.python => 'Python',
      AppCodeBlockLanguage.java => 'Java',
      AppCodeBlockLanguage.kotlin => 'Kotlin',
      AppCodeBlockLanguage.json => 'JSON',
      AppCodeBlockLanguage.yaml => 'YAML',
      AppCodeBlockLanguage.markdown => 'Markdown',
      AppCodeBlockLanguage.bash => 'Bash',
      AppCodeBlockLanguage.plaintext => 'Text',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final brightness = Theme.of(context).brightness;
    final colors = CodeBlockColors.from(colorExt, widget.theme, brightness);
    final spacingExt = context.appSpacing;

    final lines = widget.code.split('\n');

    Widget codeContent = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showLineNumbers)
            _LineNumbers(
              count: lines.length,
              colors: colors,
              highlightLines: widget.highlightLines,
            ),
          Padding(
            padding: EdgeInsets.all(spacingExt.medium),
            child: SelectableText.rich(
              TextSpan(
                children: _buildCodeSpans(lines, colors),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: colors.text,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.maxHeight != null) {
      codeContent = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight!),
        child: SingleChildScrollView(child: codeContent),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(
          color: colors.border,
          width: BorderTokens.widthThin,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showHeader)
            _CodeHeader(
              filename: widget.filename,
              languageLabel: _languageLabel,
              colors: colors,
              showCopyButton: widget.showCopyButton,
              copied: _copied,
              onCopy: _copyToClipboard,
            ),
          codeContent,
        ],
      ),
    );
  }

  List<TextSpan> _buildCodeSpans(List<String> lines, CodeBlockColors colors) {
    // 간단한 구문 강조 (실제로는 더 정교한 파서 필요)
    final spans = <TextSpan>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isHighlighted = widget.highlightLines?.contains(i + 1) ?? false;

      if (isHighlighted) {
        spans.add(TextSpan(
          text: line,
          style: TextStyle(
            backgroundColor: colors.selectionBackground,
          ),
        ));
      } else {
        spans.add(TextSpan(text: line));
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }
}

/// 코드 헤더
class _CodeHeader extends StatelessWidget {
  final String? filename;
  final String languageLabel;
  final CodeBlockColors colors;
  final bool showCopyButton;
  final bool copied;
  final VoidCallback onCopy;

  const _CodeHeader({
    required this.filename,
    required this.languageLabel,
    required this.colors,
    required this.showCopyButton,
    required this.copied,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacingExt.medium,
        vertical: spacingExt.small,
      ),
      decoration: BoxDecoration(
        color: colors.headerBackground,
        border: Border(
          bottom: BorderSide(
            color: colors.border,
            width: BorderTokens.widthThin,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              filename ?? languageLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.headerText,
                    fontFamily: 'monospace',
                  ),
            ),
          ),
          if (showCopyButton)
            _CopyButton(
              copied: copied,
              colors: colors,
              onCopy: onCopy,
            ),
        ],
      ),
    );
  }
}

/// 라인 번호
class _LineNumbers extends StatelessWidget {
  final int count;
  final CodeBlockColors colors;
  final List<int>? highlightLines;

  const _LineNumbers({
    required this.count,
    required this.colors,
    this.highlightLines,
  });

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacingExt.small,
        vertical: spacingExt.medium,
      ),
      decoration: BoxDecoration(
        color: colors.lineNumberBackground,
        border: Border(
          right: BorderSide(
            color: colors.border,
            width: BorderTokens.widthThin,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(count, (index) {
          final lineNumber = index + 1;
          final isHighlighted = highlightLines?.contains(lineNumber) ?? false;

          return Container(
            height: 19.5, // 1.5 line height * 13px font
            alignment: Alignment.centerRight,
            decoration: isHighlighted
                ? BoxDecoration(color: colors.selectionBackground)
                : null,
            child: Text(
              '$lineNumber',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: colors.lineNumber,
                height: 1.5,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 복사 버튼
class _CopyButton extends StatefulWidget {
  final bool copied;
  final CodeBlockColors colors;
  final VoidCallback onCopy;

  const _CopyButton({
    required this.copied,
    required this.colors,
    required this.onCopy,
  });

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onCopy,
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BorderTokens.radiusSmall),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.copied ? Icons.check : Icons.copy,
                size: ComponentSizeTokens.iconSmall,
                color: widget.copied
                    ? Colors.green
                    : (_isHovered
                        ? widget.colors.copyButtonHover
                        : widget.colors.copyButton),
              ),
              if (widget.copied) ...[
                const SizedBox(width: 4),
                Text(
                  '복사됨',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 인라인 코드 스니펫
class AppInlineCode extends StatelessWidget {
  /// 코드 문자열
  final String code;

  const AppInlineCode({
    super.key,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorExt.surfaceTertiary,
        borderRadius: BorderRadius.circular(BorderTokens.radiusSmall),
        border: Border.all(
          color: colorExt.borderPrimary,
          width: BorderTokens.widthThin,
        ),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: colorExt.textPrimary,
        ),
      ),
    );
  }
}
