import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// 재사용 가능한 펼치기/접기 콘텐츠 위젯
///
/// 지정된 줄 수 이상의 텍스트를 자동으로 축약하고,
/// "더 보기" 버튼으로 전체 내용을 펼칠 수 있습니다.
///
/// 사용 예시:
/// ```dart
/// CollapsibleContent(
///   content: post.content,
///   maxLines: 3,
///   style: AppTheme.bodyMedium,
/// )
/// ```
class CollapsibleContent extends StatefulWidget {
  /// 표시할 텍스트 내용
  final String content;

  /// 초기 표시 최대 줄 수 (기본값: 5)
  final int maxLines;

  /// 텍스트 스타일 (기본값: AppTheme.bodyMedium)
  final TextStyle? style;

  /// "더 보기" 버튼 텍스트 (기본값: "더 보기")
  final String expandText;

  /// "접기" 버튼 텍스트 (기본값: "접기")
  final String collapseText;

  /// 펼쳤을 때 스크롤 가능 영역으로 제한할지 여부 (기본값: false)
  /// - true 인 경우, 펼쳤을 때 [expandedMaxLines] 줄 높이에 해당하는 영역 내에서 스크롤로 표시합니다.
  final bool expandedScrollable;

  /// [expandedScrollable] 이 true 일 때, 펼친 상태에서 보이는 최대 줄 수 (기본값: 10)
  final int expandedMaxLines;

  const CollapsibleContent({
    super.key,
    required this.content,
    this.maxLines = 5,
    this.style,
    this.expandText = '더 보기',
    this.collapseText = '접기',
    this.expandedScrollable = false,
    this.expandedMaxLines = 10,
  });

  @override
  State<CollapsibleContent> createState() => _CollapsibleContentState();
}

class _CollapsibleContentState extends State<CollapsibleContent> {
  bool _isExpanded = false;
  bool _isOverflowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverflow();
    });
  }

  @override
  void didUpdateWidget(CollapsibleContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.maxLines != widget.maxLines) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkOverflow();
      });
    }
  }

  /// 텍스트가 maxLines를 초과하는지 확인
  void _checkOverflow() {
    // 위젯이 이미 dispose된 경우 즉시 반환하여
    // context나 MediaQuery 접근으로 인한 예외를 방지
    if (!mounted) return;

    // 렌더링 시와 동일한 줄간격(height)을 적용하여 측정 일치
    final base = widget.style ?? AppTheme.bodyMedium;
    final measureStyle = base.copyWith(height: 1.5);
    final textSpan = TextSpan(
      text: widget.content,
      style: measureStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    );

    // 현재 컨텍스트의 최대 너비로 레이아웃
    // context.size가 null일 수 있으므로 안전하게 처리
    final maxWidth = context.size?.width ?? MediaQuery.of(context).size.width;
    textPainter.layout(maxWidth: maxWidth);

    // 위젯이 이미 dispose된 경우 setState를 호출하면 예외가 발생하므로 검사
    final didOverflow = textPainter.didExceedMaxLines;
    if (!mounted) return;

    // 상태가 실제로 바뀌는 경우에만 setState 호출하여 불필요한 rebuild를 방지
    if (didOverflow != _isOverflowing) {
      setState(() {
        _isOverflowing = didOverflow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTextStyle = widget.style ?? AppTheme.bodyMedium;
    final effectiveTextStyle = baseTextStyle.copyWith(
      color: AppColors.neutral900,
      height: 1.5,
    );

    Widget buildCollapsed() {
      return Text(
        widget.content,
        style: effectiveTextStyle,
        maxLines: widget.maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    Widget buildExpanded() {
      if (!widget.expandedScrollable) {
        // 기존 전체 펼치기 동작
        return Text(
          widget.content,
          style: effectiveTextStyle,
        );
      }

      // 펼친 상태를 스크롤 가능한 영역(최대 높이 제한)으로 처리
      // 줄 높이 추정치 = fontSize * height
      final defaultStyle = DefaultTextStyle.of(context).style;
      final fontSize = effectiveTextStyle.fontSize ?? defaultStyle.fontSize ?? 14.0;
      final heightMultiplier = effectiveTextStyle.height ?? defaultStyle.height ?? 1.0;
      final lineHeightPx = fontSize * heightMultiplier;
      final maxVisibleHeight = lineHeightPx * widget.expandedMaxLines;

      return ConstrainedBox(
        constraints: BoxConstraints(
          // 내용이 더 짧으면 그만큼만, 길면 최대 10줄 높이까지 표시
          maxHeight: maxVisibleHeight,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Text(
            widget.content,
            style: effectiveTextStyle,
            softWrap: true,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topLeft,
          child: _isExpanded ? buildExpanded() : buildCollapsed(),
        ),
        if (_isOverflowing) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded ? widget.collapseText : widget.expandText,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.action,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: AppColors.action,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
