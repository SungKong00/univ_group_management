import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Reusable weekly navigation header component
///
/// Features:
/// - Navigate between weeks using arrow buttons
/// - Display current week date range (format: YYYY.M.D - M.D)
/// - "Today" button to return to current week
/// - "+" button to add new event
/// - Callback for week changes and add action
///
/// Design System:
/// - AppTheme.bodyMedium for date text
/// - AppSpacing.sm for padding
/// - AppSpacing.xs for button spacing
/// - Material Design IconButtons and OutlinedButton
///
/// Reusability:
/// - StatefulWidget with internal state management
/// - External changes only via callbacks
/// - Flexible button visibility with props
class WeeklyNavigationHeader extends StatefulWidget {
  /// Initial week start date (Monday)
  /// If null, defaults to current week
  final DateTime? initialWeekStart;

  /// Callback when week changes
  /// Passes the new week start date (Monday)
  final Function(DateTime weekStart)? onWeekChanged;

  /// Callback when "+" button is pressed
  /// Passes the current week start date
  final Function(DateTime weekStart)? onAddPressed;

  /// Show "+" button
  final bool showAddButton;

  /// Show "Today" button
  final bool showTodayButton;

  const WeeklyNavigationHeader({
    super.key,
    this.initialWeekStart,
    this.onWeekChanged,
    this.onAddPressed,
    this.showAddButton = true,
    this.showTodayButton = true,
  });

  @override
  State<WeeklyNavigationHeader> createState() => _WeeklyNavigationHeaderState();
}

class _WeeklyNavigationHeaderState extends State<WeeklyNavigationHeader> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = widget.initialWeekStart ?? _getWeekStart(DateTime.now());
  }

  /// Get week start (Monday) from any date
  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Get week end (Sunday) from week start
  DateTime _getWeekEnd(DateTime weekStart) {
    return weekStart.add(const Duration(days: 6));
  }

  /// Format date range as "YYYY.M.D - M.D"
  String _formatDateRange(DateTime start, DateTime end) {
    final startStr = '${start.year}.${start.month}.${start.day}';
    final endStr = '${end.month}.${end.day}';
    return '$startStr - $endStr';
  }

  /// Go to previous week
  void _previousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
    widget.onWeekChanged?.call(_weekStart);
  }

  /// Go to next week
  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
    });
    widget.onWeekChanged?.call(_weekStart);
  }

  /// Go to today's week
  void _todayWeek() {
    setState(() {
      _weekStart = _getWeekStart(DateTime.now());
    });
    widget.onWeekChanged?.call(_weekStart);
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = _getWeekEnd(_weekStart);
    final dateRange = _formatDateRange(_weekStart, weekEnd);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Center: Date navigation (< date >)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousWeek,
                tooltip: '이전 주',
                iconSize: 24,
              ),
              Text(dateRange, style: AppTheme.bodyMedium),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextWeek,
                tooltip: '다음 주',
                iconSize: 24,
              ),
            ],
          ),

          const Spacer(),

          // Right: Today button (and Add button if needed)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showTodayButton)
                OutlinedButton(
                  onPressed: _todayWeek,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('오늘', style: TextStyle(fontSize: 13)),
                ),
              if (widget.showAddButton) const SizedBox(width: AppSpacing.xs),
              if (widget.showAddButton)
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => widget.onAddPressed?.call(_weekStart),
                  tooltip: '일정 추가',
                  iconSize: 20,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
