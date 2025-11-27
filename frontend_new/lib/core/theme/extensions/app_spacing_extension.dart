import 'package:flutter/material.dart';

/// 디자인 시스템 간격(Spacing) 토큰
///
/// 4dp 그리드 시스템을 기반으로 한 일관된 간격 체계를 const로 정의합니다.
/// xs(4px)부터 gargantuan(128px)까지 10개 계층의 간격과 특수 용도 간격을 제공합니다.
class AppSpacingExtension extends ThemeExtension<AppSpacingExtension> {
  /// 4px - 최소 간격
  final double xs;

  /// 8px - 작은 간격
  final double small;

  /// 12px - 중간-작은 간격
  final double medium;

  /// 16px - 기본 간격
  final double large;

  /// 24px - 중간-큰 간격
  final double xl;

  /// 32px - 큰 간격
  final double xxl;

  /// 48px - 매우 큰 간격
  final double xxxl;

  /// 64px - 섹션 간격
  final double huge;

  /// 96px - 초대형 간격
  final double massive;

  /// 128px - 최대 간격
  final double gargantuan;

  // ============================================================
  // 특수 용도 간격
  // ============================================================

  /// 6px - 폼 필드 레이블 간격
  final double formLabelGap;

  /// 4px - 폼 Helper 텍스트 간격
  final double formHelperGap;

  /// 2px - 제목과 설명 사이의 타이트한 그룹핑
  final double labelDescriptionGap;

  /// 8px - 컴포넌트 내 아이콘 간격
  final double componentIconGap;

  /// 스크롤바 간격 (4px)
  final double scrollbarGap;

  /// 최소 터치 영역 (44px)
  final double minTapSize;

  const AppSpacingExtension({
    required this.xs,
    required this.small,
    required this.medium,
    required this.large,
    required this.xl,
    required this.xxl,
    required this.xxxl,
    required this.huge,
    required this.massive,
    required this.gargantuan,
    required this.formLabelGap,
    required this.formHelperGap,
    required this.labelDescriptionGap,
    required this.componentIconGap,
    required this.scrollbarGap,
    required this.minTapSize,
  });

  /// 기본 간격 시스템 (4dp 그리드)
  factory AppSpacingExtension.standard() {
    return const AppSpacingExtension(
      xs: 4.0,
      small: 8.0,
      medium: 12.0,
      large: 16.0,
      xl: 24.0,
      xxl: 32.0,
      xxxl: 48.0,
      huge: 64.0,
      massive: 96.0,
      gargantuan: 128.0,
      formLabelGap: 6.0,
      formHelperGap: 4.0,
      labelDescriptionGap: 2.0,
      componentIconGap: 8.0,
      scrollbarGap: 4.0,
      minTapSize: 44.0,
    );
  }

  @override
  ThemeExtension<AppSpacingExtension> copyWith({
    double? xs,
    double? small,
    double? medium,
    double? large,
    double? xl,
    double? xxl,
    double? xxxl,
    double? huge,
    double? massive,
    double? gargantuan,
    double? formLabelGap,
    double? formHelperGap,
    double? labelDescriptionGap,
    double? componentIconGap,
    double? scrollbarGap,
    double? minTapSize,
  }) {
    return AppSpacingExtension(
      xs: xs ?? this.xs,
      small: small ?? this.small,
      medium: medium ?? this.medium,
      large: large ?? this.large,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      xxxl: xxxl ?? this.xxxl,
      huge: huge ?? this.huge,
      massive: massive ?? this.massive,
      gargantuan: gargantuan ?? this.gargantuan,
      formLabelGap: formLabelGap ?? this.formLabelGap,
      formHelperGap: formHelperGap ?? this.formHelperGap,
      labelDescriptionGap: labelDescriptionGap ?? this.labelDescriptionGap,
      componentIconGap: componentIconGap ?? this.componentIconGap,
      scrollbarGap: scrollbarGap ?? this.scrollbarGap,
      minTapSize: minTapSize ?? this.minTapSize,
    );
  }

  @override
  ThemeExtension<AppSpacingExtension> lerp(
    covariant ThemeExtension<AppSpacingExtension>? other,
    double t,
  ) {
    if (other is! AppSpacingExtension) return this;

    return AppSpacingExtension(
      xs: lerpDouble(xs, other.xs, t),
      small: lerpDouble(small, other.small, t),
      medium: lerpDouble(medium, other.medium, t),
      large: lerpDouble(large, other.large, t),
      xl: lerpDouble(xl, other.xl, t),
      xxl: lerpDouble(xxl, other.xxl, t),
      xxxl: lerpDouble(xxxl, other.xxxl, t),
      huge: lerpDouble(huge, other.huge, t),
      massive: lerpDouble(massive, other.massive, t),
      gargantuan: lerpDouble(gargantuan, other.gargantuan, t),
      formLabelGap: lerpDouble(formLabelGap, other.formLabelGap, t),
      formHelperGap: lerpDouble(formHelperGap, other.formHelperGap, t),
      labelDescriptionGap: lerpDouble(
        labelDescriptionGap,
        other.labelDescriptionGap,
        t,
      ),
      componentIconGap: lerpDouble(componentIconGap, other.componentIconGap, t),
      scrollbarGap: lerpDouble(scrollbarGap, other.scrollbarGap, t),
      minTapSize: lerpDouble(minTapSize, other.minTapSize, t),
    );
  }

  double lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

/// Helper extension for easy access
extension AppSpacingExtensionHelper on BuildContext {
  AppSpacingExtension get appSpacing =>
      Theme.of(this).extension<AppSpacingExtension>()!;
}
