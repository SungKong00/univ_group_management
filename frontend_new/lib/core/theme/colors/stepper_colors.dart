import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// Stepper 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class StepperColors {
  /// 단계 원 배경 색상
  final Color stepBackground;

  /// 단계 텍스트/아이콘 색상
  final Color stepForeground;

  /// 연결선 색상
  final Color connector;

  /// 제목 텍스트 색상
  final Color titleText;

  /// 설명 텍스트 색상
  final Color descriptionText;

  const StepperColors({
    required this.stepBackground,
    required this.stepForeground,
    required this.connector,
    required this.titleText,
    required this.descriptionText,
  });

  /// 상태별 팩토리 메서드
  factory StepperColors.from(AppColorExtension c, AppStepStatus status) {
    return switch (status) {
      AppStepStatus.completed => StepperColors(
        stepBackground: c.stateSuccessBg,
        stepForeground: c.textOnBrand,
        connector: c.stateSuccessBg,
        titleText: c.textPrimary,
        descriptionText: c.textSecondary,
      ),
      AppStepStatus.active => StepperColors(
        stepBackground: c.brandPrimary,
        stepForeground: c.textOnBrand,
        connector: c.borderSecondary,
        titleText: c.textPrimary,
        descriptionText: c.textSecondary,
      ),
      AppStepStatus.pending => StepperColors(
        stepBackground: c.surfaceTertiary,
        stepForeground: c.textTertiary,
        connector: c.borderSecondary,
        titleText: c.textTertiary,
        descriptionText: c.textQuaternary,
      ),
      AppStepStatus.error => StepperColors(
        stepBackground: c.stateErrorBg,
        stepForeground: c.textOnBrand,
        connector: c.stateErrorBg,
        titleText: c.stateErrorText,
        descriptionText: c.textSecondary,
      ),
    };
  }
}
