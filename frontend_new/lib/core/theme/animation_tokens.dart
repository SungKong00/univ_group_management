import 'package:flutter/material.dart';
import 'theme_loader.dart';

/// Linear.app Animation Tokens
///
/// Consistent animation durations and curves
/// Source: assets/theme/linear_theme.json > animations
class AnimationTokens {
  AnimationTokens._();

  static Map<String, dynamic> get _animations =>
      ThemeLoader.themeData['animations'] as Map<String, dynamic>;

  static Map<String, dynamic> get _durations =>
      _animations['durations'] as Map<String, dynamic>;

  static Map<String, dynamic> get _curves =>
      _animations['curves'] as Map<String, dynamic>;

  // Durations
  static Duration get fast => _parseDuration(_durations['fast'] as String);
  static Duration get regular =>
      _parseDuration(_durations['regular'] as String);
  static Duration get slow => _parseDuration(_durations['slow'] as String);
  static Duration get verySlow =>
      _parseDuration(_durations['very_slow'] as String);

  // Curves
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve spring = Curves.elasticOut;

  /// "250ms" → Duration(milliseconds: 250)
  static Duration _parseDuration(String value) {
    final ms = int.parse(value.replaceAll('ms', ''));
    return Duration(milliseconds: ms);
  }
}
