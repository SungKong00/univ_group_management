import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// CheckboxGroup 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class CheckboxGroupColors {
  /// 체크박스 테두리 색상 (기본)
  final Color border;

  /// 체크박스 테두리 색상 (호버)
  final Color borderHover;

  /// 체크박스 테두리 색상 (선택됨)
  final Color borderChecked;

  /// 체크박스 테두리 색상 (포커스)
  final Color borderFocus;

  /// 체크박스 테두리 색상 (비활성화)
  final Color borderDisabled;

  /// 체크박스 배경 색상 (기본)
  final Color background;

  /// 체크박스 배경 색상 (호버)
  final Color backgroundHover;

  /// 체크박스 배경 색상 (선택됨)
  final Color backgroundChecked;

  /// 체크박스 배경 색상 (비활성화)
  final Color backgroundDisabled;

  /// 체크 아이콘 색상
  final Color checkIcon;

  /// 체크 아이콘 색상 (비활성화)
  final Color checkIconDisabled;

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

  const CheckboxGroupColors({
    required this.border,
    required this.borderHover,
    required this.borderChecked,
    required this.borderFocus,
    required this.borderDisabled,
    required this.background,
    required this.backgroundHover,
    required this.backgroundChecked,
    required this.backgroundDisabled,
    required this.checkIcon,
    required this.checkIconDisabled,
    required this.labelText,
    required this.descriptionText,
    required this.disabledText,
    required this.errorText,
    required this.groupLabelText,
  });

  /// 기본 팩토리 메서드
  factory CheckboxGroupColors.from(AppColorExtension c) {
    return CheckboxGroupColors(
      border: c.borderSecondary,
      borderHover: c.borderPrimary,
      borderChecked: c.brandPrimary,
      borderFocus: c.borderFocus,
      borderDisabled: c.borderTertiary,
      background: Colors.transparent,
      backgroundHover: c.surfaceSecondary,
      backgroundChecked: c.brandPrimary,
      backgroundDisabled: c.surfaceSecondary,
      checkIcon: c.textOnBrand,
      checkIconDisabled: c.textQuaternary,
      labelText: c.textPrimary,
      descriptionText: c.textSecondary,
      disabledText: c.textQuaternary,
      errorText: c.stateErrorText,
      groupLabelText: c.textPrimary,
    );
  }

  /// 커스텀 선택 색상 팩토리
  factory CheckboxGroupColors.withCheckedColor(
    AppColorExtension c,
    Color checkedColor,
  ) {
    return CheckboxGroupColors(
      border: c.borderSecondary,
      borderHover: c.borderPrimary,
      borderChecked: checkedColor,
      borderFocus: c.borderFocus,
      borderDisabled: c.borderTertiary,
      background: Colors.transparent,
      backgroundHover: c.surfaceSecondary,
      backgroundChecked: checkedColor,
      backgroundDisabled: c.surfaceSecondary,
      checkIcon: c.textOnBrand,
      checkIconDisabled: c.textQuaternary,
      labelText: c.textPrimary,
      descriptionText: c.textSecondary,
      disabledText: c.textQuaternary,
      errorText: c.stateErrorText,
      groupLabelText: c.textPrimary,
    );
  }
}
