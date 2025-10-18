import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

class TimeGridPainter extends CustomPainter {
  TimeGridPainter({
    required this.startHour,
    required this.endHour,
    required this.timeColumnWidth,
    required this.weekStart,
    this.paintHeader = true,
    this.paintGrid = true,
  }) : assert(endHour > startHour, 'endHour must be greater than startHour');

  final int startHour;
  final int endHour;
  final double timeColumnWidth;
  final DateTime weekStart;
  final bool paintHeader;
  final bool paintGrid;

  static const int _daysInWeek = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint hourLinePaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.0;
    final Paint halfHourLinePaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.5;
    final Paint dayColumnPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    final double dayColumnWidth = (size.width - timeColumnWidth) / _daysInWeek;

    if (paintGrid) {
      final int hourSpan = endHour - startHour;
      final double hourHeight = size.height / hourSpan;
      final double halfHourHeight = hourHeight / 2;

      for (int i = 0; i < hourSpan; i++) {
        final double hourY = i * hourHeight;
        final double halfHourY = hourY + halfHourHeight;

        // Draw hour and half-hour guides
        canvas.drawLine(
          Offset(timeColumnWidth, hourY),
          Offset(size.width, hourY),
          hourLinePaint,
        );
        if (halfHourY < size.height) {
          canvas.drawLine(
            Offset(timeColumnWidth, halfHourY),
            Offset(size.width, halfHourY),
            halfHourLinePaint,
          );
        }

        // Draw hour label (e.g. 09:00)
        final hour = startHour + i;
        final textPainter = TextPainter(
          text: TextSpan(
            text: DateFormat('HH:mm').format(DateTime(2024, 1, 1, hour)),
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
          textDirection: TextDirection.ltr,
        )
          ..layout();
        final double labelX = timeColumnWidth - textPainter.width - 6;
        final double labelY = hourY - 8;
        textPainter.paint(canvas, Offset(labelX, labelY.clamp(0.0, size.height)));
      }

      // Draw bottom boundary line for the grid
      canvas.drawLine(
        Offset(timeColumnWidth, size.height),
        Offset(size.width, size.height),
        hourLinePaint,
      );

      // Draw vertical day separators
      for (int dayIndex = 0; dayIndex <= _daysInWeek; dayIndex++) {
        final double x = timeColumnWidth + dayIndex * dayColumnWidth;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), dayColumnPaint);
      }

      // Draw divider for time column
      canvas.drawLine(
        Offset(timeColumnWidth, 0),
        Offset(timeColumnWidth, size.height),
        hourLinePaint,
      );
    }

    if (paintHeader) {
      final Paint headerGridPaint = Paint()
        ..color = Colors.grey[400]!
        ..strokeWidth = 1.0;

      for (int dayIndex = 0; dayIndex < _daysInWeek; dayIndex++) {
        final DateTime day = weekStart.add(Duration(days: dayIndex));
        final bool isToday = _isSameDay(day, DateTime.now());

        final String dayText = DateFormat.E('ko_KR').format(day);
        final String dateText = DateFormat('d').format(day);

        final TextPainter headerPainter = TextPainter(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: '\n$dateText',
                style: TextStyle(
                  color: isToday ? Colors.blue : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            text: dayText,
            style: TextStyle(
              color: isToday ? Colors.blue : Colors.grey[700],
              fontSize: 12,
              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )
          ..layout(minWidth: dayColumnWidth, maxWidth: dayColumnWidth);

        final double x = timeColumnWidth + dayIndex * dayColumnWidth;
        headerPainter.paint(canvas, Offset(x, 4));

        if (dayIndex > 0) {
          canvas.drawLine(
            Offset(x, 0),
            Offset(x, size.height),
            headerGridPaint,
          );
        }
      }

      // Bottom border of header
      canvas.drawLine(
        Offset(0, size.height),
        Offset(size.width, size.height),
        headerGridPaint,
      );
      // Divider for time column inside header
      canvas.drawLine(
        Offset(timeColumnWidth, 0),
        Offset(timeColumnWidth, size.height),
        headerGridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TimeGridPainter oldDelegate) {
    return oldDelegate.startHour != startHour ||
        oldDelegate.endHour != endHour ||
        oldDelegate.timeColumnWidth != timeColumnWidth ||
        oldDelegate.weekStart != weekStart ||
        oldDelegate.paintHeader != paintHeader ||
        oldDelegate.paintGrid != paintGrid;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
