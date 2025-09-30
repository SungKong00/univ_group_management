import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF6A1B9A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFEDE7F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF0F172A);
  static const Color surfaceVariant = Color(0xFFF8FAFC);
  static const Color outline = Color(0xFFE5E7EB);
  static const Color brandStrong = Color(0xFF4A148C);
  static const Color brandLight = Color(0xFF9C27B0);
  static const Color neutral900 = Color(0xFF0F172A);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral600 = Color(0xFF64748B);
  static const Color neutral500 = Color(0xFF94A3B8);
  static const Color neutral400 = Color(0xFFCBD5E1);
  static const Color neutral300 = Color(0xFFE2E8F0);
  static const Color neutral200 = Color(0xFFF1F5F9);
  static const Color neutral100 = Color(0xFFF8FAFC);
  static const Color neutral50 = Color(0xFFFCFCFC);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color focusRing = Color.fromRGBO(106, 27, 154, 0.45);
}

class AppSpacing {
  static const double xxs = 8.0;
  static const double xs = 12.0;
  static const double sm = 16.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
  static const double offsetMin = 96.0;
  static const double offsetMax = 120.0;
}

class AppRadius {
  static const double card = 20.0;
  static const double button = 12.0;
  static const double input = 12.0;
  static const double dialog = 16.0;
}

class AppElevation {
  static const double card = 8.0;
  static const double dialog = 6.0;
}

class AppMotion {
  static const Duration quick = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 160);
  static const Curve easing = Curves.easeOutCubic;
}

class AppTypography {
  static TextTheme buildTextTheme() {
    final base = GoogleFonts.notoSansKrTextTheme();
    return base.copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.neutral900,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.neutral900,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.neutral900,
      ),
      headlineLarge: GoogleFonts.notoSansKr(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.neutral900,
      ),
      headlineMedium: GoogleFonts.notoSansKr(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.neutral900,
      ),
      headlineSmall: GoogleFonts.notoSansKr(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.neutral900,
      ),
      titleLarge: GoogleFonts.notoSansKr(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.neutral900,
      ),
      titleMedium: GoogleFonts.notoSansKr(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.neutral900,
      ),
      bodyLarge: GoogleFonts.notoSansKr(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.neutral700,
      ),
      bodyMedium: GoogleFonts.notoSansKr(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.neutral700,
      ),
      bodySmall: GoogleFonts.notoSansKr(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.neutral600,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.neutral700,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.neutral700,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.neutral600,
      ),
    );
  }
}

class AppButtonStyles {
  static ButtonStyle primary(ColorScheme colorScheme) {
    return FilledButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
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
        colorScheme.primary.withValues(alpha: 0.25),
      ),
      animationDuration: const Duration(milliseconds: 160),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.onPrimary.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return colorScheme.onPrimary.withValues(alpha: 0.08);
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

