import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// ========== Spacing System (8px 기반) ==========
class AppSpacing {
  AppSpacing._();

  static const double xxs = 8.0;
  static const double xs = 12.0;
  static const double sm = 16.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
  static const double offsetMin = 96.0;
  static const double offsetMax = 120.0;
}

// ========== Border Radius ==========
class AppRadius {
  AppRadius._();

  static const double card = 20.0;
  static const double button = 12.0;
  static const double input = 12.0;
  static const double dialog = 16.0;
}

// ========== Elevation ==========
class AppElevation {
  AppElevation._();

  static const double card = 8.0;
  static const double dialog = 6.0;
}

// ========== Motion / Animation ==========
class AppMotion {
  AppMotion._();

  static const Duration quick = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 160);
  static const Curve easing = Curves.easeOutCubic;
}

// ========== Component Specs ==========
class AppComponents {
  AppComponents._();

  // Button
  static const double buttonHeight = 52.0;

  // Card
  static const double loginCardMaxWidth = 420.0;
  static const double dialogMaxWidth = 360.0;
  static const double actionCardIconSize = 32.0;
  static const double groupCardWidth = 200.0;

  // Logo
  static const double logoSize = 56.0;
  static const double logoRadius = 16.0;
  static const double logoIconSize = 28.0;

  // Icon
  static const double infoIconSize = 16.0;
  static const double googleIconSize = 24.0;
  static const double activityIconSize = 20.0;

  // Avatar
  static const double avatarSmall = 16.0;
  static const double avatarMedium = 20.0;

  // Indicator
  static const double progressIndicatorSize = 20.0;

  // Badge
  static const double badgeRadius = 12.0;
}

// ========== Typography ==========
class AppTypography {
  AppTypography._();

