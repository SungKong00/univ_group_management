import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Assignee Button 컴포넌트 전용 색상 구조
///
/// Issue 담당자 설정 버튼 (assigned/unassigned 상태)
class AssigneeButtonColors {
  /// 배경 색상
  final Color background;

  /// 호버 시 배경
  final Color backgroundHover;

  /// 활성 시 배경
  final Color backgroundActive;

  /// 테두리 색상
  final Color border;

  /// 텍스트 색상
  final Color text;

  /// 아이콘 색상
  final Color icon;

  /// 아바타 배경
  final Color avatarBg;

  const AssigneeButtonColors({
    required this.background,
    required this.backgroundHover,
    required this.backgroundActive,
    required this.border,
    required this.text,
    required this.icon,
    required this.avatarBg,
  });

  /// Assigned 상태 (담당자 있음)
  factory AssigneeButtonColors.assigned(AppColorExtension c) {
    return AssigneeButtonColors(
      background: c.surfaceSecondary,
      backgroundHover: c.surfaceTertiary,
      backgroundActive: c.surfaceQuaternary,
      border: c.borderSecondary,
      text: c.textPrimary,
      icon: c.brandSecondary,
      avatarBg: c.brandPrimary,
    );
  }

  /// Unassigned 상태 (담당자 없음)
  factory AssigneeButtonColors.unassigned(AppColorExtension c) {
    return AssigneeButtonColors(
      background: c.surfaceTertiary,
      backgroundHover: c.surfaceQuaternary,
      backgroundActive: c.overlayLight,
      border: c.borderTertiary,
      text: c.textTertiary,
      icon: c.textTertiary,
      avatarBg: c.surfaceQuaternary,
    );
  }

  /// Multiple 상태 (여러 담당자)
  factory AssigneeButtonColors.multiple(AppColorExtension c) {
    return AssigneeButtonColors(
      background: c.surfaceSecondary,
      backgroundHover: c.surfaceTertiary,
      backgroundActive: c.surfaceQuaternary,
      border: c.brandSecondary,
      text: c.textPrimary,
      icon: c.brandSecondary,
      avatarBg: c.brandPrimary,
    );
  }
}
