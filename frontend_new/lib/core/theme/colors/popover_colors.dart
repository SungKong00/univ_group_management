import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Popover 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class PopoverColors {
  /// 배경 색상
  final Color background;

  /// 테두리 색상
  final Color border;

  /// 그림자 색상
  final Color shadow;

  /// 텍스트 색상
  final Color text;

  /// 보조 텍스트 색상
  final Color textSecondary;

  /// 화살표 색상
  final Color arrow;

  const PopoverColors({
    required this.background,
    required this.border,
    required this.shadow,
    required this.text,
    required this.textSecondary,
    required this.arrow,
  });

  /// 기본 팩토리 메서드
  factory PopoverColors.from(AppColorExtension c) {
    return PopoverColors(
      background: c.surfaceSecondary,
      border: c.borderSecondary,
      shadow: Colors.black.withValues(alpha: 0.2),
      text: c.textPrimary,
      textSecondary: c.textSecondary,
      arrow: c.surfaceSecondary,
    );
  }
}
