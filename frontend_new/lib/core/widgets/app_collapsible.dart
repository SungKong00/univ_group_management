import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/collapsible_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/enums.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppCollapsibleStyle;

/// 접기/펼치기 컴포넌트
///
/// **용도**: 콘텐츠 접기, 섹션 축소, FAQ
/// **접근성**: 키보드 조작, ARIA 지원
///
/// ```dart
/// // 기본 사용
/// AppCollapsible(
///   title: '더 보기',
///   child: Text('숨겨진 콘텐츠'),
/// )
///
/// // 스타일 지정
/// AppCollapsible(
///   title: '섹션 제목',
///   style: AppCollapsibleStyle.bordered,
///   initiallyExpanded: true,
///   child: SectionContent(),
/// )
/// ```
class AppCollapsible extends StatefulWidget {
  /// 헤더 제목
  final String title;

  /// 헤더 부제목
  final String? subtitle;

  /// 헤더 선행 위젯
  final Widget? leading;

  /// 헤더 후행 위젯 (아이콘 외)
  final Widget? trailing;

  /// 콘텐츠 위젯
  final Widget child;

  /// 스타일
  final AppCollapsibleStyle style;

  /// 초기 펼침 상태
  final bool initiallyExpanded;

  /// 펼침 상태 변경 콜백
  final ValueChanged<bool>? onExpansionChanged;

  /// 외부에서 펼침 상태 제어
  final bool? isExpanded;

  /// 아이콘 회전 애니메이션 사용
  final bool animateIcon;

  /// 커스텀 확장 아이콘
  final IconData? expandIcon;

  /// 커스텀 축소 아이콘
  final IconData? collapseIcon;

  const AppCollapsible({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.trailing,
    this.style = AppCollapsibleStyle.plain,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.isExpanded,
    this.animateIcon = true,
    this.expandIcon,
    this.collapseIcon,
  });

  @override
  State<AppCollapsible> createState() => _AppCollapsibleState();
}

class _AppCollapsibleState extends State<AppCollapsible>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconRotation;
  late Animation<double> _heightFactor;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded ?? widget.initiallyExpanded;
    _controller = AnimationController(
      duration: AnimationTokens.durationSmooth,
      vsync: this,
    );

    _iconRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: AnimationTokens.curveSmooth),
    );

    _heightFactor = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AnimationTokens.curveSmooth),
    );

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AppCollapsible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != null && widget.isExpanded != _isExpanded) {
      _setExpanded(widget.isExpanded!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setExpanded(bool expanded) {
    setState(() {
      _isExpanded = expanded;
    });
    if (expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    widget.onExpansionChanged?.call(expanded);
  }

  void _toggleExpanded() {
    _setExpanded(!_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = CollapsibleColors.from(colorExt, widget.style);

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          title: widget.title,
          subtitle: widget.subtitle,
          leading: widget.leading,
          trailing: widget.trailing,
          isExpanded: _isExpanded,
          colors: colors,
          iconRotation: widget.animateIcon ? _iconRotation : null,
          expandIcon: widget.expandIcon,
          collapseIcon: widget.collapseIcon,
          onTap: _toggleExpanded,
        ),
        ClipRect(
          child: AnimatedBuilder(
            animation: _heightFactor,
            builder: (context, child) {
              return Align(heightFactor: _heightFactor.value, child: child);
            },
            child: Padding(
              padding: EdgeInsets.all(spacingExt.medium),
              child: widget.child,
            ),
          ),
        ),
      ],
    );

    return switch (widget.style) {
      AppCollapsibleStyle.plain => content,
      AppCollapsibleStyle.bordered => Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: colors.border,
            width: BorderTokens.widthThin,
          ),
          borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        ),
        child: content,
      ),
      AppCollapsibleStyle.card => Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
          border: Border.all(
            color: colors.border,
            width: BorderTokens.widthThin,
          ),
        ),
        child: content,
      ),
    };
  }
}

/// 헤더 위젯
class _Header extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool isExpanded;
  final CollapsibleColors colors;
  final Animation<double>? iconRotation;
  final IconData? expandIcon;
  final IconData? collapseIcon;
  final VoidCallback onTap;

  const _Header({
    required this.title,
    required this.isExpanded,
    required this.colors,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.trailing,
    this.iconRotation,
    this.expandIcon,
    this.collapseIcon,
  });

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          padding: EdgeInsets.all(spacingExt.medium),
          color: _isHovered
              ? widget.colors.backgroundHover
              : widget.colors.headerBackground,
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                SizedBox(width: spacingExt.small),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: widget.colors.headerText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.colors.icon,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                widget.trailing!,
                SizedBox(width: spacingExt.small),
              ],
              _buildIcon(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final icon = widget.isExpanded
        ? (widget.collapseIcon ?? Icons.expand_less)
        : (widget.expandIcon ?? Icons.expand_more);

    if (widget.iconRotation != null && widget.expandIcon == null) {
      return RotationTransition(
        turns: widget.iconRotation!,
        child: Icon(Icons.expand_more, color: widget.colors.icon),
      );
    }

    return Icon(icon, color: widget.colors.icon);
  }
}

/// 다중 Collapsible 그룹 (아코디언처럼 하나만 열림)
class AppCollapsibleGroup extends StatefulWidget {
  /// 아이템 목록
  final List<AppCollapsibleItem> items;

  /// 스타일
  final AppCollapsibleStyle style;

  /// 하나만 열리도록 제한
  final bool singleExpand;

  /// 초기에 열린 인덱스
  final int? initialExpandedIndex;

  const AppCollapsibleGroup({
    super.key,
    required this.items,
    this.style = AppCollapsibleStyle.bordered,
    this.singleExpand = true,
    this.initialExpandedIndex,
  });

  @override
  State<AppCollapsibleGroup> createState() => _AppCollapsibleGroupState();
}

class _AppCollapsibleGroupState extends State<AppCollapsibleGroup> {
  late Set<int> _expandedIndices;

  @override
  void initState() {
    super.initState();
    _expandedIndices = widget.initialExpandedIndex != null
        ? {widget.initialExpandedIndex!}
        : {};
  }

  void _handleExpansionChanged(int index, bool expanded) {
    setState(() {
      if (expanded) {
        if (widget.singleExpand) {
          _expandedIndices = {index};
        } else {
          _expandedIndices.add(index);
        }
      } else {
        _expandedIndices.remove(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    return Column(
      children: widget.items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == widget.items.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : spacingExt.small),
          child: AppCollapsible(
            title: item.title,
            subtitle: item.subtitle,
            leading: item.leading,
            trailing: item.trailing,
            style: widget.style,
            isExpanded: _expandedIndices.contains(index),
            onExpansionChanged: (expanded) =>
                _handleExpansionChanged(index, expanded),
            child: item.child,
          ),
        );
      }).toList(),
    );
  }
}

/// Collapsible 아이템 데이터
class AppCollapsibleItem {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget child;

  const AppCollapsibleItem({
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.trailing,
  });
}
