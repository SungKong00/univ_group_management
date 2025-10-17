
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
    final linePaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    final double hourHeight = (size.height - dayRowHeight) / (endHour - startHour);

    // Draw hour lines and labels
    for (int i = 0; i <= (endHour - startHour); i++) {
      final y = dayRowHeight + i * hourHeight;
      canvas.drawLine(Offset(timeColumnWidth, y), Offset(size.width, y), linePaint);

      if (i < (endHour - startHour)) {
        final hour = startHour + i;
        final textPainter = TextPainter(
          text: TextSpan(
            text: DateFormat('ha').format(DateTime(2024, 1, 1, hour)), // '9AM' format
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(5, y + 5));
      }
    }

    // Draw day columns and labels
    final double dayColumnWidth = (size.width - timeColumnWidth) / 7;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (int i = 0; i < 7; i++) {
      final x = timeColumnWidth + i * dayColumnWidth;
      if (i > 0) {
        canvas.drawLine(Offset(x, dayRowHeight), Offset(x, size.height), linePaint);
      }

      final day = startOfWeek.add(Duration(days: i));
      final dayText = DateFormat.E('ko_KR').format(day); // Mon, Tue in Korean
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
    canvas.drawLine(Offset(0, dayRowHeight), Offset(size.width, dayRowHeight), linePaint..strokeWidth = 1.0);
    // Draw line separating time column from grid
    canvas.drawLine(Offset(timeColumnWidth, 0), Offset(timeColumnWidth, size.height), linePaint..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(covariant TimeGridPainter oldDelegate) {
    return oldDelegate.startHour != startHour || oldDelegate.endHour != endHour;
  }
}
