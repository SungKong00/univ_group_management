import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// DatePicker 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class DatePickerColors {
  // === Header ===
  /// 헤더 배경색
  final Color headerBackground;

  /// 헤더 텍스트 색상
  final Color headerText;

  /// 월/년 선택 버튼 색상
  final Color headerButton;

  /// 네비게이션 화살표 색상
  final Color navigationArrow;

  // === Calendar Grid ===
  /// 요일 헤더 텍스트 색상
  final Color weekdayText;

  /// 일반 날짜 텍스트 색상
  final Color dayText;

  /// 비활성화된 날짜 텍스트 색상
  final Color dayTextDisabled;

  /// 오늘 날짜 텍스트 색상
  final Color todayText;

  /// 오늘 날짜 테두리 색상
  final Color todayBorder;

  /// 선택된 날짜 배경색
  final Color selectedBackground;

  /// 선택된 날짜 텍스트 색상
  final Color selectedText;

  /// 호버 배경색
  final Color hoverBackground;

  /// 범위 선택 배경색 (시작~끝 사이)
  final Color rangeBackground;

  /// 범위 선택 끝점 배경색
  final Color rangeEndpointBackground;

  // === Footer ===
  /// 푸터 배경색
  final Color footerBackground;

  /// 푸터 구분선 색상
  final Color footerDivider;

  // === Container ===
  /// 전체 배경색
  final Color background;

  /// 테두리 색상
  final Color border;

  const DatePickerColors({
    required this.headerBackground,
    required this.headerText,
    required this.headerButton,
    required this.navigationArrow,
    required this.weekdayText,
    required this.dayText,
    required this.dayTextDisabled,
    required this.todayText,
    required this.todayBorder,
    required this.selectedBackground,
    required this.selectedText,
    required this.hoverBackground,
    required this.rangeBackground,
    required this.rangeEndpointBackground,
    required this.footerBackground,
    required this.footerDivider,
    required this.background,
    required this.border,
  });

  /// 표준 DatePicker 색상
  factory DatePickerColors.standard(AppColorExtension c) {
    return DatePickerColors(
      headerBackground: c.surfaceSecondary,
      headerText: c.textPrimary,
      headerButton: c.textSecondary,
      navigationArrow: c.textSecondary,
      weekdayText: c.textTertiary,
      dayText: c.textPrimary,
      dayTextDisabled: c.textQuaternary,
      todayText: c.brandText,
      todayBorder: c.brandPrimary,
      selectedBackground: c.brandPrimary,
      selectedText: c.textOnBrand,
      hoverBackground: c.surfaceTertiary,
      rangeBackground: c.brandPrimary.withValues(alpha: 0.15),
      rangeEndpointBackground: c.brandPrimary,
      footerBackground: c.surfaceSecondary,
      footerDivider: c.borderPrimary,
      background: c.surfaceSecondary,
      border: c.borderPrimary,
    );
  }
}
