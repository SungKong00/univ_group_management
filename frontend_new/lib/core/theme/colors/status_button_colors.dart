import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Status Button 컴포넌트 전용 색상 구조
///
/// Issue 상태 변경 버튼 (Done, In Progress, Pending, Cancelled)
class StatusButtonColors {
  /// 배경 색상
  final Color background;

  /// 호버 시 배경
  final Color backgroundHover;

  /// 테두리 색상
  final Color border;

  /// 텍스트 색상
  final Color text;

  /// 아이콘 색상
  final Color icon;

  const StatusButtonColors({
    required this.background,
    required this.backgroundHover,
    required this.border,
    required this.text,
    required this.icon,
  });

  /// Done 상태
  factory StatusButtonColors.done(AppColorExtension c) {
    return StatusButtonColors(
      background: c.stateSuccessBg,
      backgroundHover: c.stateSuccessBg.withValues(alpha: 0.9),
      border: c.stateSuccessText,
      text: c.stateSuccessText,
      icon: c.stateSuccessText,
    );
  }

  /// In Progress 상태
  factory StatusButtonColors.inProgress(AppColorExtension c) {
    return StatusButtonColors(
      background: c.stateInfoBg,
      backgroundHover: c.stateInfoBg.withValues(alpha: 0.9),
      border: c.stateInfoText,
      text: c.stateInfoText,
      icon: c.stateInfoText,
    );
  }

  /// Pending 상태
  factory StatusButtonColors.pending(AppColorExtension c) {
    return StatusButtonColors(
      background: c.stateWarningBg,
      backgroundHover: c.stateWarningBg.withValues(alpha: 0.9),
      border: c.stateWarningText,
      text: c.stateWarningText,
      icon: c.stateWarningText,
    );
  }

  /// Cancelled 상태
  factory StatusButtonColors.cancelled(AppColorExtension c) {
    return StatusButtonColors(
      background: c.stateErrorBg,
      backgroundHover: c.stateErrorBg.withValues(alpha: 0.9),
      border: c.stateErrorText,
      text: c.stateErrorText,
      icon: c.stateErrorText,
    );
  }
}

/// Status 열거형
enum IssueStatus { done, inProgress, pending, cancelled }
