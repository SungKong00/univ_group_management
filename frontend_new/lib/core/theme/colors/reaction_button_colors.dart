import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Reaction Button 컴포넌트 전용 색상 구조
///
/// 댓글/이슈에 대한 이모지 반응 버튼
class ReactionButtonColors {
  /// 배경 색상
  final Color background;

  /// 호버 시 배경
  final Color backgroundHover;

  /// 활성 시 배경
  final Color backgroundActive;

  /// 테두리 색상
  final Color border;

  /// 활성 시 테두리
  final Color borderActive;

  /// 텍스트/이모지 색상
  final Color text;

  /// 카운트 텍스트
  final Color countText;

  const ReactionButtonColors({
    required this.background,
    required this.backgroundHover,
    required this.backgroundActive,
    required this.border,
    required this.borderActive,
    required this.text,
    required this.countText,
  });

  /// Inactive 상태 (반응 안 함)
  factory ReactionButtonColors.inactive(AppColorExtension c) {
    return ReactionButtonColors(
      background: c.surfaceSecondary,
      backgroundHover: c.surfaceTertiary,
      backgroundActive: c.brandPrimary.withValues(alpha: 0.15),
      border: c.borderTertiary,
      borderActive: c.brandPrimary,
      text: c.textSecondary,
      countText: c.textSecondary,
    );
  }

  /// Active 상태 (반응함)
  factory ReactionButtonColors.active(AppColorExtension c) {
    return ReactionButtonColors(
      background: c.brandPrimary.withValues(alpha: 0.15),
      backgroundHover: c.brandPrimary.withValues(alpha: 0.25),
      backgroundActive: c.brandPrimary.withValues(alpha: 0.2),
      border: c.brandPrimary,
      borderActive: c.brandPrimary,
      text: c.brandPrimary,
      countText: c.brandPrimary,
    );
  }

  /// 추가 버튼 (+ 버튼)
  factory ReactionButtonColors.add(AppColorExtension c) {
    return ReactionButtonColors(
      background: Colors.transparent,
      backgroundHover: c.overlayLight,
      backgroundActive: c.overlayMedium,
      border: c.borderTertiary,
      borderActive: c.brandSecondary,
      text: c.textTertiary,
      countText: c.textTertiary,
    );
  }
}

/// Reaction Button 상태 열거형
enum ReactionState { inactive, active, add }
