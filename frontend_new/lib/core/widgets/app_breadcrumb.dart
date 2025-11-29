import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/breadcrumb_colors.dart';
import '../theme/enums.dart';
import '../theme/animation_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppBreadcrumbSeparator, BreadcrumbStyle;

/// 브레드크럼 아이템 데이터
class AppBreadcrumbItem {
  /// 라벨
  final String label;

  /// 아이콘 (선택적)
  final IconData? icon;

  /// 클릭 콜백 (null이면 현재 페이지로 간주)
  final VoidCallback? onTap;

  const AppBreadcrumbItem({required this.label, this.icon, this.onTap});
}

/// 브레드크럼 컴포넌트
///
/// **용도**: 페이지 경로 표시, 네비게이션 히스토리
/// **접근성**: 스크린 리더 지원, 키보드 네비게이션
///
/// ```dart
/// AppBreadcrumb(
///   items: [
///     AppBreadcrumbItem(label: '홈', icon: Icons.home, onTap: () {}),
///     AppBreadcrumbItem(label: '제품', onTap: () {}),
///     AppBreadcrumbItem(label: '상세'), // 현재 페이지
///   ],
/// )
/// ```
class AppBreadcrumb extends StatelessWidget {
  /// 아이템 목록
  final List<AppBreadcrumbItem> items;

  /// 구분자 타입
  final AppBreadcrumbSeparator separator;

  /// 스타일
  final BreadcrumbStyle style;

  /// 최대 표시 개수 (초과 시 ... 표시)
  final int? maxItems;

  /// 축소 모드 (모바일용)
  final bool collapsed;

  const AppBreadcrumb({
    super.key,
    required this.items,
    this.separator = AppBreadcrumbSeparator.chevron,
    this.style = BreadcrumbStyle.default_,
    this.maxItems,
    this.collapsed = false,
  });

  String get _separatorChar => switch (separator) {
    AppBreadcrumbSeparator.slash => '/',
    AppBreadcrumbSeparator.arrow => '>',
    AppBreadcrumbSeparator.chevron => '›',
    AppBreadcrumbSeparator.dot => '•',
  };

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = BreadcrumbColors.from(colorExt, style);

    if (items.isEmpty) return const SizedBox.shrink();

    // 축소 모드: 마지막 2개만 표시
    if (collapsed && items.length > 2) {
      return _buildCollapsed(colors, spacingExt);
    }

    // 최대 개수 제한
    final displayItems = maxItems != null && items.length > maxItems!
        ? _getCollapsedItems()
        : items;

    return Semantics(
      label: '브레드크럼 네비게이션',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < displayItems.length; i++) ...[
              if (displayItems[i].label == '...')
                _buildEllipsis(colors, spacingExt)
              else
                _BreadcrumbItemWidget(
                  item: displayItems[i],
                  isLast: i == displayItems.length - 1,
                  colors: colors,
                  spacing: spacingExt,
                ),
              if (i < displayItems.length - 1)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacingExt.xs),
                  child: Text(
                    _separatorChar,
                    style: TextStyle(color: colors.separator, fontSize: 14),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsed(BreadcrumbColors colors, AppSpacingExtension spacing) {
    final first = items.first;
    final last = items.last;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (first.icon != null) Icon(first.icon, size: 16, color: colors.icon),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.xs),
          child: Text(
            _separatorChar,
            style: TextStyle(color: colors.separator, fontSize: 14),
          ),
        ),
        Text('...', style: TextStyle(color: colors.text, fontSize: 14)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.xs),
          child: Text(
            _separatorChar,
            style: TextStyle(color: colors.separator, fontSize: 14),
          ),
        ),
        Text(
          last.label,
          style: TextStyle(
            color: colors.textActive,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEllipsis(BreadcrumbColors colors, AppSpacingExtension spacing) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.xs),
      child: Text('...', style: TextStyle(color: colors.text, fontSize: 14)),
    );
  }

  List<AppBreadcrumbItem> _getCollapsedItems() {
    if (maxItems == null || items.length <= maxItems!) return items;

    return [
      items.first,
      const AppBreadcrumbItem(label: '...'),
      ...items.skip(items.length - (maxItems! - 2)),
    ];
  }
}

/// 브레드크럼 아이템 위젯
class _BreadcrumbItemWidget extends StatefulWidget {
  final AppBreadcrumbItem item;
  final bool isLast;
  final BreadcrumbColors colors;
  final AppSpacingExtension spacing;

  const _BreadcrumbItemWidget({
    required this.item,
    required this.isLast,
    required this.colors,
    required this.spacing,
  });

  @override
  State<_BreadcrumbItemWidget> createState() => _BreadcrumbItemWidgetState();
}

class _BreadcrumbItemWidgetState extends State<_BreadcrumbItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colors = widget.colors;
    final isClickable = item.onTap != null && !widget.isLast;

    return Semantics(
      label: item.label,
      button: isClickable,
      child: MouseRegion(
        cursor: isClickable
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: isClickable ? item.onTap : null,
          child: AnimatedContainer(
            duration: AnimationTokens.durationQuick,
            padding: EdgeInsets.symmetric(
              horizontal: widget.spacing.xs,
              vertical: widget.spacing.labelDescriptionGap,
            ),
            decoration: BoxDecoration(
              color: _isHovered && isClickable
                  ? colors.backgroundHover
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon,
                    size: 16,
                    color: widget.isLast
                        ? colors.textActive
                        : _isHovered
                        ? colors.textHover
                        : colors.icon,
                  ),
                  SizedBox(width: widget.spacing.labelDescriptionGap),
                ],
                Text(
                  item.label,
                  style: TextStyle(
                    color: widget.isLast
                        ? colors.textActive
                        : _isHovered && isClickable
                        ? colors.textHover
                        : colors.text,
                    fontSize: 14,
                    fontWeight: widget.isLast
                        ? FontWeight.w500
                        : FontWeight.w400,
                    decoration: _isHovered && isClickable
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
