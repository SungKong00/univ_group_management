import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_theme.dart';
import 'color_tokens.dart';

/// 버튼 스타일 헬퍼 클래스
///
/// 토스 디자인 철학 기반 버튼 스타일 제공
/// - primary: Action 컬러 기반 주요 CTA 버튼
/// - outlined: 보조 액션 버튼
/// - tonal: 약한 강조 버튼
/// - error: 위험/삭제 액션 버튼
/// - google: Google OAuth 전용 버튼
/// - neutralOutlined: 중립적인 외곽선 버튼
class AppButtonStyles {
  AppButtonStyles._();

  /// Primary Action 버튼 스타일
  /// 가장 중요한 CTA에 사용 (Action Blue #1E6FFF)
  static ButtonStyle primary(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return FilledButton.styleFrom(
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

  /// Outlined 버튼 스타일
  /// 보조 액션에 사용
  static ButtonStyle outlined(ColorScheme colorScheme) {
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

  /// Tonal 버튼 스타일
  /// 약한 강조가 필요한 액션에 사용
  static ButtonStyle tonal(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return FilledButton.styleFrom(
      backgroundColor: isDark
          ? AppColors.action.withValues(alpha: 0.12)
          : AppColors.action.withValues(alpha: 0.08),
      foregroundColor: AppColors.action,
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
      elevation: 0,
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return AppColors.action.withValues(alpha: 0.2);
        }
        if (states.contains(WidgetState.hovered)) {
          return AppColors.action.withValues(alpha: 0.12);
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

  /// Error 버튼 스타일
  /// 위험한 액션 (삭제, 로그아웃 등)에 사용
  static ButtonStyle error(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return FilledButton.styleFrom(
      backgroundColor: AppColors.error,
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
        return AppColors.error;
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

  /// Google 로그인 버튼 스타일
  /// Google 공식 브랜드 가이드라인 100% 준수
  /// - Light: 배경 #FFFFFF, 경계선 #747775, 텍스트 #1F1F1F
  /// - Dark: 배경 #131314, 경계선 #8E918F, 텍스트 #E3E3E3
  /// - 로고 패딩: 12px (왼쪽), 10px (오른쪽)
  static ButtonStyle google(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return OutlinedButton.styleFrom(
      foregroundColor: isDark ? ColorTokens.googleTextDark : ColorTokens.googleTextLight,
      backgroundColor: isDark ? ColorTokens.googleBgDark : Colors.white,
      minimumSize: const Size.fromHeight(AppComponents.buttonHeight),
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,   // 12px (Google 가이드라인)
        right: AppSpacing.xs,  // 12px
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      textStyle: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w500,  // Medium
        height: 1.4,
        letterSpacing: 0.25,
      ),
      side: BorderSide(
        color: isDark ? ColorTokens.googleBorderDark : ColorTokens.googleBorderLight,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04);
        }
        if (states.contains(WidgetState.hovered)) {
          return isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.02);
        }
        return null;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return const BorderSide(color: AppColors.focusRing, width: 2);
        }
        return BorderSide(
          color: isDark ? ColorTokens.googleBorderDark : ColorTokens.googleBorderLight,
          width: 1,
        );
      }),
    );
  }

  /// Neutral Outlined 버튼 스타일
  /// 중립적인 보조 액션에 사용
  static ButtonStyle neutralOutlined(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final neutralColor = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return OutlinedButton.styleFrom(
      foregroundColor: neutralColor,
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
      side: BorderSide(color: colorScheme.outline, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return neutralColor.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return neutralColor.withValues(alpha: 0.08);
        }
        return null;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return const BorderSide(color: AppColors.focusRing, width: 2);
        }
        if (states.contains(WidgetState.hovered)) {
          return BorderSide(color: neutralColor, width: 1);
        }
        return BorderSide(color: colorScheme.outline, width: 1);
      }),
    );
  }
}