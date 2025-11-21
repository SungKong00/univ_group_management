import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Vertical Card Color Palette
///
/// 세로 방향 카드(이미지 상단 + 텍스트) 전용 색상 시스템
class VerticalCardColors {
  final Color background;
  final Color backgroundHover;
  final Color border;
  final Color title;
  final Color subtitle;
  final Color description;
  final Color meta;
  final Color divider;

  VerticalCardColors({
    required this.background,
    required this.backgroundHover,
    required this.border,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.meta,
    required this.divider,
  });

  /// Standard variant (기본 스타일 - 중립적인 카드)
  factory VerticalCardColors.standard(AppColorExtension colors) {
    return VerticalCardColors(
      background: colors.surfaceSecondary,
      backgroundHover: colors.surfaceTertiary,
      border: colors.borderSecondary,
      title: colors.textPrimary,
      subtitle: colors.textSecondary,
      description: colors.textTertiary,
      meta: colors.textQuaternary,
      divider: colors.dividerPrimary,
    );
  }

  /// Featured variant (강조된 스타일 - Success 색상 강조)
  factory VerticalCardColors.featured(AppColorExtension colors) {
    return VerticalCardColors(
      background: colors.stateSuccessBg.withValues(alpha: 0.08),
      backgroundHover: colors.stateSuccessBg.withValues(alpha: 0.12),
      border: colors.stateSuccessBg.withValues(alpha: 0.3),
      title: colors.stateSuccessText,
      subtitle: colors.textPrimary,
      description: colors.textSecondary,
      meta: colors.textTertiary,
      divider: colors.stateSuccessBg.withValues(alpha: 0.2),
    );
  }

  /// Highlighted variant (최상위 강조 - Brand 색상 강조)
  factory VerticalCardColors.highlighted(AppColorExtension colors) {
    return VerticalCardColors(
      background: colors.brandPrimary.withValues(alpha: 0.08),
      backgroundHover: colors.brandPrimary.withValues(alpha: 0.12),
      border: colors.brandPrimary.withValues(alpha: 0.3),
      title: colors.brandSecondary,
      subtitle: colors.textPrimary,
      description: colors.textSecondary,
      meta: colors.textTertiary,
      divider: colors.brandPrimary.withValues(alpha: 0.2),
    );
  }
}
