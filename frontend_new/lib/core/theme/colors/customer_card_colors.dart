import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Customer Card 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class CustomerCardColors {
  /// 카드 배경
  final Color background;

  /// 호버 시 배경
  final Color backgroundHover;

  /// 카드 테두리
  final Color border;

  /// 로고 배경
  final Color logoBg;

  /// 회사명 텍스트
  final Color companyName;

  /// 설명 텍스트
  final Color description;

  /// 메타 정보 (산업군, 규모 등)
  final Color meta;

  const CustomerCardColors({
    required this.background,
    required this.backgroundHover,
    required this.border,
    required this.logoBg,
    required this.companyName,
    required this.description,
    required this.meta,
  });

  /// 기본 Customer Card 스타일
  factory CustomerCardColors.standard(AppColorExtension c) {
    return CustomerCardColors(
      background: c.surfaceSecondary,
      backgroundHover: c.surfaceHover,
      border: c.borderPrimary,
      logoBg: c.surfaceTertiary,
      companyName: c.textPrimary,
      description: c.textSecondary,
      meta: c.textTertiary,
    );
  }

  /// Featured Customer 스타일 (강조)
  factory CustomerCardColors.featured(AppColorExtension c) {
    return CustomerCardColors(
      background: c.surfaceTertiary,
      backgroundHover: c.surfaceQuaternary,
      border: c.brandPrimary,
      logoBg: c.surfaceQuaternary,
      companyName: c.brandPrimary,
      description: c.textPrimary,
      meta: c.textSecondary,
    );
  }
}
