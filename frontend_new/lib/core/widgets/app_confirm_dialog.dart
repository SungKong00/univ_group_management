import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';

/// 확인 다이얼로그 표시 함수
///
/// 위험한 작업 전 사용자에게 재확인을 요청합니다.
///
/// ```dart
/// // 기본 사용
/// final confirmed = await showAppConfirmDialog(
///   context: context,
///   title: '삭제 확인',
///   message: '이 항목을 삭제하시겠습니까?',
/// );
///
/// // 위험 모드
/// final confirmed = await showAppConfirmDialog(
///   context: context,
///   title: '계정 삭제',
///   message: '모든 데이터가 영구적으로 삭제됩니다.',
///   isDestructive: true,
///   confirmLabel: '영구 삭제',
/// );
/// ```
Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = '확인',
  String cancelLabel = '취소',
  bool isDestructive = false,
  IconData? icon,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '다이얼로그 닫기',
    barrierColor: Colors.black54,
    transitionDuration: AnimationTokens.durationStandard,
    pageBuilder: (context, animation, secondaryAnimation) {
      return _AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        icon: icon,
        animation: animation,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  );
  return result ?? false;
}

class _AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;
  final Animation<double> animation;

  const _AppConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
    required this.animation,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;

    final scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: AnimationTokens.curveSmooth),
    );
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: AnimationTokens.curveDefault),
    );

    final iconColor = isDestructive
        ? colorExt.stateErrorBg
        : colorExt.brandPrimary;
    final confirmBgColor = isDestructive
        ? colorExt.stateErrorBg
        : colorExt.brandPrimary;

    return Center(
      child: FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 400,
              margin: EdgeInsets.all(spacingExt.large),
              padding: EdgeInsets.all(spacingExt.large),
              decoration: BoxDecoration(
                color: colorExt.surfacePrimary,
                borderRadius: BorderRadius.circular(BorderTokens.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 아이콘
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon ??
                          (isDestructive
                              ? Icons.warning_amber
                              : Icons.help_outline),
                      size: ComponentSizeTokens.iconLarge,
                      color: iconColor,
                    ),
                  ),
                  SizedBox(height: spacingExt.medium),

                  // 제목
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorExt.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: spacingExt.small),

                  // 메시지
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorExt.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: spacingExt.large),

                  // 버튼들
                  Row(
                    children: [
                      // 취소 버튼
                      Expanded(
                        child: _DialogButton(
                          label: cancelLabel,
                          onTap: () => Navigator.of(context).pop(false),
                          backgroundColor: colorExt.surfaceTertiary,
                          textColor: colorExt.textPrimary,
                        ),
                      ),
                      SizedBox(width: spacingExt.small),

                      // 확인 버튼
                      Expanded(
                        child: _DialogButton(
                          label: confirmLabel,
                          onTap: () => Navigator.of(context).pop(true),
                          backgroundColor: confirmBgColor,
                          textColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 다이얼로그 버튼
class _DialogButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;

  const _DialogButton({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _isPressed
                ? widget.backgroundColor.withValues(alpha: 0.8)
                : _isHovered
                ? widget.backgroundColor.withValues(alpha: 0.9)
                : widget.backgroundColor,
            borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: widget.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
