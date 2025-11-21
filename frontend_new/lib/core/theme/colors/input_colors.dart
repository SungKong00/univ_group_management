import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Input/TextField 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class InputColors {
  /// 입력 필드 배경
  final Color background;

  /// 포커스 시 배경
  final Color backgroundFocused;

  /// 비활성 시 배경
  final Color backgroundDisabled;

  /// 에러 시 배경
  final Color backgroundError;

  /// 테두리
  final Color border;

  /// 포커스 시 테두리
  final Color borderFocused;

  /// 에러 시 테두리
  final Color borderError;

  /// 입력 텍스트
  final Color text;

  /// placeholder 텍스트
  final Color placeholder;

  /// 레이블 텍스트
  final Color label;

  /// Helper 텍스트
  final Color helper;

  /// 에러 메시지 텍스트
  final Color errorText;

  const InputColors({
    required this.background,
    required this.backgroundFocused,
    required this.backgroundDisabled,
    required this.backgroundError,
    required this.border,
    required this.borderFocused,
    required this.borderError,
    required this.text,
    required this.placeholder,
    required this.label,
    required this.helper,
    required this.errorText,
  });

  /// 기본 Input 스타일
  factory InputColors.standard(AppColorExtension c) {
    return InputColors(
      background: c.surfaceSecondary,
      backgroundFocused: c.surfaceTertiary,
      backgroundDisabled: c.surfacePrimary,
      backgroundError: c.stateErrorBg.withValues(alpha: 0.1),
      border: c.borderPrimary,
      borderFocused: c.borderFocus,
      borderError: c.stateErrorBg,
      text: c.textPrimary,
      placeholder: c.textTertiary,
      label: c.textSecondary,
      helper: c.textTertiary,
      errorText: c.stateErrorText,
    );
  }

  /// 검색 Input 스타일
  factory InputColors.search(AppColorExtension c) {
    return InputColors(
      background: c.surfaceSecondary,
      backgroundFocused: c.surfaceTertiary,
      backgroundDisabled: c.surfacePrimary,
      backgroundError: c.stateErrorBg.withValues(alpha: 0.1),
      border: c.borderTertiary,
      borderFocused: c.borderSecondary,
      borderError: c.stateErrorBg,
      text: c.textPrimary,
      placeholder: c.textQuaternary,
      label: c.textSecondary,
      helper: c.textTertiary,
      errorText: c.stateErrorText,
    );
  }
}
