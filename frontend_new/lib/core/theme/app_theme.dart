import 'package:flutter/material.dart';
import 'extensions/app_color_extension.dart';
import 'extensions/app_typography_extension.dart';
import 'extensions/app_spacing_extension.dart';
import 'extensions/app_responsive_extension.dart';
import 'border_tokens.dart';

/// Linear.app 스타일 Material 3 테마
///
/// 4개의 ThemeExtension(색상, 타이포그래피, 간격, 반응형)과 Material 3 표준을 결합하여 일관된 디자인 시스템을 제공합니다.
///
/// 구조:
/// - Material 3 ColorScheme: 기본 13개 색상
/// - AppColorExtension: 40개 semantic 색상 토큰
/// - Material 3 TextTheme: 13개 표준 스타일
/// - AppTypographyExtension: 3개 추가 스타일 (title8, title9, textMicro)
/// - AppSpacingExtension: 간격 시스템
/// - AppResponsiveExtension: 반응형 토큰
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    // Extension 인스턴스 생성
    final colorExt = AppColorExtension.dark();
    final typographyExt = AppTypographyExtension.dark();
    final spacingExt = AppSpacingExtension.standard();
    final responsiveExt = AppResponsiveExtension.standard();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ========================================================
      // Material 3 ColorScheme (Extension과 연동)
      // ========================================================
      colorScheme: ColorScheme.dark(
        // Primary
        primary: colorExt.brandPrimary,
        onPrimary: colorExt.brandText,
        primaryContainer: colorExt.brandSecondary,
        onPrimaryContainer: colorExt.brandText,

        // Secondary
        secondary: colorExt.brandSecondary,
        onSecondary: colorExt.brandText,
        secondaryContainer: colorExt.surfaceTertiary,
        onSecondaryContainer: colorExt.textPrimary,

        // Surface
        surface: colorExt.surfacePrimary,
        onSurface: colorExt.textPrimary,
        surfaceContainerHighest: colorExt.surfaceSecondary,
        surfaceContainerHigh: colorExt.surfaceTertiary,
        surfaceContainerLow: colorExt.surfaceQuaternary,

        // Error
        error: colorExt.stateErrorBg,
        onError: colorExt.textOnBrand,
        errorContainer: colorExt.stateErrorBg.withValues(alpha: 0.1),
        onErrorContainer: colorExt.stateErrorText,

        // Outline
        outline: colorExt.borderPrimary,
        outlineVariant: colorExt.borderSecondary,

        // Shadow & Scrim
        shadow: colorExt.shadow,
        scrim: colorExt.overlayScrim,

        // Inverse
        inverseSurface: colorExt.textPrimary,
        onInverseSurface: colorExt.surfacePrimary,
        inversePrimary: colorExt.brandSecondary,
      ),

      // ========================================================
      // Scaffold
      // ========================================================
      scaffoldBackgroundColor: colorExt.surfacePrimary,

      // ========================================================
      // Material 3 TextTheme (13개 표준 스타일)
      // ========================================================
      textTheme: _buildTextTheme(colorExt),

      // ========================================================
      // Card 테마
      // ========================================================
      cardTheme: CardThemeData(
        color: colorExt.surfaceSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderTokens.largeRadius(),
          side: BorderSide(color: colorExt.borderPrimary, width: 1),
        ),
      ),

      // ========================================================
      // AppBar 테마
      // ========================================================
      appBarTheme: AppBarTheme(
        backgroundColor: colorExt.surfaceSecondary,
        foregroundColor: colorExt.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 21.0, // title2
          height: 1.33,
          letterSpacing: -0.012 * 21.0,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
          color: colorExt.textPrimary,
        ),
      ),

      // ========================================================
      // Input 테마
      // ========================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorExt.surfaceSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderTokens.mediumRadius(),
          borderSide: BorderSide(color: colorExt.borderPrimary, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderTokens.mediumRadius(),
          borderSide: BorderSide(color: colorExt.borderPrimary, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderTokens.mediumRadius(),
          borderSide: BorderSide(color: colorExt.borderFocus, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderTokens.mediumRadius(),
          borderSide: BorderSide(color: colorExt.stateErrorBg, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderTokens.mediumRadius(),
          borderSide: BorderSide(color: colorExt.stateErrorBg, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacingExt.medium,
          vertical: spacingExt.small,
        ),
        hintStyle: TextStyle(
          fontSize: 15.0, // textRegular
          height: 1.6,
          letterSpacing: -0.011 * 15.0,
          fontWeight: FontWeight.w400,
          fontFamily: 'Inter',
          color: colorExt.textTertiary,
        ),
      ),

      // ========================================================
      // 버튼 테마
      // ========================================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorExt.brandPrimary,
          foregroundColor: colorExt.brandText,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: spacingExt.large,
            vertical: spacingExt.small,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderTokens.mediumRadius(),
          ),
          textStyle: TextStyle(
            fontSize: 15.0,
            height: 1.6,
            letterSpacing: -0.011 * 15.0,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorExt.textPrimary,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: spacingExt.large,
            vertical: spacingExt.small,
          ),
          side: BorderSide(color: colorExt.borderSecondary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderTokens.mediumRadius(),
          ),
          textStyle: TextStyle(
            fontSize: 15.0,
            height: 1.6,
            letterSpacing: -0.011 * 15.0,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorExt.textPrimary,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: spacingExt.large,
            vertical: spacingExt.small,
          ),
          textStyle: TextStyle(
            fontSize: 15.0,
            height: 1.6,
            letterSpacing: -0.011 * 15.0,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),

      // ========================================================
      // Divider 테마
      // ========================================================
      dividerTheme: DividerThemeData(
        color: colorExt.dividerPrimary,
        thickness: 1,
        space: 1,
      ),

      // ========================================================
      // Icon 테마
      // ========================================================
      iconTheme: IconThemeData(color: colorExt.textSecondary, size: 20),

      // ========================================================
      // ThemeExtensions 등록
      // ========================================================
      extensions: [colorExt, typographyExt, spacingExt, responsiveExt],
    );
  }

  /// Material 3 TextTheme 13개 스타일 정의
  ///
  /// Linear 디자인 시스템의 title1~7, textLarge, textRegular, textSmall을 Material 3 표준에 매핑합니다.
  ///
  /// Material 3 표준:
  /// - displayLarge, displayMedium, displaySmall (초대형 제목)
  /// - headlineLarge, headlineMedium, headlineSmall (제목)
  /// - titleLarge, titleMedium, titleSmall (소제목)
  /// - bodyLarge, bodyMedium, bodySmall (본문)
  /// - labelLarge, labelMedium, labelSmall (레이블)
  ///
  /// Linear 매핑:
  /// - displayLarge ← title7 (3.5rem)
  /// - displayMedium ← title6 (3rem)
  /// - displaySmall ← title5 (2.5rem)
  /// - headlineLarge ← title4 (2rem)
  /// - headlineMedium ← title3 (1.5rem)
  /// - headlineSmall ← title2 (1.3125rem)
  /// - titleLarge ← title1 (1.0625rem)
  /// - titleMedium ← textLarge (1.0625rem, weight 400)
  /// - titleSmall ← textRegular (0.9375rem)
  /// - bodyLarge ← textLarge (1.0625rem)
  /// - bodyMedium ← textRegular (0.9375rem)
  /// - bodySmall ← textSmall (0.875rem)
  /// - labelLarge ← textRegular (0.9375rem)
  ///
  /// Extension 추가 3개 (AppTypographyExtension):
  /// - title8 (4rem)
  /// - title9 (4.5rem)
  /// - textMicro (0.75rem)
  static TextTheme _buildTextTheme(AppColorExtension colorExt) {
    const fontFamily = 'Inter';

    return TextTheme(
      // Display (초대형 제목)
      displayLarge: TextStyle(
        fontSize: 56.0, // title7: 3.5rem
        height: 1.1,
        letterSpacing: -0.022 * 56.0,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        color: colorExt.textPrimary,
      ),

      displayMedium: TextStyle(
        fontSize: 48.0, // title6: 3rem
        height: 1.1,
        letterSpacing: -0.022 * 48.0,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        color: colorExt.textPrimary,
      ),

      displaySmall: TextStyle(
        fontSize: 40.0, // title5: 2.5rem
        height: 1.1,
        letterSpacing: -0.022 * 40.0,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        color: colorExt.textPrimary,
      ),

      // Headline (제목)
      headlineLarge: TextStyle(
        fontSize: 32.0, // title4: 2rem
        height: 1.125,
        letterSpacing: -0.022 * 32.0,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        color: colorExt.textPrimary,
      ),

      headlineMedium: TextStyle(
        fontSize: 24.0, // title3: 1.5rem
        height: 1.33,
        letterSpacing: -0.012 * 24.0,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        color: colorExt.textPrimary,
      ),

      headlineSmall: TextStyle(
        fontSize: 21.0, // title2: 1.3125rem
        height: 1.33,
        letterSpacing: -0.012 * 21.0,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        color: colorExt.textPrimary,
      ),

      // Title (소제목)
      titleLarge: TextStyle(
        fontSize: 17.0, // title1: 1.0625rem
        height: 1.4,
        letterSpacing: -0.012 * 17.0,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        color: colorExt.textPrimary,
      ),

      titleMedium: const TextStyle(
        fontSize: 17.0, // textLarge: 1.0625rem
        height: 1.6,
        letterSpacing: 0,
        fontWeight: FontWeight.w400,
        fontFamily: fontFamily,
      ).copyWith(color: colorExt.textPrimary),

      titleSmall: const TextStyle(
        fontSize: 15.0, // textRegular: 0.9375rem
        height: 1.6,
        letterSpacing: -0.011 * 15.0,
        fontWeight: FontWeight.w400,
        fontFamily: fontFamily,
      ).copyWith(color: colorExt.textSecondary),

      // Body (본문)
      bodyLarge: const TextStyle(
        fontSize: 17.0, // textLarge: 1.0625rem
        height: 1.6,
        letterSpacing: 0,
        fontWeight: FontWeight.w400,
        fontFamily: fontFamily,
      ).copyWith(color: colorExt.textPrimary),

      bodyMedium: const TextStyle(
        fontSize: 15.0, // textRegular: 0.9375rem
        height: 1.6,
        letterSpacing: -0.011 * 15.0,
        fontWeight: FontWeight.w400,
        fontFamily: fontFamily,
      ).copyWith(color: colorExt.textSecondary),

      bodySmall: const TextStyle(
        fontSize: 14.0, // textSmall: 0.875rem
        height: 1.5,
        letterSpacing: -0.013 * 14.0,
        fontWeight: FontWeight.w400,
        fontFamily: fontFamily,
      ).copyWith(color: colorExt.textTertiary),

      // Label (레이블)
      labelLarge: TextStyle(
        fontSize: 15.0, // textRegular: 0.9375rem
        height: 1.6,
        letterSpacing: -0.011 * 15.0,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        color: colorExt.textPrimary,
      ),

      labelMedium: TextStyle(
        fontSize: 14.0, // textSmall: 0.875rem
        height: 1.5,
        letterSpacing: -0.013 * 14.0,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        color: colorExt.textSecondary,
      ),

      labelSmall: TextStyle(
        fontSize: 13.0, // textMini: 0.8125rem
        height: 1.5,
        letterSpacing: -0.01 * 13.0,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        color: colorExt.textTertiary,
      ),
    );
  }
}
