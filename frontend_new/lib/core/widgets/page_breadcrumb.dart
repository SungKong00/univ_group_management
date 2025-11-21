import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/breadcrumb_colors.dart';
import '../theme/responsive_tokens.dart';

// Export breadcrumb style for convenience
export '../theme/colors/breadcrumb_colors.dart' show BreadcrumbStyle;

/// 페이지 경로 표시 컴포넌트 (Issues > Project-001 > Details)
///
/// **기능**:
/// - 계층적 경로 표시
/// - 호버 상태 피드백
/// - 반응형 레이아웃
///
/// **사용 예시**:
/// ```dart
/// PageBreadcrumb(
///   items: ['Issues', 'Project-001', 'Details'],
///   style: BreadcrumbStyle.default_,
///   onItemTap: (index) => print('Tapped: $index'),
/// )
/// ```
class PageBreadcrumb extends StatefulWidget {
  /// 경로 항목 리스트
  final List<String> items;

  /// 스타일 변형
  final BreadcrumbStyle style;

  /// 항목 클릭 콜백
  final Function(int)? onItemTap;

  const PageBreadcrumb({
    super.key,
    required this.items,
    this.style = BreadcrumbStyle.default_,
    this.onItemTap,
  });

  @override
  State<PageBreadcrumb> createState() => _PageBreadcrumbState();
}

class _PageBreadcrumbState extends State<PageBreadcrumb> {
  final Map<int, bool> _hoveredIndices = {};

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;

    // ========================================================
    // Step 1: 스타일에 따른 색상 결정
    // ========================================================
    final breadcrumbColors = switch (widget.style) {
      BreadcrumbStyle.default_ => BreadcrumbColors.default_(colorExt),
      BreadcrumbStyle.dark => BreadcrumbColors.dark(colorExt),
      BreadcrumbStyle.compact => BreadcrumbColors.compact(colorExt),
    };

    final itemSpacing = ResponsiveTokens.space12;
    final separatorSpacing = ResponsiveTokens.space8;

    // ========================================================
    // Step 2: 경로 항목 빌드
    // ========================================================
    final List<Widget> breadcrumbItems = [];

    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final isLast = i == widget.items.length - 1;
      final isHovered = _hoveredIndices[i] ?? false;

      // 현재 항목
      breadcrumbItems.add(
        MouseRegion(
          onEnter: (_) => setState(() => _hoveredIndices[i] = true),
          onExit: (_) => setState(() => _hoveredIndices[i] = false),
          cursor: isLast ? MouseCursor.defer : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: isLast ? null : () => widget.onItemTap?.call(i),
            child: Text(
              item,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isLast
                        ? breadcrumbColors.textActive
                        : (isHovered
                              ? breadcrumbColors.textHover
                              : breadcrumbColors.text),
                  ) ??
                  TextStyle(
                    color: isLast
                        ? breadcrumbColors.textActive
                        : (isHovered
                              ? breadcrumbColors.textHover
                              : breadcrumbColors.text),
                  ),
            ),
          ),
        ),
      );

      // 마지막 항목이 아니면 구분자 추가
      if (!isLast) {
        breadcrumbItems.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: separatorSpacing),
            child: Text(
              '/',
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: breadcrumbColors.separator,
                  ) ??
                  TextStyle(color: breadcrumbColors.separator),
            ),
          ),
        );
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: itemSpacing),
        child: Row(mainAxisSize: MainAxisSize.min, children: breadcrumbItems),
      ),
    );
  }
}
