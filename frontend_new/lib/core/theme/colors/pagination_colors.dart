import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// Pagination 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class PaginationColors {
  /// 기본 배경 색상
  final Color background;

  /// 활성 페이지 배경
  final Color backgroundActive;

  /// 호버 시 배경
  final Color backgroundHover;

  /// 비활성 배경
  final Color backgroundDisabled;

  /// 기본 텍스트 색상
  final Color text;

  /// 활성 페이지 텍스트
  final Color textActive;

  /// 비활성 텍스트
  final Color textDisabled;

  /// 테두리 색상
  final Color border;

  /// 활성 테두리
  final Color borderActive;

  const PaginationColors({
    required this.background,
    required this.backgroundActive,
    required this.backgroundHover,
    required this.backgroundDisabled,
    required this.text,
    required this.textActive,
    required this.textDisabled,
    required this.border,
    required this.borderActive,
  });

  /// 스타일별 팩토리 메서드
  ///
  /// 모든 페이지네이션 스타일(numbered, simple, compact)이 동일한 색상을 사용합니다.
  /// 스타일의 차이는 UI 레이아웃으로만 표현됩니다 (AppPagination 참조).
  factory PaginationColors.from(AppColorExtension c, AppPaginationStyle style) {
    return PaginationColors(
      background: Colors.transparent,
      backgroundActive: c.brandPrimary,
      backgroundHover: c.surfaceTertiary,
      backgroundDisabled: c.surfaceSecondary,
      text: c.textSecondary,
      textActive: c.textOnBrand,
      textDisabled: c.textQuaternary,
      border: c.borderSecondary,
      borderActive: c.brandPrimary,
    );
  }

  /// 기본 페이지네이션 색상 (하위 호환성)
  @Deprecated('Use PaginationColors.from() instead')
  factory PaginationColors.standard(AppColorExtension c) {
    return PaginationColors.from(c, AppPaginationStyle.numbered);
  }
}
