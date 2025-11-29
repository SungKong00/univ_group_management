import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Drawer 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class DrawerColors {
  /// 배경 색상
  final Color background;

  /// 헤더 배경 색상
  final Color headerBackground;

  /// 텍스트 색상
  final Color text;

  /// 보조 텍스트 색상
  final Color textSecondary;

  /// 테두리 색상
  final Color border;

  /// 오버레이 색상
  final Color overlay;

  /// 아이템 호버 색상
  final Color itemHover;

  /// 아이템 활성 색상
  final Color itemActive;

  /// 아이콘 색상
  final Color icon;

  /// 활성 아이콘 색상
  final Color iconActive;

  const DrawerColors({
    required this.background,
    required this.headerBackground,
    required this.text,
    required this.textSecondary,
    required this.border,
    required this.overlay,
    required this.itemHover,
    required this.itemActive,
    required this.icon,
    required this.iconActive,
  });

  /// 팩토리 메서드
  factory DrawerColors.from(AppColorExtension c) {
    return DrawerColors(
      background: c.surfaceSecondary,
      headerBackground: c.surfaceTertiary,
      text: c.textPrimary,
      textSecondary: c.textSecondary,
      border: c.borderPrimary,
      overlay: c.overlayScrim,
      itemHover: c.surfaceTertiary,
      itemActive: c.brandPrimary.withValues(alpha: 0.15),
      icon: c.textSecondary,
      iconActive: c.brandPrimary,
    );
  }
}
