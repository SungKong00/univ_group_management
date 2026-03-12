import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Sidebar 컴포넌트 전용 색상 구조
///
/// Issue 속성 사이드바 (Properties sidebar)
class SidebarColors {
  /// 배경 색상
  final Color background;

  /// 섹션 구분선
  final Color divider;

  /// 섹션 제목 텍스트
  final Color sectionTitle;

  /// 레이블 텍스트
  final Color label;

  /// 값 텍스트
  final Color value;

  /// 호버 시 배경
  final Color itemBackgroundHover;

  /// 편집 버튼 배경
  final Color editButtonBg;

  /// 편집 버튼 텍스트
  final Color editButtonText;

  /// 아이콘 색상
  final Color icon;

  const SidebarColors({
    required this.background,
    required this.divider,
    required this.sectionTitle,
    required this.label,
    required this.value,
    required this.itemBackgroundHover,
    required this.editButtonBg,
    required this.editButtonText,
    required this.icon,
  });

  /// 기본 사이드바
  factory SidebarColors.default_(AppColorExtension c) {
    return SidebarColors(
      background: c.surfaceSecondary,
      divider: c.borderPrimary,
      sectionTitle: c.textPrimary,
      label: c.textSecondary,
      value: c.textPrimary,
      itemBackgroundHover: c.overlayLight,
      editButtonBg: c.surfaceTertiary,
      editButtonText: c.textPrimary,
      icon: c.textSecondary,
    );
  }

  /// 다크 배경 사이드바
  factory SidebarColors.dark(AppColorExtension c) {
    return SidebarColors(
      background: c.surfaceTertiary,
      divider: c.borderSecondary,
      sectionTitle: c.textPrimary,
      label: c.textSecondary,
      value: c.textPrimary,
      itemBackgroundHover: c.overlayMedium,
      editButtonBg: c.surfaceQuaternary,
      editButtonText: c.textPrimary,
      icon: c.textSecondary,
    );
  }

  /// 콤팩트 사이드바
  factory SidebarColors.compact(AppColorExtension c) {
    return SidebarColors(
      background: c.surfacePrimary,
      divider: c.borderTertiary,
      sectionTitle: c.textSecondary,
      label: c.textTertiary,
      value: c.textSecondary,
      itemBackgroundHover: c.overlayLight,
      editButtonBg: Colors.transparent,
      editButtonText: c.textSecondary,
      icon: c.textTertiary,
    );
  }
}
