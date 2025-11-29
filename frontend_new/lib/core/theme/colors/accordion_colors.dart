import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// Accordion 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class AccordionColors {
  /// 헤더 배경 색상
  final Color headerBackground;

  /// 헤더 호버 배경
  final Color headerBackgroundHover;

  /// 콘텐츠 배경 색상
  final Color contentBackground;

  /// 헤더 텍스트 색상
  final Color headerText;

  /// 콘텐츠 텍스트 색상
  final Color contentText;

  /// 아이콘 색상
  final Color icon;

  /// 테두리 색상
  final Color border;

  /// 구분선 색상
  final Color divider;

  const AccordionColors({
    required this.headerBackground,
    required this.headerBackgroundHover,
    required this.contentBackground,
    required this.headerText,
    required this.contentText,
    required this.icon,
    required this.border,
    required this.divider,
  });

  /// 스타일별 팩토리 메서드
  factory AccordionColors.from(AppColorExtension c, AppAccordionStyle style) {
    return switch (style) {
      AppAccordionStyle.bordered => AccordionColors(
        headerBackground: c.surfaceSecondary,
        headerBackgroundHover: c.surfaceTertiary,
        contentBackground: c.surfaceSecondary,
        headerText: c.textPrimary,
        contentText: c.textSecondary,
        icon: c.textSecondary,
        border: c.borderSecondary,
        divider: c.dividerPrimary,
      ),
      AppAccordionStyle.separated => AccordionColors(
        headerBackground: Colors.transparent,
        headerBackgroundHover: c.surfaceTertiary,
        contentBackground: Colors.transparent,
        headerText: c.textPrimary,
        contentText: c.textSecondary,
        icon: c.textSecondary,
        border: Colors.transparent,
        divider: c.dividerPrimary,
      ),
      AppAccordionStyle.plain => AccordionColors(
        headerBackground: Colors.transparent,
        headerBackgroundHover: c.surfaceTertiary,
        contentBackground: Colors.transparent,
        headerText: c.textPrimary,
        contentText: c.textSecondary,
        icon: c.textSecondary,
        border: Colors.transparent,
        divider: Colors.transparent,
      ),
    };
  }
}
