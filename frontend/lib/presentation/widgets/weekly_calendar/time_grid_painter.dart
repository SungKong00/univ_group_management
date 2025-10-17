
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

class TimeGridPainter extends CustomPainter {
  final int startHour;
  final int endHour;
  final double timeColumnWidth;
  final double dayRowHeight;

  TimeGridPainter({
    this.startHour = 0,
    this.endHour = 24,
    this.timeColumnWidth = 50.0,
    this.dayRowHeight = 30.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hourLinePaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.0;

    final halfHourLinePaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.5;

    final dayColumnPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    final double hourHeight = (size.height - dayRowHeight) / (endHour - startHour);
    final double halfHourHeight = hourHeight / 2;

    // Draw hour and half-hour lines and labels
    for (int i = 0; i < (endHour - startHour); i++) {
      final hourY = dayRowHeight + i * hourHeight;
      final halfHourY = hourY + halfHourHeight;

      // Draw hour line
      canvas.drawLine(Offset(timeColumnWidth, hourY), Offset(size.width, hourY), hourLinePaint);
      // Draw half-hour line
      canvas.drawLine(Offset(timeColumnWidth, halfHourY), Offset(size.width, halfHourY), halfHourLinePaint);

      // Draw hour label
      final hour = startHour + i;
      final textPainter = TextPainter(
        text: TextSpan(
          text: DateFormat('ha').format(DateTime(2024, 1, 1, hour)), // '9AM' format
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      // Right-align the text within the time column
      final xOffset = timeColumnWidth - textPainter.width - 5; // 5px padding
      textPainter.paint(canvas, Offset(xOffset, hourY - 8));
    }

    // Draw day columns and labels
    final double dayColumnWidth = (size.width - timeColumnWidth) / 7;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (int i = 0; i < 7; i++) {
      final x = timeColumnWidth + i * dayColumnWidth;
      if (i > 0) {
        canvas.drawLine(Offset(x, dayRowHeight), Offset(x, size.height), dayColumnPaint);
      }

      final day = startOfWeek.add(Duration(days: i));
      final dayText = DateFormat.E('ko_KR').format(day);
      final dateText = DateFormat('d').format(day);

      final dayTextPainter = TextPainter(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: '\n$dateText', // Date number
              style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
          text: dayText, // Day of week
          style: TextStyle(color: Colors.grey[700], fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      dayTextPainter.layout(minWidth: dayColumnWidth, maxWidth: dayColumnWidth);
      dayTextPainter.paint(canvas, Offset(x, 5));
    }

    // Draw line separating days row from grid
    canvas.drawLine(Offset(0, dayRowHeight), Offset(size.width, dayRowHeight), hourLinePaint);
    // Draw line separating time column from grid
    canvas.drawLine(Offset(timeColumnWidth, 0), Offset(timeColumnWidth, size.height), hourLinePaint);
  }

  @override
  bool shouldRepaint(covariant TimeGridPainter oldDelegate) {
    return oldDelegate.startHour != startHour || oldDelegate.endHour != endHour;
  }
}
