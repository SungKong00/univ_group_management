import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Slider 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class SliderColors {
  /// 트랙 배경 색상 (비활성 영역)
  final Color trackBackground;

  /// 트랙 활성 색상 (활성 영역)
  final Color trackActive;

  /// 트랙 비활성화 색상
  final Color trackDisabled;

  /// 썸(노브) 색상
  final Color thumb;

  /// 썸 호버 색상
  final Color thumbHover;

  /// 썸 비활성화 색상
  final Color thumbDisabled;

  /// 썸 테두리 색상
  final Color thumbBorder;

  /// 포커스 링 색상
  final Color focusRing;

  /// 마크 색상
  final Color mark;

  /// 마크 활성 색상
  final Color markActive;

  /// 라벨 텍스트 색상
  final Color labelText;

  /// 값 텍스트 색상
  final Color valueText;

  /// 비활성화 텍스트 색상
  final Color disabledText;

  /// 툴팁 배경 색상
  final Color tooltipBackground;

  /// 툴팁 텍스트 색상
  final Color tooltipText;

  const SliderColors({
    required this.trackBackground,
    required this.trackActive,
    required this.trackDisabled,
    required this.thumb,
    required this.thumbHover,
    required this.thumbDisabled,
    required this.thumbBorder,
    required this.focusRing,
    required this.mark,
    required this.markActive,
    required this.labelText,
    required this.valueText,
    required this.disabledText,
    required this.tooltipBackground,
    required this.tooltipText,
  });

  /// 기본 팩토리 메서드
  factory SliderColors.from(AppColorExtension c) {
    return SliderColors(
      trackBackground: c.surfaceTertiary,
      trackActive: c.brandPrimary,
      trackDisabled: c.surfaceSecondary,
      thumb: c.textOnBrand,
      thumbHover: c.textOnBrand,
      thumbDisabled: c.textQuaternary,
      thumbBorder: c.brandPrimary,
      focusRing: c.borderFocus,
      mark: c.borderSecondary,
      markActive: c.brandPrimary,
      labelText: c.textPrimary,
      valueText: c.textSecondary,
      disabledText: c.textQuaternary,
      tooltipBackground: c.surfaceQuaternary,
      tooltipText: c.textPrimary,
    );
  }

  /// 커스텀 활성 색상 팩토리
  factory SliderColors.withActiveColor(AppColorExtension c, Color activeColor) {
    return SliderColors(
      trackBackground: c.surfaceTertiary,
      trackActive: activeColor,
      trackDisabled: c.surfaceSecondary,
      thumb: c.textOnBrand,
      thumbHover: c.textOnBrand,
      thumbDisabled: c.textQuaternary,
      thumbBorder: activeColor,
      focusRing: c.borderFocus,
      mark: c.borderSecondary,
      markActive: activeColor,
      labelText: c.textPrimary,
      valueText: c.textSecondary,
      disabledText: c.textQuaternary,
      tooltipBackground: c.surfaceQuaternary,
      tooltipText: c.textPrimary,
    );
  }
}
