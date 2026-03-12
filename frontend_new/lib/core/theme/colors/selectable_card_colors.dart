import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Selectable Card Color Palette
///
/// 선택 가능한 카드(체크박스 포함) 전용 색상 시스템
class SelectableCardColors {
  final Color background;
  final Color backgroundHover;
  final Color backgroundSelected;
  final Color border;
  final Color borderSelected;
  final Color title;
  final Color subtitle;
  final Color checkboxBg;
  final Color checkboxBorder;

  SelectableCardColors({
    required this.background,
    required this.backgroundHover,
    required this.backgroundSelected,
    required this.border,
    required this.borderSelected,
    required this.title,
    required this.subtitle,
    required this.checkboxBg,
    required this.checkboxBorder,
  });

  /// Standard variant (기본 스타일 - 중립적인 카드)
  factory SelectableCardColors.standard(AppColorExtension colors) {
    return SelectableCardColors(
      background: colors.surfaceSecondary,
      backgroundHover: colors.surfaceTertiary,
      backgroundSelected: colors.brandPrimary.withValues(alpha: 0.10),
      border: colors.borderSecondary,
      borderSelected: colors.brandPrimary,
      title: colors.textPrimary,
      subtitle: colors.textSecondary,
      checkboxBg: colors.surfaceTertiary,
      checkboxBorder: colors.borderPrimary,
    );
  }

  /// Featured variant (강조된 스타일 - Success 색상 강조)
  factory SelectableCardColors.featured(AppColorExtension colors) {
    return SelectableCardColors(
      background: colors.stateSuccessBg.withValues(alpha: 0.08),
      backgroundHover: colors.stateSuccessBg.withValues(alpha: 0.10),
      backgroundSelected: colors.stateSuccessBg.withValues(alpha: 0.15),
      border: colors.stateSuccessBg.withValues(alpha: 0.2),
      borderSelected: colors.stateSuccessBg.withValues(alpha: 0.4),
      title: colors.stateSuccessText,
      subtitle: colors.textPrimary,
      checkboxBg: colors.surfaceSecondary,
      checkboxBorder: colors.stateSuccessBg.withValues(alpha: 0.5),
    );
  }

  /// Highlighted variant (최상위 강조 - Info 색상 강조)
  factory SelectableCardColors.highlighted(AppColorExtension colors) {
    return SelectableCardColors(
      background: colors.stateInfoBg.withValues(alpha: 0.08),
      backgroundHover: colors.stateInfoBg.withValues(alpha: 0.10),
      backgroundSelected: colors.stateInfoBg.withValues(alpha: 0.15),
      border: colors.stateInfoBg.withValues(alpha: 0.2),
      borderSelected: colors.stateInfoBg.withValues(alpha: 0.4),
      title: colors.stateInfoText,
      subtitle: colors.textPrimary,
      checkboxBg: colors.surfaceSecondary,
      checkboxBorder: colors.stateInfoBg.withValues(alpha: 0.5),
    );
  }
}
