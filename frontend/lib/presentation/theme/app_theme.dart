import 'package:flutter/material.dart';

class AppTheme {
  // Colors (Toss style)
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFAFBFC);
  static const Color onTextPrimary = Color(0xFF111827);
  static const Color onTextSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // Status chips
  static const Color success = Color(0xFF16A34A);
  static const Color info = Color(0xFF3B82F6);
  static const Color warn = Color(0xFFF59E0B);
  static const Color neutral = Color(0xFF9CA3AF);

  static const Color error = Color(0xFFEF4444);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primary,
      surface: surface,
      background: background,
      onSurface: onTextPrimary,
    ),
    scaffoldBackgroundColor: background,
    textTheme: const TextTheme(
      // H3 18/Semi
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.45, color: onTextPrimary),
      // Body 14–15/Reg
      bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.6, color: onTextPrimary),
      bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.6, color: onTextSecondary),
      // Caption 12/Reg
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.45, color: onTextSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1),
      ),
    ),
  );

  // 호환용 별칭 (기존 코드와의 접점)
  static const Color textSecondaryColor = onTextSecondary;
  static const Color errorColor = error;
}

class AppStyles {
  // Spacing (8pt grid)
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;

  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const BorderRadius radius12 = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radius16 = BorderRadius.all(Radius.circular(16));

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.04),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // 호환용 별칭 (기존 코드와의 접점)
  static const EdgeInsets paddingL = EdgeInsets.all(24);
  static const BorderRadius radiusM = radius12;
}
