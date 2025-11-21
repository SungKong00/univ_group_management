import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Carousel 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class CarouselColors {
  /// 캐러셀 배경
  final Color background;

  /// 인디케이터 비활성 색상
  final Color indicatorInactive;

  /// 인디케이터 활성 색상
  final Color indicatorActive;

  /// 이전/다음 버튼 배경
  final Color navButtonBackground;

  /// 이전/다음 버튼 아이콘
  final Color navButtonIcon;

  /// 이전/다음 버튼 호버 배경
  final Color navButtonBackgroundHover;

  const CarouselColors({
    required this.background,
    required this.indicatorInactive,
    required this.indicatorActive,
    required this.navButtonBackground,
    required this.navButtonIcon,
    required this.navButtonBackgroundHover,
  });

  /// 기본 Carousel 스타일
  factory CarouselColors.standard(AppColorExtension c) {
    return CarouselColors(
      background: c.surfacePrimary,
      indicatorInactive: c.borderSecondary,
      indicatorActive: c.brandPrimary,
      navButtonBackground: c.surfaceSecondary,
      navButtonIcon: c.textPrimary,
      navButtonBackgroundHover: c.surfaceTertiary,
    );
  }

  /// 투명 배경 Carousel 스타일
  factory CarouselColors.transparent(AppColorExtension c) {
    return CarouselColors(
      background: Colors.transparent,
      indicatorInactive: c.overlayLight,
      indicatorActive: c.brandPrimary,
      navButtonBackground: c.overlayMedium,
      navButtonIcon: c.textPrimary,
      navButtonBackgroundHover: c.overlayScrim.withValues(alpha: 0.5),
    );
  }
}
