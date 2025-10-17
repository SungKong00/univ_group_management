
import 'package:flutter/material.dart';

class EventPainter extends CustomPainter {
  final List<({Rect rect, String title})> events;

  EventPainter({required this.events});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    // Sort events for proper z-index rendering:
    // 1. Earlier start time first (drawn below)
    // 2. If same start time, longer duration first (drawn below)
    // Result: Later/shorter blocks appear on top
    final sortedEvents = List<({Rect rect, String title})>.from(events)
      ..sort((a, b) {
        // Compare top position (start time)
        final topCompare = a.rect.top.compareTo(b.rect.top);
        if (topCompare != 0) return topCompare;

        // If same start, compare height (duration) in descending order
        final heightA = a.rect.height;
        final heightB = b.rect.height;
        return heightB.compareTo(heightA); // Longer first (reverse)
      });

    for (final event in sortedEvents) {
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
    // Deep comparison since we're sorting the events list
    if (oldDelegate.events.length != events.length) return true;
    for (int i = 0; i < events.length; i++) {
      if (oldDelegate.events[i] != events[i]) return true;
    }
    return false;
  }
}