  static TextTheme buildTextTheme() {
    final base = GoogleFonts.notoSansKrTextTheme();
    return base.copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      headlineLarge: GoogleFonts.notoSansKr(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.notoSansKr(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.notoSansKr(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      titleLarge: GoogleFonts.notoSansKr(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.notoSansKr(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.notoSansKr(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.notoSansKr(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.notoSansKr(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
    );
  }
}

// ========== Main Theme Class ==========
class AppTheme {
  AppTheme._();

  // ========== Light Theme ==========
  static ThemeData get lightTheme => _buildLightTheme();

  static ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.light(
      // Brand (메인 퍼플 #5C068C)
      primary: AppColors.brand,
      onPrimary: Colors.white,
      primaryContainer: AppColors.brandContainerLight,

      // Action (하이라이트 블루 #1E6FFF)
      secondary: AppColors.action,
      onSecondary: Colors.white,

      // Surface
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightOnSurface,

      // Feedback
      error: AppColors.error,
      onError: Colors.white,

      // Outline
      outline: AppColors.lightOutline,

      brightness: Brightness.light,
    );

    return _buildTheme(colorScheme);
  }

  // ========== Dark Theme ==========
  static ThemeData get darkTheme => _buildDarkTheme();

  static ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.dark(
      // Brand (메인 퍼플 #5C068C)
      primary: AppColors.brand,
      onPrimary: Colors.white,
      primaryContainer: AppColors.brandContainerDark,

      // Action (하이라이트 블루 #1E6FFF)
      secondary: AppColors.action,
      onSecondary: Colors.white,

      // Surface
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,

      // Feedback
      error: AppColors.error,
      onError: Colors.white,

      // Outline
      outline: AppColors.darkOutline,

      brightness: Brightness.dark,
    );

    return _buildTheme(colorScheme);
  }

  // ========== Common Theme Builder ==========
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final textTheme = AppTypography.buildTextTheme();
    final isDark = colorScheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: GoogleFonts.notoSansKr().fontFamily,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,

      // ========== Card Theme ==========
      cardTheme: CardThemeData(
        elevation: AppElevation.card,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        ),
        color: isDark ? AppColors.darkElevated : Colors.white,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      // ========== Button Themes ==========
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buildActionButtonStyle(colorScheme),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buildBrandButtonStyle(colorScheme),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buildOutlinedButtonStyle(colorScheme),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.action,
          textStyle: GoogleFonts.notoSansKr(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ),

      // ========== Input Decoration Theme ==========
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightOutline.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.focusRing, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),

      // ========== SnackBar Theme ==========
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkElevated : Color(0xFF1E293B),
        contentTextStyle: GoogleFonts.notoSansKr(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ========== Divider Theme ==========
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
      ),

      // ========== Progress Indicator Theme ==========
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.action,
      ),
    );
  }

  // ========== Button Style Builders ==========

  /// Action 버튼 (CTA - 하이라이트 블루 #1E6FFF)
  /// 가장 중요한 Call-to-Action에 사용
  static ButtonStyle _buildActionButtonStyle(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.action,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(AppComponents.buttonHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      textStyle: GoogleFonts.notoSansKr(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    ).copyWith(
      elevation: const WidgetStatePropertyAll<double>(2),
      shadowColor: WidgetStatePropertyAll<Color>(
        AppColors.action.withValues(alpha: 0.25),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return isDark
              ? AppColors.disabledBgDark
              : AppColors.disabledBgLight;
        }
        if (states.contains(WidgetState.hovered)) {
          return AppColors.actionHover;
        }
        return AppColors.action;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return isDark
              ? AppColors.disabledTextDark
              : AppColors.disabledTextLight;
        }
        return Colors.white;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return Colors.white.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return Colors.white.withValues(alpha: 0.08);
        }
        return null;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return const BorderSide(color: AppColors.focusRing, width: 2);
        }
        return null;
      }),
    );
  }

  /// Brand 버튼 (브랜드 강조 - 메인 퍼플 #5C068C)
  /// 브랜드 정체성이 중요한 액션에 사용 (로고 주변, 주요 브랜드 액션)
  static ButtonStyle _buildBrandButtonStyle(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return FilledButton.styleFrom(
      backgroundColor: AppColors.brand,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(AppComponents.buttonHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      textStyle: GoogleFonts.notoSansKr(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return isDark
              ? AppColors.disabledBgDark
              : AppColors.disabledBgLight;
        }
        return AppColors.brand;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return isDark
              ? AppColors.disabledTextDark
              : AppColors.disabledTextLight;
        }
        return Colors.white;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return const BorderSide(color: AppColors.focusRing, width: 2);
        }
        return null;
      }),
    );
  }

  /// Outlined 버튼 (보조 액션)
  static ButtonStyle _buildOutlinedButtonStyle(ColorScheme colorScheme) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.action,
      minimumSize: const Size.fromHeight(AppComponents.buttonHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      textStyle: GoogleFonts.notoSansKr(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      side: const BorderSide(color: AppColors.action, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return AppColors.action.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return AppColors.action.withValues(alpha: 0.08);
        }
        return null;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return const BorderSide(color: AppColors.focusRing, width: 2);
        }
        if (states.contains(WidgetState.hovered)) {
          return const BorderSide(color: AppColors.actionHover, width: 1);
        }
        return const BorderSide(color: AppColors.action, width: 1);
      }),
    );
  }

  // ========== Deprecated (하위 호환성 유지) ==========
  @Deprecated('Use AppColors.brand instead')
  static const Color brandPrimary = Color(0xFF5C068C);

  @Deprecated('Use AppColors.brand instead')
  static const Color brandStrong = Color(0xFF5C068C);

  @Deprecated('Use AppColors.brand instead')
  static const Color brandLight = Color(0xFF9C27B0);

  @Deprecated('Use Theme.of(context).colorScheme.onPrimary instead')
  static const Color onPrimary = Colors.white;

  @Deprecated('Use Theme.of(context).colorScheme.primaryContainer instead')
  static const Color primaryContainer = Color(0xFFF3E5F5);

  @Deprecated('Use Theme.of(context).colorScheme.surface instead')
  static const Color surface = Colors.white;

  @Deprecated('Use AppColors.lightBackground instead')
  static const Color background = Color(0xFFF8FAFC);

  @Deprecated('Use AppColors.lightOnSurface instead')
  static const Color gray900 = Color(0xFF121212);

  @Deprecated('Use AppColors.lightSecondary instead')
  static const Color gray700 = Color(0xFF6C757D);

  @Deprecated('Use AppColors.lightSecondary instead')
  static const Color gray600 = Color(0xFF6C757D);

  @Deprecated('Use AppColors.disabledTextLight instead')
  static const Color gray500 = Color(0xFFADB5BD);

  @Deprecated('Use AppColors.disabledBgLight instead')
  static const Color gray300 = Color(0xFFE9ECEF);

  @Deprecated('Use AppColors.lightOutline instead')
  static const Color gray200 = Color(0xFFF1F5F9);

  @Deprecated('Use AppColors.lightBackground instead')
  static const Color gray100 = Color(0xFFF8FAFC);

  @Deprecated('Use Theme.of(context).colorScheme.outline instead')
  static const Color outline = Color(0xFFE5E7EB);

  @Deprecated('Use AppColors.success instead')
  static const Color success = Color(0xFF00D9B2);

  @Deprecated('Use AppColors.error instead')
  static const Color error = Color(0xFFE63946);

  @Deprecated('Use AppColors.focusRing instead')
  static const Color focusRing = Color.fromRGBO(92, 6, 140, 0.45);

  // ========== Legacy Theme Helpers (유지) ==========
  static const double spacing8 = AppSpacing.xxs;
  static const double spacing12 = AppSpacing.xs;
  static const double spacing16 = AppSpacing.sm;
  static const double spacing24 = AppSpacing.md;
  static const double spacing32 = AppSpacing.lg;
  static const double spacing48 = AppSpacing.xl;
  static const double spacing96 = AppSpacing.offsetMin;
  static const double spacing120 = AppSpacing.offsetMax;

  static const double radiusCard = AppRadius.card;
  static const double radiusButton = AppRadius.button;
  static const double radiusInput = AppRadius.input;

  static const double shadowCard = AppElevation.card;

  // Typography Helpers
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Context-based helpers
  static TextStyle displayLargeTheme(BuildContext context) =>
      Theme.of(context).textTheme.displayLarge!;
  static TextStyle displayMediumTheme(BuildContext context) =>
      Theme.of(context).textTheme.displayMedium!;
  static TextStyle displaySmallTheme(BuildContext context) =>
      Theme.of(context).textTheme.displaySmall!;
  static TextStyle headlineSmallTheme(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall!;
  static TextStyle headlineMediumTheme(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium!;
  static TextStyle titleLargeTheme(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!;
  static TextStyle titleMediumTheme(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!;
  static TextStyle bodyLargeTheme(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!;
  static TextStyle bodyMediumTheme(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!;
  static TextStyle bodySmallTheme(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!;
  static TextStyle labelSmallTheme(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall!;
}
