import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Card 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class CardColors {
  /// 카드 배경
  final Color background;

  /// 호버 시 배경
  final Color backgroundHover;

  /// 카드 테두리
  final Color border;

  /// 제목 텍스트
  final Color title;

  /// 본문 텍스트
  final Color body;

  /// 메타 정보 텍스트 (날짜, 태그 등)
  final Color meta;

  /// 구분선
  final Color divider;

  const CardColors({
    required this.background,
    required this.backgroundHover,
    required this.border,
    required this.title,
    required this.body,
    required this.meta,
    required this.divider,
  });

  /// 기본 카드 스타일
  factory CardColors.standard(AppColorExtension c) {
    return CardColors(
      background: c.surfaceSecondary,
      backgroundHover: c.surfaceHover,
      border: c.borderPrimary,
      title: c.textPrimary,
      body: c.textSecondary,
      meta: c.textTertiary,
      divider: c.dividerPrimary,
    );
  }

  /// 중첩 카드 스타일 (카드 안의 카드)
  factory CardColors.nested(AppColorExtension c) {
    return CardColors(
      background: c.surfaceTertiary,
      backgroundHover: c.surfaceQuaternary,
      border: c.borderSecondary,
      title: c.textPrimary,
      body: c.textSecondary,
      meta: c.textTertiary,
      divider: c.dividerSecondary,
    );
  }

  /// 강조 카드 스타일 (중요 정보)
  factory CardColors.highlighted(AppColorExtension c) {
    return CardColors(
      background: c.surfaceTertiary,
      backgroundHover: c.surfaceQuaternary,
      border: c.brandPrimary,
      title: c.brandPrimary,
      body: c.textPrimary,
      meta: c.textSecondary,
      divider: c.brandPrimary.withValues(alpha: 0.3),
    );
  }
}
