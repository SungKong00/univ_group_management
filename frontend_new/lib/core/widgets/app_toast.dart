import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/toast_colors.dart';
import '../theme/enums.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';
import '../theme/responsive_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppToastType, AppToastPosition;

/// Toast 데이터 모델
class AppToastData {
  final String message;
  final AppToastType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final IconData? icon;

  const AppToastData({
    required this.message,
    this.type = AppToastType.info,
    this.duration = const Duration(seconds: 4),
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.icon,
  });
}

/// Toast 관리자 (Overlay 기반)
///
/// 앱 전역에서 Toast를 표시하기 위한 싱글톤 관리자입니다.
/// `AppToastManager.show()` 또는 `showAppToast()` 함수로 호출합니다.
class AppToastManager {
  static final AppToastManager _instance = AppToastManager._internal();
  factory AppToastManager() => _instance;
  AppToastManager._internal();

  OverlayEntry? _currentEntry;
  Timer? _dismissTimer;

  /// Toast 표시
  void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    AppToastPosition position = AppToastPosition.topCenter,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onDismiss,
    IconData? icon,
  }) {
    // 기존 Toast 제거
    dismiss();

    final overlay = Overlay.of(context);

    _currentEntry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        message: message,
        type: type,
        position: position,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () {
          onDismiss?.call();
          dismiss();
        },
        icon: icon,
      ),
    );

    overlay.insert(_currentEntry!);

    // 자동 dismiss 타이머
    _dismissTimer = Timer(duration, () {
      dismiss();
    });
  }

  /// Toast 닫기
  void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

/// 전역 Toast 표시 함수
///
/// ```dart
/// showAppToast(
///   context,
///   message: '저장되었습니다.',
///   type: AppToastType.success,
/// );
/// ```
void showAppToast(
  BuildContext context, {
  required String message,
  AppToastType type = AppToastType.info,
  AppToastPosition position = AppToastPosition.topCenter,
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  VoidCallback? onAction,
  VoidCallback? onDismiss,
  IconData? icon,
}) {
  AppToastManager().show(
    context,
    message: message,
    type: type,
    position: position,
    duration: duration,
    actionLabel: actionLabel,
    onAction: onAction,
    onDismiss: onDismiss,
    icon: icon,
  );
}

/// Toast Overlay 위젯 (내부용)
class _ToastOverlay extends StatefulWidget {
  final String message;
  final AppToastType type;
  final AppToastPosition position;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final IconData? icon;

  const _ToastOverlay({
    required this.message,
    required this.type,
    required this.position,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.icon,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationTokens.durationSmooth,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AnimationTokens.curveSmooth),
    );

    // Position에 따른 슬라이드 방향
    final slideBegin = switch (widget.position) {
      AppToastPosition.topCenter ||
      AppToastPosition.topRight => const Offset(0, -1),
      AppToastPosition.bottomCenter ||
      AppToastPosition.bottomRight => const Offset(0, 1),
    };

    _slideAnimation = Tween<Offset>(begin: slideBegin, end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: AnimationTokens.curveSlide,
          ),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = ResponsiveTokens.pagePadding(width);

    // Position에 따른 정렬
    final (top, bottom, alignment) = switch (widget.position) {
      AppToastPosition.topCenter => (padding + 48, null, Alignment.topCenter),
      AppToastPosition.topRight => (padding + 48, null, Alignment.topRight),
      AppToastPosition.bottomCenter => (
        null,
        padding + 48,
        Alignment.bottomCenter,
      ),
      AppToastPosition.bottomRight => (
        null,
        padding + 48,
        Alignment.bottomRight,
      ),
    };

    return Positioned(
      top: top,
      bottom: bottom,
      left: 0,
      right: 0,
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _ToastContent(
                message: widget.message,
                type: widget.type,
                actionLabel: widget.actionLabel,
                onAction: widget.onAction,
                onDismiss: _dismiss,
                icon: widget.icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Toast 콘텐츠 위젯
class _ToastContent extends StatelessWidget {
  final String message;
  final AppToastType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final IconData? icon;

  const _ToastContent({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final spacingExt = context.appSpacing;
    final width = MediaQuery.sizeOf(context).width;
    final colors = ToastColors.from(colorExt, type);

    final displayIcon = icon ?? ToastColors.getDefaultIcon(type);
    final maxWidth = switch (ResponsiveTokens.getScreenSize(width)) {
      ScreenSize.xs => width - spacingExt.xl,
      ScreenSize.sm => width - spacingExt.large,
      ScreenSize.md => 400.0,
      ScreenSize.lg => 450.0,
      ScreenSize.xl => 500.0,
    };

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.symmetric(
          horizontal: spacingExt.large,
          vertical: spacingExt.medium,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(
            color: colors.border,
            width: BorderTokens.widthThin,
          ),
          borderRadius: BorderTokens.mediumRadius(),
          boxShadow: [
            BoxShadow(
              color: colorExt.shadow,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              displayIcon,
              size: ResponsiveTokens.iconSize(width),
              color: colors.icon,
            ),
            SizedBox(width: spacingExt.medium),

            // Message
            Flexible(
              child: Text(
                message,
                style: textTheme.bodyMedium?.copyWith(color: colors.text),
              ),
            ),

            // Action Button (optional)
            if (actionLabel != null && onAction != null) ...[
              SizedBox(width: spacingExt.medium),
              GestureDetector(
                onTap: () {
                  onAction!();
                  onDismiss?.call();
                },
                child: Text(
                  actionLabel!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.action,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            // Dismiss Button
            SizedBox(width: spacingExt.xs),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                size: ResponsiveTokens.iconSize(width) - 2,
                color: colors.dismiss,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 인라인 Toast 위젯 (Overlay 없이 직접 배치용)
///
/// ```dart
/// AppToast(
///   message: '파일이 업로드되었습니다.',
///   type: AppToastType.success,
///   onDismiss: () => setState(() => _showToast = false),
/// )
/// ```
class AppToast extends StatelessWidget {
  final String message;
  final AppToastType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final IconData? icon;

  const AppToast({
    super.key,
    required this.message,
    this.type = AppToastType.info,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _ToastContent(
      message: message,
      type: type,
      actionLabel: actionLabel,
      onAction: onAction,
      onDismiss: onDismiss,
      icon: icon,
    );
  }
}
