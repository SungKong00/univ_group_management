import 'package:flutter/material.dart';

/// Color palette for place reservations
/// 6 distinct colors cycling through places for easy visual distinction
class PlaceColors {
  PlaceColors._();

  /// Default color palette (6 colors)
  /// Colors are selected for good contrast and visibility
  static const List<Color> palette = [
    Color(0xFF3B82F6), // Blue
    Color(0xFFEF4444), // Red
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
  ];

  /// Get color for a specific place by index
  /// Colors cycle through the palette
  static Color getColorForPlace(int index) {
    if (palette.isEmpty) return const Color(0xFF3B82F6);
    return palette[index % palette.length];
  }

  /// Get color for a place by its ID (hash-based consistent color)
  static Color getColorForPlaceId(String placeId) {
    final hash = placeId.hashCode.abs();
    return palette[hash % palette.length];
  }

  /// Get lighter variant of a color (for backgrounds)
  static Color lighter(Color color, [double factor = 0.15]) {
    return Color.alphaBlend(
      Colors.white.withValues(alpha: factor),
      color,
    );
  }

  /// Get darker variant of a color (for borders/text)
  static Color darker(Color color, [double factor = 0.2]) {
    return Color.alphaBlend(
      Colors.black.withValues(alpha: factor),
      color,
    );
  }
}
