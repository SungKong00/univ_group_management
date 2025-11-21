import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Horizontal Card Color Palette
///
/// 가로 방향 카드(이미지 좌측 + 텍스트 우측) 전용 색상 시스템
class HorizontalCardColors {
  final Color background;
  final Color backgroundHover;
  final Color border;
  final Color title;
  final Color subtitle;
  final Color description;
  final Color meta;
  final Color divider;

  HorizontalCardColors({
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
  factory HorizontalCardColors.standard(AppColorExtension colors) {
    return HorizontalCardColors(
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

  /// Featured variant (강조된 스타일 - Info 색상 강조)
  factory HorizontalCardColors.featured(AppColorExtension colors) {
    return HorizontalCardColors(
      background: colors.stateInfoBg.withValues(alpha: 0.08),
      backgroundHover: colors.stateInfoBg.withValues(alpha: 0.12),
      border: colors.stateInfoBg.withValues(alpha: 0.3),
      title: colors.stateInfoText,
      subtitle: colors.textPrimary,
      description: colors.textSecondary,
      meta: colors.textTertiary,
      divider: colors.stateInfoBg.withValues(alpha: 0.2),
    );
  }

  /// Highlighted variant (최상위 강조 - Warning 색상 강조)
  factory HorizontalCardColors.highlighted(AppColorExtension colors) {
    return HorizontalCardColors(
      background: colors.stateWarningBg.withValues(alpha: 0.08),
      backgroundHover: colors.stateWarningBg.withValues(alpha: 0.12),
      border: colors.stateWarningBg.withValues(alpha: 0.3),
      title: colors.stateWarningText,
      subtitle: colors.textPrimary,
      description: colors.textSecondary,
      meta: colors.textTertiary,
      divider: colors.stateWarningBg.withValues(alpha: 0.2),
    );
  }
}
