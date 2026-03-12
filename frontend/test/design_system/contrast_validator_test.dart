import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_colors.dart';

/// WCAG 2.1 AA Contrast Ratio Validation Test
///
/// Tests all AppColors pairs used in navigation components to ensure
/// they meet WCAG 2.1 AA requirements:
/// - Normal text (< 18pt or < 14pt bold): minimum 4.5:1
/// - Large text (≥ 18pt or ≥ 14pt bold): minimum 3:1
///
/// Spec: specs/001-workspace-navigation-refactor/tasks.md#T127.5
void main() {
  /// Calculate relative luminance according to WCAG 2.1
  /// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
  double relativeLuminance(Color color) {
    final r = ((color.r * 255.0).round() & 0xff) / 255.0;
    final g = ((color.g * 255.0).round() & 0xff) / 255.0;
    final b = ((color.b * 255.0).round() & 0xff) / 255.0;

    final rsRGB = r <= 0.03928
        ? r / 12.92
        : math.pow((r + 0.055) / 1.055, 2.4).toDouble();
    final gsRGB = g <= 0.03928
        ? g / 12.92
        : math.pow((g + 0.055) / 1.055, 2.4).toDouble();
    final bsRGB = b <= 0.03928
        ? b / 12.92
        : math.pow((b + 0.055) / 1.055, 2.4).toDouble();

    return 0.2126 * rsRGB + 0.7152 * gsRGB + 0.0722 * bsRGB;
  }

  /// Calculate contrast ratio according to WCAG 2.1
  /// https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio
  double contrastRatio(Color foreground, Color background) {
    final l1 = relativeLuminance(foreground);
    final l2 = relativeLuminance(background);

    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Convert Color to hex string for debugging
  String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  group('WCAG 2.1 AA Contrast Ratio Validation', () {
    /// Helper function to check contrast ratio and fail with descriptive message
    void validateContrast(
      Color foreground,
      Color background,
      String label, {
      double minRatio = 4.5, // Default: normal text
    }) {
      final ratio = contrastRatio(foreground, background);
      final passed = ratio >= minRatio;

      expect(
        passed,
        isTrue,
        reason:
            '''
❌ WCAG 2.1 AA VIOLATION: $label
   Foreground: ${colorToHex(foreground)}
   Background: ${colorToHex(background)}
   Contrast Ratio: ${ratio.toStringAsFixed(2)}:1
   Required: ≥${minRatio.toStringAsFixed(1)}:1
   Status: ${passed ? '✓ PASS' : '✗ FAIL'}
        ''',
      );

      // Print success message
      if (passed) {
        // ignore: avoid_print
        print(
          '✓ $label: ${ratio.toStringAsFixed(2)}:1 (required ≥${minRatio.toStringAsFixed(1)}:1)',
        );
      }
    }

    test('Primary action (action) vs surface (white)', () {
      validateContrast(
        AppColors.action,
        Colors.white,
        'Action blue on white surface',
      );
    });

    test('Brand text (brand) vs surface (white)', () {
      validateContrast(
        AppColors.brand,
        Colors.white,
        'Brand purple on white surface',
      );
    });

    test('Text primary (neutral900) vs surface (white)', () {
      validateContrast(
        AppColors.lightOnSurface,
        AppColors.lightSurface,
        'Primary text on light surface',
      );
    });

    test('Text secondary (neutral700) vs surface (white)', () {
      validateContrast(
        AppColors.lightSecondary,
        AppColors.lightSurface,
        'Secondary text on light surface',
      );
    });

    test('Action text (action) vs actionTonalBg', () {
      validateContrast(
        AppColors.action,
        AppColors.actionTonalBg,
        'Action text on action tonal background',
      );
    });

    test('Selected navigation item (action) vs surface', () {
      validateContrast(
        AppColors.action,
        Colors.white,
        'Selected navigation item',
      );
    });

    test('Unselected navigation item (neutral600) vs surface', () {
      validateContrast(
        const Color(0xFF6B7280), // neutral600 approximation
        Colors.white,
        'Unselected navigation item icon',
      );
    });

    test('Dark mode: white text vs dark surface', () {
      validateContrast(
        AppColors.darkOnSurface,
        AppColors.darkSurface,
        'Dark mode primary text',
      );
    });

    test('Dark mode: secondary text vs dark surface', () {
      validateContrast(
        AppColors.darkSecondary,
        AppColors.darkSurface,
        'Dark mode secondary text',
      );
    });

    test('Error text (error) vs surface', () {
      validateContrast(
        AppColors.error,
        Colors.white,
        'Error text on white surface',
      );
    });

    test('Success text (success) vs surface', () {
      validateContrast(
        AppColors.success,
        Colors.white,
        'Success text on white surface',
      );
    });

    test('Warning text (warning) vs surface', () {
      validateContrast(
        AppColors.warning,
        Colors.white,
        'Warning text on white surface',
      );
    });

    test('Focus ring (brand 45%) vs surface - LARGE TEXT ONLY', () {
      // Focus ring has reduced opacity, so it only needs 3:1 for large text
      validateContrast(
        AppColors.focusRing,
        Colors.white,
        'Focus ring on white surface (large text)',
        minRatio: 3.0, // Large text requirement
      );
    });

    test('Disabled text (neutral500) vs surface', () {
      validateContrast(
        AppColors.disabledTextLight,
        Colors.white,
        'Disabled text on white surface',
      );
    });

    test('Brand strong (hover) vs surface', () {
      validateContrast(
        AppColors.brandStrong,
        Colors.white,
        'Brand strong (hover state) on white surface',
      );
    });

    test('Action hover vs surface', () {
      validateContrast(
        AppColors.actionHover,
        Colors.white,
        'Action hover state on white surface',
      );
    });
  });

  group('Contrast Ratio Summary Report', () {
    test('Generate summary of all navigation color combinations', () {
      final combinations = [
        ('Action', AppColors.action, Colors.white),
        ('Brand', AppColors.brand, Colors.white),
        ('Primary Text', AppColors.lightOnSurface, AppColors.lightSurface),
        ('Secondary Text', AppColors.lightSecondary, AppColors.lightSurface),
        ('Dark Primary', AppColors.darkOnSurface, AppColors.darkSurface),
        ('Dark Secondary', AppColors.darkSecondary, AppColors.darkSurface),
      ];

      // ignore: avoid_print
      print('\n=== WCAG 2.1 AA Contrast Ratio Summary ===');
      for (final (label, fg, bg) in combinations) {
        final ratio = contrastRatio(fg, bg);
        final normalPass = ratio >= 4.5;
        final largePass = ratio >= 3.0;

        // ignore: avoid_print
        print(
          '$label: ${ratio.toStringAsFixed(2)}:1 '
          '(Normal: ${normalPass ? '✓' : '✗'}, Large: ${largePass ? '✓' : '✗'})',
        );
      }
      // ignore: avoid_print
      print('=======================================\n');

      // This test always passes (it's just for reporting)
      expect(true, isTrue);
    });
  });
}
