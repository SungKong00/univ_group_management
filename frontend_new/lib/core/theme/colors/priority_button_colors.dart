import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Priority Button 컴포넌트 전용 색상 구조
///
/// Issue 우선순위 설정 버튼 (High, Medium, Low, None)
class PriorityButtonColors {
  /// 배경 색상
  final Color background;

  /// 호버 시 배경
  final Color backgroundHover;

  /// 테두리 색상
  final Color border;

  /// 텍스트 색상
  final Color text;

  /// 아이콘 색상
  final Color icon;

  const PriorityButtonColors({
    required this.background,
    required this.backgroundHover,
    required this.border,
    required this.text,
    required this.icon,
  });

  /// High 우선순위 (빨강)
  factory PriorityButtonColors.high(AppColorExtension c) {
    return PriorityButtonColors(
      background: c.stateErrorBg,
      backgroundHover: c.stateErrorBg.withValues(alpha: 0.9),
      border: c.stateErrorText,
      text: c.stateErrorText,
      icon: c.stateErrorText,
    );
  }

  /// Medium 우선순위 (주황)
  factory PriorityButtonColors.medium(AppColorExtension c) {
    return PriorityButtonColors(
      background: c.stateWarningBg,
      backgroundHover: c.stateWarningBg.withValues(alpha: 0.9),
      border: c.stateWarningText,
      text: c.stateWarningText,
      icon: c.stateWarningText,
    );
  }

  /// Low 우선순위 (파랑)
  factory PriorityButtonColors.low(AppColorExtension c) {
    return PriorityButtonColors(
      background: c.stateInfoBg,
      backgroundHover: c.stateInfoBg.withValues(alpha: 0.9),
      border: c.stateInfoText,
      text: c.stateInfoText,
      icon: c.stateInfoText,
    );
  }

  /// None 우선순위 (회색)
  factory PriorityButtonColors.none(AppColorExtension c) {
    return PriorityButtonColors(
      background: c.surfaceTertiary,
      backgroundHover: c.surfaceQuaternary,
      border: c.borderSecondary,
      text: c.textTertiary,
      icon: c.textTertiary,
    );
  }
}
