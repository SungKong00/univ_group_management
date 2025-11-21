import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Labels Section 컴포넌트 전용 색상 구조
///
/// Issue 레이블 관리 및 표시
class LabelsSectionColors {
  /// 레이블 배경
  final Color labelBg;

  /// 레이블 텍스트
  final Color labelText;

  /// 레이블 테두리
  final Color labelBorder;

  /// 레이블 호버 배경
  final Color labelBgHover;

  /// 추가 버튼 배경
  final Color addButtonBg;

  /// 추가 버튼 텍스트
  final Color addButtonText;

  /// 추가 버튼 호버
  final Color addButtonHover;

  /// 제거 아이콘
  final Color removeIcon;

  /// 제거 아이콘 호버
  final Color removeIconHover;

  /// 섹션 배경
  final Color sectionBg;

  const LabelsSectionColors({
    required this.labelBg,
    required this.labelText,
    required this.labelBorder,
    required this.labelBgHover,
    required this.addButtonBg,
    required this.addButtonText,
    required this.addButtonHover,
    required this.removeIcon,
    required this.removeIconHover,
    required this.sectionBg,
  });

  /// 기본 레이블 섹션
  factory LabelsSectionColors.default_(AppColorExtension c) {
    return LabelsSectionColors(
      labelBg: c.brandPrimary.withValues(alpha: 0.1),
      labelText: c.brandPrimary,
      labelBorder: c.brandPrimary.withValues(alpha: 0.3),
      labelBgHover: c.brandPrimary.withValues(alpha: 0.2),
      addButtonBg: c.surfaceSecondary,
      addButtonText: c.brandPrimary,
      addButtonHover: c.surfaceTertiary,
      removeIcon: c.textSecondary,
      removeIconHover: c.stateErrorText,
      sectionBg: c.surfaceSecondary,
    );
  }

  /// 다크 배경
  factory LabelsSectionColors.dark(AppColorExtension c) {
    return LabelsSectionColors(
      labelBg: c.brandSecondary.withValues(alpha: 0.15),
      labelText: c.brandSecondary,
      labelBorder: c.brandSecondary.withValues(alpha: 0.4),
      labelBgHover: c.brandSecondary.withValues(alpha: 0.25),
      addButtonBg: c.surfaceTertiary,
      addButtonText: c.brandSecondary,
      addButtonHover: c.surfaceQuaternary,
      removeIcon: c.textSecondary,
      removeIconHover: c.stateErrorText,
      sectionBg: c.surfaceTertiary,
    );
  }

  /// 다채로운 레이블 (여러 색상)
  factory LabelsSectionColors.colorful(AppColorExtension c) {
    return LabelsSectionColors(
      labelBg: c.brandPrimary.withValues(alpha: 0.15),
      labelText: c.brandPrimary,
      labelBorder: c.brandPrimary.withValues(alpha: 0.3),
      labelBgHover: c.brandPrimary.withValues(alpha: 0.25),
      addButtonBg: c.surfaceSecondary,
      addButtonText: c.brandSecondary,
      addButtonHover: c.overlayLight,
      removeIcon: c.textTertiary,
      removeIconHover: c.stateErrorText,
      sectionBg: Colors.transparent,
    );
  }
}