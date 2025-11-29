import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Spinner 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class SpinnerColors {
  /// 기본 색상
  final Color primary;

  /// 보조 색상 (트랙)
  final Color track;

  /// 브랜드 색상
  final Color brand;

  /// 성공 색상
  final Color success;

  /// 경고 색상
  final Color warning;

  /// 에러 색상
  final Color error;

  /// 정보 색상
  final Color info;

  const SpinnerColors({
    required this.primary,
    required this.track,
    required this.brand,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  /// 기본 팩토리 메서드
  factory SpinnerColors.from(AppColorExtension c) {
    return SpinnerColors(
      primary: c.textPrimary,
      track: c.surfaceTertiary,
      brand: c.brandPrimary,
      success: c.stateSuccessText,
      warning: c.stateWarningText,
      error: c.stateErrorText,
      info: c.stateInfoText,
    );
  }
}
