import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Rating 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class RatingColors {
  /// 활성 색상 (채워진 별/하트)
  final Color active;

  /// 비활성 색상 (빈 별/하트)
  final Color inactive;

  /// 호버 색상
  final Color hover;

  /// 텍스트 색상 (숫자 표시)
  final Color text;

  /// 보조 텍스트 색상 (리뷰 수 등)
  final Color secondaryText;

  const RatingColors({
    required this.active,
    required this.inactive,
    required this.hover,
    required this.text,
    required this.secondaryText,
  });

  /// 기본 색상 팩토리 (별 스타일)
  factory RatingColors.from(AppColorExtension c) {
    return RatingColors(
      active: c.stateWarningBg,    // 노란색 상태 사용
      inactive: c.borderSecondary,
      hover: c.stateWarningText,   // 호버는 더 진한 노란색
      text: c.textPrimary,
      secondaryText: c.textTertiary,
    );
  }

  /// 하트 스타일 색상
  factory RatingColors.heart(AppColorExtension c) {
    return RatingColors(
      active: c.stateErrorBg,  // Red for hearts
      inactive: c.borderSecondary,
      hover: c.stateErrorText,
      text: c.textPrimary,
      secondaryText: c.textTertiary,
    );
  }
}
