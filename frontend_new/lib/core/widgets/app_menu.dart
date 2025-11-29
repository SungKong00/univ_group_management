import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/menu_colors.dart';
import '../theme/enums.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppMenuItemType;

/// 메뉴 아이템 데이터 모델
class AppMenuItem {
  /// 아이템 타입
  final AppMenuItemType type;

  /// 라벨 텍스트
  final String? label;

  /// 아이콘
  final IconData? icon;

  /// 단축키 표시
  final String? shortcut;

  /// 탭 콜백
  final VoidCallback? onTap;

  /// 비활성화 여부
  final bool isDisabled;

  /// 위험 액션 여부
  final bool isDestructive;

  /// 서브메뉴 아이템들 (submenu 타입용)
  final List<AppMenuItem>? children;

  const AppMenuItem({
    this.type = AppMenuItemType.item,
    this.label,
    this.icon,
    this.shortcut,
    this.onTap,
    this.isDisabled = false,
    this.isDestructive = false,
    this.children,
  });

  /// 구분선 팩토리
  factory AppMenuItem.divider() =>
      const AppMenuItem(type: AppMenuItemType.divider);

  /// 헤더 팩토리
  factory AppMenuItem.header(String label) =>
      AppMenuItem(type: AppMenuItemType.header, label: label);

  /// 서브메뉴 팩토리
  factory AppMenuItem.submenu({
    required String label,
    IconData? icon,
    required List<AppMenuItem> children,
  }) => AppMenuItem(
    type: AppMenuItemType.submenu,
    label: label,
    icon: icon,
    children: children,
  );
}

/// 컨텍스트 메뉴 컴포넌트
///
/// **용도**: 우클릭 메뉴, 드롭다운 액션 메뉴, 옵션 메뉴
/// **접근성**: 키보드 네비게이션, 스크린 리더 지원
///
/// ```dart
/// // 기본 사용
/// AppMenu(
///   items: [
///     AppMenuItem(label: '복사', icon: Icons.copy, onTap: () {}),
///     AppMenuItem(label: '붙여넣기', icon: Icons.paste, onTap: () {}),
///     AppMenuItem.divider(),
///     AppMenuItem(label: '삭제', icon: Icons.delete, isDestructive: true, onTap: () {}),
///   ],
/// )
///
/// // 팝업 메뉴로 표시
/// showAppMenu(
///   context: context,
///   position: RelativeRect.fromLTRB(100, 100, 0, 0),
///   items: [...],
/// );
/// ```
class AppMenu extends StatelessWidget {
  /// 메뉴 아이템 목록
  final List<AppMenuItem> items;

  /// 메뉴 최소 너비
  final double minWidth;

  /// 메뉴 최대 너비
  final double maxWidth;

  const AppMenu({
    super.key,
    required this.items,
    this.minWidth = 180,
    this.maxWidth = 280,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = MenuColors.from(colorExt);

    return Container(
      constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderTokens.largeRadius(),
        border: Border.all(color: colors.border, width: BorderTokens.widthThin),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderTokens.largeRadius(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < items.length; i++)
              _buildMenuItem(context, items[i], colors, spacingExt),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    AppMenuItem item,
    MenuColors colors,
    AppSpacingExtension spacing,
  ) {
    switch (item.type) {
      case AppMenuItemType.divider:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: spacing.xs),
          child: Divider(height: 1, thickness: 1, color: colors.divider),
        );

      case AppMenuItemType.header:
        return Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.medium,
            spacing.small,
            spacing.medium,
            spacing.xs,
          ),
          child: Text(
            item.label ?? '',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        );

      case AppMenuItemType.submenu:
        return _SubmenuItem(item: item, colors: colors, spacing: spacing);

      case AppMenuItemType.item:
        return _MenuItem(item: item, colors: colors, spacing: spacing);
    }
  }
}

/// 일반 메뉴 아이템 위젯
class _MenuItem extends StatefulWidget {
  final AppMenuItem item;
  final MenuColors colors;
  final AppSpacingExtension spacing;

