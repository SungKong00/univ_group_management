import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/accordion_colors.dart';
import '../theme/enums.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppAccordionStyle;

/// 아코디언 아이템 데이터 모델
class AppAccordionItem {
  /// 헤더 제목
  final String title;

  /// 헤더 부제목 (선택)
  final String? subtitle;

  /// 헤더 아이콘 (선택)
  final IconData? icon;

  /// 콘텐츠 위젯
  final Widget content;

  /// 초기 펼침 상태
  final bool initiallyExpanded;

  /// 비활성화 여부
  final bool isDisabled;

  const AppAccordionItem({
    required this.title,
    this.subtitle,
    this.icon,
    required this.content,
    this.initiallyExpanded = false,
    this.isDisabled = false,
  });
}

/// 아코디언 컴포넌트
///
/// **용도**: FAQ, 접힘/펼침 콘텐츠, 설정 섹션
/// **접근성**: 키보드 네비게이션, 스크린 리더 지원
///
/// ```dart
/// // 기본 사용
/// AppAccordion(
///   items: [
///     AppAccordionItem(
///       title: '섹션 1',
///       content: Text('내용 1'),
///     ),
///     AppAccordionItem(
///       title: '섹션 2',
///       content: Text('내용 2'),
///     ),
///   ],
/// )
///
/// // 단일 열기 모드
/// AppAccordion(
///   items: [...],
///   allowMultiple: false,
/// )
/// ```
class AppAccordion extends StatefulWidget {
  /// 아코디언 아이템 목록
  final List<AppAccordionItem> items;

  /// 아코디언 스타일
  final AppAccordionStyle style;

  /// 다중 펼침 허용 여부
  final bool allowMultiple;

  /// 펼침 상태 변경 콜백
  final ValueChanged<Set<int>>? onExpansionChanged;

  const AppAccordion({
    super.key,
    required this.items,
    this.style = AppAccordionStyle.bordered,
    this.allowMultiple = true,
    this.onExpansionChanged,
  });

  @override
  State<AppAccordion> createState() => _AppAccordionState();
}

class _AppAccordionState extends State<AppAccordion> {
  late Set<int> _expandedIndices;

  @override
  void initState() {
    super.initState();
    _expandedIndices = {};
    for (int i = 0; i < widget.items.length; i++) {
      if (widget.items[i].initiallyExpanded) {
        _expandedIndices.add(i);
      }
    }
  }

  void _handleExpansion(int index) {
    if (widget.items[index].isDisabled) return;

    setState(() {
      if (_expandedIndices.contains(index)) {
        _expandedIndices.remove(index);
      } else {
        if (!widget.allowMultiple) {
          _expandedIndices.clear();
        }
        _expandedIndices.add(index);
      }
    });

    widget.onExpansionChanged?.call(_expandedIndices);
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = AccordionColors.from(colorExt, widget.style);

    return Container(
      decoration: widget.style == AppAccordionStyle.bordered
          ? BoxDecoration(
              border: Border.all(
                color: colors.border,
                width: BorderTokens.widthThin,
              ),
              borderRadius: BorderTokens.mediumRadius(),
            )
          : null,
      child: ClipRRect(
        borderRadius: widget.style == AppAccordionStyle.bordered
            ? BorderTokens.mediumRadius()
            : BorderRadius.zero,
        child: Column(
          children: [
            for (int i = 0; i < widget.items.length; i++) ...[
              _AccordionItemWidget(
                item: widget.items[i],
                isExpanded: _expandedIndices.contains(i),
                onTap: () => _handleExpansion(i),
                colors: colors,
                spacing: spacingExt,
                style: widget.style,
                isFirst: i == 0,
                isLast: i == widget.items.length - 1,
              ),
              if (i < widget.items.length - 1 &&
                  widget.style == AppAccordionStyle.separated)
                Divider(height: 1, thickness: 1, color: colors.divider),
            ],
          ],
        ),
      ),
    );
  }
}

/// 아코디언 아이템 위젯
class _AccordionItemWidget extends StatefulWidget {
  final AppAccordionItem item;
  final bool isExpanded;
  final VoidCallback onTap;
  final AccordionColors colors;
  final AppSpacingExtension spacing;
  final AppAccordionStyle style;
  final bool isFirst;
  final bool isLast;

