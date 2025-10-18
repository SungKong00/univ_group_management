import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/calendar/group_event.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/calendar/calendar_event.dart';
import '../../../presentation/providers/group_calendar_provider.dart';
import 'time_grid_painter.dart';

/// External events overlay for displaying group calendar events on weekly schedule editor.
///
/// Features:
/// - Multi-group selection with checkboxes
/// - Week navigation (previous/next/today)
/// - Loading/error state per group
/// - Group event → CalendarEvent conversion
/// - Color-coded events by group
///
/// Usage Example:
/// ```dart
/// class MyCalendarPage extends StatefulWidget {
///   @override
///   State<MyCalendarPage> createState() => _MyCalendarPageState();
/// }
///
/// class _MyCalendarPageState extends State<MyCalendarPage> {
///   DateTime _weekStart = _getWeekStart(DateTime.now());
///   List<CalendarEvent> _externalEvents = [];
///
///   DateTime _getWeekStart(DateTime date) {
///     return date.subtract(Duration(days: date.weekday - 1));
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: Text('캘린더')),
///       body: Column(
///         children: [
///           // External events overlay (group calendars)
///           Expanded(
///             flex: 2,
///             child: ExternalEventsOverlay(
///               selectedGroupIds: [1, 2, 3], // User's joined groups
///               weekStart: _weekStart,
///               onWeekChanged: (newWeekStart) {
///                 setState(() => _weekStart = newWeekStart);
///               },
///               onEventsLoaded: (events) {
///                 setState(() => _externalEvents = events);
///               },
///             ),
///           ),
///           Divider(height: 1),
///           // Personal schedule editor
///           Expanded(
///             flex: 3,
///             child: WeeklyScheduleEditor(
///               allowMultiDaySelection: false,
///               isEditable: true,
///             ),
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
class ExternalEventsOverlay extends StatefulWidget {
  /// List of selected group IDs to display events from
  final List<int> selectedGroupIds;

  /// Start date of the week to display (Monday)
  final DateTime weekStart;

  /// Callback when week changes (triggered by navigation buttons)
  final ValueChanged<DateTime> onWeekChanged;

  /// Callback when events are loaded (passes all loaded events)
  final ValueChanged<List<CalendarEvent>>? onEventsLoaded;

  /// Show loading state (spinner in header)
  final bool showLoadingState;

  const ExternalEventsOverlay({
    super.key,
    required this.selectedGroupIds,
    required this.weekStart,
    required this.onWeekChanged,
    this.onEventsLoaded,
    this.showLoadingState = true,
  });

  @override
  State<ExternalEventsOverlay> createState() => _ExternalEventsOverlayState();
}

class _ExternalEventsOverlayState extends State<ExternalEventsOverlay> {
  // Group-specific state tracking
  final Map<int, List<CalendarEvent>> _eventsByGroup = {};
  final Map<int, bool> _isLoadingByGroup = {};
  final Map<int, String?> _errorByGroup = {};

  // Group toggle state (which groups to display)
  final Set<int> _enabledGroupIds = {};

  // Grid geometry (matching WeeklyScheduleEditor)
  final double _timeColumnWidth = 50.0;
  final double _dayRowHeight = 50.0;
  final int _startHour = 0;
  final int _endHour = 24;
  final int _daysInWeek = 7;
  final double _minSlotHeight = 20.0; // 15-minute slot height

  @override
  void initState() {
    super.initState();
    // Enable all groups by default
    _enabledGroupIds.addAll(widget.selectedGroupIds);
    _loadEventsForAllGroups();
  }

  @override
  void didUpdateWidget(ExternalEventsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload if week or group selection changed
    if (oldWidget.weekStart != widget.weekStart ||
        oldWidget.selectedGroupIds != widget.selectedGroupIds) {
      _loadEventsForAllGroups();
    }
  }

  /// Calculate week end date (Sunday) from week start (Monday)
  DateTime get _weekEnd => widget.weekStart.add(const Duration(days: 6));

  /// Get week start from any date (finds Monday of that week)
  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Load events for all selected groups
  Future<void> _loadEventsForAllGroups() async {
    for (final groupId in widget.selectedGroupIds) {
      await _loadEventsForGroup(groupId);
    }

    // Notify parent with all loaded events
    _notifyEventsLoaded();
  }

