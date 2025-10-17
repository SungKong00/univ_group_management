
import 'package:flutter/material.dart';

class EventPainter extends CustomPainter {
  final List<({Rect rect, String title})> events;

  EventPainter({required this.events});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    for (final event in events) {
      final rrect = RRect.fromRectAndRadius(event.rect, const Radius.circular(4));
      canvas.drawRRect(rrect, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: event.title,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        maxLines: 2,
        ellipsis: '...',
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(minWidth: 0, maxWidth: event.rect.width - 8); // 4px padding on each side
      textPainter.paint(canvas, event.rect.topLeft + const Offset(4, 4));
    }
  }

  @override
  bool shouldRepaint(covariant EventPainter oldDelegate) {
    return oldDelegate.events != events;
  }
}
