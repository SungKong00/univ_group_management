import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// Breadcrumb 컴포넌트 전용 색상 구조
///
/// 페이지 경로 표시 (Issues > Project-001 > Details)
class BreadcrumbColors {
  /// 기본 텍스트 색상
  final Color text;

  /// 호버 시 텍스트
  final Color textHover;

  /// 현재 페이지 텍스트
  final Color textActive;

  /// 구분자 색상 (/)
  final Color separator;

  /// 배경 색상
  final Color background;

  /// 호버 시 배경
  final Color backgroundHover;

  /// 아이콘 색상
  final Color icon;

  const BreadcrumbColors({
    required this.text,
    required this.textHover,
    required this.textActive,
    required this.separator,
    required this.background,
    required this.backgroundHover,
    required this.icon,
  });

  /// Style별 팩토리 메서드
  factory BreadcrumbColors.from(AppColorExtension c, BreadcrumbStyle style) {
    return switch (style) {
      BreadcrumbStyle.default_ => BreadcrumbColors(
        text: c.textSecondary,
        textHover: c.brandPrimary,
        textActive: c.textPrimary,
        separator: c.textTertiary,
        background: Colors.transparent,
        backgroundHover: c.overlayLight,
        icon: c.textSecondary,
      ),
      BreadcrumbStyle.dark => BreadcrumbColors(
        text: c.textSecondary,
        textHover: c.brandSecondary,
        textActive: c.textPrimary,
        separator: c.textQuaternary,
        background: Colors.transparent,
        backgroundHover: c.overlayMedium,
        icon: c.textSecondary,
      ),
      BreadcrumbStyle.compact => BreadcrumbColors(
        text: c.textTertiary,
        textHover: c.brandSecondary,
        textActive: c.textSecondary,
        separator: c.borderTertiary,
        background: Colors.transparent,
        backgroundHover: c.overlayLight,
        icon: c.textTertiary,
      ),
    };
  }

  /// 기본 스타일 (하위 호환성)
  @Deprecated('Use BreadcrumbColors.from() instead')
  factory BreadcrumbColors.default_(AppColorExtension c) {
    return BreadcrumbColors.from(c, BreadcrumbStyle.default_);
  }

  /// 다크 스타일 (하위 호환성)
  @Deprecated('Use BreadcrumbColors.from() instead')
  factory BreadcrumbColors.dark(AppColorExtension c) {
    return BreadcrumbColors.from(c, BreadcrumbStyle.dark);
  }

  /// 콤팩트 스타일 (하위 호환성)
  @Deprecated('Use BreadcrumbColors.from() instead')
  factory BreadcrumbColors.compact(AppColorExtension c) {
    return BreadcrumbColors.from(c, BreadcrumbStyle.compact);
  }
}
