import 'package:flutter/material.dart';
import '../theme/enums.dart';

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
            child: Container(decoration: BoxDecoration(gradient: gradient)),
          ),
        ),
      ],
    );
  }

  Gradient _getGradient() {
    // Hardcoded gradients (from GradientTokens)
    return switch (type) {
      GradientType.subtleTopFade => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x0DFFFFFF), // rgba(255,255,255,0.05)
          Color(0x00FFFFFF), // rgba(255,255,255,0)
        ],
      ),
      GradientType.lightTopFade => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x14FFFFFF), // rgba(255,255,255,0.08)
          Color(0x00FFFFFF), // rgba(255,255,255,0)
        ],
      ),
      GradientType.extraLightTopFade => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x08FFFFFF), // rgba(255,255,255,0.03)
          Color(0x00FFFFFF), // rgba(255,255,255,0)
        ],
      ),
      GradientType.subtleBottomFade => const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color(0x0DFFFFFF), // rgba(255,255,255,0.05)
          Color(0x00FFFFFF), // rgba(255,255,255,0)
        ],
      ),
      GradientType.subtleLeftFade => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0x0DFFFFFF), // rgba(255,255,255,0.05)
          Color(0x00FFFFFF), // rgba(255,255,255,0)
        ],
      ),
      GradientType.subtleRightFade => const LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          Color(0x0DFFFFFF), // rgba(255,255,255,0.05)
          Color(0x00FFFFFF), // rgba(255,255,255,0)
        ],
      ),
      GradientType.radialFade => const RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Color(0x0DFFFFFF), // rgba(255,255,255,0.05)
          Color(0x00FFFFFF), // rgba(255,255,255,0)
        ],
      ),
    };
  }
}
