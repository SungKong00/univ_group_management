import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Menu 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class MenuColors {
  /// 메뉴 배경 색상
  final Color background;

  /// 호버 시 배경
  final Color backgroundHover;

  /// 텍스트 색상
  final Color text;

  /// 보조 텍스트 색상
  final Color textSecondary;

  /// 비활성 텍스트 색상
  final Color textDisabled;

  /// 테두리 색상
  final Color border;

  /// 구분선 색상
  final Color divider;

  /// 아이콘 색상
  final Color icon;

  /// 위험 액션 색상
  final Color destructive;

  const MenuColors({
    required this.background,
    required this.backgroundHover,
    required this.text,
    required this.textSecondary,
    required this.textDisabled,
    required this.border,
    required this.divider,
    required this.icon,
    required this.destructive,
  });

  /// 팩토리 메서드
  factory MenuColors.from(AppColorExtension c) {
    return MenuColors(
      background: c.surfaceSecondary,
      backgroundHover: c.surfaceTertiary,
      text: c.textPrimary,
      textSecondary: c.textSecondary,
      textDisabled: c.textQuaternary,
      border: c.borderSecondary,
      divider: c.dividerPrimary,
      icon: c.textSecondary,
      destructive: c.stateErrorText,
    );
  }

  /// 기본 메뉴 색상 (하위 호환성)
  @Deprecated('Use MenuColors.from() instead')
  factory MenuColors.standard(AppColorExtension c) {
    return MenuColors.from(c);
  }
}
