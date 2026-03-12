import 'package:flutter/material.dart';

/// Painter for Fixed Duration Mode preview (purple semi-transparent)
///
/// Displays a purple preview rectangle when user hovers (web) or touches (mobile)
/// to show where the fixed-duration event will be placed.
class FixedDurationPreviewPainter extends CustomPainter {
  final Rect? previewRect;

  FixedDurationPreviewPainter({required this.previewRect});

  @override
  void paint(Canvas canvas, Size size) {
    if (previewRect == null) return;

    // Purple preview color (matching the existing system's selection color)
    final fillPaint = Paint()
      ..color = Colors.deepPurple
          .withValues(alpha: 0.3) // Semi-transparent purple
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.deepPurple
          .withValues(alpha: 0.6) // Slightly more opaque border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw filled rectangle
    canvas.drawRect(previewRect!, fillPaint);

    // Draw border
    canvas.drawRect(previewRect!, borderPaint);
  }

  @override
  bool shouldRepaint(covariant FixedDurationPreviewPainter oldDelegate) {
    return oldDelegate.previewRect != previewRect;
  }
}
