import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Chart 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class ChartColors {
  /// 배경 색상
  final Color background;

  /// 그리드 라인 색상
  final Color gridLine;

  /// 축 라인 색상
  final Color axisLine;

  /// 축 레이블 색상
  final Color axisLabel;

  /// 툴팁 배경
  final Color tooltipBackground;

  /// 툴팁 텍스트
  final Color tooltipText;

  /// 범례 텍스트
  final Color legendText;

  /// 데이터 시리즈 색상들 (최대 6개)
  final List<Color> seriesColors;

  const ChartColors({
    required this.background,
    required this.gridLine,
    required this.axisLine,
    required this.axisLabel,
    required this.tooltipBackground,
    required this.tooltipText,
    required this.legendText,
    required this.seriesColors,
  });

  /// 기본 색상 팩토리
  factory ChartColors.from(AppColorExtension c) {
    return ChartColors(
      background: c.surfacePrimary,
      gridLine: c.borderPrimary,
      axisLine: c.borderSecondary,
      axisLabel: c.textTertiary,
      tooltipBackground: c.surfaceQuaternary,
      tooltipText: c.textPrimary,
      legendText: c.textSecondary,
      seriesColors: [
        c.brandPrimary,
        c.stateInfoBg,
        c.stateSuccessBg,
        c.stateWarningBg,
        c.stateErrorBg,
        c.brandSecondary,
      ],
    );
  }
}
