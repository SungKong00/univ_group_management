
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HighlightPainter extends CustomPainter {
  final Rect? highlightRect;

  HighlightPainter({this.highlightRect});

  @override
  void paint(Canvas canvas, Size size) {
    if (highlightRect != null) {
      final paint = Paint()
        ..color = AppColors.brand.withOpacity(0.12)
        ..style = PaintingStyle.fill;
      canvas.drawRect(highlightRect!, paint);
    }
  }

  @override
  bool shouldRepaint(covariant HighlightPainter oldDelegate) {
    return oldDelegate.highlightRect != highlightRect;
  }
}
