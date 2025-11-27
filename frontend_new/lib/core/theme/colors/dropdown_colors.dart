import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Dropdown 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class DropdownColors {
  // === Trigger (버튼) ===

  /// 트리거 배경
  final Color triggerBackground;

  /// 트리거 호버 시 배경
  final Color triggerBackgroundHover;

  /// 트리거 포커스 시 배경
  final Color triggerBackgroundFocus;

  /// 트리거 비활성 시 배경
  final Color triggerBackgroundDisabled;

  /// 트리거 텍스트
  final Color triggerText;

  /// 트리거 placeholder
  final Color triggerPlaceholder;

  /// 트리거 아이콘
  final Color triggerIcon;

  /// 트리거 테두리
  final Color triggerBorder;

  /// 트리거 포커스 테두리
  final Color triggerBorderFocus;

  // === Menu ===

  /// 메뉴 배경
  final Color menuBackground;

  /// 메뉴 테두리
  final Color menuBorder;

  // === Item ===

  /// 아이템 배경
  final Color itemBackground;

  /// 아이템 호버 시 배경
  final Color itemBackgroundHover;

  /// 아이템 선택 시 배경
  final Color itemBackgroundSelected;

  /// 아이템 텍스트
  final Color itemText;

  /// 아이템 선택 시 텍스트
  final Color itemTextSelected;

  /// 아이템 설명 텍스트
  final Color itemDescription;

  /// 아이템 비활성 텍스트
  final Color itemTextDisabled;

  /// 그룹 헤더 텍스트
  final Color groupHeader;

  // === State ===

  /// 에러 상태 테두리
  final Color errorBorder;

  /// 에러 상태 텍스트
  final Color errorText;

  const DropdownColors({
    required this.triggerBackground,
    required this.triggerBackgroundHover,
    required this.triggerBackgroundFocus,
    required this.triggerBackgroundDisabled,
    required this.triggerText,
    required this.triggerPlaceholder,
    required this.triggerIcon,
    required this.triggerBorder,
    required this.triggerBorderFocus,
    required this.menuBackground,
    required this.menuBorder,
    required this.itemBackground,
    required this.itemBackgroundHover,
    required this.itemBackgroundSelected,
    required this.itemText,
    required this.itemTextSelected,
    required this.itemDescription,
    required this.itemTextDisabled,
    required this.groupHeader,
    required this.errorBorder,
    required this.errorText,
  });

  /// 기본 드롭다운 색상
  factory DropdownColors.standard(AppColorExtension c) {
    return DropdownColors(
      // Trigger
      triggerBackground: c.surfaceSecondary,
      triggerBackgroundHover: c.surfaceTertiary,
      triggerBackgroundFocus: c.surfaceSecondary,
      triggerBackgroundDisabled: c.surfacePrimary,
      triggerText: c.textPrimary,
      triggerPlaceholder: c.textTertiary,
      triggerIcon: c.textSecondary,
      triggerBorder: c.borderPrimary,
      triggerBorderFocus: c.borderFocus,
      // Menu
      menuBackground: c.surfaceSecondary,
      menuBorder: c.borderSecondary,
      // Item
      itemBackground: Colors.transparent,
      itemBackgroundHover: c.surfaceTertiary,
      itemBackgroundSelected: c.brandPrimary.withValues(alpha: 0.1),
      itemText: c.textPrimary,
      itemTextSelected: c.brandPrimary,
      itemDescription: c.textTertiary,
      itemTextDisabled: c.textQuaternary,
      groupHeader: c.textTertiary,
      // State
      errorBorder: c.stateErrorBg,
      errorText: c.stateErrorText,
    );
  }
}
