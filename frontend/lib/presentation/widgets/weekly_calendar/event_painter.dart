import 'package:flutter/material.dart';

class EventPainter extends CustomPainter {
  final List<({Rect rect, String title, String id, int? columnIndex, int? totalColumns, int? span})> events;

  EventPainter({required this.events});

  @override
  void paint(Canvas canvas, Size size) {
    final sortedEvents = List<({Rect rect, String title, String id, int? columnIndex, int? totalColumns, int? span})>.from(events)
      ..sort((a, b) {
        final topCompare = a.rect.top.compareTo(b.rect.top);
        if (topCompare != 0) return topCompare;
        final heightA = a.rect.height;
        final heightB = b.rect.height;
        return heightB.compareTo(heightA);
      });

    for (final event in sortedEvents) {
      Rect eventRect = event.rect;

      if (event.columnIndex != null && event.totalColumns != null && event.totalColumns! > 0) {
        final int totalColumns = event.totalColumns!;
        final double columnWidth = event.rect.width / totalColumns;
        final int span = event.span ?? 1;

        eventRect = Rect.fromLTWH(
          event.rect.left + columnWidth * event.columnIndex!,
          event.rect.top,
          columnWidth * span - 2, // Subtract a small amount for spacing
          event.rect.height,
        );
      }

      final isExternalEvent = event.id.startsWith('ext-');
      final paint = Paint()
        ..color = isExternalEvent
            ? Colors.blue.withOpacity(0.45)
            : const Color(0xFF5C068C).withOpacity(0.45)
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

      textPainter.layout(minWidth: 0, maxWidth: eventRect.width - 8);
      textPainter.paint(canvas, eventRect.topLeft + const Offset(4, 4));
    }
  }

  @override
  bool shouldRepaint(covariant EventPainter oldDelegate) {
    if (oldDelegate.events.length != events.length) return true;
    for (int i = 0; i < events.length; i++) {
      if (oldDelegate.events[i] != events[i]) return true;
    }
    return false;
  }
}