  /// Load events for a specific group
  Future<void> _loadEventsForGroup(int groupId) async {
    setState(() {
      _isLoadingByGroup[groupId] = true;
      _errorByGroup[groupId] = null;
    });

    try {
      // Use groupCalendarProvider to fetch events
      final container = ProviderContainer();
      final notifier = container.read(groupCalendarProvider(groupId).notifier);

      await notifier.loadEvents(
        groupId: groupId,
        startDate: widget.weekStart,
        endDate: _weekEnd,
      );

      final state = container.read(groupCalendarProvider(groupId));

      if (state.errorMessage != null) {
        throw Exception(state.errorMessage);
      }

      // Convert GroupEvent → CalendarEvent
      final calendarEvents = state.events
          .map((groupEvent) => _convertToCalendarEvent(groupEvent))
          .toList();

      setState(() {
        _eventsByGroup[groupId] = calendarEvents;
        _isLoadingByGroup[groupId] = false;
      });

      container.dispose();
    } catch (e) {
      setState(() {
        _isLoadingByGroup[groupId] = false;
        _errorByGroup[groupId] = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Convert GroupEvent to CalendarEvent
  CalendarEvent _convertToCalendarEvent(GroupEvent groupEvent) {
    return CalendarEvent(
      id: groupEvent.id.toString(),
      title: groupEvent.title,
      startTime: groupEvent.startDate,
      endTime: groupEvent.endDate,
      place: groupEvent.location,
      isOfficial: groupEvent.isOfficial,
    );
  }

  /// Notify parent widget with all loaded events from enabled groups
  void _notifyEventsLoaded() {
    if (widget.onEventsLoaded == null) return;

    final allEvents = <CalendarEvent>[];
    for (final groupId in _enabledGroupIds) {
      final events = _eventsByGroup[groupId];
      if (events != null) {
        allEvents.addAll(events);
      }
    }

    widget.onEventsLoaded!(allEvents);
  }

  /// Toggle group visibility
  void _toggleGroup(int groupId, bool enabled) {
    setState(() {
      if (enabled) {
        _enabledGroupIds.add(groupId);
      } else {
        _enabledGroupIds.remove(groupId);
      }
    });

    _notifyEventsLoaded();
  }

  /// Navigate to previous week
  void _previousWeek() {
    final newWeekStart = widget.weekStart.subtract(const Duration(days: 7));
    widget.onWeekChanged(newWeekStart);
  }

  /// Navigate to next week
  void _nextWeek() {
    final newWeekStart = widget.weekStart.add(const Duration(days: 7));
    widget.onWeekChanged(newWeekStart);
  }

  /// Navigate to current week (today)
  void _goToToday() {
    final today = DateTime.now();
    final newWeekStart = _getWeekStart(today);
    widget.onWeekChanged(newWeekStart);
  }

  /// Format week range for header display
  String _formatWeekRange() {
    final startMonth = widget.weekStart.month;
    final startDay = widget.weekStart.day;
    final endMonth = _weekEnd.month;
    final endDay = _weekEnd.day;

    if (startMonth == endMonth) {
      return '${widget.weekStart.year}년 $startMonth월 $startDay-$endDay일';
    } else {
      return '${widget.weekStart.year}년 $startMonth월 $startDay일 - $endMonth월 $endDay일';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Navigation Header
        _buildNavigationHeader(),
        const SizedBox(height: AppSpacing.sm),

        // Group Toggle Panel
        _buildGroupTogglePanel(),
        const SizedBox(height: AppSpacing.md),

        // Calendar Grid with external events
        Expanded(
          child: SingleChildScrollView(
            child: _buildCalendarGrid(),
          ),
        ),
      ],
    );
  }

  /// Build navigation header with week controls
  Widget _buildNavigationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous week button
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousWeek,
            tooltip: '이전 주',
          ),

          // Week range display
          Expanded(
            child: Center(
              child: Text(
                _formatWeekRange(),
                style: AppTheme.titleMedium,
              ),
            ),
          ),

          // Next week button
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextWeek,
            tooltip: '다음 주',
          ),

          const SizedBox(width: AppSpacing.xxs),

          // Today button
          OutlinedButton.icon(
            onPressed: _goToToday,
            icon: const Icon(Icons.today, size: 16),
            label: const Text('오늘'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build group toggle panel with checkboxes
  Widget _buildGroupTogglePanel() {
    if (widget.selectedGroupIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel header
          Text(
            '그룹 일정 표시',
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),

          // Group checkboxes
          ...widget.selectedGroupIds.map((groupId) {
            final isEnabled = _enabledGroupIds.contains(groupId);
            final isLoading = _isLoadingByGroup[groupId] ?? false;
            final error = _errorByGroup[groupId];
            final eventCount = _eventsByGroup[groupId]?.length ?? 0;

            return _buildGroupToggleItem(
              groupId: groupId,
              isEnabled: isEnabled,
              isLoading: isLoading,
              error: error,
              eventCount: eventCount,
            );
          }),
        ],
      ),
    );
  }

  /// Build individual group toggle item
  Widget _buildGroupToggleItem({
    required int groupId,
    required bool isEnabled,
    required bool isLoading,
    String? error,
    required int eventCount,
  }) {
    // Get group color (cycling through palette)
    final groupColor = _getGroupColor(groupId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs / 2),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: isEnabled,
            onChanged: (value) => _toggleGroup(groupId, value ?? false),
          ),

          // Color indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: groupColor,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: AppSpacing.xxs),

          // Group name/ID and event count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group $groupId', // TODO: Get actual group name
                  style: AppTheme.bodyMedium,
                ),
                if (!isLoading && error == null)
                  Text(
                    '$eventCount개 일정',
                    style: AppTheme.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),

