
import 'package:flutter/material.dart';

class EventPainter extends CustomPainter {
  final List<Rect> events;

  EventPainter({required this.events});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (final eventRect in events) {
      // Draw the event block
      final rrect = RRect.fromRectAndRadius(eventRect, const Radius.circular(4));
      canvas.drawRRect(rrect, paint);

      // Optionally, add text inside the event block
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '일정', // Placeholder text
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: eventRect.width);
      textPainter.paint(canvas, eventRect.topLeft + const Offset(4, 4));
    }
  }

  @override
  bool shouldRepaint(covariant EventPainter oldDelegate) {
    return oldDelegate.events != events;
  }
}
