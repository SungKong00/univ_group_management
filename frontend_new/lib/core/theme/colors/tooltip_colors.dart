import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Tooltip 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class TooltipColors {
  /// 배경 색상
  final Color background;

  /// 텍스트 색상
  final Color text;

  /// 테두리 색상
  final Color border;

  const TooltipColors({
    required this.background,
    required this.text,
    required this.border,
  });

  /// 기본 툴팁 색상
  factory TooltipColors.standard(AppColorExtension c) {
    return TooltipColors(
      background: c.surfaceQuaternary,
      text: c.textPrimary,
      border: c.borderSecondary,
    );
  }
}
