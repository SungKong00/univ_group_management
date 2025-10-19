import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// 겹친 일정 모달용 커스텀 TimeGridPainter
///
/// 시간 눈금과 그리드 라인만 렌더링 (헤더 없음, 단일 컬럼)
class OverlapModalTimeGridPainter extends CustomPainter {
  const OverlapModalTimeGridPainter({
    required this.minSlot,
    required this.maxSlot,
    required this.startHour,
    required this.slotHeight,
    required this.timeColumnWidth,
  });

  final int minSlot;
  final int maxSlot;
  final int startHour;
  final double slotHeight;
  final double timeColumnWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final totalSlots = maxSlot - minSlot + 1;

    // 1. 시간 눈금 (왼쪽 컬럼)
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    for (int i = 0; i < totalSlots; i++) {
      final slot = minSlot + i;
      final isHourMark = slot % 4 == 0;

      if (isHourMark) {
        final hour = startHour + (slot ~/ 4);
        final minute = (slot % 4) * 15;
        final timeText = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

        textPainter.text = TextSpan(
          text: timeText,
          style: AppTheme.bodySmall.copyWith(
            color: AppColors.neutral500,
            fontSize: 11,
          ),
        );
        textPainter.layout(maxWidth: timeColumnWidth - 8);

        final top = i * slotHeight + 4;
        final left = timeColumnWidth - textPainter.width - 8;
        textPainter.paint(canvas, Offset(left, top));
      }
    }

    // 2. 그리드 라인 (오른쪽 영역)
    final linePaint = Paint()..strokeWidth = 1;

    for (int i = 0; i < totalSlots; i++) {
      final slot = minSlot + i;
      final isHourLine = slot % 4 == 0;
      final y = i * slotHeight;

      linePaint.color = isHourLine
          ? AppColors.lightOutline
          : AppColors.lightOutline.withValues(alpha: 0.35);
      linePaint.strokeWidth = isHourLine ? 1 : 0.5;

      canvas.drawLine(
        Offset(timeColumnWidth, y),
        Offset(size.width, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant OverlapModalTimeGridPainter oldDelegate) {
    return minSlot != oldDelegate.minSlot ||
        maxSlot != oldDelegate.maxSlot ||
        startHour != oldDelegate.startHour ||
        slotHeight != oldDelegate.slotHeight ||
        timeColumnWidth != oldDelegate.timeColumnWidth;
  }
}
