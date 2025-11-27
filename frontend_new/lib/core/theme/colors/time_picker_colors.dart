import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// TimePicker 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class TimePickerColors {
  // === Header ===
  /// 헤더 배경색
  final Color headerBackground;

  /// 헤더 텍스트 색상
  final Color headerText;

  // === Time Display ===
  /// 시간 표시 배경색
  final Color displayBackground;

  /// 시간 표시 텍스트 색상
  final Color displayText;

  /// 선택된 시간 표시 배경색
  final Color displaySelectedBackground;

  /// 선택된 시간 표시 텍스트 색상
  final Color displaySelectedText;

  /// 구분자 (콜론) 색상
  final Color separator;

  // === Spinner/Wheel ===
  /// 스피너 배경색
  final Color spinnerBackground;

  /// 스피너 텍스트 색상
  final Color spinnerText;

  /// 스피너 선택 영역 배경색
  final Color spinnerSelectedBackground;

  /// 스피너 선택 영역 텍스트 색상
  final Color spinnerSelectedText;

  /// 스피너 구분선 색상
  final Color spinnerDivider;

  // === AM/PM Toggle ===
  /// AM/PM 토글 배경색
  final Color periodBackground;

  /// AM/PM 토글 텍스트 색상
  final Color periodText;

  /// 선택된 AM/PM 배경색
  final Color periodSelectedBackground;

  /// 선택된 AM/PM 텍스트 색상
  final Color periodSelectedText;

  // === Container ===
  /// 전체 배경색
  final Color background;

  /// 테두리 색상
  final Color border;

  const TimePickerColors({
    required this.headerBackground,
    required this.headerText,
    required this.displayBackground,
    required this.displayText,
    required this.displaySelectedBackground,
    required this.displaySelectedText,
    required this.separator,
    required this.spinnerBackground,
    required this.spinnerText,
    required this.spinnerSelectedBackground,
    required this.spinnerSelectedText,
    required this.spinnerDivider,
    required this.periodBackground,
    required this.periodText,
    required this.periodSelectedBackground,
    required this.periodSelectedText,
    required this.background,
    required this.border,
  });

  /// 표준 TimePicker 색상
  factory TimePickerColors.standard(AppColorExtension c) {
    return TimePickerColors(
      headerBackground: c.surfaceSecondary,
      headerText: c.textPrimary,
      displayBackground: c.surfaceTertiary,
      displayText: c.textSecondary,
      displaySelectedBackground: c.brandPrimary.withValues(alpha: 0.15),
      displaySelectedText: c.brandText,
      separator: c.textTertiary,
      spinnerBackground: c.surfaceSecondary,
      spinnerText: c.textSecondary,
      spinnerSelectedBackground: c.surfaceTertiary,
      spinnerSelectedText: c.textPrimary,
      spinnerDivider: c.borderPrimary,
      periodBackground: c.surfaceTertiary,
      periodText: c.textSecondary,
      periodSelectedBackground: c.brandPrimary,
      periodSelectedText: c.textOnBrand,
      background: c.surfaceSecondary,
      border: c.borderPrimary,
    );
  }
}
