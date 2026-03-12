import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/drawer_colors.dart';
import '../theme/enums.dart';
import '../theme/animation_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppDrawerPosition;

/// 드로어 아이템 데이터
class AppDrawerItem {
  /// 아이템 제목
  final String title;

  /// 아이콘
  final IconData? icon;

  /// 클릭 콜백
  final VoidCallback? onTap;

  /// 활성화 여부
  final bool isActive;

  /// 비활성화 여부
  final bool isDisabled;

  /// 배지 텍스트
  final String? badge;

  /// 하위 아이템
  final List<AppDrawerItem>? children;

  const AppDrawerItem({
    required this.title,
    this.icon,
    this.onTap,
    this.isActive = false,
    this.isDisabled = false,
    this.badge,
    this.children,
  });
}

/// 드로어 컴포넌트
///
/// **용도**: 네비게이션 메뉴, 필터 패널, 설정 메뉴
/// **접근성**: 키보드 네비게이션, 스크린 리더 지원
///
/// ```dart
/// AppDrawer(
///   header: DrawerHeader(child: UserInfo()),
///   items: [
///     AppDrawerItem(title: '홈', icon: Icons.home),
///     AppDrawerItem(title: '설정', icon: Icons.settings),
///   ],
/// )
/// ```
class AppDrawer extends StatelessWidget {
  /// 드로어 아이템 목록
  final List<AppDrawerItem> items;

  /// 헤더 위젯
  final Widget? header;

  /// 푸터 위젯
  final Widget? footer;

  /// 드로어 너비
  final double width;

  /// 드로어 위치
  final AppDrawerPosition position;

  /// 닫힘 콜백
  final VoidCallback? onClose;

  const AppDrawer({
    super.key,
    required this.items,
    this.header,
    this.footer,
    this.width = 280,
    this.position = AppDrawerPosition.left,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = DrawerColors.from(colorExt);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          right: position == AppDrawerPosition.left
              ? BorderSide(color: colors.border, width: 1)
              : BorderSide.none,
          left: position == AppDrawerPosition.right
              ? BorderSide(color: colors.border, width: 1)
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          if (header != null) header!,
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: spacingExt.small),
              itemCount: items.length,
              itemBuilder: (context, index) => _DrawerItemWidget(
                item: items[index],
                colors: colors,
                spacing: spacingExt,
              ),
            ),
          ),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

/// 드로어 아이템 위젯
class _DrawerItemWidget extends StatefulWidget {
  final AppDrawerItem item;
  final DrawerColors colors;
  final AppSpacingExtension spacing;

  const _DrawerItemWidget({
    required this.item,
    required this.colors,
    required this.spacing,
  });

  @override
  State<_DrawerItemWidget> createState() => _DrawerItemWidgetState();
}

class _DrawerItemWidgetState extends State<_DrawerItemWidget> {
  bool _isHovered = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colors = widget.colors;
    final spacing = widget.spacing;
    final hasChildren = item.children != null && item.children!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: item.title,
          button: true,
          enabled: !item.isDisabled,
          child: MouseRegion(
            cursor: item.isDisabled
                ? SystemMouseCursors.forbidden
                : SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: item.isDisabled
                  ? null
                  : () {
                      if (hasChildren) {
                        setState(() => _isExpanded = !_isExpanded);
                      } else {
                        item.onTap?.call();
                      }
                    },
              child: AnimatedContainer(
                duration: AnimationTokens.durationQuick,
                margin: EdgeInsets.symmetric(
                  horizontal: spacing.small,
                  vertical: spacing.labelDescriptionGap,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.medium,
                  vertical: spacing.small,
                ),
                decoration: BoxDecoration(
                  color: item.isActive
                      ? colors.itemActive
                      : _isHovered
                      ? colors.itemHover
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (item.icon != null) ...[
                      Icon(
                        item.icon,
                        size: 20,
                        color: item.isActive
                            ? colors.iconActive
                            : item.isDisabled
                            ? colors.icon.withValues(alpha: 0.5)
                            : colors.icon,
                      ),
                      SizedBox(width: spacing.small),
                    ],
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          color: item.isActive
                              ? colors.iconActive
                              : item.isDisabled
                              ? colors.text.withValues(alpha: 0.5)
                              : colors.text,
                          fontSize: 14,
                          fontWeight: item.isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (item.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.iconActive.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.badge!,
                          style: TextStyle(
                            color: colors.iconActive,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (hasChildren) ...[
                      SizedBox(width: spacing.xs),
                      AnimatedRotation(
                        duration: AnimationTokens.durationQuick,
                        turns: _isExpanded ? 0.5 : 0,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: colors.icon,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasChildren)
          AnimatedCrossFade(
            duration: AnimationTokens.durationStandard,
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.only(left: spacing.large),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: item.children!
                    .map(
                      (child) => _DrawerItemWidget(
                        item: child,
                        colors: colors,
                        spacing: spacing,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }
}

/// 드로어 헤더 위젯
class AppDrawerHeader extends StatelessWidget {
  /// 헤더 콘텐츠
  final Widget child;

  /// 배경 색상
  final Color? backgroundColor;

  /// 패딩
  final EdgeInsets? padding;

  const AppDrawerHeader({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = DrawerColors.from(colorExt);

    return Container(
      width: double.infinity,
      padding:
          padding ??
          EdgeInsets.all(spacingExt.medium).copyWith(
            top: spacingExt.medium + MediaQuery.paddingOf(context).top,
          ),
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.headerBackground,
        border: Border(bottom: BorderSide(color: colors.border, width: 1)),
      ),
      child: child,
    );
  }
}

/// 드로어 표시 함수
void showAppDrawer({
  required BuildContext context,
  required Widget drawer,
  AppDrawerPosition position = AppDrawerPosition.left,
}) {
  final colorExt = context.appColors;
  final colors = DrawerColors.from(colorExt);

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '드로어 닫기',
    barrierColor: colors.overlay,
    transitionDuration: AnimationTokens.durationSmooth,
    pageBuilder: (context, animation, secondaryAnimation) => drawer,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final offsetTween = Tween<Offset>(
        begin: Offset(position == AppDrawerPosition.left ? -1 : 1, 0),
        end: Offset.zero,
      );

      return SlideTransition(
        position: offsetTween.animate(
          CurvedAnimation(parent: animation, curve: AnimationTokens.curveSlide),
        ),
        child: Align(
          alignment: position == AppDrawerPosition.left
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: child,
        ),
      );
    },
  );
}
