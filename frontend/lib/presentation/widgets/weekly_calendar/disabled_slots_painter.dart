import 'package:flutter/material.dart';
import 'dart:developer' as developer;
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
      developer.log(
        '⚠️ DisabledSlotsPainter: No disabled slots to paint',
        name: 'DisabledSlotsPainter',
      );
      return;
    }

    developer.log(
      '🎨 DisabledSlotsPainter: Painting ${disabledSlots!.length} disabled slots',
      name: 'DisabledSlotsPainter',
    );
    developer.log(
      '📅 WeekStart: ${weekStart.year}-${weekStart.month}-${weekStart.day} '
      '${weekStart.hour}:${weekStart.minute}:${weekStart.second}',
      name: 'DisabledSlotsPainter',
    );

    final paint = Paint()
      ..color = AppColors.neutral300.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    int paintedCount = 0;
    int mondayMorningCount = 0; // Count Monday morning slots (hour < 9)
    int filteredByWeekRange = 0; // Count slots filtered by week range

    // Iterate through each disabled slot
    for (final slot in disabledSlots!) {
      // Check if slot is within current week
      if (slot.isBefore(weekStart) ||
          slot.isAfter(weekStart.add(const Duration(days: 7)))) {
        filteredByWeekRange++;
        // Log first few filtered Monday slots for debugging
        if (filteredByWeekRange <= 3 && slot.weekday == 1) {
          developer.log(
            '🚫 Filtered by week range: ${slot.year}-${slot.month}-${slot.day} '
            '${slot.hour}:${slot.minute.toString().padLeft(2, '0')} '
            '(isBefore: ${slot.isBefore(weekStart)}, '
            'isAfter: ${slot.isAfter(weekStart.add(const Duration(days: 7)))})',
            name: 'DisabledSlotsPainter',
          );
        }
        continue;
      }

      // Calculate day index relative to weekStart (0 = first day of week, 6 = last day)
      // BUG FIX: Normalize to date-only (remove time) before calculating difference
      // This prevents time-of-day from affecting the day calculation
      final slotDateOnly = DateTime(slot.year, slot.month, slot.day);
      final weekStartDateOnly = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final dayIndex = slotDateOnly.difference(weekStartDateOnly).inDays;

      // Log first few Monday slots for debugging
      if (slot.weekday == 1 && mondayMorningCount < 3) {
        developer.log(
          '🔍 Monday slot: ${slot.year}-${slot.month}-${slot.day} ${slot.hour}:${slot.minute.toString().padLeft(2, '0')} '
          '→ dayIndex=$dayIndex (slotDateOnly=${slotDateOnly.month}/${slotDateOnly.day}, '
          'weekStartDateOnly=${weekStartDateOnly.month}/${weekStartDateOnly.day})',
          name: 'DisabledSlotsPainter',
        );
      }

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

      // Track Monday morning slots
      if (dayIndex == 0 && slotHour < 9) {
        mondayMorningCount++;
      }

      // Draw gray rectangle
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint,
      );
      paintedCount++;
    }

    developer.log(
      '✅ DisabledSlotsPainter: Painted $paintedCount slots '
      '(Monday morning: $mondayMorningCount, filtered by week range: $filteredByWeekRange)',
      name: 'DisabledSlotsPainter',
    );
  }

  @override
  bool shouldRepaint(covariant DisabledSlotsPainter oldDelegate) {
    return disabledSlots != oldDelegate.disabledSlots ||
        weekStart != oldDelegate.weekStart ||
        visibleStartHour != oldDelegate.visibleStartHour ||
        visibleEndHour != oldDelegate.visibleEndHour;
  }
}
