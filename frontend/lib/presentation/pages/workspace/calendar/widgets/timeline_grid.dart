import 'package:flutter/material.dart';

/// 타임라인 그리드 (06:00~24:00, 1시간 = 60px)
/// 30분 단위 점선 보조선, 1시간 단위 실선 + 레이블
class TimelineGrid extends StatelessWidget {
  const TimelineGrid({super.key});

  static const double hourHeight = 60.0;
  static const int startHour = 6;
  static const int endHour = 24;

  @override
  Widget build(BuildContext context) {
    final totalHours = endHour - startHour;
    final totalHeight = totalHours * hourHeight;

    return SizedBox(
      height: totalHeight,
      width: 48,
      child: Stack(
        children: [
          // 보조선 및 시간 레이블
          ...List.generate(totalHours * 2, (index) {
            final isHour = index % 2 == 0;
            final hour = startHour + (index ~/ 2);
            final top = (index / 2) * hourHeight;

            return Positioned(
              left: 0,
              right: 0,
              top: top,
              child: SizedBox(
                width: 48,
                child: isHour
                    ? Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E9E9E), // neutral500
                        ),
                        textAlign: TextAlign.center,
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFFE0E0E0) // neutral300
      ..strokeWidth = 0.5;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
