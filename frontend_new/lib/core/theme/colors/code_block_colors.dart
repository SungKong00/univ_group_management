import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// CodeBlock 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class CodeBlockColors {
  /// 배경 색상
  final Color background;

  /// 텍스트 색상
  final Color text;

  /// 헤더 배경
  final Color headerBackground;

  /// 헤더 텍스트
  final Color headerText;

  /// 라인 번호 색상
  final Color lineNumber;

  /// 라인 번호 배경
  final Color lineNumberBackground;

  /// 선택 배경
  final Color selectionBackground;

  /// 테두리 색상
  final Color border;

  /// 복사 버튼 색상
  final Color copyButton;

  /// 복사 버튼 호버
  final Color copyButtonHover;

  // 구문 강조 색상
  final Color syntaxKeyword;
  final Color syntaxString;
  final Color syntaxNumber;
  final Color syntaxComment;
  final Color syntaxFunction;
  final Color syntaxClass;
  final Color syntaxVariable;
  final Color syntaxOperator;

  const CodeBlockColors({
    required this.background,
    required this.text,
    required this.headerBackground,
    required this.headerText,
    required this.lineNumber,
    required this.lineNumberBackground,
    required this.selectionBackground,
    required this.border,
    required this.copyButton,
    required this.copyButtonHover,
    required this.syntaxKeyword,
    required this.syntaxString,
    required this.syntaxNumber,
    required this.syntaxComment,
    required this.syntaxFunction,
    required this.syntaxClass,
    required this.syntaxVariable,
    required this.syntaxOperator,
  });

  /// 테마별 팩토리 메서드
  factory CodeBlockColors.from(
    AppColorExtension c,
    AppCodeBlockTheme theme,
    Brightness brightness,
  ) {
    final isDark = switch (theme) {
      AppCodeBlockTheme.light => false,
      AppCodeBlockTheme.dark => true,
      AppCodeBlockTheme.auto => brightness == Brightness.dark,
    };

    if (isDark) {
      return CodeBlockColors(
        background: c.surfacePrimary,
        text: c.textPrimary,
        headerBackground: c.surfaceSecondary,
        headerText: c.textSecondary,
        lineNumber: c.textTertiary,
        lineNumberBackground: c.surfacePrimary,
        selectionBackground: c.selectionBg,
        border: c.borderSecondary,
        copyButton: c.textTertiary,
        copyButtonHover: c.textPrimary,
        // 기본값: 밝은 톤으로 다크 배경에 보이도록
        syntaxKeyword: c.stateInfoBg, // Blue (Info)
        syntaxString: c.stateWarningBg, // Orange (Warning)
        syntaxNumber: c.stateSuccessBg, // Green (Success)
        syntaxComment: c.textTertiary, // Muted
        syntaxFunction: c.brandPrimary, // Brand
        syntaxClass: c.textSecondary, // Secondary text
        syntaxVariable: c.brandSecondary, // Brand secondary
        syntaxOperator: c.textPrimary, // Primary text
      );
    } else {
      return CodeBlockColors(
        background: c.surfaceSecondary,
        text: c.textPrimary,
        headerBackground: c.surfaceTertiary,
        headerText: c.textSecondary,
        lineNumber: c.textTertiary,
        lineNumberBackground: c.surfaceSecondary,
        selectionBackground: c.selectionBg,
        border: c.borderPrimary,
        copyButton: c.textTertiary,
        copyButtonHover: c.textPrimary,
        // 라이트 테마: 낮은 채도, 진한 톤
        syntaxKeyword: c.stateInfoText, // Dark blue
        syntaxString: c.stateErrorText, // Dark red
        syntaxNumber: c.stateSuccessText, // Dark green
        syntaxComment: c.textQuaternary, // Very light gray
        syntaxFunction: c.textSecondary, // Dark gray
        syntaxClass: c.textSecondary, // Dark gray
        syntaxVariable: c.textPrimary, // Black
        syntaxOperator: c.textPrimary, // Black
      );
    }
  }
}
