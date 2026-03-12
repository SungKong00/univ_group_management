import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Wide Card Color Palette
///
/// 와이드 카드(배너/프로모션) 전용 색상 시스템
class WideCardColors {
  final Color background;
  final Color backgroundHover;
  final Color border;
  final Color title;
  final Color subtitle;
  final Color description;
  final Color ctaBackground;
  final Color ctaText;

  WideCardColors({
    required this.background,
    required this.backgroundHover,
    required this.border,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.ctaBackground,
    required this.ctaText,
  });

  /// Standard variant (기본 스타일 - 중립적인 배너)
  factory WideCardColors.standard(AppColorExtension colors) {
    return WideCardColors(
      background: colors.surfaceSecondary,
      backgroundHover: colors.surfaceTertiary,
      border: colors.borderSecondary,
      title: colors.textPrimary,
      subtitle: colors.textSecondary,
      description: colors.textTertiary,
      ctaBackground: colors.brandPrimary,
      ctaText: colors.textOnBrand,
    );
  }

  /// Featured variant (강조된 스타일 - Brand 배경)
  factory WideCardColors.featured(AppColorExtension colors) {
    return WideCardColors(
      background: colors.brandPrimary.withValues(alpha: 0.12),
      backgroundHover: colors.brandPrimary.withValues(alpha: 0.16),
      border: colors.brandPrimary.withValues(alpha: 0.3),
      title: colors.brandSecondary,
      subtitle: colors.textPrimary,
      description: colors.textSecondary,
      ctaBackground: colors.brandPrimary,
      ctaText: colors.textOnBrand,
    );
  }

  /// Highlighted variant (최상위 강조 - Success 강조)
  factory WideCardColors.highlighted(AppColorExtension colors) {
    return WideCardColors(
      background: colors.stateSuccessBg.withValues(alpha: 0.12),
      backgroundHover: colors.stateSuccessBg.withValues(alpha: 0.16),
      border: colors.stateSuccessBg.withValues(alpha: 0.3),
      title: colors.stateSuccessText,
      subtitle: colors.textPrimary,
      description: colors.textSecondary,
      ctaBackground: colors.stateSuccessBg,
      ctaText: colors.textOnBrand,
    );
  }
}
