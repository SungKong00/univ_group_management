import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Pricing Card 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
/// 테마 변경 시 AppColorExtension만 수정하면 자동으로 업데이트됩니다.
class PricingCardColors {
  /// 카드 배경
  final Color background;

  /// 호버 시 배경
  final Color backgroundHover;

  /// 카드 테두리
  final Color border;

  /// 강조 테두리 (프리미엄 플랜 등)
  final Color borderHighlight;

  /// 제목 텍스트
  final Color title;

  /// 부제 텍스트
  final Color subtitle;

  /// 가격 텍스트
  final Color price;

  /// 가격 단위 텍스트 (/month 등)
  final Color priceUnit;

  /// 태그 배경 (Popular, Best Value 등)
  final Color tagBg;

  /// 태그 텍스트
  final Color tagText;

  /// 기능 목록 텍스트
  final Color featureText;

  /// 활성화된 기능 아이콘
  final Color featureIconEnabled;

  /// 비활성화된 기능 아이콘
  final Color featureIconDisabled;

  const PricingCardColors({
    required this.background,
    required this.backgroundHover,
    required this.border,
    required this.borderHighlight,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.priceUnit,
    required this.tagBg,
    required this.tagText,
    required this.featureText,
    required this.featureIconEnabled,
    required this.featureIconDisabled,
  });

  /// 일반 플랜용 색상 (semantic 토큰 조합)
  factory PricingCardColors.standard(AppColorExtension c) {
    return PricingCardColors(
      background: c.surfaceSecondary,
      backgroundHover: c.surfaceHover,
      border: c.borderPrimary,
      borderHighlight: c.brandPrimary,
      title: c.textPrimary,
      subtitle: c.textSecondary,
      price: c.textPrimary,
      priceUnit: c.textTertiary,
      tagBg: c.overlayLight,
      tagText: c.textSecondary,
      featureText: c.textSecondary,
      featureIconEnabled: c.stateSuccessText,
      featureIconDisabled: c.textQuaternary,
    );
  }

  /// 프리미엄 플랜용 색상 (강조 스타일)
  factory PricingCardColors.premium(AppColorExtension c) {
    return PricingCardColors(
      background: c.surfaceTertiary,
      backgroundHover: c.surfaceQuaternary,
      border: c.brandPrimary,
      borderHighlight: c.brandPrimary,
      title: c.brandText,
      subtitle: c.textSecondary,
      price: c.brandPrimary,
      priceUnit: c.textTertiary,
      tagBg: c.brandPrimary,
      tagText: c.brandText,
      featureText: c.textPrimary,
      featureIconEnabled: c.brandPrimary,
      featureIconDisabled: c.textQuaternary,
    );
  }

  /// Enterprise 플랜용 색상 (최고급 스타일)
  factory PricingCardColors.enterprise(AppColorExtension c) {
    return PricingCardColors(
      background: c.surfaceQuaternary,
      backgroundHover: c.surfaceTertiary,
      border: c.borderTertiary,
      borderHighlight: c.stateInfoBg,
      title: c.textPrimary,
      subtitle: c.textSecondary,
      price: c.stateInfoText,
      priceUnit: c.textTertiary,
      tagBg: c.stateInfoBg,
      tagText: c.textOnBrand,
      featureText: c.textPrimary,
      featureIconEnabled: c.stateInfoText,
      featureIconDisabled: c.textQuaternary,
    );
  }
}
