import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// Divider 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class DividerColors {
  /// 구분선 색상
  final Color line;

  /// 라벨 텍스트 색상
  final Color labelText;

  /// 라벨 배경 색상
  final Color labelBackground;

  const DividerColors({
    required this.line,
    required this.labelText,
    required this.labelBackground,
  });

  /// 색상 스타일별 팩토리 메서드
  factory DividerColors.from(
    AppColorExtension c,
    AppDividerColorStyle colorStyle,
  ) {
    return switch (colorStyle) {
      AppDividerColorStyle.standard => DividerColors(
        line: c.dividerPrimary,
        labelText: c.textTertiary,
        labelBackground: c.surfacePrimary,
      ),
      AppDividerColorStyle.prominent => DividerColors(
        line: c.borderPrimary,
        labelText: c.textSecondary,
        labelBackground: c.surfacePrimary,
      ),
      AppDividerColorStyle.subtle => DividerColors(
        line: c.dividerTertiary,
        labelText: c.textQuaternary,
        labelBackground: c.surfacePrimary,
      ),
    };
  }

  /// 기본 구분선 색상 (하위 호환성)
  @Deprecated('Use DividerColors.from() instead')
  factory DividerColors.standard(AppColorExtension c) {
    return DividerColors.from(c, AppDividerColorStyle.standard);
  }

  /// 강조 구분선 색상 (하위 호환성)
  @Deprecated('Use DividerColors.from() instead')
  factory DividerColors.prominent(AppColorExtension c) {
    return DividerColors.from(c, AppDividerColorStyle.prominent);
  }

  /// 미묘한 구분선 색상 (하위 호환성)
  @Deprecated('Use DividerColors.from() instead')
  factory DividerColors.subtle(AppColorExtension c) {
    return DividerColors.from(c, AppDividerColorStyle.subtle);
  }
}
