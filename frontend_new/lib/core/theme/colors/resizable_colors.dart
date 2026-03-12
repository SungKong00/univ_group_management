import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Resizable 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class ResizableColors {
  /// 핸들 배경 색상
  final Color handleBackground;

  /// 핸들 호버 배경
  final Color handleBackgroundHover;

  /// 핸들 드래그 배경
  final Color handleBackgroundDrag;

  /// 핸들 그립 색상
  final Color handleGrip;

  /// 핸들 그립 호버 색상
  final Color handleGripHover;

  /// 테두리 색상
  final Color border;

  /// 가이드라인 색상 (리사이즈 시)
  final Color guideline;

  const ResizableColors({
    required this.handleBackground,
    required this.handleBackgroundHover,
    required this.handleBackgroundDrag,
    required this.handleGrip,
    required this.handleGripHover,
    required this.border,
    required this.guideline,
  });

  /// 기본 색상 팩토리
  factory ResizableColors.from(AppColorExtension c) {
    return ResizableColors(
      handleBackground: c.surfaceSecondary,
      handleBackgroundHover: c.surfaceTertiary,
      handleBackgroundDrag: c.brandSecondary,
      handleGrip: c.borderSecondary,
      handleGripHover: c.textSecondary,
      border: c.borderPrimary,
      guideline: c.brandPrimary,
    );
  }
}
