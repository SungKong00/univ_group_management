import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Sheet 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class SheetColors {
  /// 배경 색상
  final Color background;

  /// 오버레이 색상
  final Color overlay;

  /// 헤더 배경 색상
  final Color headerBackground;

  /// 헤더 테두리 색상
  final Color headerBorder;

  /// 제목 텍스트 색상
  final Color titleText;

  /// 닫기 버튼 색상
  final Color closeButton;

  /// 닫기 버튼 호버 색상
  final Color closeButtonHover;

  /// 닫기 버튼 배경 호버 색상
  final Color closeButtonBgHover;

  /// 테두리 색상
  final Color border;

  /// 그림자 색상
  final Color shadow;

  const SheetColors({
    required this.background,
    required this.overlay,
    required this.headerBackground,
    required this.headerBorder,
    required this.titleText,
    required this.closeButton,
    required this.closeButtonHover,
    required this.closeButtonBgHover,
    required this.border,
    required this.shadow,
  });

  /// 기본 팩토리 메서드
  factory SheetColors.from(AppColorExtension c) {
    return SheetColors(
      background: c.surfacePrimary,
      overlay: c.overlayScrim,
      headerBackground: c.surfaceSecondary,
      headerBorder: c.borderSecondary,
      titleText: c.textPrimary,
      closeButton: c.textTertiary,
      closeButtonHover: c.textPrimary,
      closeButtonBgHover: c.surfaceTertiary,
      border: c.borderSecondary,
      shadow: Colors.black.withValues(alpha: 0.3),
    );
  }
}
