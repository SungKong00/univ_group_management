import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// Timeline 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class TimelineColors {
  /// 라인 색상
  final Color line;

  /// 노드 배경 색상
  final Color nodeBackground;

  /// 노드 테두리 색상
  final Color nodeBorder;

  /// 노드 아이콘 색상
  final Color nodeIcon;

  /// 콘텐츠 배경 색상
  final Color contentBackground;

  /// 콘텐츠 텍스트 색상
  final Color contentText;

  /// 타임스탬프 색상
  final Color timestamp;

  const TimelineColors({
    required this.line,
    required this.nodeBackground,
    required this.nodeBorder,
    required this.nodeIcon,
    required this.contentBackground,
    required this.contentText,
    required this.timestamp,
  });

  /// 기본 색상 팩토리
  factory TimelineColors.from(AppColorExtension c) {
    return TimelineColors(
      line: c.borderPrimary,
      nodeBackground: c.surfacePrimary,
      nodeBorder: c.borderPrimary,
      nodeIcon: c.textSecondary,
      contentBackground: c.surfaceSecondary,
      contentText: c.textPrimary,
      timestamp: c.textTertiary,
    );
  }

  /// 상태별 노드 색상
  Color getNodeColorForStatus(AppTimelineItemStatus status, AppColorExtension c) {
    return switch (status) {
      AppTimelineItemStatus.completed => c.stateSuccessBg,
      AppTimelineItemStatus.active => c.brandPrimary,
      AppTimelineItemStatus.pending => c.surfaceTertiary,
      AppTimelineItemStatus.error => c.stateErrorBg,
    };
  }

  /// 상태별 아이콘 색상
  Color getIconColorForStatus(AppTimelineItemStatus status, AppColorExtension c) {
    return switch (status) {
      AppTimelineItemStatus.completed => c.stateSuccessText,
      AppTimelineItemStatus.active => c.textOnBrand,
      AppTimelineItemStatus.pending => c.textTertiary,
      AppTimelineItemStatus.error => c.stateErrorText,
    };
  }
}