  static ButtonStyle tonal(ColorScheme colorScheme) {
    return FilledButton.styleFrom(
      backgroundColor: AppColors.primaryContainer,
      foregroundColor: colorScheme.primary,
      minimumSize: const Size.fromHeight(AppComponents.buttonHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      textStyle: GoogleFonts.notoSansKr(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.primary.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return colorScheme.primary.withValues(alpha: 0.08);
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

  static ButtonStyle outlined(ColorScheme colorScheme) {
    return OutlinedButton.styleFrom(
      foregroundColor: colorScheme.primary,
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
      side: const BorderSide(color: AppColors.primary, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.primary.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return colorScheme.primary.withValues(alpha: 0.08);
        }
        return null;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return const BorderSide(color: AppColors.focusRing, width: 2);
        }
        if (states.contains(WidgetState.hovered)) {
          return const BorderSide(color: AppColors.brandStrong, width: 1);
        }
        return const BorderSide(color: AppColors.primary, width: 1);
      }),
    );
  }

  static ButtonStyle google(ColorScheme colorScheme) {
    return OutlinedButton.styleFrom(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.neutral700,
      minimumSize: const Size.fromHeight(AppComponents.buttonHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      textStyle: GoogleFonts.notoSansKr(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.neutral700,
      ),
      side: const BorderSide(color: AppColors.outline, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return AppColors.neutral200.withValues(alpha: 0.8);
        }
        if (states.contains(WidgetState.hovered)) {
          return AppColors.neutral100.withValues(alpha: 0.6);
        }
        return null;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return const BorderSide(color: AppColors.focusRing, width: 2);
        }
        if (states.contains(WidgetState.hovered)) {
          return const BorderSide(color: AppColors.neutral400, width: 1);
        }
        return const BorderSide(color: AppColors.outline, width: 1);
      }),
    );
  }

  static ButtonStyle neutralOutlined(ColorScheme colorScheme) {
    return OutlinedButton.styleFrom(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.neutral700,
      minimumSize: const Size(88, 44),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      textStyle: GoogleFonts.notoSansKr(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      side: const BorderSide(color: AppColors.outline, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return AppColors.neutral300.withValues(alpha: 0.3);
        }
        if (states.contains(WidgetState.hovered)) {
          return AppColors.neutral200.withValues(alpha: 0.3);
        }
        return null;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return const BorderSide(color: AppColors.focusRing, width: 2);
        }
        if (states.contains(WidgetState.hovered)) {
          return const BorderSide(color: AppColors.neutral500, width: 1);
        }
        return const BorderSide(color: AppColors.outline, width: 1);
      }),
    );
  }

  static ButtonStyle error(ColorScheme colorScheme) {
    return FilledButton.styleFrom(
      backgroundColor: AppColors.error,
      foregroundColor: AppColors.onPrimary,
      minimumSize: const Size(88, 44),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      textStyle: GoogleFonts.notoSansKr(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    ).copyWith(
      elevation: const WidgetStatePropertyAll<double>(0),
      animationDuration: const Duration(milliseconds: 120),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return const Color(0xFFDC2626); // Darker red
        }
        if (states.contains(WidgetState.hovered)) {
          return const Color(0xFFDC2626);
        }
        return AppColors.error;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return AppColors.onPrimary.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return AppColors.onPrimary.withValues(alpha: 0.08);
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
}

class AppComponents {
  static const double buttonHeight = 52.0;
  static const double loginCardMaxWidth = 420.0;
  static const double dialogMaxWidth = 360.0;
  static const double logoSize = 56.0;
  static const double logoRadius = 16.0;
  static const double logoIconSize = 28.0;
  static const double infoIconSize = 16.0;
  static const double googleIconSize = 20.0;
  static const double progressIndicatorSize = 20.0;
}

class AppTheme {
  static ThemeData get lightTheme => _buildLightTheme();

  static ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      secondary: AppColors.brandLight,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      outline: AppColors.outline,
      error: AppColors.error,
      brightness: Brightness.light,
    );

    final textTheme = AppTypography.buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: GoogleFonts.notoSansKr().fontFamily,
      scaffoldBackgroundColor: AppColors.surface,
      canvasColor: AppColors.surface,
      cardTheme: CardThemeData(
        elevation: AppElevation.card,
        shadowColor: AppColors.neutral900.withValues(alpha: 0.08),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        ),
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppButtonStyles.primary(colorScheme),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: AppButtonStyles.tonal(colorScheme),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: AppButtonStyles.outlined(colorScheme),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.notoSansKr(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.focusRing, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.neutral900,
        contentTextStyle: GoogleFonts.notoSansKr(
          color: AppColors.onPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }

  static const Color brandPrimary = AppColors.primary;
  static const Color brandStrong = AppColors.brandStrong;
  static const Color brandLight = AppColors.brandLight;
  static const Color onPrimary = AppColors.onPrimary;
  static const Color primaryContainer = AppColors.primaryContainer;
  static const Color surface = AppColors.surface;
  static const Color background = AppColors.surfaceVariant;
  static const Color gray900 = AppColors.neutral900;
  static const Color gray800 = AppColors.neutral800;
  static const Color gray700 = AppColors.neutral700;
  static const Color gray600 = AppColors.neutral600;
  static const Color gray500 = AppColors.neutral500;
  static const Color gray400 = AppColors.neutral400;
  static const Color gray300 = AppColors.neutral300;
  static const Color gray200 = AppColors.neutral200;
  static const Color gray100 = AppColors.neutral100;
  static const Color gray50 = AppColors.neutral50;
  static const Color onSurface = AppColors.onSurface;
  static const Color outline = AppColors.outline;
  static const Color success = AppColors.success;
  static const Color error = AppColors.error;
  static const Color focusRing = AppColors.focusRing;

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

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral900,
    height: 1.2,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral900,
    height: 1.2,
  );
  static const TextStyle displaySmall = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral900,
    height: 1.3,
  );
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
    height: 1.3,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
    height: 1.3,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
    height: 1.35,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
    height: 1.4,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.neutral900,
    height: 1.4,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral700,
    height: 1.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral700,
    height: 1.5,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral600,
    height: 1.5,
  );
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral700,
    height: 1.4,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral700,
    height: 1.4,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral600,
    height: 1.4,
  );

  static TextStyle displayLargeTheme(BuildContext context) => Theme.of(context).textTheme.displayLarge!;
  static TextStyle displayMediumTheme(BuildContext context) => Theme.of(context).textTheme.displayMedium!;
  static TextStyle displaySmallTheme(BuildContext context) => Theme.of(context).textTheme.displaySmall!;
  static TextStyle headlineLargeTheme(BuildContext context) => Theme.of(context).textTheme.headlineLarge!;
  static TextStyle headlineMediumTheme(BuildContext context) => Theme.of(context).textTheme.headlineMedium!;
  static TextStyle headlineSmallTheme(BuildContext context) => Theme.of(context).textTheme.headlineSmall!;
  static TextStyle titleLargeTheme(BuildContext context) => Theme.of(context).textTheme.titleLarge!;
  static TextStyle titleMediumTheme(BuildContext context) => Theme.of(context).textTheme.titleMedium!;
  static TextStyle bodyLargeTheme(BuildContext context) => Theme.of(context).textTheme.bodyLarge!;
  static TextStyle bodyMediumTheme(BuildContext context) => Theme.of(context).textTheme.bodyMedium!;
  static TextStyle bodySmallTheme(BuildContext context) => Theme.of(context).textTheme.bodySmall!;
  static TextStyle labelLargeTheme(BuildContext context) => Theme.of(context).textTheme.labelLarge!;
  static TextStyle labelMediumTheme(BuildContext context) => Theme.of(context).textTheme.labelMedium!;
  static TextStyle labelSmallTheme(BuildContext context) => Theme.of(context).textTheme.labelSmall!;
}
