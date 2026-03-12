import 'package:flutter/material.dart';

/// Material 3 TextTheme 외의 추가 타이포그래피 스타일
///
/// Material 3는 13개 표준 스타일을 제공하지만, Linear 디자인 시스템은 16개를 사용합니다.
/// 이 Extension은 Material 3에 포함되지 않은 3개 스타일(title8, title9, textMicro)을 제공합니다.
///
/// Material 3 표준 13개 (ThemeData.textTheme에 포함):
/// - displayLarge (title7에 매핑)
/// - displayMedium (title6에 매핑)
/// - displaySmall (title5에 매핑)
/// - headlineLarge (title4에 매핑)
/// - headlineMedium (title3에 매핑)
/// - headlineSmall (title2에 매핑)
/// - titleLarge (title1에 매핑)
/// - titleMedium
/// - titleSmall
/// - bodyLarge (textLarge에 매핑)
/// - bodyMedium (textRegular에 매핑)
/// - bodySmall (textSmall에 매핑)
/// - labelLarge
///
/// Extension 추가 6개 (Material 3 외):
/// - title8 (4rem, 64px)
/// - title9 (4.5rem, 72px)
/// - textMicro (0.75rem, 12px)
/// - buttonSmall (0.8125rem, 13px)
/// - buttonMedium (0.875rem, 14px)
/// - buttonLarge (0.9375rem, 15px)
class AppTypographyExtension extends ThemeExtension<AppTypographyExtension> {
  /// title8: 4rem (64px)
  ///
  /// 히어로 섹션, 랜딩 페이지 초대형 제목용
  final TextStyle title8;

  /// title9: 4.5rem (72px)
  ///
  /// 최대 크기 제목, 특별 프로모션용
  final TextStyle title9;

  /// textMicro: 0.75rem (12px)
  ///
  /// 극소형 텍스트, 저작권 정보, 미세 주석용
  final TextStyle textMicro;

  /// buttonSmall: 0.8125rem (13px)
  ///
  /// 소형 버튼 텍스트 (AppButton small size)
  final TextStyle buttonSmall;

  /// buttonMedium: 0.875rem (14px)
  ///
  /// 중형 버튼 텍스트 (AppButton medium size)
  final TextStyle buttonMedium;

  /// buttonLarge: 0.9375rem (15px)
  ///
  /// 대형 버튼 텍스트 (AppButton large size)
  final TextStyle buttonLarge;

  const AppTypographyExtension({
    required this.title8,
    required this.title9,
    required this.textMicro,
    required this.buttonSmall,
    required this.buttonMedium,
    required this.buttonLarge,
  });

  /// Dark theme 기본 타이포그래피
  factory AppTypographyExtension.dark() {
    const fontFamily = 'Inter';

    return AppTypographyExtension(
      title8: TextStyle(
        fontSize: 64.0, // 4rem
        height: 1.06,
        letterSpacing: -0.022 * 64.0,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        fontVariations: const [FontVariation('opsz', 32)], // auto → 큰 크기용
      ),
      title9: TextStyle(
        fontSize: 72.0, // 4.5rem
        height: 1.0,
        letterSpacing: -0.022 * 72.0,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        fontVariations: const [FontVariation('opsz', 32)],
      ),
      textMicro: TextStyle(
        fontSize: 12.0, // 0.75rem
        height: 1.4,
        letterSpacing: 0,
        fontWeight: FontWeight.w400,
        fontFamily: fontFamily,
        fontVariations: [FontVariation('opsz', 12)], // 작은 크기용
      ),
      buttonSmall: TextStyle(
        fontSize: 13.0, // 0.8125rem
        height: 1.0,
        letterSpacing: -0.01 * 13.0,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
      ),
      buttonMedium: TextStyle(
        fontSize: 14.0, // 0.875rem
        height: 1.0,
        letterSpacing: -0.013 * 14.0,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
      ),
      buttonLarge: TextStyle(
        fontSize: 15.0, // 0.9375rem
        height: 1.0,
        letterSpacing: -0.011 * 15.0,
        fontWeight: FontWeight.w700,
        fontFamily: fontFamily,
      ),
    );
  }

  @override
  ThemeExtension<AppTypographyExtension> copyWith({
    TextStyle? title8,
    TextStyle? title9,
    TextStyle? textMicro,
    TextStyle? buttonSmall,
    TextStyle? buttonMedium,
    TextStyle? buttonLarge,
  }) {
    return AppTypographyExtension(
      title8: title8 ?? this.title8,
      title9: title9 ?? this.title9,
      textMicro: textMicro ?? this.textMicro,
      buttonSmall: buttonSmall ?? this.buttonSmall,
      buttonMedium: buttonMedium ?? this.buttonMedium,
      buttonLarge: buttonLarge ?? this.buttonLarge,
    );
  }

  @override
  ThemeExtension<AppTypographyExtension> lerp(
    covariant ThemeExtension<AppTypographyExtension>? other,
    double t,
  ) {
    if (other is! AppTypographyExtension) return this;

    return AppTypographyExtension(
      title8: TextStyle.lerp(title8, other.title8, t)!,
      title9: TextStyle.lerp(title9, other.title9, t)!,
      textMicro: TextStyle.lerp(textMicro, other.textMicro, t)!,
      buttonSmall: TextStyle.lerp(buttonSmall, other.buttonSmall, t)!,
      buttonMedium: TextStyle.lerp(buttonMedium, other.buttonMedium, t)!,
      buttonLarge: TextStyle.lerp(buttonLarge, other.buttonLarge, t)!,
    );
  }
}

/// Helper extension for easy access
extension AppTypographyExtensionHelper on BuildContext {
  AppTypographyExtension get appTypography =>
      Theme.of(this).extension<AppTypographyExtension>()!;
}
