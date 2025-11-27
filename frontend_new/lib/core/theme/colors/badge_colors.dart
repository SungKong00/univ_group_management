import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// Badge 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
/// Variant(subtle/prominent)와 Color(success/warning/error/info/neutral/brand)
/// 조합에 따라 적절한 색상을 반환합니다.
class BadgeColors {
  /// 배경 색상
  final Color background;

  /// 텍스트/아이콘 색상
  final Color text;

  /// 테두리 색상 (subtle variant용)
  final Color border;

  const BadgeColors({
    required this.background,
    required this.text,
    required this.border,
  });

  /// Variant × Color 조합 기반 팩토리
  ///
  /// subtle: 투명 배경 + 색상 텍스트 + 미묘한 테두리
  /// prominent: 15% opacity 배경 + 색상 텍스트 + 투명 테두리
  factory BadgeColors.from(
    AppColorExtension c,
    AppBadgeVariant variant,
    AppBadgeColor color,
  ) {
    final (bg, text, border) = _getColorSet(c, color);

    return switch (variant) {
      AppBadgeVariant.subtle => BadgeColors(
          background: Colors.transparent,
          text: text,
          border: border,
        ),
      AppBadgeVariant.prominent => BadgeColors(
          background: bg.withValues(alpha: 0.15),
          text: text,
          border: Colors.transparent,
        ),
    };
  }

  /// 색상별 (배경, 텍스트, 테두리) 세트 반환
  static (Color bg, Color text, Color border) _getColorSet(
    AppColorExtension c,
    AppBadgeColor color,
  ) {
    return switch (color) {
      AppBadgeColor.success => (
          c.stateSuccessBg,
          c.stateSuccessText,
          c.stateSuccessBg.withValues(alpha: 0.3),
        ),
      AppBadgeColor.warning => (
          c.stateWarningBg,
          c.stateWarningText,
          c.stateWarningBg.withValues(alpha: 0.3),
        ),
      AppBadgeColor.error => (
          c.stateErrorBg,
          c.stateErrorText,
          c.stateErrorBg.withValues(alpha: 0.3),
        ),
      AppBadgeColor.info => (
          c.stateInfoBg,
          c.stateInfoText,
          c.stateInfoBg.withValues(alpha: 0.3),
        ),
      AppBadgeColor.neutral => (
          c.surfaceTertiary,
          c.textSecondary,
          c.borderSecondary,
        ),
      AppBadgeColor.brand => (
          c.brandPrimary,
          c.brandPrimary,
          c.brandPrimary.withValues(alpha: 0.3),
        ),
    };
  }

  /// Success 색상 (편의 팩토리)
  factory BadgeColors.success(AppColorExtension c,
          {AppBadgeVariant variant = AppBadgeVariant.prominent}) =>
      BadgeColors.from(c, variant, AppBadgeColor.success);

  /// Warning 색상 (편의 팩토리)
  factory BadgeColors.warning(AppColorExtension c,
          {AppBadgeVariant variant = AppBadgeVariant.prominent}) =>
      BadgeColors.from(c, variant, AppBadgeColor.warning);

  /// Error 색상 (편의 팩토리)
  factory BadgeColors.error(AppColorExtension c,
          {AppBadgeVariant variant = AppBadgeVariant.prominent}) =>
      BadgeColors.from(c, variant, AppBadgeColor.error);

  /// Info 색상 (편의 팩토리)
  factory BadgeColors.info(AppColorExtension c,
          {AppBadgeVariant variant = AppBadgeVariant.prominent}) =>
      BadgeColors.from(c, variant, AppBadgeColor.info);

  /// Neutral 색상 (편의 팩토리)
  factory BadgeColors.neutral(AppColorExtension c,
          {AppBadgeVariant variant = AppBadgeVariant.prominent}) =>
      BadgeColors.from(c, variant, AppBadgeColor.neutral);

  /// Brand 색상 (편의 팩토리)
  factory BadgeColors.brand(AppColorExtension c,
          {AppBadgeVariant variant = AppBadgeVariant.prominent}) =>
      BadgeColors.from(c, variant, AppBadgeColor.brand);
}
