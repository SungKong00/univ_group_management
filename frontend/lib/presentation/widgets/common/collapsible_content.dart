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

  const CollapsibleContent({
    super.key,
    required this.content,
    this.maxLines = 5,
    this.style,
    this.expandText = '더 보기',
    this.collapseText = '접기',
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
    final textStyle = widget.style ?? AppTheme.bodyMedium;
    final textSpan = TextSpan(
      text: widget.content,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    );

    // 현재 컨텍스트의 최대 너비로 레이아웃
    textPainter.layout(maxWidth: context.size?.width ?? double.infinity);

    setState(() {
      _isOverflowing = textPainter.didExceedMaxLines;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.style ?? AppTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Text(
            widget.content,
            style: textStyle.copyWith(
              color: AppColors.neutral900,
              height: 1.5,
            ),
            maxLines: _isExpanded ? null : widget.maxLines,
            overflow: _isExpanded ? null : TextOverflow.ellipsis,
          ),
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
