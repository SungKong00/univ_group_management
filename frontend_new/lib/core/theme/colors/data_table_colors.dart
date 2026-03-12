import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// DataTable 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class DataTableColors {
  /// 테이블 배경 색상
  final Color background;

  /// 헤더 배경 색상
  final Color headerBackground;

  /// 행 배경 색상
  final Color rowBackground;

  /// 행 호버 배경 색상
  final Color rowBackgroundHover;

  /// 행 선택 배경 색상
  final Color rowBackgroundSelected;

  /// 짝수 행 배경 색상 (스트라이프)
  final Color rowBackgroundAlt;

  /// 테두리 색상
  final Color border;

  /// 헤더 텍스트 색상
  final Color headerText;

  /// 셀 텍스트 색상
  final Color cellText;

  /// 보조 텍스트 색상
  final Color cellTextSecondary;

  /// 비활성화 텍스트 색상
  final Color textDisabled;

  /// 정렬 아이콘 색상
  final Color sortIcon;

  /// 정렬 아이콘 활성 색상
  final Color sortIconActive;

  /// 체크박스 색상
  final Color checkbox;

  /// 체크박스 선택 색상
  final Color checkboxSelected;

  /// 빈 상태 아이콘 색상
  final Color emptyIcon;

  /// 빈 상태 텍스트 색상
  final Color emptyText;

  /// 로딩 인디케이터 색상
  final Color loading;

  const DataTableColors({
    required this.background,
    required this.headerBackground,
    required this.rowBackground,
    required this.rowBackgroundHover,
    required this.rowBackgroundSelected,
    required this.rowBackgroundAlt,
    required this.border,
    required this.headerText,
    required this.cellText,
    required this.cellTextSecondary,
    required this.textDisabled,
    required this.sortIcon,
    required this.sortIconActive,
    required this.checkbox,
    required this.checkboxSelected,
    required this.emptyIcon,
    required this.emptyText,
    required this.loading,
  });

  /// 기본 팩토리 메서드
  factory DataTableColors.from(AppColorExtension c) {
    return DataTableColors(
      background: c.surfacePrimary,
      headerBackground: c.surfaceSecondary,
      rowBackground: c.surfacePrimary,
      rowBackgroundHover: c.surfaceSecondary,
      rowBackgroundSelected: c.brandPrimary.withValues(alpha: 0.1),
      rowBackgroundAlt: c.surfaceSecondary.withValues(alpha: 0.5),
      border: c.borderSecondary,
      headerText: c.textSecondary,
      cellText: c.textPrimary,
      cellTextSecondary: c.textSecondary,
      textDisabled: c.textQuaternary,
      sortIcon: c.textTertiary,
      sortIconActive: c.brandPrimary,
      checkbox: c.borderPrimary,
      checkboxSelected: c.brandPrimary,
      emptyIcon: c.textQuaternary,
      emptyText: c.textTertiary,
      loading: c.brandPrimary,
    );
  }
}
