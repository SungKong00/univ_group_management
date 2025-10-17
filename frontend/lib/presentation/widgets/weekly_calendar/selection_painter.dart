
import 'package:flutter/material.dart';

class SelectionPainter extends CustomPainter {
  final Rect? selection;

  SelectionPainter({this.selection});

  @override
  void paint(Canvas canvas, Size size) {
    if (selection != null) {
      final paint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRect(selection!, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SelectionPainter oldDelegate) {
    return oldDelegate.selection != selection;
  }
}