  const _MenuItem({
    required this.item,
    required this.colors,
    required this.spacing,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colors = widget.colors;
    final spacing = widget.spacing;

    final textColor = item.isDisabled
        ? colors.textDisabled
        : item.isDestructive
        ? colors.destructive
        : colors.text;

    final iconColor = item.isDisabled
        ? colors.textDisabled
        : item.isDestructive
        ? colors.destructive
        : colors.icon;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: item.isDisabled
            ? null
            : () {
                Navigator.of(context).pop();
                item.onTap?.call();
              },
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          color: _isHovered && !item.isDisabled
              ? colors.backgroundHover
              : Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: spacing.medium,
            vertical: spacing.small,
          ),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 16, color: iconColor),
                SizedBox(width: spacing.small),
              ],
              Expanded(
                child: Text(
                  item.label ?? '',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (item.shortcut != null) ...[
                SizedBox(width: spacing.small),
                Text(
                  item.shortcut!,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
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

/// 서브메뉴 아이템 위젯
class _SubmenuItem extends StatefulWidget {
  final AppMenuItem item;
  final MenuColors colors;
  final AppSpacingExtension spacing;

  const _SubmenuItem({
    required this.item,
    required this.colors,
    required this.spacing,
  });

  @override
  State<_SubmenuItem> createState() => _SubmenuItemState();
}

class _SubmenuItemState extends State<_SubmenuItem> {
  bool _isHovered = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _showSubmenu() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 200,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(200, 0),
          child: Material(
            color: Colors.transparent,
            child: AppMenu(items: widget.item.children ?? []),
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
    final spacing = widget.spacing;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _showSubmenu();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _removeOverlay();
        },
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          color: _isHovered ? colors.backgroundHover : Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: spacing.medium,
            vertical: spacing.small,
          ),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 16, color: colors.icon),
                SizedBox(width: spacing.small),
              ],
              Expanded(
                child: Text(
                  item.label ?? '',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// 팝업 메뉴 표시 함수
///
/// ```dart
/// showAppMenu(
///   context: context,
///   position: RelativeRect.fromLTRB(100, 100, 0, 0),
///   items: [
///     AppMenuItem(label: '복사', icon: Icons.copy, onTap: () {}),
///     AppMenuItem(label: '붙여넣기', icon: Icons.paste, onTap: () {}),
///   ],
/// );
/// ```
Future<void> showAppMenu({
  required BuildContext context,
  required RelativeRect position,
  required List<AppMenuItem> items,
  double minWidth = 180,
  double maxWidth = 280,
}) async {
  return showMenu<void>(
    context: context,
    position: position,
    shape: RoundedRectangleBorder(borderRadius: BorderTokens.largeRadius()),
    color: Colors.transparent,
    elevation: 0,
    items: [
      PopupMenuItem<void>(
        enabled: false,
        padding: EdgeInsets.zero,
        child: AppMenu(items: items, minWidth: minWidth, maxWidth: maxWidth),
      ),
    ],
  );
}

/// 컨텍스트 메뉴 래퍼 위젯
///
/// 자식 위젯에 우클릭/롱프레스 메뉴를 추가합니다.
///
/// ```dart
/// AppMenuTrigger(
///   items: [
///     AppMenuItem(label: '복사', icon: Icons.copy, onTap: () {}),
///   ],
///   child: Container(...),
/// )
/// ```
class AppMenuTrigger extends StatelessWidget {
  /// 메뉴 아이템 목록
  final List<AppMenuItem> items;

  /// 자식 위젯
  final Widget child;

  /// 메뉴 최소 너비
  final double minWidth;

  /// 메뉴 최대 너비
  final double maxWidth;

  const AppMenuTrigger({
    super.key,
    required this.items,
    required this.child,
    this.minWidth = 180,
    this.maxWidth = 280,
  });

  void _showMenu(BuildContext context, Offset position) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    showAppMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: items,
      minWidth: minWidth,
      maxWidth: maxWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) =>
          _showMenu(context, details.globalPosition),
      onLongPressStart: (details) => _showMenu(context, details.globalPosition),
      child: child,
    );
  }
}
