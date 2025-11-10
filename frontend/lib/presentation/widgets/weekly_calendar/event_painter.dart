import 'package:flutter/material.dart';
import '../calendar/color_generator.dart';

class EventPainter extends CustomPainter {
  final List<
    ({
      Rect rect,
      String title,
      String id,
      int? columnIndex,
      int? totalColumns,
      int? span,
      DateTime? startTime,
      String? location,
      Color? color,
    })
  >
  events;

  EventPainter({required this.events});

  @override
  void paint(Canvas canvas, Size size) {
    final sortedEvents =
        List<
            ({
              Rect rect,
              String title,
              String id,
              int? columnIndex,
              int? totalColumns,
              int? span,
              DateTime? startTime,
              String? location,
              Color? color,
            })
          >.from(events)
          ..sort((a, b) {
            final topCompare = a.rect.top.compareTo(b.rect.top);
            if (topCompare != 0) return topCompare;
            final heightA = a.rect.height;
            final heightB = b.rect.height;
            return heightB.compareTo(heightA);
          });

    for (final event in sortedEvents) {
      Rect eventRect = event.rect;

      if (event.columnIndex != null &&
          event.totalColumns != null &&
          event.totalColumns! > 0) {
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

      // Use event color if available, otherwise use ColorGenerator
      final isExternalEvent = event.id.startsWith('ext-');
      final baseColor =
          event.color ??
          (isExternalEvent
              ? Colors
                    .blue // External events remain blue
              : ColorGenerator.getColorForSchedule(event.id));

      // Apply opacity for better readability
      final paint = Paint()
        ..color = baseColor.withOpacity(0.85)
        ..style = PaintingStyle.fill;

      // Add subtle shadow for depth
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.1)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      final rrect = RRect.fromRectAndRadius(
        eventRect,
        const Radius.circular(6),
      );

      // Draw shadow
      canvas.drawRRect(rrect.shift(const Offset(0, 1)), shadowPaint);
      // Draw event rectangle
      canvas.drawRRect(rrect, paint);

      // Draw border for better distinction
      final borderPaint = Paint()
        ..color = baseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRRect(rrect, borderPaint);

      // Use white text color for all events (darker backgrounds ensure readability)
      const textColor = Colors.white;

      // Draw time if available
      double textOffset = 4;
      if (event.startTime != null) {
        final timeText =
            '${event.startTime!.hour.toString().padLeft(2, '0')}:${event.startTime!.minute.toString().padLeft(2, '0')}';
        final timePainter = TextPainter(
          text: TextSpan(
            text: timeText,
            style: TextStyle(
              color: textColor.withOpacity(0.9),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        timePainter.layout(minWidth: 0, maxWidth: eventRect.width - 8);
        timePainter.paint(canvas, eventRect.topLeft + Offset(4, textOffset));
        textOffset += 14;
      }

      // Draw title with improved font size
      final textPainter = TextPainter(
        text: TextSpan(
          text: event.title,
          style: const TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        maxLines: 2,
        ellipsis: '...',
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(minWidth: 0, maxWidth: eventRect.width - 8);
      textPainter.paint(canvas, eventRect.topLeft + Offset(4, textOffset));
      textOffset += textPainter.height + 2;

      // Draw location if available and there's space
      if (event.location != null &&
          event.location!.isNotEmpty &&
          eventRect.height > 50) {
        final locationPainter = TextPainter(
          text: TextSpan(
            text: '📍 ${event.location}',
            style: TextStyle(color: textColor.withOpacity(0.85), fontSize: 10),
          ),
          maxLines: 1,
          ellipsis: '...',
          textDirection: TextDirection.ltr,
        );
        locationPainter.layout(minWidth: 0, maxWidth: eventRect.width - 8);
        if (textOffset + locationPainter.height < eventRect.height - 4) {
          locationPainter.paint(
            canvas,
            eventRect.topLeft + Offset(4, textOffset),
          );
        }
      }
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
