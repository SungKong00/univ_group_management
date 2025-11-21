import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Tab/Segmented Control 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class TabColors {
  /// 비활성 탭 배경
  final Color background;

  /// 활성 탭 배경
  final Color backgroundActive;

  /// 호버 시 배경
  final Color backgroundHover;

  /// 비활성 탭 텍스트
  final Color text;

  /// 활성 탭 텍스트
  final Color textActive;

  /// 탭 인디케이터 (하단 바)
  final Color indicator;

  /// 탭 구분선
  final Color divider;

  const TabColors({
    required this.background,
    required this.backgroundActive,
    required this.backgroundHover,
    required this.text,
    required this.textActive,
    required this.indicator,
    required this.divider,
  });

  /// 기본 Tab 스타일
  factory TabColors.standard(AppColorExtension c) {
    return TabColors(
      background: Colors.transparent,
      backgroundActive: c.surfaceSecondary,
      backgroundHover: c.overlayLight,
      text: c.textSecondary,
      textActive: c.textPrimary,
      indicator: c.brandPrimary,
      divider: c.dividerPrimary,
    );
  }

  /// Segmented Control 스타일
  factory TabColors.segmented(AppColorExtension c) {
    return TabColors(
      background: c.surfacePrimary,
      backgroundActive: c.surfaceSecondary,
      backgroundHover: c.surfaceHover,
      text: c.textTertiary,
      textActive: c.textPrimary,
      indicator: c.brandPrimary,
      divider: c.borderPrimary,
    );
  }

  /// Pill-style Tab 스타일
  factory TabColors.pill(AppColorExtension c) {
    return TabColors(
      background: Colors.transparent,
      backgroundActive: c.brandPrimary,
      backgroundHover: c.overlayLight,
      text: c.textSecondary,
      textActive: c.textOnBrand,
      indicator: Colors.transparent,
      divider: Colors.transparent,
    );
  }
}
