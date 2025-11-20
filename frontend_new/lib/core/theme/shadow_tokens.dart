import 'package:flutter/material.dart';
import 'theme_loader.dart';

/// Linear.app Shadow System (Dark Mode)
///
/// Dark 배경에서는 밝은 그림자(white with low opacity) 사용
/// Source: assets/theme/linear_theme.json > shadows
class ShadowTokens {
  ShadowTokens._();

  static Map<String, dynamic> get _shadows =>
      ThemeLoader.themeData['shadows'] as Map<String, dynamic>;

  // None: 그림자 없음
  static const none = [
    BoxShadow(color: Colors.transparent, blurRadius: 0, offset: Offset(0, 0)),
  ];

  // Low: 0px 2px 4px (미묘한 그림자)
  static List<BoxShadow> get low {
    final shadow = _shadows['low'] as Map<String, dynamic>;
    return [
      BoxShadow(
        color: ThemeLoader.parseColor(shadow['color'] as String),
        blurRadius: _parsePixels(shadow['blur'] as String),
        spreadRadius: _parsePixels(shadow['spread'] as String),
        offset: Offset(
          _parsePixels(shadow['offset_x'] as String),
          _parsePixels(shadow['offset_y'] as String),
        ),
      ),
    ];
  }

  // Medium: 0px 4px 24px (일반 그림자)
  static List<BoxShadow> get medium {
    final shadow = _shadows['medium'] as Map<String, dynamic>;
    return [
      BoxShadow(
        color: ThemeLoader.parseColor(shadow['color'] as String),
        blurRadius: _parsePixels(shadow['blur'] as String),
        spreadRadius: _parsePixels(shadow['spread'] as String),
        offset: Offset(
          _parsePixels(shadow['offset_x'] as String),
          _parsePixels(shadow['offset_y'] as String),
        ),
      ),
    ];
  }

  // High: 0px 7px 32px (진한 그림자)
  static List<BoxShadow> get high {
    final shadow = _shadows['high'] as Map<String, dynamic>;
    return [
      BoxShadow(
        color: ThemeLoader.parseColor(shadow['color'] as String),
        blurRadius: _parsePixels(shadow['blur'] as String),
        spreadRadius: _parsePixels(shadow['spread'] as String),
        offset: Offset(
          _parsePixels(shadow['offset_x'] as String),
          _parsePixels(shadow['offset_y'] as String),
        ),
      ),
    ];
  }

  // High Hover: 더 진한 그림자 (hover 시 사용)
  static List<BoxShadow> get highHover {
    final shadow = _shadows['high_hover'] as Map<String, dynamic>;
    return [
      BoxShadow(
        color: ThemeLoader.parseColor(shadow['color'] as String),
        blurRadius: _parsePixels(shadow['blur'] as String),
        spreadRadius: _parsePixels(shadow['spread'] as String),
        offset: Offset(
          _parsePixels(shadow['offset_x'] as String),
          _parsePixels(shadow['offset_y'] as String),
        ),
      ),
    ];
  }

  /// "4px" → 4.0 변환
  static double _parsePixels(String value) {
    return double.parse(value.replaceAll('px', ''));
  }
}
