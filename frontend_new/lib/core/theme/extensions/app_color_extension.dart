import 'package:flutter/material.dart';

/// 역할 기반(semantic) 색상 토큰 시스템
///
/// 40개 semantic 색상 토큰을 const로 정의하여 일관된 색상 시스템을 제공합니다.
/// 다크 테마 기준으로 설계되었으며, 새로운 테마 추가 시 dark() 팩토리와 copyWith() 메서드만 수정하면 모든 컴포넌트가 자동으로 업데이트됩니다.
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  // ============================================================
  // Brand Colors (3개)
  // ============================================================

  /// 브랜드 메인 색상 (버튼, 강조 요소)
  final Color brandPrimary;

  /// 브랜드 보조 색상 (액센트, 링크)
  final Color brandSecondary;

  /// 브랜드 배경 위의 텍스트 색상
  final Color brandText;

  // ============================================================
  // Surface Colors (5개)
  // ============================================================

  /// 메인 배경 (앱 베이스)
  final Color surfacePrimary;

  /// 카드 배경 (level 1)
  final Color surfaceSecondary;

  /// 중첩 카드 배경 (level 2)
  final Color surfaceTertiary;

  /// 3단계 중첩 배경 (level 3)
  final Color surfaceQuaternary;

  /// 호버 상태 배경
  final Color surfaceHover;

  // ============================================================
  // Text Colors (5개)
  // ============================================================

  /// 주요 텍스트 (제목, 본문)
  final Color textPrimary;

  /// 보조 텍스트 (부제, 설명)
  final Color textSecondary;

  /// 3차 텍스트 (메타 정보)
  final Color textTertiary;

  /// 비활성 텍스트
  final Color textQuaternary;

  /// 브랜드 배경 위의 텍스트
  final Color textOnBrand;

  // ============================================================
  // Border Colors (4개)
  // ============================================================

  /// 주요 테두리
  final Color borderPrimary;

  /// 보조 테두리
  final Color borderSecondary;

  /// 미묘한 테두리
  final Color borderTertiary;

  /// 포커스 링 색상
  final Color borderFocus;

  // ============================================================
  // State Colors (10개)
  // ============================================================

  /// 성공 상태 배경
  final Color stateSuccessBg;

  /// 성공 상태 텍스트/아이콘
  final Color stateSuccessText;

  /// 경고 상태 배경
  final Color stateWarningBg;

  /// 경고 상태 텍스트/아이콘
  final Color stateWarningText;

  /// 에러 상태 배경
  final Color stateErrorBg;

  /// 에러 상태 텍스트/아이콘
  final Color stateErrorText;

  /// 정보 상태 배경
  final Color stateInfoBg;

  /// 정보 상태 텍스트/아이콘
  final Color stateInfoText;

  /// Linear 기능 색상: Plan
  final Color statePlanBg;

  /// Linear 기능 색상: Build
  final Color stateBuildBg;

  // ============================================================
  // Overlay Colors (3개)
  // ============================================================

  /// 스크림 오버레이 (모달 배경)
  final Color overlayScrim;

  /// 밝은 오버레이 (미묘한 강조)
  final Color overlayLight;

  /// 중간 오버레이
  final Color overlayMedium;

  // ============================================================
  // Interactive Colors (4개)
  // ============================================================

  /// 링크 기본 색상
  final Color linkDefault;

  /// 링크 호버 색상
  final Color linkHover;

  /// 텍스트 선택 배경
  final Color selectionBg;

  /// 액센트 호버 색상
  final Color accentHover;

  // ============================================================
  // Scrollbar Colors (3개)
  // ============================================================

  /// 스크롤바 기본 색상
  final Color scrollbarDefault;

  /// 스크롤바 호버 색상
  final Color scrollbarHover;

  /// 스크롤바 활성 색상
  final Color scrollbarActive;

  // ============================================================
  // Divider Colors (3개)
  // ============================================================

  /// 주요 구분선
  final Color dividerPrimary;

  /// 보조 구분선
  final Color dividerSecondary;

  /// 미묘한 구분선
  final Color dividerTertiary;

  const AppColorExtension({
    // Brand
    required this.brandPrimary,
    required this.brandSecondary,
    required this.brandText,
    // Surface
    required this.surfacePrimary,
    required this.surfaceSecondary,
    required this.surfaceTertiary,
    required this.surfaceQuaternary,
    required this.surfaceHover,
    // Text
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textQuaternary,
    required this.textOnBrand,
    // Border
    required this.borderPrimary,
    required this.borderSecondary,
    required this.borderTertiary,
    required this.borderFocus,
    // State
    required this.stateSuccessBg,
    required this.stateSuccessText,
    required this.stateWarningBg,
    required this.stateWarningText,
    required this.stateErrorBg,
    required this.stateErrorText,
    required this.stateInfoBg,
    required this.stateInfoText,
    required this.statePlanBg,
    required this.stateBuildBg,
    // Overlay
    required this.overlayScrim,
    required this.overlayLight,
    required this.overlayMedium,
    // Interactive
    required this.linkDefault,
    required this.linkHover,
    required this.selectionBg,
    required this.accentHover,
    // Scrollbar
    required this.scrollbarDefault,
    required this.scrollbarHover,
    required this.scrollbarActive,
    // Divider
    required this.dividerPrimary,
    required this.dividerSecondary,
    required this.dividerTertiary,
  });

  /// Dark theme 기본 색상 (Updated Brand Colors)
  factory AppColorExtension.dark() {
    return const AppColorExtension(
      // Brand
      brandPrimary: Color(0xFF5C068C), // #5c068c (color-brand)
      brandSecondary: Color(0xFF7A0BB8), // #7a0bb8 (color-accent)
      brandText: Color(0xFFFFFFFF), // #fff
      // Surface
      surfacePrimary: Color(0xFF0A0A0B), // #0a0a0b (bg-lvl-0)
      surfaceSecondary: Color(0xFF141416), // #141416 (bg-lvl-1)
      surfaceTertiary: Color(0xFF1E1E21), // #1e1e21 (bg-lvl-2)
      surfaceQuaternary: Color(0xFF28282C), // #28282c (bg-lvl-3)
      surfaceHover: Color(0xFF9010E0), // #9010e0 (color-hover)
      // Text
      textPrimary: Color(0xFFFFFFFF), // #ffffff (text-primary)
      textSecondary: Color(0xFFA1A1AA), // #a1a1aa (text-secondary)
      textTertiary: Color(0xFF71717A), // #71717a (text-tertiary)
      textQuaternary: Color(0xFF52525B), // #52525b (text-quaternary)
      textOnBrand: Color(0xFFFFFFFF), // #fff
      // Border
      borderPrimary: Color(0xFF52525B), // #52525b (text-quaternary)
      borderSecondary: Color(0xFF28282C), // #28282c (bg-lvl-3)
      borderTertiary: Color(0xFF1E1E21), // #1e1e21 (bg-lvl-2)
      borderFocus: Color(0xFF9010E0), // #9010e0 (color-hover)
      // State
      stateSuccessBg: Color(0xFF10B981), // #10b981 (color-success)
      stateSuccessText: Color(0xFF10B981), // #10b981
      stateWarningBg: Color(0xFFF59E0B), // #f59e0b (color-warning)
      stateWarningText: Color(0xFFF97316), // #f97316 (color-orange)
      stateErrorBg: Color(0xFFEF4444), // #ef4444 (color-error)
      stateErrorText: Color(0xFFEF4444), // #ef4444
      stateInfoBg: Color(0xFF3B82F6), // #3b82f6 (color-info)
      stateInfoText: Color(0xFF3B82F6), // #3b82f6
      statePlanBg: Color(0xFF10B981), // #10b981 (success)
      stateBuildBg: Color(0xFFF59E0B), // #f59e0b (warning)
      // Overlay
      overlayScrim: Color(0xE6000000), // rgba(0,0,0,0.9)
      overlayLight: Color(0x0DFFFFFF), // rgba(255,255,255,0.05)
      overlayMedium: Color(0x14FFFFFF), // rgba(255,255,255,0.08)
      // Interactive
      linkDefault: Color(0xFF7A0BB8), // #7a0bb8 (color-accent)
      linkHover: Color(0xFF9010E0), // #9010e0 (color-hover)
      selectionBg: Color(0xFF5C068C), // #5c068c (color-brand)
      accentHover: Color(0xFF9010E0), // #9010e0 (color-hover)
      // Scrollbar
      scrollbarDefault: Color(0x1AFFFFFF), // rgba(255,255,255,0.1)
      scrollbarHover: Color(0x33FFFFFF), // rgba(255,255,255,0.2)
      scrollbarActive: Color(0x66FFFFFF), // rgba(255,255,255,0.4)
      // Divider
      dividerPrimary: Color(0xFF1E1E21), // #1e1e21 (bg-lvl-2)
      dividerSecondary: Color(0xFF141416), // #141416 (bg-lvl-1)
      dividerTertiary: Color(0xFF0A0A0B), // #0a0a0b (bg-lvl-0)
    );
  }

  @override
  ThemeExtension<AppColorExtension> copyWith({
    // Brand
    Color? brandPrimary,
    Color? brandSecondary,
    Color? brandText,
    // Surface
    Color? surfacePrimary,
    Color? surfaceSecondary,
    Color? surfaceTertiary,
    Color? surfaceQuaternary,
    Color? surfaceHover,
    // Text
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textQuaternary,
    Color? textOnBrand,
    // Border
    Color? borderPrimary,
    Color? borderSecondary,
    Color? borderTertiary,
    Color? borderFocus,
    // State
    Color? stateSuccessBg,
    Color? stateSuccessText,
    Color? stateWarningBg,
    Color? stateWarningText,
    Color? stateErrorBg,
    Color? stateErrorText,
    Color? stateInfoBg,
    Color? stateInfoText,
    Color? statePlanBg,
    Color? stateBuildBg,
    // Overlay
    Color? overlayScrim,
    Color? overlayLight,
    Color? overlayMedium,
    // Interactive
    Color? linkDefault,
    Color? linkHover,
    Color? selectionBg,
    Color? accentHover,
    // Scrollbar
    Color? scrollbarDefault,
    Color? scrollbarHover,
    Color? scrollbarActive,
    // Divider
    Color? dividerPrimary,
    Color? dividerSecondary,
    Color? dividerTertiary,
  }) {
    return AppColorExtension(
      // Brand
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandSecondary: brandSecondary ?? this.brandSecondary,
      brandText: brandText ?? this.brandText,
      // Surface
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      surfaceTertiary: surfaceTertiary ?? this.surfaceTertiary,
      surfaceQuaternary: surfaceQuaternary ?? this.surfaceQuaternary,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      // Text
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textQuaternary: textQuaternary ?? this.textQuaternary,
      textOnBrand: textOnBrand ?? this.textOnBrand,
      // Border
      borderPrimary: borderPrimary ?? this.borderPrimary,
      borderSecondary: borderSecondary ?? this.borderSecondary,
      borderTertiary: borderTertiary ?? this.borderTertiary,
      borderFocus: borderFocus ?? this.borderFocus,
      // State
      stateSuccessBg: stateSuccessBg ?? this.stateSuccessBg,
      stateSuccessText: stateSuccessText ?? this.stateSuccessText,
      stateWarningBg: stateWarningBg ?? this.stateWarningBg,
      stateWarningText: stateWarningText ?? this.stateWarningText,
      stateErrorBg: stateErrorBg ?? this.stateErrorBg,
      stateErrorText: stateErrorText ?? this.stateErrorText,
      stateInfoBg: stateInfoBg ?? this.stateInfoBg,
      stateInfoText: stateInfoText ?? this.stateInfoText,
      statePlanBg: statePlanBg ?? this.statePlanBg,
      stateBuildBg: stateBuildBg ?? this.stateBuildBg,
      // Overlay
      overlayScrim: overlayScrim ?? this.overlayScrim,
      overlayLight: overlayLight ?? this.overlayLight,
      overlayMedium: overlayMedium ?? this.overlayMedium,
      // Interactive
      linkDefault: linkDefault ?? this.linkDefault,
      linkHover: linkHover ?? this.linkHover,
      selectionBg: selectionBg ?? this.selectionBg,
      accentHover: accentHover ?? this.accentHover,
      // Scrollbar
      scrollbarDefault: scrollbarDefault ?? this.scrollbarDefault,
      scrollbarHover: scrollbarHover ?? this.scrollbarHover,
      scrollbarActive: scrollbarActive ?? this.scrollbarActive,
      // Divider
      dividerPrimary: dividerPrimary ?? this.dividerPrimary,
      dividerSecondary: dividerSecondary ?? this.dividerSecondary,
      dividerTertiary: dividerTertiary ?? this.dividerTertiary,
    );
  }

  @override
  ThemeExtension<AppColorExtension> lerp(
    covariant ThemeExtension<AppColorExtension>? other,
    double t,
  ) {
    if (other is! AppColorExtension) return this;

    return AppColorExtension(
      // Brand
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandSecondary: Color.lerp(brandSecondary, other.brandSecondary, t)!,
      brandText: Color.lerp(brandText, other.brandText, t)!,
      // Surface
      surfacePrimary: Color.lerp(surfacePrimary, other.surfacePrimary, t)!,
      surfaceSecondary: Color.lerp(
        surfaceSecondary,
        other.surfaceSecondary,
        t,
      )!,
      surfaceTertiary: Color.lerp(surfaceTertiary, other.surfaceTertiary, t)!,
      surfaceQuaternary: Color.lerp(
        surfaceQuaternary,
        other.surfaceQuaternary,
        t,
      )!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      // Text
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textQuaternary: Color.lerp(textQuaternary, other.textQuaternary, t)!,
      textOnBrand: Color.lerp(textOnBrand, other.textOnBrand, t)!,
      // Border
      borderPrimary: Color.lerp(borderPrimary, other.borderPrimary, t)!,
      borderSecondary: Color.lerp(borderSecondary, other.borderSecondary, t)!,
      borderTertiary: Color.lerp(borderTertiary, other.borderTertiary, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      // State
      stateSuccessBg: Color.lerp(stateSuccessBg, other.stateSuccessBg, t)!,
      stateSuccessText: Color.lerp(
        stateSuccessText,
        other.stateSuccessText,
        t,
      )!,
      stateWarningBg: Color.lerp(stateWarningBg, other.stateWarningBg, t)!,
      stateWarningText: Color.lerp(
        stateWarningText,
        other.stateWarningText,
        t,
      )!,
      stateErrorBg: Color.lerp(stateErrorBg, other.stateErrorBg, t)!,
      stateErrorText: Color.lerp(stateErrorText, other.stateErrorText, t)!,
      stateInfoBg: Color.lerp(stateInfoBg, other.stateInfoBg, t)!,
      stateInfoText: Color.lerp(stateInfoText, other.stateInfoText, t)!,
      statePlanBg: Color.lerp(statePlanBg, other.statePlanBg, t)!,
      stateBuildBg: Color.lerp(stateBuildBg, other.stateBuildBg, t)!,
      // Overlay
      overlayScrim: Color.lerp(overlayScrim, other.overlayScrim, t)!,
      overlayLight: Color.lerp(overlayLight, other.overlayLight, t)!,
      overlayMedium: Color.lerp(overlayMedium, other.overlayMedium, t)!,
      // Interactive
      linkDefault: Color.lerp(linkDefault, other.linkDefault, t)!,
      linkHover: Color.lerp(linkHover, other.linkHover, t)!,
      selectionBg: Color.lerp(selectionBg, other.selectionBg, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      // Scrollbar
      scrollbarDefault: Color.lerp(
        scrollbarDefault,
        other.scrollbarDefault,
        t,
      )!,
      scrollbarHover: Color.lerp(scrollbarHover, other.scrollbarHover, t)!,
      scrollbarActive: Color.lerp(scrollbarActive, other.scrollbarActive, t)!,
      // Divider
      dividerPrimary: Color.lerp(dividerPrimary, other.dividerPrimary, t)!,
      dividerSecondary: Color.lerp(
        dividerSecondary,
        other.dividerSecondary,
        t,
      )!,
      dividerTertiary: Color.lerp(dividerTertiary, other.dividerTertiary, t)!,
    );
  }
}

/// Helper extension for easy access
extension AppColorExtensionHelper on BuildContext {
  AppColorExtension get appColors =>
      Theme.of(this).extension<AppColorExtension>()!;
}