  const _AccordionItemWidget({
    required this.item,
    required this.isExpanded,
    required this.onTap,
    required this.colors,
    required this.spacing,
    required this.style,
    required this.isFirst,
    required this.isLast,
  });

  @override
  State<_AccordionItemWidget> createState() => _AccordionItemWidgetState();
}

class _AccordionItemWidgetState extends State<_AccordionItemWidget>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _iconRotation;
  late Animation<double> _contentHeight;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationTokens.durationSmooth,
      vsync: this,
    );
    _iconRotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: AnimationTokens.curveSmooth),
    );
    _contentHeight = CurvedAnimation(
      parent: _controller,
      curve: AnimationTokens.curveSmooth,
    );

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_AccordionItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colors = widget.colors;
    final spacing = widget.spacing;

    return Column(
      children: [
        // 헤더
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: item.isDisabled ? null : widget.onTap,
            child: AnimatedContainer(
              duration: AnimationTokens.durationQuick,
              color: _isHovered && !item.isDisabled
                  ? colors.headerBackgroundHover
                  : colors.headerBackground,
              padding: EdgeInsets.symmetric(
                horizontal: spacing.medium,
                vertical: spacing.medium,
              ),
              child: Row(
                children: [
                  if (item.icon != null) ...[
                    Icon(
                      item.icon,
                      size: 20,
                      color: item.isDisabled
                          ? colors.icon.withValues(alpha: 0.5)
                          : colors.icon,
                    ),
                    SizedBox(width: spacing.small),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            color: item.isDisabled
                                ? colors.headerText.withValues(alpha: 0.5)
                                : colors.headerText,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (item.subtitle != null) ...[
                          SizedBox(height: spacing.labelDescriptionGap),
                          Text(
                            item.subtitle!,
                            style: TextStyle(
                              color: item.isDisabled
                                  ? colors.contentText.withValues(alpha: 0.5)
                                  : colors.contentText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _iconRotation,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: item.isDisabled
                          ? colors.icon.withValues(alpha: 0.5)
                          : colors.icon,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 콘텐츠
        SizeTransition(
          sizeFactor: _contentHeight,
          child: Container(
            width: double.infinity,
            color: colors.contentBackground,
            padding: EdgeInsets.fromLTRB(
              spacing.medium,
              0,
              spacing.medium,
              spacing.medium,
            ),
            child: item.content,
          ),
        ),

        // 구분선 (bordered 스타일)
        if (widget.style == AppAccordionStyle.bordered && !widget.isLast)
          Divider(height: 1, thickness: 1, color: colors.divider),
      ],
    );
  }
}

/// 단일 아코디언 패널 컴포넌트
///
/// ```dart
/// AppAccordionPanel(
///   title: '섹션 제목',
///   content: Text('콘텐츠'),
///   isExpanded: true,
///   onToggle: (expanded) {},
/// )
/// ```
class AppAccordionPanel extends StatelessWidget {
  /// 헤더 제목
  final String title;

  /// 헤더 부제목 (선택)
  final String? subtitle;

  /// 헤더 아이콘 (선택)
  final IconData? icon;

  /// 콘텐츠 위젯
  final Widget content;

  /// 펼침 상태
  final bool isExpanded;

  /// 토글 콜백
  final ValueChanged<bool>? onToggle;

  /// 비활성화 여부
  final bool isDisabled;

  /// 스타일
  final AppAccordionStyle style;

  const AppAccordionPanel({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.content,
    this.isExpanded = false,
    this.onToggle,
    this.isDisabled = false,
    this.style = AppAccordionStyle.bordered,
  });

  @override
  Widget build(BuildContext context) {
    return AppAccordion(
      style: style,
      allowMultiple: true,
      items: [
        AppAccordionItem(
          title: title,
          subtitle: subtitle,
          icon: icon,
          content: content,
          initiallyExpanded: isExpanded,
          isDisabled: isDisabled,
        ),
      ],
      onExpansionChanged: (indices) {
        onToggle?.call(indices.contains(0));
      },
    );
  }
}
