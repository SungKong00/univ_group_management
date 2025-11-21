import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Button 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class ButtonColors {
  /// 배경 색상
  final Color background;

  /// 호버 시 배경
  final Color backgroundHover;

  /// 활성(pressed) 시 배경
  final Color backgroundActive;

  /// 비활성 시 배경
  final Color backgroundDisabled;

  /// 텍스트 색상
  final Color text;

  /// 비활성 시 텍스트
  final Color textDisabled;

  /// 테두리 색상 (Outlined 버튼용)
  final Color border;

  /// 포커스 링 색상
  final Color focusRing;

  const ButtonColors({
    required this.background,
    required this.backgroundHover,
    required this.backgroundActive,
    required this.backgroundDisabled,
    required this.text,
    required this.textDisabled,
    required this.border,
    required this.focusRing,
  });

  /// Primary 버튼 (브랜드 강조)
  factory ButtonColors.primary(AppColorExtension c) {
    return ButtonColors(
      background: c.brandPrimary,
      backgroundHover: c.brandSecondary,
      backgroundActive: c.accentHover,
      backgroundDisabled: c.surfaceTertiary,
      text: c.brandText,
      textDisabled: c.textQuaternary,
      border: c.brandPrimary,
      focusRing: c.borderFocus,
    );
  }

  /// Secondary 버튼 (보조 액션)
  factory ButtonColors.secondary(AppColorExtension c) {
    return ButtonColors(
      background: c.surfaceSecondary,
      backgroundHover: c.surfaceTertiary,
      backgroundActive: c.surfaceQuaternary,
      backgroundDisabled: c.surfacePrimary,
      text: c.textPrimary,
      textDisabled: c.textQuaternary,
      border: c.borderPrimary,
      focusRing: c.borderFocus,
    );
  }

  /// Ghost 버튼 (투명 배경)
  factory ButtonColors.ghost(AppColorExtension c) {
    return ButtonColors(
      background: Colors.transparent,
      backgroundHover: c.overlayLight,
      backgroundActive: c.overlayMedium,
      backgroundDisabled: Colors.transparent,
      text: c.textSecondary,
      textDisabled: c.textQuaternary,
      border: Colors.transparent,
      focusRing: c.borderFocus,
    );
  }

  /// Destructive 버튼 (삭제, 위험 작업)
  factory ButtonColors.destructive(AppColorExtension c) {
    return ButtonColors(
      background: c.stateErrorBg,
      backgroundHover: c.stateErrorBg.withValues(alpha: 0.9),
      backgroundActive: c.stateErrorBg.withValues(alpha: 0.8),
      backgroundDisabled: c.surfaceTertiary,
      text: c.textOnBrand,
      textDisabled: c.textQuaternary,
      border: c.stateErrorBg,
      focusRing: c.stateErrorBg,
    );
  }

  /// Variant별 색상 (Size 독립)
  ///
  /// 색상은 variant만 보고 결정되며, size는 레이아웃/타이포에만 영향.
  /// 각 variant는 모든 size에서 동일한 색상을 유지합니다.
  ///
  /// Primary: brandText (밝은 흰색) - 크기 무관
  /// Secondary: textPrimary (기본 텍스트) - 크기 무관
  /// Ghost: textSecondary (보조 텍스트) - 크기 무관, large에서도 진한 색 안 씀
  factory ButtonColors.from(
    AppColorExtension c,
    AppButtonVariant variant,
    AppButtonSize size, // 시그니처 유지하되 색상에는 영향 없음
  ) {
    // size는 무시하고 variant만 보고 색상 결정
    return switch (variant) {
      AppButtonVariant.primary => ButtonColors(
        background: c.brandPrimary,
        backgroundHover: c.brandSecondary,
        backgroundActive: c.accentHover,
        backgroundDisabled: c.surfaceTertiary,
        text: c.brandText,
        textDisabled: c.textQuaternary,
        border: c.brandPrimary,
        focusRing: c.borderFocus,
      ),
      AppButtonVariant.secondary => ButtonColors(
        background: c.surfaceSecondary,
        backgroundHover: c.surfaceTertiary,
        backgroundActive: c.surfaceQuaternary,
        backgroundDisabled: c.surfacePrimary,
        text: c.textPrimary,
        textDisabled: c.textQuaternary,
        border: c.borderPrimary,
        focusRing: c.borderFocus,
      ),
      AppButtonVariant.ghost => ButtonColors(
        background: Colors.transparent,
        backgroundHover: c.overlayLight,
        backgroundActive: c.overlayMedium,
        backgroundDisabled: Colors.transparent,
        text: c.textSecondary, // large에서도 항상 보조 톤 유지
        textDisabled: c.textQuaternary,
        border: Colors.transparent,
        focusRing: c.borderFocus,
      ),
    };
  }
}

/// Button 컴포넌트용 Variant 열거형
enum AppButtonVariant { primary, secondary, ghost }

/// Button 컴포넌트용 Size 열거형
enum AppButtonSize { small, medium, large }
