import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SelectionPainter extends CustomPainter {
  final Rect? selection;

  SelectionPainter({this.selection});

  @override
  void paint(Canvas canvas, Size size) {
    if (selection != null) {
      final paint = Paint()
        ..color = AppColors.brand.withOpacity(0.24)
        ..style = PaintingStyle.fill;
      canvas.drawRect(selection!, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SelectionPainter oldDelegate) {
    return oldDelegate.selection != selection;
  }
}
