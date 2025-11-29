import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/hover_card_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/enums.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppHoverCardSize;

/// 호버 카드 컴포넌트
///
/// **용도**: 미리보기, 사용자 정보, 추가 컨텍스트
/// **접근성**: 호버/포커스로 표시, 딜레이 지원
///
/// ```dart
/// // 기본 사용
/// AppHoverCard(
///   triggerBuilder: (context) => Text('@username'),
///   contentBuilder: (context) => UserProfileCard(user),
/// )
///
/// // 크기 및 딜레이 설정
/// AppHoverCard(
///   size: AppHoverCardSize.large,
///   showDelay: Duration(milliseconds: 300),
///   hideDelay: Duration(milliseconds: 100),
///   triggerBuilder: (context) => ProductName(),
///   contentBuilder: (context) => ProductPreview(),
/// )
/// ```
class AppHoverCard extends StatefulWidget {
  /// 트리거 빌더
  final Widget Function(BuildContext context) triggerBuilder;

  /// 콘텐츠 빌더
  final Widget Function(BuildContext context) contentBuilder;

  /// 카드 크기
  final AppHoverCardSize size;

  /// 표시 딜레이
  final Duration showDelay;

  /// 숨김 딜레이
  final Duration hideDelay;

  /// 위치 (상단/하단)
  final bool preferTop;

  /// 커스텀 너비
  final double? width;

  const AppHoverCard({
    super.key,
    required this.triggerBuilder,
    required this.contentBuilder,
    this.size = AppHoverCardSize.medium,
    this.showDelay = const Duration(milliseconds: 400),
    this.hideDelay = const Duration(milliseconds: 100),
    this.preferTop = false,
    this.width,
  });

  @override
  State<AppHoverCard> createState() => _AppHoverCardState();
}

class _AppHoverCardState extends State<AppHoverCard> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isHoveringTrigger = false;
  bool _isHoveringCard = false;
  bool _isVisible = false;

  double _getWidth() {
    if (widget.width != null) return widget.width!;
    return switch (widget.size) {
      AppHoverCardSize.small => 240.0,
      AppHoverCardSize.medium => 320.0,
      AppHoverCardSize.large => 400.0,
    };
  }

  void _onTriggerEnter() {
    _isHoveringTrigger = true;
    Future.delayed(widget.showDelay, () {
      if (_isHoveringTrigger && mounted) {
        _show();
      }
    });
  }

  void _onTriggerExit() {
    _isHoveringTrigger = false;
    Future.delayed(widget.hideDelay, () {
      if (!_isHoveringTrigger && !_isHoveringCard && mounted) {
        _hide();
      }
    });
  }

  void _onCardEnter() {
    _isHoveringCard = true;
  }

  void _onCardExit() {
    _isHoveringCard = false;
    Future.delayed(widget.hideDelay, () {
      if (!_isHoveringTrigger && !_isHoveringCard && mounted) {
        _hide();
      }
    });
  }

  void _show() {
    if (_isVisible) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _isVisible = true;
  }

  void _hide() {
    if (!_isVisible) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isVisible = false;
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => _HoverCardOverlay(
        link: _layerLink,
        width: _getWidth(),
        preferTop: widget.preferTop,
        onEnter: _onCardEnter,
        onExit: _onCardExit,
        contentBuilder: widget.contentBuilder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _onTriggerEnter(),
        onExit: (_) => _onTriggerExit(),
        child: widget.triggerBuilder(context),
      ),
    );
  }
}

/// 호버 카드 오버레이
class _HoverCardOverlay extends StatefulWidget {
  final LayerLink link;
  final double width;
  final bool preferTop;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final Widget Function(BuildContext context) contentBuilder;

  const _HoverCardOverlay({
    required this.link,
    required this.width,
    required this.preferTop,
    required this.onEnter,
    required this.onExit,
    required this.contentBuilder,
  });

  @override
  State<_HoverCardOverlay> createState() => _HoverCardOverlayState();
}

class _HoverCardOverlayState extends State<_HoverCardOverlay>
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
      CurvedAnimation(parent: _controller, curve: AnimationTokens.curveSmooth),
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
    final colors = HoverCardColors.from(colorExt);

    return CompositedTransformFollower(
      link: widget.link,
      targetAnchor: widget.preferTop
          ? Alignment.topCenter
          : Alignment.bottomCenter,
      followerAnchor: widget.preferTop
          ? Alignment.bottomCenter
          : Alignment.topCenter,
      offset: Offset(0, widget.preferTop ? -8 : 8),
      child: MouseRegion(
        onEnter: (_) => widget.onEnter(),
        onExit: (_) => widget.onExit(),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            alignment: widget.preferTop
                ? Alignment.bottomCenter
                : Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: widget.width,
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
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: widget.contentBuilder(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
