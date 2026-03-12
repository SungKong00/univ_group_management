import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Switch 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class SwitchColors {
  /// 트랙 배경 색상 (비활성 상태)
  final Color trackBackground;

  /// 트랙 배경 색상 (활성 상태)
  final Color trackBackgroundActive;

  /// 트랙 배경 색상 (호버)
  final Color trackBackgroundHover;

  /// 트랙 배경 색상 (비활성화)
  final Color trackBackgroundDisabled;

  /// 썸(원형 버튼) 색상
  final Color thumb;

  /// 썸 색상 (비활성화)
  final Color thumbDisabled;

  /// 테두리 색상
  final Color border;

  /// 테두리 색상 (활성 상태)
  final Color borderActive;

  /// 테두리 색상 (포커스)
  final Color borderFocus;

  /// 라벨 텍스트 색상
  final Color labelText;

  /// 설명 텍스트 색상
  final Color descriptionText;

  /// 비활성화 텍스트 색상
  final Color disabledText;

  const SwitchColors({
    required this.trackBackground,
    required this.trackBackgroundActive,
    required this.trackBackgroundHover,
    required this.trackBackgroundDisabled,
    required this.thumb,
    required this.thumbDisabled,
    required this.border,
    required this.borderActive,
    required this.borderFocus,
    required this.labelText,
    required this.descriptionText,
    required this.disabledText,
  });

  /// 기본 팩토리 메서드
  factory SwitchColors.from(AppColorExtension c) {
    return SwitchColors(
      trackBackground: c.surfaceTertiary,
      trackBackgroundActive: c.brandPrimary,
      trackBackgroundHover: c.surfaceQuaternary,
      trackBackgroundDisabled: c.surfaceSecondary,
      thumb: c.textPrimary,
      thumbDisabled: c.textQuaternary,
      border: c.borderSecondary,
      borderActive: c.brandPrimary,
      borderFocus: c.borderFocus,
      labelText: c.textPrimary,
      descriptionText: c.textSecondary,
      disabledText: c.textQuaternary,
    );
  }

  /// 커스텀 활성 색상 팩토리
  factory SwitchColors.withActiveColor(AppColorExtension c, Color activeColor) {
    return SwitchColors(
      trackBackground: c.surfaceTertiary,
      trackBackgroundActive: activeColor,
      trackBackgroundHover: c.surfaceQuaternary,
      trackBackgroundDisabled: c.surfaceSecondary,
      thumb: c.textPrimary,
      thumbDisabled: c.textQuaternary,
      border: c.borderSecondary,
      borderActive: activeColor,
      borderFocus: c.borderFocus,
      labelText: c.textPrimary,
      descriptionText: c.textSecondary,
      disabledText: c.textQuaternary,
    );
  }
}
