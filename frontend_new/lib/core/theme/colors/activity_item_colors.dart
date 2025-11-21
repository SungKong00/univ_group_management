import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Activity Item 컴포넌트 전용 색상 구조
///
/// 활동 로그 (댓글 추가, 상태 변경, 담당자 변경 등)
class ActivityItemColors {
  /// 배경 색상
  final Color background;

  /// 호버 시 배경
  final Color backgroundHover;

  /// 좌측 라인 색상
  final Color timelineColor;

  /// 아이콘 배경
  final Color iconBg;

  /// 아이콘 색상
  final Color iconColor;

  /// 메타 텍스트 색상 (누가, 언제)
  final Color metaText;

  /// 변경 내용 강조
  final Color changeEmphasis;

  /// 텍스트 색상
  final Color text;

  const ActivityItemColors({
    required this.background,
    required this.backgroundHover,
    required this.timelineColor,
    required this.iconBg,
    required this.iconColor,
    required this.metaText,
    required this.changeEmphasis,
    required this.text,
  });

  /// 댓글 추가
  factory ActivityItemColors.comment(AppColorExtension c) {
    return ActivityItemColors(
      background: c.surfaceSecondary,
      backgroundHover: c.surfaceTertiary,
      timelineColor: c.brandSecondary,
      iconBg: c.brandSecondary.withValues(alpha: 0.2),
      iconColor: c.brandSecondary,
      metaText: c.textSecondary,
      changeEmphasis: c.brandSecondary,
      text: c.textPrimary,
    );
  }

  /// 상태 변경
  factory ActivityItemColors.statusChange(AppColorExtension c) {
    return ActivityItemColors(
      background: c.surfaceSecondary,
      backgroundHover: c.surfaceTertiary,
      timelineColor: c.stateInfoText,
      iconBg: c.stateInfoBg,
      iconColor: c.stateInfoText,
      metaText: c.textSecondary,
      changeEmphasis: c.stateInfoText,
      text: c.textPrimary,
    );
  }

  /// 담당자 변경
  factory ActivityItemColors.assigneeChange(AppColorExtension c) {
    return ActivityItemColors(
      background: c.surfaceSecondary,
      backgroundHover: c.surfaceTertiary,
      timelineColor: c.brandPrimary,
      iconBg: c.brandPrimary.withValues(alpha: 0.2),
      iconColor: c.brandPrimary,
      metaText: c.textSecondary,
      changeEmphasis: c.brandPrimary,
      text: c.textPrimary,
    );
  }

  /// 우선순위 변경
  factory ActivityItemColors.priorityChange(AppColorExtension c) {
    return ActivityItemColors(
      background: c.surfaceSecondary,
      backgroundHover: c.surfaceTertiary,
      timelineColor: c.stateWarningText,
      iconBg: c.stateWarningBg,
      iconColor: c.stateWarningText,
      metaText: c.textSecondary,
      changeEmphasis: c.stateWarningText,
      text: c.textPrimary,
    );
  }

  /// 삭제 / 시스템 액션
  factory ActivityItemColors.system(AppColorExtension c) {
    return ActivityItemColors(
      background: c.surfaceTertiary,
      backgroundHover: c.surfaceQuaternary,
      timelineColor: c.textTertiary,
      iconBg: c.surfaceQuaternary,
      iconColor: c.textTertiary,
      metaText: c.textQuaternary,
      changeEmphasis: c.textTertiary,
      text: c.textSecondary,
    );
  }
}

/// Activity 타입 열거형
enum ActivityType {
  comment,
  statusChange,
  assigneeChange,
  priorityChange,
  system,
}
