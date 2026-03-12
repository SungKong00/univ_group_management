import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// ImageGallery 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class ImageGalleryColors {
  /// 배경 색상
  final Color background;

  /// 이미지 배경 색상 (로딩/에러 시)
  final Color imageBackground;

  /// 오버레이 색상
  final Color overlay;

  /// 라이트박스 배경
  final Color lightboxBackground;

  /// 라이트박스 컨트롤 색상
  final Color lightboxControl;

  /// 라이트박스 컨트롤 호버
  final Color lightboxControlHover;

  /// 캡션 배경
  final Color captionBackground;

  /// 캡션 텍스트
  final Color captionText;

  /// 인디케이터 활성
  final Color indicatorActive;

  /// 인디케이터 비활성
  final Color indicatorInactive;

  /// 테두리 색상
  final Color border;

  const ImageGalleryColors({
    required this.background,
    required this.imageBackground,
    required this.overlay,
    required this.lightboxBackground,
    required this.lightboxControl,
    required this.lightboxControlHover,
    required this.captionBackground,
    required this.captionText,
    required this.indicatorActive,
    required this.indicatorInactive,
    required this.border,
  });

  /// 기본 색상 팩토리
  factory ImageGalleryColors.from(AppColorExtension c) {
    return ImageGalleryColors(
      background: c.surfacePrimary,
      imageBackground: c.surfaceTertiary,
      overlay: c.overlayMedium,
      lightboxBackground: c.overlayScrim,
      lightboxControl: c.textOnBrand.withValues(alpha: 0.8),
      lightboxControlHover: c.textOnBrand,
      captionBackground: c.overlayMedium,
      captionText: c.textOnBrand,
      indicatorActive: c.brandPrimary,
      indicatorInactive: c.surfaceTertiary,
      border: c.borderPrimary,
    );
  }
}
