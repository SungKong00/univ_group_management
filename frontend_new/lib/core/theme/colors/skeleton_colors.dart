import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Skeleton 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
/// Shimmer 효과를 위한 기본/하이라이트 색상을 제공합니다.
class SkeletonColors {
  /// 기본 배경색
  final Color base;

  /// 하이라이트 색상 (shimmer 효과)
  final Color highlight;

  const SkeletonColors({required this.base, required this.highlight});

  /// 표준 스켈레톤 색상
  factory SkeletonColors.standard(AppColorExtension c) {
    return SkeletonColors(
      base: c.surfaceTertiary,
      highlight: c.surfaceQuaternary,
    );
  }

  /// 어두운 배경용 스켈레톤 색상
  factory SkeletonColors.dark(AppColorExtension c) {
    return SkeletonColors(
      base: c.surfaceSecondary,
      highlight: c.surfaceTertiary,
    );
  }
}
