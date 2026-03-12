import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// Navbar 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class NavbarColors {
  /// 배경 색상
  final Color background;

  /// 텍스트 색상
  final Color text;

  /// 텍스트 호버 색상
  final Color textHover;

  /// 텍스트 활성 색상
  final Color textActive;

  /// 아이콘 색상
  final Color icon;

  /// 테두리 색상
  final Color border;

  /// 그림자 색상
  final Color shadow;

  const NavbarColors({
    required this.background,
    required this.text,
    required this.textHover,
    required this.textActive,
    required this.icon,
    required this.border,
    required this.shadow,
  });

  /// Style별 팩토리 메서드
  factory NavbarColors.from(AppColorExtension c, AppNavbarStyle style) {
    return switch (style) {
      AppNavbarStyle.standard => NavbarColors(
        background: c.surfaceSecondary,
        text: c.textSecondary,
        textHover: c.textPrimary,
        textActive: c.brandPrimary,
        icon: c.textSecondary,
        border: c.borderPrimary,
        shadow: Colors.black.withValues(alpha: 0.1),
      ),
      AppNavbarStyle.transparent => NavbarColors(
        background: Colors.transparent,
        text: c.textSecondary,
        textHover: c.textPrimary,
        textActive: c.brandPrimary,
        icon: c.textSecondary,
        border: Colors.transparent,
        shadow: Colors.transparent,
      ),
      AppNavbarStyle.sticky => NavbarColors(
        background: c.surfaceSecondary.withValues(alpha: 0.95),
        text: c.textSecondary,
        textHover: c.textPrimary,
        textActive: c.brandPrimary,
        icon: c.textSecondary,
        border: c.borderPrimary,
        shadow: Colors.black.withValues(alpha: 0.15),
      ),
    };
  }
}
