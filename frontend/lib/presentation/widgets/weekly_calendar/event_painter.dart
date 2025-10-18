import 'package:flutter/material.dart';

class EventPainter extends CustomPainter {
  final List<({Rect rect, String title, String id, int? columnIndex, int? totalColumns})> events;

  EventPainter({required this.events});

  @override
  void paint(Canvas canvas, Size size) {
    // Sort events for proper z-index rendering:
    // 1. Earlier start time first (drawn below)
    // 2. If same start time, longer duration first (drawn below)
    // Result: Later/shorter blocks appear on top
    final sortedEvents = List<({Rect rect, String title, String id, int? columnIndex, int? totalColumns})>.from(events)
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
      Rect eventRect = event.rect;

      // Apply column layout if overlap info is provided
      if (event.columnIndex != null && event.totalColumns != null && event.totalColumns! > 1) {
        final columnWidth = event.rect.width / event.totalColumns!;
        final columnOffset = columnWidth * event.columnIndex!;

        eventRect = Rect.fromLTRB(
          event.rect.left + columnOffset,
          event.rect.top,
          event.rect.left + columnOffset + columnWidth,
          event.rect.bottom,
        );
      }

      // Determine color based on event type
      // External events (read-only, reference): Blue
      // User-created events (editable): Purple (brand color)
      final isExternalEvent = event.id.startsWith('ext-');
      final paint = Paint()
        ..color = isExternalEvent
            ? Colors.blue.withValues(alpha: 0.45)  // External (참고용)
            : const Color(0xFF5C068C).withValues(alpha: 0.45)  // User-created (보라색)
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(eventRect, const Radius.circular(4));
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

      textPainter.layout(minWidth: 0, maxWidth: eventRect.width - 8); // 4px padding on each side
      textPainter.paint(canvas, eventRect.topLeft + const Offset(4, 4));
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
