import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Paints disabled time slots as gray cells
///
/// Disabled slots are unavailable time periods (outside operating hours,
/// already reserved, or blocked by admin).
///
/// Visual Design:
/// - Background: AppColors.neutral300 with 40% opacity
/// - No border (uses TimeGridPainter's existing grid lines)
/// - Non-interactive (parent widget handles click prevention)
class DisabledSlotsPainter extends CustomPainter {
  final Set<DateTime>? disabledSlots;
  final DateTime weekStart;
  final int visibleStartHour;
  final int visibleEndHour;
  final double timeColumnWidth;
  final double slotHeight; // Height per 15-minute slot
  final double dayColumnWidth;

  DisabledSlotsPainter({
    required this.disabledSlots,
    required this.weekStart,
    required this.visibleStartHour,
    required this.visibleEndHour,
    required this.timeColumnWidth,
    required this.slotHeight,
    required this.dayColumnWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (disabledSlots == null || disabledSlots!.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = AppColors.neutral300.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Iterate through each disabled slot
    for (final slot in disabledSlots!) {
      // Check if slot is within current week
      if (slot.isBefore(weekStart) ||
          slot.isAfter(weekStart.add(const Duration(days: 7)))) {
        continue;
      }

      // Calculate day index (0 = Monday, 6 = Sunday)
      final dayIndex = slot.weekday - 1;
      if (dayIndex < 0 || dayIndex >= 7) {
        continue;
      }

      // Calculate slot index (0 = visibleStartHour:00, 1 = visibleStartHour:15, etc.)
      final slotHour = slot.hour;
      final slotMinute = slot.minute;

      // Check if slot is within visible hour range
      if (slotHour < visibleStartHour || slotHour >= visibleEndHour) {
        continue;
      }

      // Calculate slot index relative to visible start hour
      // Each hour has 4 slots (0, 15, 30, 45 minutes)
      final slotIndex = (slotHour - visibleStartHour) * 4 + (slotMinute ~/ 15);

      // Calculate rectangle position
      final left = timeColumnWidth + dayIndex * dayColumnWidth;
      final top = slotIndex * slotHeight;
      final right = left + dayColumnWidth;
      final bottom = top + slotHeight * 2; // 30 minutes = 2 slots of 15 minutes

      // Draw gray rectangle
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DisabledSlotsPainter oldDelegate) {
    return disabledSlots != oldDelegate.disabledSlots ||
        weekStart != oldDelegate.weekStart ||
        visibleStartHour != oldDelegate.visibleStartHour ||
        visibleEndHour != oldDelegate.visibleEndHour;
  }
}
