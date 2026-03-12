import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// SearchInput 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class SearchInputColors {
  /// 배경 색상
  final Color background;

  /// 배경 색상 (포커스)
  final Color backgroundFocused;

  /// 테두리 색상
  final Color border;

  /// 테두리 색상 (포커스)
  final Color borderFocused;

  /// 텍스트 색상
  final Color text;

  /// 플레이스홀더 색상
  final Color placeholder;

  /// 아이콘 색상
  final Color icon;

  /// 아이콘 색상 (호버)
  final Color iconHover;

  /// 클리어 버튼 배경 색상
  final Color clearButtonBackground;

  /// 클리어 버튼 아이콘 색상
  final Color clearButtonIcon;

  /// 서제스천 배경 색상
  final Color suggestionBackground;

  /// 서제스천 배경 색상 (호버)
  final Color suggestionBackgroundHover;

  /// 서제스천 텍스트 색상
  final Color suggestionText;

  /// 서제스천 매칭 텍스트 색상
  final Color suggestionHighlight;

  /// 히스토리 아이콘 색상
  final Color historyIcon;

  /// 로딩 스피너 색상
  final Color loadingSpinner;

  const SearchInputColors({
    required this.background,
    required this.backgroundFocused,
    required this.border,
    required this.borderFocused,
    required this.text,
    required this.placeholder,
    required this.icon,
    required this.iconHover,
    required this.clearButtonBackground,
    required this.clearButtonIcon,
    required this.suggestionBackground,
    required this.suggestionBackgroundHover,
    required this.suggestionText,
    required this.suggestionHighlight,
    required this.historyIcon,
    required this.loadingSpinner,
  });

  /// 기본 팩토리 메서드
  factory SearchInputColors.from(AppColorExtension c) {
    return SearchInputColors(
      background: c.surfaceSecondary,
      backgroundFocused: c.surfacePrimary,
      border: c.borderSecondary,
      borderFocused: c.borderFocus,
      text: c.textPrimary,
      placeholder: c.textTertiary,
      icon: c.textSecondary,
      iconHover: c.textPrimary,
      clearButtonBackground: c.surfaceTertiary,
      clearButtonIcon: c.textSecondary,
      suggestionBackground: c.surfaceSecondary,
      suggestionBackgroundHover: c.surfaceTertiary,
      suggestionText: c.textPrimary,
      suggestionHighlight: c.brandPrimary,
      historyIcon: c.textTertiary,
      loadingSpinner: c.brandPrimary,
    );
  }
}
