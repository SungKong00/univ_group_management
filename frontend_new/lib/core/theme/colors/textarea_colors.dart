import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Textarea 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class TextareaColors {
  /// 배경 색상
  final Color background;

  /// 호버 시 배경
  final Color backgroundHover;

  /// 포커스 시 배경
  final Color backgroundFocus;

  /// 비활성화 배경
  final Color backgroundDisabled;

  /// 텍스트 색상
  final Color text;

  /// 플레이스홀더 색상
  final Color placeholder;

  /// 테두리 색상
  final Color border;

  /// 호버 시 테두리
  final Color borderHover;

  /// 포커스 시 테두리
  final Color borderFocus;

  /// 에러 테두리
  final Color borderError;

  /// 헬퍼 텍스트 색상
  final Color helperText;

  /// 에러 텍스트 색상
  final Color errorText;

  /// 글자 수 텍스트 색상
  final Color characterCountText;

  /// 라벨 텍스트 색상
  final Color labelText;

  const TextareaColors({
    required this.background,
    required this.backgroundHover,
    required this.backgroundFocus,
    required this.backgroundDisabled,
    required this.text,
    required this.placeholder,
    required this.border,
    required this.borderHover,
    required this.borderFocus,
    required this.borderError,
    required this.helperText,
    required this.errorText,
    required this.characterCountText,
    required this.labelText,
  });

  /// 기본 색상 팩토리
  factory TextareaColors.from(AppColorExtension c) {
    return TextareaColors(
      background: c.surfacePrimary,
      backgroundHover: c.surfaceSecondary,
      backgroundFocus: c.surfaceSecondary,
      backgroundDisabled: c.surfaceTertiary,
      text: c.textPrimary,
      placeholder: c.textTertiary,
      border: c.borderPrimary,
      borderHover: c.borderSecondary,
      borderFocus: c.borderFocus,
      borderError: c.stateErrorBg,
      helperText: c.textTertiary,
      errorText: c.stateErrorText,
      characterCountText: c.textQuaternary,
      labelText: c.textSecondary,
    );
  }
}
