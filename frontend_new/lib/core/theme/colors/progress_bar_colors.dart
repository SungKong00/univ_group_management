import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// ProgressBar 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class ProgressBarColors {
  /// 트랙 배경 색상
  final Color trackBackground;

  /// 진행 바 색상
  final Color progressFill;

  /// 텍스트 색상
  final Color text;

  const ProgressBarColors({
    required this.trackBackground,
    required this.progressFill,
    required this.text,
  });

  /// 색상별 팩토리 메서드
  factory ProgressBarColors.from(
    AppColorExtension c,
    AppProgressBarColor color,
  ) {
    final trackBackground = c.surfaceTertiary;
    final text = c.textSecondary;

    return switch (color) {
      AppProgressBarColor.brand => ProgressBarColors(
        trackBackground: trackBackground,
        progressFill: c.brandPrimary,
        text: text,
      ),
      AppProgressBarColor.success => ProgressBarColors(
        trackBackground: trackBackground,
        progressFill: c.stateSuccessBg,
        text: text,
      ),
      AppProgressBarColor.warning => ProgressBarColors(
        trackBackground: trackBackground,
        progressFill: c.stateWarningBg,
        text: text,
      ),
      AppProgressBarColor.error => ProgressBarColors(
        trackBackground: trackBackground,
        progressFill: c.stateErrorBg,
        text: text,
      ),
      AppProgressBarColor.info => ProgressBarColors(
        trackBackground: trackBackground,
        progressFill: c.stateInfoBg,
        text: text,
      ),
    };
  }
}
