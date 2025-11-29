import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// BottomNav 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class BottomNavColors {
  /// 배경 색상
  final Color background;

  /// 텍스트 색상 (비활성)
  final Color text;

  /// 텍스트 색상 (활성)
  final Color textActive;

  /// 아이콘 색상 (비활성)
  final Color icon;

  /// 아이콘 색상 (활성)
  final Color iconActive;

  /// 테두리 색상
  final Color border;

  /// 인디케이터 색상
  final Color indicator;

  /// 배지 배경 색상
  final Color badgeBackground;

  /// 배지 텍스트 색상
  final Color badgeText;

  const BottomNavColors({
    required this.background,
    required this.text,
    required this.textActive,
    required this.icon,
    required this.iconActive,
    required this.border,
    required this.indicator,
    required this.badgeBackground,
    required this.badgeText,
  });

  /// Style별 팩토리 메서드
  factory BottomNavColors.from(AppColorExtension c, AppBottomNavStyle style) {
    return switch (style) {
      AppBottomNavStyle.standard => BottomNavColors(
        background: c.surfaceSecondary,
        text: c.textSecondary,
        textActive: c.brandPrimary,
        icon: c.textSecondary,
        iconActive: c.brandPrimary,
        border: c.borderPrimary,
        indicator: c.brandPrimary.withValues(alpha: 0.15),
        badgeBackground: c.stateErrorBg,
        badgeText: Colors.white,
      ),
      AppBottomNavStyle.compact => BottomNavColors(
        background: c.surfaceSecondary,
        text: c.textSecondary,
        textActive: c.brandPrimary,
        icon: c.textSecondary,
        iconActive: c.brandPrimary,
        border: c.borderPrimary,
        indicator: c.brandPrimary.withValues(alpha: 0.15),
        badgeBackground: c.stateErrorBg,
        badgeText: Colors.white,
      ),
      AppBottomNavStyle.shifting => BottomNavColors(
        background: c.surfaceSecondary,
        text: c.textSecondary,
        textActive: c.textPrimary,
        icon: c.textSecondary,
        iconActive: c.brandPrimary,
        border: c.borderPrimary,
        indicator: c.brandPrimary,
        badgeBackground: c.stateErrorBg,
        badgeText: Colors.white,
      ),
    };
  }
}
