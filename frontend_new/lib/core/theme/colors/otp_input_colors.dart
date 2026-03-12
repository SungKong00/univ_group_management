import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// OtpInput 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class OtpInputColors {
  /// 셀 배경 색상
  final Color background;

  /// 셀 배경 색상 (포커스)
  final Color backgroundFocused;

  /// 셀 배경 색상 (채워짐)
  final Color backgroundFilled;

  /// 셀 배경 색상 (비활성화)
  final Color backgroundDisabled;

  /// 셀 테두리 색상
  final Color border;

  /// 셀 테두리 색상 (포커스)
  final Color borderFocused;

  /// 셀 테두리 색상 (채워짐)
  final Color borderFilled;

  /// 셀 테두리 색상 (에러)
  final Color borderError;

  /// 셀 테두리 색상 (성공)
  final Color borderSuccess;

  /// 텍스트 색상
  final Color text;

  /// 텍스트 색상 (비활성화)
  final Color textDisabled;

  /// 커서 색상
  final Color cursor;

  /// 라벨 텍스트 색상
  final Color labelText;

  /// 에러 텍스트 색상
  final Color errorText;

  /// 성공 텍스트 색상
  final Color successText;

  const OtpInputColors({
    required this.background,
    required this.backgroundFocused,
    required this.backgroundFilled,
    required this.backgroundDisabled,
    required this.border,
    required this.borderFocused,
    required this.borderFilled,
    required this.borderError,
    required this.borderSuccess,
    required this.text,
    required this.textDisabled,
    required this.cursor,
    required this.labelText,
    required this.errorText,
    required this.successText,
  });

  /// 기본 팩토리 메서드
  factory OtpInputColors.from(AppColorExtension c) {
    return OtpInputColors(
      background: c.surfaceSecondary,
      backgroundFocused: c.surfacePrimary,
      backgroundFilled: c.surfaceTertiary,
      backgroundDisabled: c.surfaceSecondary,
      border: c.borderSecondary,
      borderFocused: c.borderFocus,
      borderFilled: c.borderPrimary,
      borderError: c.stateErrorText,
      borderSuccess: c.stateSuccessText,
      text: c.textPrimary,
      textDisabled: c.textQuaternary,
      cursor: c.brandPrimary,
      labelText: c.textPrimary,
      errorText: c.stateErrorText,
      successText: c.stateSuccessText,
    );
  }
}
