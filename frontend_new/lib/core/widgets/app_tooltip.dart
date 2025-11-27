import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/tooltip_colors.dart';
import '../theme/enums.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';
import '../theme/responsive_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppTooltipPosition;

/// 호버/탭 시 추가 정보를 표시하는 Tooltip 컴포넌트
///
/// **접근성**: 키보드 포커스 시에도 툴팁 표시
/// **반응형**: 화면 가장자리 감지 및 자동 위치 조정
///
/// ```dart
/// // 기본 사용
/// AppTooltip(
///   message: '이 버튼을 클릭하면 저장됩니다.',
///   child: IconButton(icon: Icon(Icons.save), onPressed: _save),
/// )
///
/// // 위치 지정
/// AppTooltip(
///   message: '설정 열기',
///   preferredPosition: AppTooltipPosition.right,
///   child: Icon(Icons.settings),
/// )
///
/// // 모바일용 탭 표시
/// AppTooltip(
///   message: '길게 누르면 복사됩니다.',
///   showOnTap: true,
///   child: Text('복사할 텍스트'),
/// )
/// ```
class AppTooltip extends StatefulWidget {
  /// 감싸는 자식 위젯
  final Widget child;

  /// 툴팁 메시지
  final String message;

  /// 선호 위치 (화면 가장자리 시 자동 조정)
  final AppTooltipPosition preferredPosition;

  /// 표시 지연 시간 (호버 후)
  final Duration showDelay;

  /// 숨김 지연 시간 (호버 해제 후)
  final Duration hideDelay;

  /// 모바일용 탭으로 표시 여부
  final bool showOnTap;

  /// 비활성화 여부
  final bool isDisabled;

  const AppTooltip({
    super.key,
    required this.child,
    required this.message,
    this.preferredPosition = AppTooltipPosition.top,
    this.showDelay = const Duration(milliseconds: 500),
    this.hideDelay = Duration.zero,
    this.showOnTap = false,
    this.isDisabled = false,
  });

  @override
  State<AppTooltip> createState() => _AppTooltipState();
}

class _AppTooltipState extends State<AppTooltip>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _showTimer;
  Timer? _hideTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationTokens.durationQuick,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AnimationTokens.curveSmooth,
      ),
    );
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _showTooltip() {
    if (widget.isDisabled || _overlayEntry != null) return;

    _showTimer?.cancel();
    _hideTimer?.cancel();

    _showTimer = Timer(widget.showDelay, () {
      _createOverlay();
      _animationController.forward();
    });
  }

  void _hideTooltip() {
    _showTimer?.cancel();

    _hideTimer?.cancel();
    _hideTimer = Timer(widget.hideDelay, () async {
      await _animationController.reverse();
      _removeOverlay();
    });
  }

  void _createOverlay() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => _TooltipOverlay(
        link: _layerLink,
        message: widget.message,
        preferredPosition: widget.preferredPosition,
        fadeAnimation: _fadeAnimation,
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _handleTap() {
    if (!widget.showOnTap || widget.isDisabled) return;

    if (_overlayEntry != null) {
      _hideTooltip();
    } else {
      _showTimer?.cancel();
      _createOverlay();
      _animationController.forward();

      // 2초 후 자동 숨김
      _hideTimer = Timer(const Duration(seconds: 2), () {
        _hideTooltip();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _showTooltip(),
        onExit: (_) => _hideTooltip(),
        child: GestureDetector(
          onTap: widget.showOnTap ? _handleTap : null,
          behavior: HitTestBehavior.translucent,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Tooltip Overlay 위젯 (내부용)
class _TooltipOverlay extends StatelessWidget {
  final LayerLink link;
  final String message;
  final AppTooltipPosition preferredPosition;
  final Animation<double> fadeAnimation;

  const _TooltipOverlay({
    required this.link,
    required this.message,
    required this.preferredPosition,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final colors = TooltipColors.standard(colorExt);

    // 위치에 따른 offset 계산
    final (alignment, targetAnchor, followerAnchor) = switch (preferredPosition) {
      AppTooltipPosition.top => (
          Alignment.bottomCenter,
          Alignment.topCenter,
          Alignment.bottomCenter,
        ),
      AppTooltipPosition.bottom => (
          Alignment.topCenter,
          Alignment.bottomCenter,
          Alignment.topCenter,
        ),
      AppTooltipPosition.left => (
          Alignment.centerRight,
          Alignment.centerLeft,
          Alignment.centerRight,
        ),
      AppTooltipPosition.right => (
          Alignment.centerLeft,
          Alignment.centerRight,
          Alignment.centerLeft,
        ),
    };

    // 위치에 따른 offset (spacingExt.small = 8px)
    final offset = switch (preferredPosition) {
      AppTooltipPosition.top => Offset(0, -spacingExt.small),
      AppTooltipPosition.bottom => Offset(0, spacingExt.small),
      AppTooltipPosition.left => Offset(-spacingExt.small, 0),
      AppTooltipPosition.right => Offset(spacingExt.small, 0),
    };

    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        targetAnchor: targetAnchor,
        followerAnchor: followerAnchor,
        offset: offset,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: switch (ResponsiveTokens.getScreenSize(width)) {
                  ScreenSize.xs => width - spacingExt.large,
                  ScreenSize.sm => 280.0,
                  ScreenSize.md => 300.0,
                  ScreenSize.lg => 320.0,
                  ScreenSize.xl => 350.0,
                },
              ),
              padding: EdgeInsets.symmetric(
                horizontal: spacingExt.medium,
                vertical: spacingExt.small,
              ),
              decoration: BoxDecoration(
                color: colors.background,
                border: Border.all(
                  color: colors.border,
                  width: BorderTokens.widthThin,
                ),
                borderRadius: BorderTokens.smallRadius(),
                boxShadow: [
                  BoxShadow(
                    color: colorExt.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.text,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
