import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/alert_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';
import '../theme/enums.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppAlertType, AppAlertStyle;

/// 알림 배너 컴포넌트
///
/// **용도**: 페이지 상단 경고, 안내, 성공/에러 메시지 표시
/// **접근성**: Semantics 지원, 닫기 버튼 키보드 접근
///
/// ```dart
/// // 기본 사용
/// AppAlert(
///   type: AppAlertType.info,
///   message: '새로운 업데이트가 있습니다.',
/// )
///
/// // 제목 포함
/// AppAlert(
///   type: AppAlertType.warning,
///   title: '주의',
///   message: '이 작업은 되돌릴 수 없습니다.',
/// )
///
/// // 액션 버튼 포함
/// AppAlert(
///   type: AppAlertType.error,
///   message: '저장에 실패했습니다.',
///   actionLabel: '다시 시도',
///   onAction: () => _retry(),
///   isDismissible: true,
///   onDismiss: () => _hideAlert(),
/// )
/// ```
class AppAlert extends StatelessWidget {
  /// 알림 타입
  final AppAlertType type;

  /// 알림 스타일
  final AppAlertStyle style;

  /// 제목 (선택)
  final String? title;

  /// 메시지
  final String message;

  /// 커스텀 아이콘
  final IconData? icon;

  /// 닫기 가능 여부
  final bool isDismissible;

  /// 닫기 콜백
  final VoidCallback? onDismiss;

  /// 액션 버튼 라벨
  final String? actionLabel;

  /// 액션 버튼 콜백
  final VoidCallback? onAction;

  const AppAlert({
    super.key,
    required this.type,
    required this.message,
    this.style = AppAlertStyle.subtle,
    this.title,
    this.icon,
    this.isDismissible = false,
    this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  IconData _getDefaultIcon() {
    return switch (type) {
      AppAlertType.info => Icons.info_outline,
      AppAlertType.success => Icons.check_circle_outline,
      AppAlertType.warning => Icons.warning_amber_outlined,
      AppAlertType.error => Icons.error_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = AlertColors.from(colorExt, type, style);

    return Semantics(
      label: '${type.name} 알림: $message',
      child: AnimatedContainer(
        duration: AnimationTokens.durationQuick,
        padding: EdgeInsets.all(spacingExt.medium),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
          border: style == AppAlertStyle.outlined
              ? Border.all(color: colors.border, width: BorderTokens.widthThin)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이콘
            Icon(
              icon ?? _getDefaultIcon(),
              size: ComponentSizeTokens.iconMedium,
              color: colors.icon,
            ),
            SizedBox(width: spacingExt.small),

            // 콘텐츠
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.titleText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: spacingExt.xs),
                  ],
                  Text(
                    message,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: colors.contentText),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    SizedBox(height: spacingExt.small),
                    _AlertActionButton(
                      label: actionLabel!,
                      onTap: onAction!,
                      color: colors.actionButton,
                    ),
                  ],
                ],
              ),
            ),

            // 닫기 버튼
            if (isDismissible) ...[
              SizedBox(width: spacingExt.small),
              _AlertCloseButton(
                onTap: onDismiss ?? () {},
                color: colors.closeButton,
                hoverColor: colors.closeButtonHover,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 액션 버튼
class _AlertActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _AlertActionButton({
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  State<_AlertActionButton> createState() => _AlertActionButtonState();
}

class _AlertActionButtonState extends State<_AlertActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: widget.color,
            fontWeight: FontWeight.w600,
            decoration: _isHovered ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }
}

/// 닫기 버튼
class _AlertCloseButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color color;
  final Color hoverColor;

  const _AlertCloseButton({
    required this.onTap,
    required this.color,
    required this.hoverColor,
  });

  @override
  State<_AlertCloseButton> createState() => _AlertCloseButtonState();
}

class _AlertCloseButtonState extends State<_AlertCloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.close,
            size: ComponentSizeTokens.iconSmall,
            color: _isHovered ? widget.hoverColor : widget.color,
          ),
        ),
      ),
    );
  }
}
