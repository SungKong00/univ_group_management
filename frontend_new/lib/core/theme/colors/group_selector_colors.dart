import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// 그룹 선택기 컴포넌트 전용 색상 구조
///
/// 그룹 드롭다운(계층적 그룹 목록)의 색상을 정의합니다.
class GroupSelectorColors {
  /// 드롭다운 배경 색상
  final Color background;

  /// 테두리 색상
  final Color border;

  /// 그림자 색상
  final Color shadow;

  /// 아이템 호버 배경
  final Color itemHover;

  /// 아이템 선택 배경
  final Color itemActive;

  /// 아이템 텍스트 색상
  final Color itemText;

  /// 아이템 텍스트 색상 (선택됨)
  final Color itemTextActive;

  /// 계층 인디케이터 색상
  final Color hierarchyIndicator;

  /// 체크 아이콘 색상
  final Color checkIcon;

  /// 구분선 색상
  final Color divider;

  const GroupSelectorColors({
    required this.background,
    required this.border,
    required this.shadow,
    required this.itemHover,
    required this.itemActive,
    required this.itemText,
    required this.itemTextActive,
    required this.hierarchyIndicator,
    required this.checkIcon,
    required this.divider,
  });

  /// 기본 팩토리
  factory GroupSelectorColors.from(AppColorExtension c) {
    return GroupSelectorColors(
      background: c.surfaceSecondary,
      border: c.borderSecondary,
      shadow: c.shadow,
      itemHover: c.surfaceTertiary,
      itemActive: c.brandPrimary.withValues(alpha: 0.15),
      itemText: c.textPrimary,
      itemTextActive: c.brandPrimary,
      hierarchyIndicator: c.textQuaternary,
      checkIcon: c.brandPrimary,
      divider: c.borderSecondary,
    );
  }
}
