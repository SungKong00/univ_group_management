import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// RadioGroup 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class RadioGroupColors {
  /// 라디오 버튼 테두리 색상 (기본)
  final Color border;

  /// 라디오 버튼 테두리 색상 (호버)
  final Color borderHover;

  /// 라디오 버튼 테두리 색상 (선택됨)
  final Color borderSelected;

  /// 라디오 버튼 테두리 색상 (포커스)
  final Color borderFocus;

  /// 라디오 버튼 테두리 색상 (비활성화)
  final Color borderDisabled;

  /// 라디오 버튼 배경 색상 (기본)
  final Color background;

  /// 라디오 버튼 배경 색상 (호버)
  final Color backgroundHover;

  /// 라디오 버튼 배경 색상 (비활성화)
  final Color backgroundDisabled;

  /// 라디오 버튼 내부 원 색상 (선택됨)
  final Color indicator;

  /// 라디오 버튼 내부 원 색상 (비활성화)
  final Color indicatorDisabled;

  /// 라벨 텍스트 색상
  final Color labelText;

  /// 설명 텍스트 색상
  final Color descriptionText;

  /// 비활성화 텍스트 색상
  final Color disabledText;

  /// 에러 텍스트 색상
  final Color errorText;

  /// 그룹 라벨 텍스트 색상
  final Color groupLabelText;

  const RadioGroupColors({
    required this.border,
    required this.borderHover,
    required this.borderSelected,
    required this.borderFocus,
    required this.borderDisabled,
    required this.background,
    required this.backgroundHover,
    required this.backgroundDisabled,
    required this.indicator,
    required this.indicatorDisabled,
    required this.labelText,
    required this.descriptionText,
    required this.disabledText,
    required this.errorText,
    required this.groupLabelText,
  });

  /// 기본 팩토리 메서드
  factory RadioGroupColors.from(AppColorExtension c) {
    return RadioGroupColors(
      border: c.borderSecondary,
      borderHover: c.borderPrimary,
      borderSelected: c.brandPrimary,
      borderFocus: c.borderFocus,
      borderDisabled: c.borderTertiary,
      background: Colors.transparent,
      backgroundHover: c.surfaceSecondary,
      backgroundDisabled: c.surfaceSecondary,
      indicator: c.brandPrimary,
      indicatorDisabled: c.textQuaternary,
      labelText: c.textPrimary,
      descriptionText: c.textSecondary,
      disabledText: c.textQuaternary,
      errorText: c.stateErrorText,
      groupLabelText: c.textPrimary,
    );
  }

  /// 커스텀 선택 색상 팩토리
  factory RadioGroupColors.withSelectedColor(
    AppColorExtension c,
    Color selectedColor,
  ) {
    return RadioGroupColors(
      border: c.borderSecondary,
      borderHover: c.borderPrimary,
      borderSelected: selectedColor,
      borderFocus: c.borderFocus,
      borderDisabled: c.borderTertiary,
      background: Colors.transparent,
      backgroundHover: c.surfaceSecondary,
      backgroundDisabled: c.surfaceSecondary,
      indicator: selectedColor,
      indicatorDisabled: c.textQuaternary,
      labelText: c.textPrimary,
      descriptionText: c.textSecondary,
      disabledText: c.textQuaternary,
      errorText: c.stateErrorText,
      groupLabelText: c.textPrimary,
    );
  }
}
