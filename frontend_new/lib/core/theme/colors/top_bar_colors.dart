import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// 상단 바 컴포넌트 전용 색상 구조
///
/// 상단 네비게이션 바(뒤로가기 버튼, 브레드크럼, 사용자 아바타)의 색상을 정의합니다.
class TopBarColors {
  /// 배경 색상
  final Color background;

  /// 테두리 색상
  final Color border;

  /// 뒤로가기 버튼 아이콘 색상
  final Color backIcon;

  /// 뒤로가기 버튼 호버 배경
  final Color backHover;

  /// 뒤로가기 버튼 비활성 색상
  final Color backDisabled;

  /// 아바타 배경 색상
  final Color avatarBackground;

  /// 아바타 텍스트/아이콘 색상
  final Color avatarText;

  const TopBarColors({
    required this.background,
    required this.border,
    required this.backIcon,
    required this.backHover,
    required this.backDisabled,
    required this.avatarBackground,
    required this.avatarText,
  });

  /// 기본 팩토리
  factory TopBarColors.from(AppColorExtension c) {
    return TopBarColors(
      background: c.surfacePrimary,
      border: c.borderSecondary,
      backIcon: c.textSecondary,
      backHover: c.surfaceTertiary,
      backDisabled: c.textQuaternary,
      avatarBackground: c.surfaceTertiary,
      avatarText: c.textPrimary,
    );
  }
}