          // Loading/error state
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),

          if (error != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => _loadEventsForGroup(groupId),
              tooltip: '다시 시도',
              color: Theme.of(context).colorScheme.error,
            ),
        ],
      ),
    );
  }

  /// Get color for group (cycling through palette)
  Color _getGroupColor(int groupId) {
    final colors = [
      const Color(0xFF5C068C), // Violet (brand)
      const Color(0xFF1E6FFF), // Blue
      const Color(0xFF10B981), // Teal/Green
      const Color(0xFFF59E0B), // Orange
      const Color(0xFFE63946), // Red
      const Color(0xFF8B5CF6), // Purple
    ];

    return colors[groupId % colors.length];
  }

  /// Convert CalendarEvent to Rect for rendering
  Rect _eventToRect(CalendarEvent event, double dayColumnWidth) {
    // Find day of week (0 = Monday)
    final dayOfWeek = event.startTime.weekday - 1;

    // Calculate slot positions (4 slots per hour, 15 min each)
    final startMinutes = event.startTime.hour * 60 + event.startTime.minute;
    final endMinutes = event.endTime.hour * 60 + event.endTime.minute;

    final startSlot = startMinutes ~/ 15;
    final endSlot = endMinutes ~/ 15;

    // Calculate rect position
    final left = _timeColumnWidth + dayOfWeek * dayColumnWidth;
    final top = _dayRowHeight + startSlot * _minSlotHeight;
    final right = left + dayColumnWidth;
    final bottom = _dayRowHeight + endSlot * _minSlotHeight;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Build calendar grid with external events overlay
  Widget _buildCalendarGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double dayColumnWidth =
            (constraints.maxWidth - _timeColumnWidth) / _daysInWeek;
        final double contentHeight =
            _dayRowHeight + (_endHour - _startHour) * 4 * _minSlotHeight;

        // Collect all enabled events with their rects and colors
        final List<({Rect rect, String title, Color color})> eventRects = [];

        for (final groupId in _enabledGroupIds) {
          final events = _eventsByGroup[groupId];
          if (events == null) continue;

          final groupColor = _getGroupColor(groupId);

          for (final event in events) {
            // Filter events within current week
            if (event.startTime.isAfter(_weekEnd) ||
                event.endTime.isBefore(widget.weekStart)) {
              continue;
            }

            final rect = _eventToRect(event, dayColumnWidth);
            eventRects.add((
              rect: rect,
              title: event.title,
              color: groupColor,
            ));
          }
        }

        return SizedBox(
          height: contentHeight,
          child: Stack(
            children: [
              // Time grid background
              CustomPaint(
                painter: TimeGridPainter(
                  startHour: _startHour,
                  endHour: _endHour,
                  timeColumnWidth: _timeColumnWidth,
                  dayRowHeight: _dayRowHeight,
                ),
                size: Size(constraints.maxWidth, contentHeight),
              ),

              // External events overlay
              CustomPaint(
                painter: _ExternalEventsPainter(events: eventRects),
                size: Size(constraints.maxWidth, contentHeight),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for external events with transparency
class _ExternalEventsPainter extends CustomPainter {
  final List<({Rect rect, String title, Color color})> events;

  _ExternalEventsPainter({required this.events});

  @override
  void paint(Canvas canvas, Size size) {
    for (final event in events) {
      // Draw event block with 0.7 opacity
      final paint = Paint()
        ..color = event.color.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;

      final rrect =
          RRect.fromRectAndRadius(event.rect, const Radius.circular(4));
      canvas.drawRRect(rrect, paint);

      // Draw border for better visibility
      final borderPaint = Paint()
        ..color = event.color.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawRRect(rrect, borderPaint);

      // Draw title text
      final textPainter = TextPainter(
        text: TextSpan(
          text: event.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        maxLines: 2,
        ellipsis: '...',
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(
        minWidth: 0,
        maxWidth: event.rect.width - 8,
      );

      textPainter.paint(
        canvas,
        event.rect.topLeft + const Offset(4, 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ExternalEventsPainter oldDelegate) {
    if (oldDelegate.events.length != events.length) return true;

    for (int i = 0; i < events.length; i++) {
      if (oldDelegate.events[i] != events[i]) return true;
    }

    return false;
  }
}
