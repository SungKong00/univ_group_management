import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// Chip 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class ChipColors {
  /// 배경 색상
  final Color background;

  /// 호버 시 배경
  final Color backgroundHover;

  /// 선택 시 배경
  final Color backgroundSelected;

  /// 텍스트 색상
  final Color text;

  /// 선택 시 텍스트
  final Color textSelected;

  /// 테두리 색상
  final Color border;

  /// 선택 시 테두리
  final Color borderSelected;

  /// 삭제 아이콘 색상
  final Color deleteIcon;

  const ChipColors({
    required this.background,
    required this.backgroundHover,
    required this.backgroundSelected,
    required this.text,
    required this.textSelected,
    required this.border,
    required this.borderSelected,
    required this.deleteIcon,
  });

  /// 타입별 팩토리 메서드
  factory ChipColors.from(AppColorExtension c, AppChipType type) {
    return switch (type) {
      AppChipType.filter => ChipColors(
          background: c.surfaceSecondary,
          backgroundHover: c.surfaceTertiary,
          backgroundSelected: c.brandPrimary.withValues(alpha: 0.15),
          text: c.textSecondary,
          textSelected: c.brandPrimary,
          border: c.borderSecondary,
          borderSelected: c.brandPrimary,
          deleteIcon: c.textTertiary,
        ),
      AppChipType.input => ChipColors(
          background: c.surfaceTertiary,
          backgroundHover: c.surfaceQuaternary,
          backgroundSelected: c.surfaceTertiary,
          text: c.textPrimary,
          textSelected: c.textPrimary,
          border: c.borderSecondary,
          borderSelected: c.borderSecondary,
          deleteIcon: c.textSecondary,
        ),
      AppChipType.suggestion => ChipColors(
          background: Colors.transparent,
          backgroundHover: c.surfaceSecondary,
          backgroundSelected: c.brandPrimary.withValues(alpha: 0.1),
          text: c.textTertiary,
          textSelected: c.brandPrimary,
          border: c.borderTertiary,
          borderSelected: c.brandPrimary.withValues(alpha: 0.3),
          deleteIcon: c.textTertiary,
        ),
    };
  }

  /// Filter 타입 (편의 팩토리)
  factory ChipColors.filter(AppColorExtension c) =>
      ChipColors.from(c, AppChipType.filter);

  /// Input 타입 (편의 팩토리)
  factory ChipColors.input(AppColorExtension c) =>
      ChipColors.from(c, AppChipType.input);

  /// Suggestion 타입 (편의 팩토리)
  factory ChipColors.suggestion(AppColorExtension c) =>
      ChipColors.from(c, AppChipType.suggestion);
}
