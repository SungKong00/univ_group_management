import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Kanban 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class KanbanColors {
  /// 보드 배경
  final Color boardBackground;

  /// 컬럼 배경
  final Color columnBackground;

  /// 컬럼 헤더 배경
  final Color columnHeaderBackground;

  /// 컬럼 헤더 텍스트
  final Color columnHeaderText;

  /// 카드 배경
  final Color cardBackground;

  /// 카드 호버 배경
  final Color cardBackgroundHover;

  /// 카드 드래그 배경
  final Color cardBackgroundDrag;

  /// 카드 텍스트
  final Color cardText;

  /// 카드 설명 텍스트
  final Color cardDescription;

  /// 카드 테두리
  final Color cardBorder;

  /// 드롭 영역 색상
  final Color dropIndicator;

  /// 카운트 배지 배경
  final Color countBadgeBackground;

  /// 카운트 배지 텍스트
  final Color countBadgeText;

  /// 추가 버튼 배경
  final Color addButtonBackground;

  /// 추가 버튼 텍스트
  final Color addButtonText;

  const KanbanColors({
    required this.boardBackground,
    required this.columnBackground,
    required this.columnHeaderBackground,
    required this.columnHeaderText,
    required this.cardBackground,
    required this.cardBackgroundHover,
    required this.cardBackgroundDrag,
    required this.cardText,
    required this.cardDescription,
    required this.cardBorder,
    required this.dropIndicator,
    required this.countBadgeBackground,
    required this.countBadgeText,
    required this.addButtonBackground,
    required this.addButtonText,
  });

  /// 기본 색상 팩토리
  factory KanbanColors.from(AppColorExtension c) {
    return KanbanColors(
      boardBackground: c.surfacePrimary,
      columnBackground: c.surfaceSecondary,
      columnHeaderBackground: c.surfaceTertiary,
      columnHeaderText: c.textPrimary,
      cardBackground: c.surfacePrimary,
      cardBackgroundHover: c.surfaceSecondary,
      cardBackgroundDrag: c.brandSecondary.withValues(alpha: 0.1),
      cardText: c.textPrimary,
      cardDescription: c.textSecondary,
      cardBorder: c.borderPrimary,
      dropIndicator: c.brandPrimary,
      countBadgeBackground: c.surfaceTertiary,
      countBadgeText: c.textSecondary,
      addButtonBackground: c.surfaceTertiary,
      addButtonText: c.textSecondary,
    );
  }
}
