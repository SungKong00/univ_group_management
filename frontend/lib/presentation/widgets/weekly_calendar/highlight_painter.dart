
import 'package:flutter/material.dart';

class HighlightPainter extends CustomPainter {
  final Rect? highlightRect;

  HighlightPainter({this.highlightRect});

  @override
  void paint(Canvas canvas, Size size) {
    if (highlightRect != null) {
      final paint = Paint()
        ..color = Colors.black.withOpacity(0.05)
        ..style = PaintingStyle.fill;
      canvas.drawRect(highlightRect!, paint);
    }
  }

  @override
  bool shouldRepaint(covariant HighlightPainter oldDelegate) {
    return oldDelegate.highlightRect != highlightRect;
  }
}
