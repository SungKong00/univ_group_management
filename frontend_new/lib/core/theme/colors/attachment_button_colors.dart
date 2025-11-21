import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Attachment Button 컴포넌트 전용 색상 구조
///
/// 파일 첨부, 업로드, 다운로드, 삭제 버튼
class AttachmentButtonColors {
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

  /// 프로그래스바 색상 (업로드 진행 중)
  final Color progressBar;

  /// 파일 크기 텍스트
  final Color fileSizeText;

  const AttachmentButtonColors({
    required this.background,
    required this.backgroundHover,
    required this.backgroundActive,
    required this.border,
    required this.text,
    required this.icon,
    required this.progressBar,
    required this.fileSizeText,
  });

  /// 기본 첨부파일 버튼
  factory AttachmentButtonColors.default_(AppColorExtension c) {
    return AttachmentButtonColors(
      background: c.surfaceSecondary,
      backgroundHover: c.surfaceTertiary,
      backgroundActive: c.surfaceQuaternary,
      border: c.borderSecondary,
      text: c.textPrimary,
      icon: c.brandSecondary,
      progressBar: c.brandSecondary,
      fileSizeText: c.textSecondary,
    );
  }

  /// 업로드 상태
  factory AttachmentButtonColors.uploading(AppColorExtension c) {
    return AttachmentButtonColors(
      background: c.surfaceSecondary,
      backgroundHover: c.surfaceSecondary,
      backgroundActive: c.surfaceSecondary,
      border: c.borderFocus,
      text: c.textPrimary,
      icon: c.stateInfoText,
      progressBar: c.stateInfoText,
      fileSizeText: c.textSecondary,
    );
  }

  /// 에러 상태 (업로드 실패)
  factory AttachmentButtonColors.error(AppColorExtension c) {
    return AttachmentButtonColors(
      background: c.stateErrorBg.withValues(alpha: 0.15),
      backgroundHover: c.stateErrorBg.withValues(alpha: 0.2),
      backgroundActive: c.stateErrorBg.withValues(alpha: 0.25),
      border: c.stateErrorText,
      text: c.stateErrorText,
      icon: c.stateErrorText,
      progressBar: c.stateErrorText,
      fileSizeText: c.stateErrorText,
    );
  }

  /// 추가 버튼 (+ 첨부파일 추가)
  factory AttachmentButtonColors.add(AppColorExtension c) {
    return AttachmentButtonColors(
      background: Colors.transparent,
      backgroundHover: c.overlayLight,
      backgroundActive: c.overlayMedium,
      border: c.borderTertiary,
      text: c.textSecondary,
      icon: c.brandSecondary,
      progressBar: c.brandSecondary,
      fileSizeText: c.textTertiary,
    );
  }

  /// 삭제 상태 (호버 시 빨강)
  factory AttachmentButtonColors.delete(AppColorExtension c) {
    return AttachmentButtonColors(
      background: c.surfaceSecondary,
      backgroundHover: c.stateErrorBg.withValues(alpha: 0.15),
      backgroundActive: c.stateErrorBg.withValues(alpha: 0.2),
      border: c.borderSecondary,
      text: c.textPrimary,
      icon: c.stateErrorText,
      progressBar: c.stateErrorText,
      fileSizeText: c.textSecondary,
    );
  }
}

/// Attachment Button 상태 열거형
enum AttachmentState { default_, uploading, error, add, delete }
