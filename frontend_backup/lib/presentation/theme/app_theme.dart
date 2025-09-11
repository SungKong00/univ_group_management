import 'package:flutter/material.dart';

class AppTheme {
  // 색상 팔레트 (미니멀 & 모던 스타일)
  static const Color primaryColor = Color(0xFF2563EB); // 블루
  static const Color secondaryColor = Color(0xFF10B981); // 그린
  static const Color backgroundColor = Color(0xFFFFFFFF); // 화이트
  static const Color surfaceColor = Color(0xFFF8FAFC); // 라이트 그레이
  static const Color errorColor = Color(0xFFEF4444); // 레드
  static const Color textPrimaryColor = Color(0xFF1F2937); // 다크 그레이
  static const Color textSecondaryColor = Color(0xFF6B7280); // 미디엄 그레이
  static const Color borderColor = Color(0xFFE5E7EB); // 라이트 보더
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      background: backgroundColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: textPrimaryColor,
      onSurface: textPrimaryColor,
      onError: Colors.white,
    ),
    
    // 앱바 테마
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textPrimaryColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: textPrimaryColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    // 버튼 테마
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // 아웃라인 버튼 테마
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // 텍스트 버튼 테마
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // 입력 필드 테마
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(
        color: textSecondaryColor,
        fontSize: 16,
      ),
      labelStyle: const TextStyle(
        color: textSecondaryColor,
        fontSize: 14,
      ),
    ),
    
    // 카드 테마
    cardTheme: CardTheme(
      color: backgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderColor),
      ),
      margin: const EdgeInsets.all(8),
    ),
    
    // 텍스트 테마
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: textPrimaryColor,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: textPrimaryColor,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: textPrimaryColor,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: textPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: textPrimaryColor,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        color: textPrimaryColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        color: textPrimaryColor,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: TextStyle(
        color: textPrimaryColor,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodySmall: TextStyle(
        color: textSecondaryColor,
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
    ),
    
    // 스캐폴드 배경색
    scaffoldBackgroundColor: backgroundColor,
  );
}

// 커스텀 스타일 유틸리티 클래스
class AppStyles {
  // 간격
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // 패딩
  static const EdgeInsets paddingS = EdgeInsets.all(spacingS);
  static const EdgeInsets paddingM = EdgeInsets.all(spacingM);
  static const EdgeInsets paddingL = EdgeInsets.all(spacingL);
  static const EdgeInsets paddingXL = EdgeInsets.all(spacingXL);
  
  static const EdgeInsets paddingHorizontalM = EdgeInsets.symmetric(horizontal: spacingM);
  static const EdgeInsets paddingVerticalM = EdgeInsets.symmetric(vertical: spacingM);
  
  // 보더 라디우스
  static const BorderRadius radiusS = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusM = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusL = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXL = BorderRadius.all(Radius.circular(24));
}