import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// Toast 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
/// Toast 타입(success/warning/error/info)에 따라 적절한 색상을 반환합니다.
class ToastColors {
  /// 배경 색상
  final Color background;

  /// 텍스트/메시지 색상
  final Color text;

  /// 아이콘 색상
  final Color icon;

  /// 테두리 색상
  final Color border;

  /// 액션 버튼 색상
  final Color action;

  /// 닫기 버튼 색상
  final Color dismiss;

  const ToastColors({
    required this.background,
    required this.text,
    required this.icon,
    required this.border,
    required this.action,
    required this.dismiss,
  });

  /// 타입별 팩토리 메서드
  factory ToastColors.from(AppColorExtension c, AppToastType type) {
    return switch (type) {
      AppToastType.success => ToastColors(
          background: c.surfaceSecondary,
          text: c.textPrimary,
          icon: c.stateSuccessText,
          border: c.stateSuccessBg.withValues(alpha: 0.3),
          action: c.stateSuccessText,
          dismiss: c.textTertiary,
        ),
      AppToastType.warning => ToastColors(
          background: c.surfaceSecondary,
          text: c.textPrimary,
          icon: c.stateWarningText,
          border: c.stateWarningBg.withValues(alpha: 0.3),
          action: c.stateWarningText,
          dismiss: c.textTertiary,
        ),
      AppToastType.error => ToastColors(
          background: c.surfaceSecondary,
          text: c.textPrimary,
          icon: c.stateErrorText,
          border: c.stateErrorBg.withValues(alpha: 0.3),
          action: c.stateErrorText,
          dismiss: c.textTertiary,
        ),
      AppToastType.info => ToastColors(
          background: c.surfaceSecondary,
          text: c.textPrimary,
          icon: c.stateInfoText,
          border: c.stateInfoBg.withValues(alpha: 0.3),
          action: c.stateInfoText,
          dismiss: c.textTertiary,
        ),
    };
  }

  /// Success 타입 (편의 팩토리)
  factory ToastColors.success(AppColorExtension c) =>
      ToastColors.from(c, AppToastType.success);

  /// Warning 타입 (편의 팩토리)
  factory ToastColors.warning(AppColorExtension c) =>
      ToastColors.from(c, AppToastType.warning);

  /// Error 타입 (편의 팩토리)
  factory ToastColors.error(AppColorExtension c) =>
      ToastColors.from(c, AppToastType.error);

  /// Info 타입 (편의 팩토리)
  factory ToastColors.info(AppColorExtension c) =>
      ToastColors.from(c, AppToastType.info);

  /// 타입별 기본 아이콘
  static IconData getDefaultIcon(AppToastType type) {
    return switch (type) {
      AppToastType.success => Icons.check_circle_outline,
      AppToastType.warning => Icons.warning_amber_outlined,
      AppToastType.error => Icons.error_outline,
      AppToastType.info => Icons.info_outline,
    };
  }
}
