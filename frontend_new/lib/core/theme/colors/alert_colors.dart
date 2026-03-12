import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// Alert 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class AlertColors {
  /// 배경 색상
  final Color background;

  /// 테두리 색상
  final Color border;

  /// 아이콘 색상
  final Color icon;

  /// 제목 텍스트 색상
  final Color titleText;

  /// 내용 텍스트 색상
  final Color contentText;

  /// 닫기 버튼 색상
  final Color closeButton;

  /// 닫기 버튼 호버 색상
  final Color closeButtonHover;

  /// 액션 버튼 색상
  final Color actionButton;

  const AlertColors({
    required this.background,
    required this.border,
    required this.icon,
    required this.titleText,
    required this.contentText,
    required this.closeButton,
    required this.closeButtonHover,
    required this.actionButton,
  });

  /// 타입 및 스타일별 팩토리 메서드
  factory AlertColors.from(
    AppColorExtension c,
    AppAlertType type,
    AppAlertStyle style,
  ) {
    final baseColors = _getBaseColors(c, type);

    return switch (style) {
      AppAlertStyle.filled => AlertColors(
        background: baseColors.background,
        border: baseColors.background,
        icon: Colors.white,
        titleText: Colors.white,
        contentText: Colors.white.withValues(alpha: 0.9),
        closeButton: Colors.white.withValues(alpha: 0.7),
        closeButtonHover: Colors.white,
        actionButton: Colors.white,
      ),
      AppAlertStyle.outlined => AlertColors(
        background: Colors.transparent,
        border: baseColors.border,
        icon: baseColors.icon,
        titleText: baseColors.text,
        contentText: c.textSecondary,
        closeButton: c.textTertiary,
        closeButtonHover: baseColors.text,
        actionButton: baseColors.text,
      ),
      AppAlertStyle.subtle => AlertColors(
        background: baseColors.subtleBackground,
        border: Colors.transparent,
        icon: baseColors.icon,
        titleText: baseColors.text,
        contentText: c.textSecondary,
        closeButton: c.textTertiary,
        closeButtonHover: baseColors.text,
        actionButton: baseColors.text,
      ),
    };
  }

  static _AlertBaseColors _getBaseColors(
    AppColorExtension c,
    AppAlertType type,
  ) {
    return switch (type) {
      AppAlertType.info => _AlertBaseColors(
        background: c.stateInfoBg,
        subtleBackground: c.stateInfoBg.withValues(alpha: 0.15),
        border: c.stateInfoBg,
        icon: c.stateInfoText,
        text: c.stateInfoText,
      ),
      AppAlertType.success => _AlertBaseColors(
        background: c.stateSuccessBg,
        subtleBackground: c.stateSuccessBg.withValues(alpha: 0.15),
        border: c.stateSuccessBg,
        icon: c.stateSuccessText,
        text: c.stateSuccessText,
      ),
      AppAlertType.warning => _AlertBaseColors(
        background: c.stateWarningBg,
        subtleBackground: c.stateWarningBg.withValues(alpha: 0.15),
        border: c.stateWarningBg,
        icon: c.stateWarningText,
        text: c.stateWarningText,
      ),
      AppAlertType.error => _AlertBaseColors(
        background: c.stateErrorBg,
        subtleBackground: c.stateErrorBg.withValues(alpha: 0.15),
        border: c.stateErrorBg,
        icon: c.stateErrorText,
        text: c.stateErrorText,
      ),
    };
  }
}

class _AlertBaseColors {
  final Color background;
  final Color subtleBackground;
  final Color border;
  final Color icon;
  final Color text;

  const _AlertBaseColors({
    required this.background,
    required this.subtleBackground,
    required this.border,
    required this.icon,
    required this.text,
  });
}
