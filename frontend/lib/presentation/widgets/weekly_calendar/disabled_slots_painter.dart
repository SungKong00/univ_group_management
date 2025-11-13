import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../../core/theme/app_colors.dart';

/// Paints disabled time slots as gray cells
///
/// Disabled slots are unavailable time periods (outside operating hours,
/// already reserved, or blocked by admin).
///
/// Visual Design:
/// - Background: AppColors.neutral400 with 45% opacity
/// - Allows viewing of underlying events (group timetable) through semi-transparency
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
      ..color = AppColors.neutral400.withOpacity(0.55)
      ..style = PaintingStyle.fill;

    // Iterate through each disabled slot
    for (final slot in disabledSlots!) {
      // Check if slot is within current week
      if (slot.isBefore(weekStart) ||
          slot.isAfter(weekStart.add(const Duration(days: 7)))) {
        continue;
      }

      // Calculate day index relative to weekStart (0 = first day of week, 6 = last day)
      // BUG FIX: Normalize to date-only (remove time) before calculating difference
      // This prevents time-of-day from affecting the day calculation
      final slotDateOnly = DateTime(slot.year, slot.month, slot.day);
      final weekStartDateOnly = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
      );
      final dayIndex = slotDateOnly.difference(weekStartDateOnly).inDays;

      // Debug: Log if we find slots outside the current week
      if (dayIndex < 0 || dayIndex >= 7) {
        developer.log(
          '⚠️ Slot outside week range: ${slot.month}/${slot.day} ${slot.hour}:${slot.minute.toString().padLeft(2, '0')} '
          '(dayIndex=$dayIndex, weekStart=${weekStart.month}/${weekStart.day})',
          name: 'DisabledSlotsPainter',
          level: 900,
        );
        continue;
      }

      // Calculate slot index (0 = visibleStartHour:00, 1 = visibleStartHour:30, etc.)
      final slotHour = slot.hour;
      final slotMinute = slot.minute;

      // Check if slot is within visible hour range
      if (slotHour < visibleStartHour || slotHour >= visibleEndHour) {
        continue;
      }

      // Calculate slot index relative to visible start hour
      // Each hour has 4 slots (0, 15, 30, 45 minutes) - each slot = 15 minutes
      final slotIndex = (slotHour - visibleStartHour) * 4 + (slotMinute ~/ 15);

      // Calculate rectangle position
      final left = timeColumnWidth + dayIndex * dayColumnWidth;
      final top = slotIndex * slotHeight;
      final right = left + dayColumnWidth;

      // Each disabled slot represents exactly 15 minutes (1 block)
      // This ensures uniform rendering without overlap or gaps
      final blocksToePaint = 1;
      final bottom = top + slotHeight * blocksToePaint;

      // Draw gray rectangle
      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);
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
