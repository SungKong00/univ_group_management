import 'package:flutter/material.dart';
import '../theme/gradient_tokens.dart';

/// Linear 스타일 Gradient Overlay
///
/// 특징:
/// - 카드/이미지 위에 미묘한 그래디언트 오버레이
/// - 깊이감과 시각적 계층 구조 추가
/// - 다양한 방향 지원 (top/bottom/left/right/radial)
class AppGradientOverlay extends StatelessWidget {
  final Widget child;
  final GradientType type;
  final double opacity;

  const AppGradientOverlay({
    super.key,
    required this.child,
    this.type = GradientType.subtleTopFade,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient();

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Opacity(
            opacity: opacity,
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Gradient _getGradient() {
    return switch (type) {
      GradientType.subtleTopFade => GradientTokens.subtleTopFade,
      GradientType.lightTopFade => GradientTokens.lightTopFade,
      GradientType.extraLightTopFade => GradientTokens.extraLightTopFade,
      GradientType.subtleBottomFade => GradientTokens.subtleBottomFade,
      GradientType.subtleLeftFade => GradientTokens.subtleLeftFade,
      GradientType.subtleRightFade => GradientTokens.subtleRightFade,
      GradientType.radialFade => GradientTokens.radialFade,
    };
  }
}

enum GradientType {
  subtleTopFade,
  lightTopFade,
  extraLightTopFade,
  subtleBottomFade,
  subtleLeftFade,
  subtleRightFade,
  radialFade,
}
