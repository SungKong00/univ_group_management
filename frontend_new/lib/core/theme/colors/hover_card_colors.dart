import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// HoverCard 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class HoverCardColors {
  /// 배경 색상
  final Color background;

  /// 테두리 색상
  final Color border;

  /// 그림자 색상
  final Color shadow;

  /// 제목 텍스트 색상
  final Color titleText;

  /// 내용 텍스트 색상
  final Color contentText;

  /// 보조 텍스트 색상
  final Color secondaryText;

  /// 구분선 색상
  final Color divider;

  const HoverCardColors({
    required this.background,
    required this.border,
    required this.shadow,
    required this.titleText,
    required this.contentText,
    required this.secondaryText,
    required this.divider,
  });

  /// 기본 팩토리 메서드
  factory HoverCardColors.from(AppColorExtension c) {
    return HoverCardColors(
      background: c.surfaceSecondary,
      border: c.borderSecondary,
      shadow: Colors.black.withValues(alpha: 0.25),
      titleText: c.textPrimary,
      contentText: c.textSecondary,
      secondaryText: c.textTertiary,
      divider: c.borderTertiary,
    );
  }
}
