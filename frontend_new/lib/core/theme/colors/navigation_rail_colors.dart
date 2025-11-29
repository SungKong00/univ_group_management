import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// NavigationRail 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class NavigationRailColors {
  /// 배경 색상
  final Color background;

  /// 텍스트 색상
  final Color text;

  /// 활성 텍스트 색상
  final Color textActive;

  /// 아이콘 색상
  final Color icon;

  /// 활성 아이콘 색상
  final Color iconActive;

  /// 인디케이터 색상
  final Color indicator;

  /// 테두리 색상
  final Color border;

  /// 호버 색상
  final Color hover;

  const NavigationRailColors({
    required this.background,
    required this.text,
    required this.textActive,
    required this.icon,
    required this.iconActive,
    required this.indicator,
    required this.border,
    required this.hover,
  });

  /// 팩토리 메서드
  factory NavigationRailColors.from(AppColorExtension c) {
    return NavigationRailColors(
      background: c.surfaceSecondary,
      text: c.textSecondary,
      textActive: c.brandPrimary,
      icon: c.textSecondary,
      iconActive: c.brandPrimary,
      indicator: c.brandPrimary.withValues(alpha: 0.15),
      border: c.borderPrimary,
      hover: c.surfaceTertiary,
    );
  }
}
