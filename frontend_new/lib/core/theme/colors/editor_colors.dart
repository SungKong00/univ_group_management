import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Editor 컴포넌트 전용 색상 구조
///
/// Issue 제목, 설명, 댓글 입력 필드용 색상
class EditorColors {
  /// 배경 색상
  final Color background;

  /// 호버 시 배경
  final Color backgroundHover;

  /// 포커스 시 배경
  final Color backgroundFocus;

  /// 테두리 색상
  final Color border;

  /// 포커스 시 테두리
  final Color borderFocus;

  /// 텍스트 색상
  final Color text;

  /// 플레이스홀더 색상
  final Color placeholder;

  /// 커서 색상
  final Color cursor;

  /// 선택 강조 색상
  final Color selection;

  /// 포맷팅 도구바 배경
  final Color toolbarBg;

  /// 포맷팅 버튼 기본
  final Color toolbarButtonDefault;

  /// 포맷팅 버튼 활성
  final Color toolbarButtonActive;

  const EditorColors({
    required this.background,
    required this.backgroundHover,
    required this.backgroundFocus,
    required this.border,
    required this.borderFocus,
    required this.text,
    required this.placeholder,
    required this.cursor,
    required this.selection,
    required this.toolbarBg,
    required this.toolbarButtonDefault,
    required this.toolbarButtonActive,
  });

  /// 기본 에디터
  factory EditorColors.default_(AppColorExtension c) {
    return EditorColors(
      background: c.surfacePrimary,
      backgroundHover: c.surfaceSecondary,
      backgroundFocus: c.surfaceSecondary,
      border: c.borderPrimary,
      borderFocus: c.borderFocus,
      text: c.textPrimary,
      placeholder: c.textTertiary,
      cursor: c.brandPrimary,
      selection: c.brandPrimary.withValues(alpha: 0.2),
      toolbarBg: c.surfaceSecondary,
      toolbarButtonDefault: c.textSecondary,
      toolbarButtonActive: c.brandPrimary,
    );
  }

  /// 제목 에디터
  factory EditorColors.title(AppColorExtension c) {
    return EditorColors(
      background: Colors.transparent,
      backgroundHover: Colors.transparent,
      backgroundFocus: c.surfaceSecondary,
      border: Colors.transparent,
      borderFocus: c.borderFocus,
      text: c.textPrimary,
      placeholder: c.textQuaternary,
      cursor: c.brandPrimary,
      selection: c.brandPrimary.withValues(alpha: 0.2),
      toolbarBg: c.surfaceSecondary,
      toolbarButtonDefault: c.textSecondary,
      toolbarButtonActive: c.brandPrimary,
    );
  }

  /// 댓글 입력 에디터
  factory EditorColors.comment(AppColorExtension c) {
    return EditorColors(
      background: c.surfaceSecondary,
      backgroundHover: c.surfaceTertiary,
      backgroundFocus: c.surfaceSecondary,
      border: c.borderSecondary,
      borderFocus: c.borderFocus,
      text: c.textPrimary,
      placeholder: c.textTertiary,
      cursor: c.brandSecondary,
      selection: c.brandSecondary.withValues(alpha: 0.2),
      toolbarBg: c.surfaceSecondary,
      toolbarButtonDefault: c.textSecondary,
      toolbarButtonActive: c.brandSecondary,
    );
  }
}
