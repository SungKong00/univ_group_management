import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Responsive navigation wrapper that adapts between mobile and desktop layouts
///
/// **Mobile breakpoint**: < 768px
/// - Shows hamburger menu button
/// - Navigation in drawer
/// - Compact header
///
/// **Desktop**: >= 768px
/// - Shows inline navigation
/// - Full header
/// - Side navigation panel
///
/// **Test mode**: When [skipWrapper] is true
/// - Returns child directly without wrapping
/// - Used in tests to simplify widget tree
class ResponsiveNavigationWrapper extends ConsumerStatefulWidget {
  const ResponsiveNavigationWrapper({
    super.key,
    required this.child,
    this.navigationItems = const [],
    this.mobileBreakpoint = 768.0,
    this.skipWrapper = false,
  });

  final Widget child;
  final List<NavigationItem> navigationItems;
  final double mobileBreakpoint;
  final bool skipWrapper;

  @override
  ConsumerState<ResponsiveNavigationWrapper> createState() =>
      _ResponsiveNavigationWrapperState();
}

class _ResponsiveNavigationWrapperState
    extends ConsumerState<ResponsiveNavigationWrapper>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Mobile navigation animation controller (200ms ease-out)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    // Find initially selected index
    _selectedIndex = widget.navigationItems.indexWhere(
      (item) => item.isSelected,
    );
    if (_selectedIndex == -1) _selectedIndex = 0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < widget.mobileBreakpoint;
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _closeDrawer() {
    _scaffoldKey.currentState?.closeDrawer();
  }

  /// Handle keyboard navigation
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (widget.navigationItems.isEmpty) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.tab:
        // Tab: Move to next item, Shift+Tab: Move to previous item
        final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
        setState(() {
          if (isShiftPressed) {
            _selectedIndex =
                (_selectedIndex - 1) % widget.navigationItems.length;
            if (_selectedIndex < 0)
              _selectedIndex = widget.navigationItems.length - 1;
          } else {
            _selectedIndex =
                (_selectedIndex + 1) % widget.navigationItems.length;
          }
        });
        return KeyEventResult.handled;

      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        // Enter/Space: Activate selected item
        if (_selectedIndex >= 0 &&
            _selectedIndex < widget.navigationItems.length) {
          widget.navigationItems[_selectedIndex].onTap?.call();
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.escape:
        // Escape: Close drawer on mobile
        if (_isMobile(context) &&
            _scaffoldKey.currentState?.isDrawerOpen == true) {
          _closeDrawer();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;

      case LogicalKeyboardKey.arrowDown:
        // Arrow down: Move to next item
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % widget.navigationItems.length;
        });
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowUp:
        // Arrow up: Move to previous item
        setState(() {
          _selectedIndex = (_selectedIndex - 1) % widget.navigationItems.length;
          if (_selectedIndex < 0)
            _selectedIndex = widget.navigationItems.length - 1;
        });
        return KeyEventResult.handled;

      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Skip wrapper in test mode - return child directly
    if (widget.skipWrapper) {
      return widget.child;
    }

    final isMobile = _isMobile(context);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: isMobile ? _buildMobileDrawer() : null,
        // Enable swipe-to-open drawer on mobile
        drawerEnableOpenDragGesture: isMobile,
        appBar: isMobile ? _buildMobileAppBar() : null,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            children: [
              // Desktop side navigation
              if (!isMobile) _buildDesktopNavigation(),
              // Main content
              Expanded(child: widget.child),
            ],
          ),
        ),
      ),
    );
  }

  /// Build mobile app bar with hamburger menu
  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      title: const Text('워크스페이스'),
      leading: Semantics(
        label: '네비게이션 메뉴 열기',
        button: true,
        child: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _openDrawer,
          tooltip: '메뉴 열기',
        ),
      ),
      centerTitle: true,
    );
  }

  /// Build mobile navigation drawer
  Widget _buildMobileDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.brand,
                border: Border(
                  bottom: BorderSide(color: AppColors.neutral300, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '네비게이션',
                    style: AppTheme.headlineSmall.copyWith(color: Colors.white),
                  ),
                  Semantics(
                    label: '네비게이션 메뉴 닫기',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _closeDrawer,
                      tooltip: '닫기',
                    ),
                  ),
                ],
              ),
            ),
            // Navigation items
            Expanded(
              child: ListView.builder(
                itemCount: widget.navigationItems.length,
                itemBuilder: (context, index) {
                  final item = widget.navigationItems[index];
                  return _buildNavigationItem(item, isMobile: true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build desktop side navigation panel
  Widget _buildDesktopNavigation() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.neutral300, width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Navigation header
            Container(
              padding: const EdgeInsets.all(16),
              child: Text('워크스페이스', style: AppTheme.headlineMedium),
            ),
            const Divider(height: 1),
            // Navigation items
            Expanded(
              child: ListView.builder(
                itemCount: widget.navigationItems.length,
                itemBuilder: (context, index) {
                  final item = widget.navigationItems[index];
                  return _buildNavigationItem(item, isMobile: false);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual navigation item
  Widget _buildNavigationItem(NavigationItem item, {required bool isMobile}) {
    final index = widget.navigationItems.indexOf(item);
    final isFocused = _selectedIndex == index;

    return Semantics(
      label:
          '${item.label}${item.isSelected ? ' (현재 선택됨)' : ''}${isFocused ? ' (포커스됨)' : ''}',
      button: true,
      selected: item.isSelected,
      focused: isFocused,
      child: Container(
        decoration: isFocused
            ? BoxDecoration(
                border: Border.all(color: AppColors.action, width: 2),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: ListTile(
          leading: Icon(
            item.icon,
            color: item.isSelected ? AppColors.action : AppColors.neutral600,
          ),
          title: Text(
            item.label,
            style: AppTheme.bodyMedium.copyWith(
              color: item.isSelected ? AppColors.action : AppColors.neutral700,
              fontWeight: item.isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          selected: item.isSelected,
          selectedTileColor: AppColors.actionTonalBg,
          onTap: () {
            // Close drawer on mobile after selection
            if (isMobile) {
              _closeDrawer();
            }
            item.onTap?.call();
          },
        ),
      ),
    );
  }
}

/// Navigation item data model
class NavigationItem {
  const NavigationItem({
    required this.label,
    required this.icon,
    this.isSelected = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;
}
