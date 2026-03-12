import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/navbar_colors.dart';
import '../theme/enums.dart';
import '../theme/animation_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppNavbarStyle;

/// 네비게이션 바 아이템 데이터
class AppNavbarItem {
  /// 라벨
  final String label;

  /// 클릭 콜백
  final VoidCallback? onTap;

  /// 활성화 여부
  final bool isActive;

  /// 하위 메뉴 (드롭다운)
  final List<AppNavbarItem>? children;

  const AppNavbarItem({
    required this.label,
    this.onTap,
    this.isActive = false,
    this.children,
  });
}

/// 상단 네비게이션 바 컴포넌트
///
/// **용도**: 웹 헤더, 메인 네비게이션
/// **접근성**: 키보드 네비게이션, 스크린 리더 지원
///
/// ```dart
/// AppNavbar(
///   leading: Logo(),
///   items: [
///     AppNavbarItem(label: '홈', isActive: true),
///     AppNavbarItem(label: '제품'),
///     AppNavbarItem(label: '서비스'),
///   ],
///   trailing: [
///     IconButton(icon: Icon(Icons.search)),
///     Avatar(),
///   ],
/// )
/// ```
class AppNavbar extends StatelessWidget {
  /// 좌측 위젯 (로고 등)
  final Widget? leading;

  /// 메뉴 아이템 목록
  final List<AppNavbarItem> items;

  /// 우측 위젯 목록 (검색, 프로필 등)
  final List<Widget>? trailing;

  /// 스타일
  final AppNavbarStyle style;

  /// 높이
  final double height;

  /// 패딩
  final EdgeInsets? padding;

  /// 중앙 정렬 (아이템)
  final bool centerItems;

  const AppNavbar({
    super.key,
    this.leading,
    required this.items,
    this.trailing,
    this.style = AppNavbarStyle.standard,
    this.height = 64,
    this.padding,
    this.centerItems = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = NavbarColors.from(colorExt, style);

    return Container(
      height: height,
      padding: padding ?? EdgeInsets.symmetric(horizontal: spacingExt.large),
      decoration: BoxDecoration(
        color: colors.background,
        border: style != AppNavbarStyle.transparent
            ? Border(bottom: BorderSide(color: colors.border, width: 1))
            : null,
        boxShadow: style == AppNavbarStyle.sticky
            ? [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, SizedBox(width: spacingExt.large)],
          if (centerItems) const Spacer(),
          ..._buildItems(colors, spacingExt),
          if (centerItems) const Spacer() else const Spacer(),
          if (trailing != null) ...[
            for (int i = 0; i < trailing!.length; i++) ...[
              if (i > 0) SizedBox(width: spacingExt.small),
              trailing![i],
            ],
          ],
        ],
      ),
    );
  }

  List<Widget> _buildItems(NavbarColors colors, AppSpacingExtension spacing) {
    return [
      for (int i = 0; i < items.length; i++) ...[
        if (i > 0) SizedBox(width: spacing.small),
        _NavbarItemWidget(item: items[i], colors: colors, spacing: spacing),
      ],
    ];
  }
}

/// 네비게이션 바 아이템 위젯
class _NavbarItemWidget extends StatefulWidget {
  final AppNavbarItem item;
  final NavbarColors colors;
  final AppSpacingExtension spacing;

  const _NavbarItemWidget({
    required this.item,
    required this.colors,
    required this.spacing,
  });

  @override
  State<_NavbarItemWidget> createState() => _NavbarItemWidgetState();
}

class _NavbarItemWidgetState extends State<_NavbarItemWidget> {
  bool _isHovered = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _showDropdown() {
    if (widget.item.children == null || widget.item.children!.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 200,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            color: widget.colors.background,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final child in widget.item.children!)
                  InkWell(
                    onTap: () {
                      _removeOverlay();
                      child.onTap?.call();
                    },
                    child: Padding(
                      padding: EdgeInsets.all(widget.spacing.medium),
                      child: Row(
                        children: [
                          Text(
                            child.label,
                            style: TextStyle(
                              color: child.isActive
                                  ? widget.colors.textActive
                                  : widget.colors.text,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colors = widget.colors;
    final hasChildren = item.children != null && item.children!.isNotEmpty;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Semantics(
        label: item.label,
        button: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) {
            setState(() => _isHovered = true);
            if (hasChildren) _showDropdown();
          },
          onExit: (_) {
            setState(() => _isHovered = false);
            if (hasChildren) {
              Future.delayed(const Duration(milliseconds: 100), () {
                if (!_isHovered) _removeOverlay();
              });
            }
          },
          child: GestureDetector(
            onTap: hasChildren ? null : item.onTap,
            child: AnimatedContainer(
              duration: AnimationTokens.durationQuick,
              padding: EdgeInsets.symmetric(
                horizontal: widget.spacing.medium,
                vertical: widget.spacing.small,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      color: item.isActive
                          ? colors.textActive
                          : _isHovered
                          ? colors.textHover
                          : colors.text,
                      fontSize: 14,
                      fontWeight: item.isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  if (hasChildren) ...[
                    SizedBox(width: widget.spacing.labelDescriptionGap),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: _isHovered ? colors.textHover : colors.text,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 반응형 네비게이션 바 (모바일에서 햄버거 메뉴)
class AppResponsiveNavbar extends StatelessWidget {
  /// 좌측 위젯 (로고 등)
  final Widget? leading;

  /// 메뉴 아이템 목록
  final List<AppNavbarItem> items;

  /// 우측 위젯 목록
  final List<Widget>? trailing;

  /// 스타일
  final AppNavbarStyle style;

  /// 높이
  final double height;

  /// 모바일 브레이크포인트
  final double mobileBreakpoint;

  /// 모바일 메뉴 열기 콜백
  final VoidCallback? onMenuPressed;

  const AppResponsiveNavbar({
    super.key,
    this.leading,
    required this.items,
    this.trailing,
    this.style = AppNavbarStyle.standard,
    this.height = 64,
    this.mobileBreakpoint = 768,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < mobileBreakpoint;
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = NavbarColors.from(colorExt, style);

    if (isMobile) {
      return Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: spacingExt.medium),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(bottom: BorderSide(color: colors.border, width: 1)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.menu, color: colors.icon),
              onPressed: onMenuPressed,
              tooltip: '메뉴 열기',
            ),
            if (leading != null) ...[
              SizedBox(width: spacingExt.small),
              leading!,
            ],
            const Spacer(),
            if (trailing != null) ...trailing!,
          ],
        ),
      );
    }

    return AppNavbar(
      leading: leading,
      items: items,
      trailing: trailing,
      style: style,
      height: height,
    );
  }
}
