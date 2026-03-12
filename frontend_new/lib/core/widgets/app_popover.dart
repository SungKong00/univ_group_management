import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/popover_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/enums.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppPopoverPosition;

/// 팝오버 컴포넌트
///
/// **용도**: 컨텍스트 정보, 미니 폼, 추가 옵션
/// **접근성**: 포커스 관리, ESC 키로 닫기
///
/// ```dart
/// // 기본 사용
/// AppPopover(
///   triggerBuilder: (context, open) => IconButton(
///     icon: Icon(Icons.more_vert),
///     onPressed: open,
///   ),
///   contentBuilder: (context, close) => PopoverContent(onClose: close),
/// )
///
/// // 위치 지정
/// AppPopover(
///   position: AppPopoverPosition.bottomStart,
///   triggerBuilder: (context, open) => TextButton(
///     onPressed: open,
///     child: Text('Options'),
///   ),
///   contentBuilder: (context, close) => OptionsList(),
/// )
/// ```
class AppPopover extends StatefulWidget {
  /// 트리거 빌더
  final Widget Function(BuildContext context, VoidCallback open) triggerBuilder;

  /// 콘텐츠 빌더
  final Widget Function(BuildContext context, VoidCallback close)
  contentBuilder;

  /// 팝오버 위치
  final AppPopoverPosition position;

  /// 콘텐츠 너비
  final double? width;

  /// 콘텐츠 최대 높이
  final double? maxHeight;

  /// 오프셋
  final Offset offset;

  /// 외부 클릭으로 닫기
  final bool dismissOnTapOutside;

  const AppPopover({
    super.key,
    required this.triggerBuilder,
    required this.contentBuilder,
    this.position = AppPopoverPosition.bottom,
    this.width,
    this.maxHeight,
    this.offset = Offset.zero,
    this.dismissOnTapOutside = true,
  });

  @override
  State<AppPopover> createState() => _AppPopoverState();
}

class _AppPopoverState extends State<AppPopover> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _open() {
    if (_isOpen) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _close() {
    if (!_isOpen) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  Offset _getOffset() {
    final offset = widget.offset;
    return switch (widget.position) {
      AppPopoverPosition.top => Offset(offset.dx, -8 + offset.dy),
      AppPopoverPosition.bottom => Offset(offset.dx, 8 + offset.dy),
      AppPopoverPosition.left => Offset(-8 + offset.dx, offset.dy),
      AppPopoverPosition.right => Offset(8 + offset.dx, offset.dy),
      AppPopoverPosition.topStart => Offset(offset.dx, -8 + offset.dy),
      AppPopoverPosition.topEnd => Offset(offset.dx, -8 + offset.dy),
      AppPopoverPosition.bottomStart => Offset(offset.dx, 8 + offset.dy),
      AppPopoverPosition.bottomEnd => Offset(offset.dx, 8 + offset.dy),
    };
  }

  Alignment _getTargetAnchor() {
    return switch (widget.position) {
      AppPopoverPosition.top => Alignment.topCenter,
      AppPopoverPosition.bottom => Alignment.bottomCenter,
      AppPopoverPosition.left => Alignment.centerLeft,
      AppPopoverPosition.right => Alignment.centerRight,
      AppPopoverPosition.topStart => Alignment.topLeft,
      AppPopoverPosition.topEnd => Alignment.topRight,
      AppPopoverPosition.bottomStart => Alignment.bottomLeft,
      AppPopoverPosition.bottomEnd => Alignment.bottomRight,
    };
  }

  Alignment _getFollowerAnchor() {
    return switch (widget.position) {
      AppPopoverPosition.top => Alignment.bottomCenter,
      AppPopoverPosition.bottom => Alignment.topCenter,
      AppPopoverPosition.left => Alignment.centerRight,
      AppPopoverPosition.right => Alignment.centerLeft,
      AppPopoverPosition.topStart => Alignment.bottomLeft,
      AppPopoverPosition.topEnd => Alignment.bottomRight,
      AppPopoverPosition.bottomStart => Alignment.topLeft,
      AppPopoverPosition.bottomEnd => Alignment.topRight,
    };
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => _PopoverOverlay(
        link: _layerLink,
        targetAnchor: _getTargetAnchor(),
        followerAnchor: _getFollowerAnchor(),
        offset: _getOffset(),
        width: widget.width,
        maxHeight: widget.maxHeight,
        dismissOnTapOutside: widget.dismissOnTapOutside,
        onClose: _close,
        contentBuilder: widget.contentBuilder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: widget.triggerBuilder(context, _open),
    );
  }
}

/// 팝오버 오버레이
class _PopoverOverlay extends StatefulWidget {
  final LayerLink link;
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Offset offset;
  final double? width;
  final double? maxHeight;
  final bool dismissOnTapOutside;
  final VoidCallback onClose;
  final Widget Function(BuildContext context, VoidCallback close)
  contentBuilder;

  const _PopoverOverlay({
    required this.link,
    required this.targetAnchor,
    required this.followerAnchor,
    required this.offset,
    required this.onClose,
    required this.contentBuilder,
    this.width,
    this.maxHeight,
    this.dismissOnTapOutside = true,
  });

  @override
  State<_PopoverOverlay> createState() => _PopoverOverlayState();
}

class _PopoverOverlayState extends State<_PopoverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationTokens.durationQuick,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AnimationTokens.curveDefault),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AnimationTokens.curveDefault),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = PopoverColors.from(colorExt);

    return Stack(
      children: [
        // 배경 탭 영역
        if (widget.dismissOnTapOutside)
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),

        // 팝오버 콘텐츠
        CompositedTransformFollower(
          link: widget.link,
          targetAnchor: widget.targetAnchor,
          followerAnchor: widget.followerAnchor,
          offset: widget.offset,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: widget.followerAnchor,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: widget.width,
                  constraints: BoxConstraints(
                    maxHeight: widget.maxHeight ?? 400,
                  ),
                  padding: EdgeInsets.all(spacingExt.medium),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(
                      BorderTokens.radiusMedium,
                    ),
                    border: Border.all(
                      color: colors.border,
                      width: BorderTokens.widthThin,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow,
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: widget.contentBuilder(context, widget.onClose),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
