import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// Collapsible 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class CollapsibleColors {
  /// 배경 색상
  final Color background;

  /// 호버 배경 색상
  final Color backgroundHover;

  /// 헤더 배경 색상
  final Color headerBackground;

  /// 헤더 텍스트 색상
  final Color headerText;

  /// 콘텐츠 배경 색상
  final Color contentBackground;

  /// 테두리 색상
  final Color border;

  /// 아이콘 색상
  final Color icon;

  const CollapsibleColors({
    required this.background,
    required this.backgroundHover,
    required this.headerBackground,
    required this.headerText,
    required this.contentBackground,
    required this.border,
    required this.icon,
  });

  /// 스타일별 팩토리 메서드
  factory CollapsibleColors.from(
    AppColorExtension c,
    AppCollapsibleStyle style,
  ) {
    return switch (style) {
      AppCollapsibleStyle.plain => CollapsibleColors(
          background: Colors.transparent,
          backgroundHover: c.surfaceSecondary,
          headerBackground: Colors.transparent,
          headerText: c.textPrimary,
          contentBackground: Colors.transparent,
          border: Colors.transparent,
          icon: c.textSecondary,
        ),
      AppCollapsibleStyle.bordered => CollapsibleColors(
          background: c.surfacePrimary,
          backgroundHover: c.surfaceSecondary,
          headerBackground: c.surfacePrimary,
          headerText: c.textPrimary,
          contentBackground: c.surfacePrimary,
          border: c.borderPrimary,
          icon: c.textSecondary,
        ),
      AppCollapsibleStyle.card => CollapsibleColors(
          background: c.surfaceSecondary,
          backgroundHover: c.surfaceTertiary,
          headerBackground: c.surfaceSecondary,
          headerText: c.textPrimary,
          contentBackground: c.surfacePrimary,
          border: c.borderPrimary,
          icon: c.textSecondary,
        ),
    };
  }
}
