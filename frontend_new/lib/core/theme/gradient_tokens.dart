import 'package:flutter/material.dart';
import 'theme_loader.dart';

/// Linear.app Gradient System (Dark Mode)
///
/// Subtle gradient overlays for depth and visual hierarchy
/// Source: assets/theme/linear_theme.json > gradients
class GradientTokens {
  GradientTokens._();

  static Map<String, dynamic> get _gradients =>
      ThemeLoader.themeData['gradients'] as Map<String, dynamic>;

  // Subtle Top Fade: 가장 일반적인 패턴
  static Gradient get subtleTopFade => _buildGradient('subtle_top_fade');

  // Light: 더 밝은 그래디언트 (hover 효과 등)
  static Gradient get lightTopFade => _buildGradient('light_top_fade');

  // Extra Light: 매우 미묘한 그래디언트
  static Gradient get extraLightTopFade =>
      _buildGradient('extra_light_top_fade');

  // Bottom Fade: 하단에서 시작
  static Gradient get subtleBottomFade => _buildGradient('subtle_bottom_fade');

  // Horizontal Fade: 좌측에서 우측
  static Gradient get subtleLeftFade => _buildGradient('subtle_left_fade');

  // Horizontal Fade: 우측에서 좌측
  static Gradient get subtleRightFade => _buildGradient('subtle_right_fade');

  // Radial Fade: 중심에서 외곽으로
  static Gradient get radialFade => _buildGradient('radial_fade');

  /// JSON에서 그래디언트 생성
  static Gradient _buildGradient(String key) {
    final gradient = _gradients[key] as Map<String, dynamic>;
    final type = gradient['type'] as String;
    final stops = (gradient['stops'] as List)
        .map((stop) => stop as Map<String, dynamic>)
        .toList();

    final colors = stops
        .map((stop) => ThemeLoader.parseColor(stop['color'] as String))
        .toList();

    if (type == 'linear') {
      final direction = _parseDirection(gradient['direction'] as String);
      return LinearGradient(
        begin: direction.begin,
        end: direction.end,
        colors: colors,
      );
    } else if (type == 'radial') {
      final radius = double.parse(gradient['radius'] as String);
      return RadialGradient(
        center: Alignment.center,
        radius: radius,
        colors: colors,
      );
    }

    throw UnsupportedError('Unknown gradient type: $type');
  }

  /// "to bottom" → (begin: topCenter, end: bottomCenter)
  static ({Alignment begin, Alignment end}) _parseDirection(String direction) {
    return switch (direction) {
      'to bottom' => (begin: Alignment.topCenter, end: Alignment.bottomCenter),
      'to top' => (begin: Alignment.bottomCenter, end: Alignment.topCenter),
      'to right' => (begin: Alignment.centerLeft, end: Alignment.centerRight),
      'to left' => (begin: Alignment.centerRight, end: Alignment.centerLeft),
      _ => (begin: Alignment.topCenter, end: Alignment.bottomCenter),
    };
  }
}
