import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Calendar 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class CalendarColors {
  /// 배경 색상
  final Color background;

  /// 헤더 배경 색상
  final Color headerBackground;

  /// 헤더 텍스트 색상
  final Color headerText;

  /// 요일 텍스트 색상
  final Color weekdayText;

  /// 일반 날짜 색상
  final Color dayText;

  /// 오늘 날짜 배경
  final Color todayBackground;

  /// 오늘 날짜 텍스트
  final Color todayText;

  /// 선택된 날짜 배경
  final Color selectedBackground;

  /// 선택된 날짜 텍스트
  final Color selectedText;

  /// 범위 배경
  final Color rangeBackground;

  /// 비활성 날짜 색상
  final Color disabledText;

  /// 테두리 색상
  final Color border;

  /// 호버 배경
  final Color hoverBackground;

  /// 이벤트 도트 색상
  final Color eventDot;

  const CalendarColors({
    required this.background,
    required this.headerBackground,
    required this.headerText,
    required this.weekdayText,
    required this.dayText,
    required this.todayBackground,
    required this.todayText,
    required this.selectedBackground,
    required this.selectedText,
    required this.rangeBackground,
    required this.disabledText,
    required this.border,
    required this.hoverBackground,
    required this.eventDot,
  });

  /// 기본 색상 팩토리
  factory CalendarColors.from(AppColorExtension c) {
    return CalendarColors(
      background: c.surfacePrimary,
      headerBackground: c.surfaceSecondary,
      headerText: c.textPrimary,
      weekdayText: c.textSecondary,
      dayText: c.textPrimary,
      todayBackground: c.brandSecondary,
      todayText: c.brandPrimary,
      selectedBackground: c.brandPrimary,
      selectedText: c.textOnBrand,
      rangeBackground: c.brandSecondary,
      disabledText: c.textQuaternary,
      border: c.borderPrimary,
      hoverBackground: c.surfaceTertiary,
      eventDot: c.brandPrimary,
    );
  }
}
