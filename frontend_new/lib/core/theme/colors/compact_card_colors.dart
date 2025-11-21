import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Compact Card Color Palette
///
/// 컴팩트 카드(아이콘/이미지 + 제목만) 전용 색상 시스템
class CompactCardColors {
  final Color background;
  final Color backgroundHover;
  final Color border;
  final Color title;
  final Color meta;
  final Color divider;

  CompactCardColors({
    required this.background,
    required this.backgroundHover,
    required this.border,
    required this.title,
    required this.meta,
    required this.divider,
  });

  /// Standard variant (기본 스타일 - 중립적인 카드)
  factory CompactCardColors.standard(AppColorExtension colors) {
    return CompactCardColors(
      background: colors.surfaceSecondary,
      backgroundHover: colors.surfaceTertiary,
      border: colors.borderSecondary,
      title: colors.textPrimary,
      meta: colors.textTertiary,
      divider: colors.dividerPrimary,
    );
  }

  /// Featured variant (강조된 스타일 - Brand 색상 강조)
  factory CompactCardColors.featured(AppColorExtension colors) {
    return CompactCardColors(
      background: colors.brandPrimary.withValues(alpha: 0.08),
      backgroundHover: colors.brandPrimary.withValues(alpha: 0.12),
      border: colors.brandPrimary.withValues(alpha: 0.3),
      title: colors.brandSecondary,
      meta: colors.textTertiary,
      divider: colors.brandPrimary.withValues(alpha: 0.2),
    );
  }

  /// Highlighted variant (최상위 강조 - Success 색상 강조)
  factory CompactCardColors.highlighted(AppColorExtension colors) {
    return CompactCardColors(
      background: colors.stateSuccessBg.withValues(alpha: 0.08),
      backgroundHover: colors.stateSuccessBg.withValues(alpha: 0.12),
      border: colors.stateSuccessBg.withValues(alpha: 0.3),
      title: colors.stateSuccessText,
      meta: colors.textTertiary,
      divider: colors.stateSuccessBg.withValues(alpha: 0.2),
    );
  }
}
