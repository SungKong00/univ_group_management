import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// 글로벌 네비게이션 컴포넌트 전용 색상 구조
///
/// 5개 탭 네비게이션(홈, 캘린더, 워크스페이스, 활동, 프로필)의 색상을 정의합니다.
/// 사이드바(데스크톱/태블릿)와 하단바(모바일) 모두에서 사용됩니다.
class GlobalNavColors {
  /// 배경 색상
  final Color background;

  /// 테두리 색상
  final Color border;

  /// 아이템 기본 아이콘 색상
  final Color icon;

  /// 아이템 활성 아이콘 색상
  final Color iconActive;

  /// 아이템 기본 텍스트 색상
  final Color text;

  /// 아이템 활성 텍스트 색상
  final Color textActive;

  /// 아이템 호버 배경 색상
  final Color itemHover;

  /// 아이템 활성 배경 색상
  final Color itemActive;

  /// 사용자 정보 영역 배경
  final Color userAreaBackground;

  /// 사용자 정보 텍스트
  final Color userText;

  /// 사용자 보조 텍스트
  final Color userTextSecondary;

  const GlobalNavColors({
    required this.background,
    required this.border,
    required this.icon,
    required this.iconActive,
    required this.text,
    required this.textActive,
    required this.itemHover,
    required this.itemActive,
    required this.userAreaBackground,
    required this.userText,
    required this.userTextSecondary,
  });

  /// 기본 팩토리
  factory GlobalNavColors.from(AppColorExtension c) {
    return GlobalNavColors(
      background: c.surfaceSecondary,
      border: c.borderSecondary,
      icon: c.textTertiary,
      iconActive: c.brandPrimary,
      text: c.textSecondary,
      textActive: c.textPrimary,
      itemHover: c.surfaceTertiary,
      itemActive: c.brandPrimary.withValues(alpha: 0.15),
      userAreaBackground: c.surfaceTertiary,
      userText: c.textPrimary,
      userTextSecondary: c.textSecondary,
    );
  }
}
