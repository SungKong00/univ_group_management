import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// Navigation Sidebar 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
/// 기존 SidebarColors는 Properties sidebar용으로 유지됩니다.
class NavSidebarColors {
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

  /// 아이템 호버 색상
  final Color itemHover;

  /// 아이템 활성 색상
  final Color itemActive;

  /// 아이콘 색상
  final Color icon;

  /// 활성 아이콘 색상
  final Color iconActive;

  /// 구분선 색상
  final Color divider;

  /// 토글 버튼 색상
  final Color toggle;

  const NavSidebarColors({
    required this.background,
    required this.headerBackground,
    required this.text,
    required this.textSecondary,
    required this.border,
    required this.itemHover,
    required this.itemActive,
    required this.icon,
    required this.iconActive,
    required this.divider,
    required this.toggle,
  });

  /// Style별 팩토리 메서드
  ///
  /// 모든 스타일(standard, compact, expandable)이 동일한 색상을 사용합니다.
  /// 스타일의 차이는 너비와 레이아웃으로만 표현됩니다 (AppSidebar 참조).
  factory NavSidebarColors.from(AppColorExtension c, AppSidebarStyle style) {
    return NavSidebarColors(
      background: c.surfaceSecondary,
      headerBackground: c.surfaceTertiary,
      text: c.textPrimary,
      textSecondary: c.textSecondary,
      border: c.borderPrimary,
      itemHover: c.surfaceTertiary,
      itemActive: c.brandPrimary.withValues(alpha: 0.15),
      icon: c.textSecondary,
      iconActive: c.brandPrimary,
      divider: c.borderPrimary,
      toggle: c.textSecondary,
    );
  }
}
