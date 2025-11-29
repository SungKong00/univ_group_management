import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// CommandPalette 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class CommandPaletteColors {
  /// 오버레이 색상
  final Color overlay;

  /// 배경 색상
  final Color background;

  /// 테두리 색상
  final Color border;

  /// 그림자 색상
  final Color shadow;

  /// 검색 입력 배경 색상
  final Color inputBackground;

  /// 검색 입력 테두리 색상
  final Color inputBorder;

  /// 검색 입력 텍스트 색상
  final Color inputText;

  /// 검색 입력 플레이스홀더 색상
  final Color inputPlaceholder;

  /// 검색 아이콘 색상
  final Color searchIcon;

  /// 아이템 배경 색상
  final Color itemBackground;

  /// 아이템 호버 배경 색상
  final Color itemBackgroundHover;

  /// 아이템 선택 배경 색상
  final Color itemBackgroundSelected;

  /// 아이템 텍스트 색상
  final Color itemText;

  /// 아이템 설명 텍스트 색상
  final Color itemDescription;

  /// 아이템 아이콘 색상
  final Color itemIcon;

  /// 단축키 배경 색상
  final Color shortcutBackground;

  /// 단축키 텍스트 색상
  final Color shortcutText;

  /// 그룹 헤더 텍스트 색상
  final Color groupHeader;

  /// 구분선 색상
  final Color divider;

  /// 빈 상태 아이콘 색상
  final Color emptyIcon;

  /// 빈 상태 텍스트 색상
  final Color emptyText;

  const CommandPaletteColors({
    required this.overlay,
    required this.background,
    required this.border,
    required this.shadow,
    required this.inputBackground,
    required this.inputBorder,
    required this.inputText,
    required this.inputPlaceholder,
    required this.searchIcon,
    required this.itemBackground,
    required this.itemBackgroundHover,
    required this.itemBackgroundSelected,
    required this.itemText,
    required this.itemDescription,
    required this.itemIcon,
    required this.shortcutBackground,
    required this.shortcutText,
    required this.groupHeader,
    required this.divider,
    required this.emptyIcon,
    required this.emptyText,
  });

  /// 기본 팩토리 메서드
  factory CommandPaletteColors.from(AppColorExtension c) {
    return CommandPaletteColors(
      overlay: c.overlayScrim,
      background: c.surfacePrimary,
      border: c.borderSecondary,
      shadow: Colors.black.withValues(alpha: 0.3),
      inputBackground: c.surfaceSecondary,
      inputBorder: c.borderSecondary,
      inputText: c.textPrimary,
      inputPlaceholder: c.textQuaternary,
      searchIcon: c.textTertiary,
      itemBackground: Colors.transparent,
      itemBackgroundHover: c.surfaceSecondary,
      itemBackgroundSelected: c.brandPrimary.withValues(alpha: 0.15),
      itemText: c.textPrimary,
      itemDescription: c.textSecondary,
      itemIcon: c.textTertiary,
      shortcutBackground: c.surfaceTertiary,
      shortcutText: c.textSecondary,
      groupHeader: c.textTertiary,
      divider: c.borderTertiary,
      emptyIcon: c.textQuaternary,
      emptyText: c.textTertiary,
    );
  }
}
