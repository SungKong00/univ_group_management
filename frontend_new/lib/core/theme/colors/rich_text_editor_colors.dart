import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// RichTextEditor 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class RichTextEditorColors {
  /// 에디터 배경
  final Color background;

  /// 에디터 텍스트
  final Color text;

  /// 플레이스홀더 텍스트
  final Color placeholder;

  /// 테두리 색상
  final Color border;

  /// 포커스 테두리
  final Color borderFocus;

  /// 툴바 배경
  final Color toolbarBackground;

  /// 툴바 버튼 색상
  final Color toolbarButton;

  /// 툴바 버튼 활성
  final Color toolbarButtonActive;

  /// 툴바 버튼 호버
  final Color toolbarButtonHover;

  /// 선택 배경
  final Color selectionBackground;

  /// 링크 색상
  final Color link;

  /// 인용구 배경
  final Color blockquoteBackground;

  /// 인용구 테두리
  final Color blockquoteBorder;

  /// 코드 배경
  final Color codeBackground;

  /// 코드 텍스트
  final Color codeText;

  const RichTextEditorColors({
    required this.background,
    required this.text,
    required this.placeholder,
    required this.border,
    required this.borderFocus,
    required this.toolbarBackground,
    required this.toolbarButton,
    required this.toolbarButtonActive,
    required this.toolbarButtonHover,
    required this.selectionBackground,
    required this.link,
    required this.blockquoteBackground,
    required this.blockquoteBorder,
    required this.codeBackground,
    required this.codeText,
  });

  /// 기본 색상 팩토리
  factory RichTextEditorColors.from(AppColorExtension c) {
    return RichTextEditorColors(
      background: c.surfacePrimary,
      text: c.textPrimary,
      placeholder: c.textTertiary,
      border: c.borderPrimary,
      borderFocus: c.brandPrimary,
      toolbarBackground: c.surfaceSecondary,
      toolbarButton: c.textSecondary,
      toolbarButtonActive: c.brandPrimary,
      toolbarButtonHover: c.surfaceTertiary,
      selectionBackground: c.selectionBg,
      link: c.linkDefault,
      blockquoteBackground: c.surfaceSecondary,
      blockquoteBorder: c.brandPrimary,
      codeBackground: c.surfaceTertiary,
      codeText: c.stateInfoText,
    );
  }
}
