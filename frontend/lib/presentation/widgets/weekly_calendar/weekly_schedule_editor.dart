import 'dart:async';
import '../../../core/utils/snack_bar_helper.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';
import '../../../core/models/calendar/group_event.dart';
import '../../../core/models/place/place.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'disabled_slots_painter.dart';
import 'event_create_dialog.dart';
import 'event_painter.dart';
import 'fixed_duration_preview_painter.dart';
import 'highlight_painter.dart';
import 'selection_painter.dart';
import 'time_grid_painter.dart';
import 'weekly_schedule_editor_painter.dart';
import '../buttons/neutral_outlined_button.dart';
import '../buttons/error_button.dart';
import '../buttons/primary_button.dart';

typedef Event = ({String id, String title, ({int day, int slot}) start, ({int day, int slot}) end, DateTime? startTime, DateTime? endTime});

/// Calculate event position (top, height) based on DateTime or slot
///
/// **Shared utility for calendar rendering**
/// - DateTime-based (precise minute positioning) if available
/// - Slot-based (15-minute granularity) as fallback
///
/// Parameters:
/// - [event]: Event with start/end times
/// - [slotHeight]: Height of a 15-minute slot in pixels
/// - [referenceStartHour]: Hour offset for the visible range (e.g., 0 for full day, 9 for 9am start)
/// - [minSlot]: Optional minimum slot offset (for modal's cropped time range)
({double top, double height}) calculateEventPosition({
  required Event event,
  required double slotHeight,
  required int referenceStartHour,
  int? minSlot,
}) {
  if (event.startTime != null && event.endTime != null) {
    // DateTime-based precise calculation
    final startMinutes = event.startTime!.hour * 60 + event.startTime!.minute;
    final endMinutes = event.endTime!.hour * 60 + event.endTime!.minute;

    // Reference point: start of visible range (accounting for minSlot if provided)
    final referenceMinutes = referenceStartHour * 60 + (minSlot ?? 0) * 15;

    // Calculate offset from reference point
    final minutesFromReference = startMinutes - referenceMinutes;
    final top = (minutesFromReference / 15.0) * slotHeight;

    // Calculate duration
    final durationMinutes = endMinutes - startMinutes;
    final height = (durationMinutes / 15.0) * slotHeight;

    return (top: top, height: height);
  } else {
    // Slot-based fallback (15-minute granularity)
    final eventStartSlot = math.min(event.start.slot, event.end.slot);
    final eventEndSlot = math.max(event.start.slot, event.end.slot);

    final top = minSlot != null
        ? (eventStartSlot - minSlot) * slotHeight
        : (eventStartSlot - referenceStartHour * 4) * slotHeight;

    final duration = eventEndSlot - eventStartSlot + 1;
    final height = duration * slotHeight;

    return (top: top, height: height);
  }
}

/// Calendar interaction mode
enum CalendarMode {
  add,   // Add new events (ignores existing event blocks)
  edit,  // Edit/delete existing events
  view,  // Read-only mode
}

/// Haptic feedback intensity types
enum HapticFeedbackType {
  medium,  // Strong feedback for important actions
  light,   // Light feedback for completion
  selection, // Subtle feedback for selection changes
}

/// Weekly Schedule Editor with platform-specific gesture handling
///
/// Web: MouseRegion-based hover feedback with two-click selection
/// Mobile: Long press + drag gesture for intuitive touch interaction
///
/// Features:
/// - Real-time visual feedback during selection
/// - Backward time selection prevention
/// - Optional multi-day selection
/// - Event overlap detection
/// - Haptic feedback on mobile
/// - External group events display (read-only)
class WeeklyScheduleEditor extends StatefulWidget {
  /// Allow selecting time range across multiple days
  final bool allowMultiDaySelection;

  /// Enable/disable editing capabilities
  final bool isEditable;

  /// Allow creating overlapping events
  final bool allowEventOverlap;

  /// External group events to display (read-only)
  final List<GroupEvent>? externalEvents;

  /// Current week start date (Monday) for filtering events
  final DateTime? weekStart;

  /// Group colors for event rendering
  final Map<int, Color>? groupColors;

  /// Disabled time slots (for place reservation system)
  /// Set of DateTime objects representing 30-minute slots that are unavailable
  final Set<DateTime>? disabledSlots;

  /// Available places from filter selection (for event creation dialog)
  final List<Place>? availablePlaces;

  /// Map of place ID to disabled slots for that specific place
  final Map<int, Set<DateTime>>? disabledSlotsByPlace;

  /// Pre-selected place ID (auto-fill from filter selection)
  final int? preSelectedPlaceId;

  /// Required duration for fixed-duration mode (multiple places selected)
  /// When set, enables single-click reservation with fixed time blocks
  final Duration? requiredDuration;

  const WeeklyScheduleEditor({
    super.key,
    this.allowMultiDaySelection = false,
    this.isEditable = true,
    this.allowEventOverlap = true,
    this.externalEvents,
    this.weekStart,
    this.groupColors,
    this.disabledSlots,
    this.availablePlaces,
    this.disabledSlotsByPlace,
    this.preSelectedPlaceId,
    this.requiredDuration,
  });

  @override
  State<WeeklyScheduleEditor> createState() => _WeeklyScheduleEditorState();
}

class _WeeklyScheduleEditorState extends State<WeeklyScheduleEditor> {
  final GlobalKey _gestureContentKey = GlobalKey();
  // Grid Geometry
  final double _timeColumnWidth = 50.0;
  final double _dayRowHeight = 50.0;
  final int _startHour = 0;
  final int _endHour = 24;
  final int _daysInWeek = 7;
  final double _minSlotHeight = 20.0; // Minimum height for a 15-minute slot

  // State
  final List<Event> _events = [];
  CalendarMode _mode = CalendarMode.add; // Default to add mode
  bool _isOverlapView = true; // Default to overlap view (side-by-side)
  bool _isSelecting = false;
  ({int day, int slot})? _startCell;
  ({int day, int slot})? _endCell;
  Rect? _selectionRect;
  Rect? _highlightRect;
  Offset? _activePointerGlobalPosition;

  // Fixed Duration Mode state
  Rect? _durationPreviewRect; // Preview rect for fixed duration mode
  ({int day, int slot})? _previewStartCell; // Current preview start cell

  late int _visibleStartHour;
  late int _visibleEndHour;
  bool _hasAppliedInitialScroll = false;
  double _currentDayColumnWidth = 0;
  double _currentContentHeight = 0;
  double _currentViewportHeight = 0; // 실제 화면에 보이는 뷰포트 높이

  // Auto-scroll
  late ScrollController _scrollController;
  Timer? _autoScrollTimer;
  static const double _edgeScrollThreshold = 50.0; // Pixels from edge to trigger scroll
  static const double _scrollSpeed = 5.0; // Pixels per timer tick (reduced from 30.0)
  int _autoScrollDirection = 0;
  double _autoScrollDayColumnWidth = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final initialRange = _calculateVisibleHourRange();
    _visibleStartHour = initialRange.startHour;
    _visibleEndHour = initialRange.endHour;
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyInitialScrollIfNeeded());
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _scrollController.dispose();
    super.dispose();
  }

  RenderBox? get _gestureRenderBox =>
      _gestureContentKey.currentContext?.findRenderObject() as RenderBox?;

  Offset _globalToGestureLocal(Offset globalPosition) {
    final renderBox = _gestureRenderBox;
    if (renderBox == null) {
      return Offset.zero;
    }
    return renderBox.globalToLocal(globalPosition);
  }

  Offset _clampLocalToContent(Offset position, double dayColumnWidth) {
    final double maxWidth = math.max(
      _timeColumnWidth + dayColumnWidth * _daysInWeek,
      _timeColumnWidth + 1,
    );
    final double maxHeight = math.max(_currentContentHeight, 1.0);

    final double clampedX = position.dx.clamp(0.0, maxWidth);
    final double clampedY = position.dy.clamp(0.0, maxHeight - 1);
    return Offset(clampedX, clampedY);
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _autoScrollDirection = 0;
  }

  void _performAutoScrollTick() {
    if (!_scrollController.hasClients || _autoScrollDirection == 0) {
      _stopAutoScroll();
      return;
    }

    final double maxExtent = _scrollController.position.maxScrollExtent;
    final double targetOffset = (_scrollController.offset + _autoScrollDirection * _scrollSpeed)
        .clamp(0.0, maxExtent);

    if (targetOffset == _scrollController.offset) {
      _stopAutoScroll();
      return;
    }

    _scrollController.jumpTo(targetOffset);

    if (_activePointerGlobalPosition != null) {
      _updateSelectionFromPointer(
        _activePointerGlobalPosition!,
        _autoScrollDayColumnWidth,
        checkAutoScroll: false,
      );
    }
  }

  DateTime get _effectiveWeekStart => widget.weekStart ?? _getWeekStart(DateTime.now());

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  ({int startHour, int endHour}) _calculateVisibleHourRange({CalendarMode? modeOverride}) {
    final CalendarMode mode = modeOverride ?? _mode;

    if (mode == CalendarMode.add) {
      return (startHour: 0, endHour: 24);
    }

    final allEvents = _getAllEvents();
    if (allEvents.isEmpty) {
      return (startHour: 9, endHour: 18);
    }

    int minSlot = (_endHour - _startHour) * 4;
    int maxSlot = 0;
    for (final event in allEvents) {
      final int eventStart = math.min(event.start.slot, event.end.slot);
      final int eventEnd = math.max(event.start.slot, event.end.slot);
      if (eventStart < minSlot) minSlot = eventStart;
      if (eventEnd > maxSlot) maxSlot = eventEnd;
    }

    // Convert to hour boundaries, ensuring the default 9-18 range is preserved
    int computedStartHour = (minSlot / 4).floor();
    int computedEndHour = ((maxSlot + 1) / 4).ceil();

    computedStartHour = math.min(computedStartHour, 9);
    computedEndHour = math.max(computedEndHour, 18);

    computedStartHour = computedStartHour.clamp(0, 23);
    computedEndHour = computedEndHour.clamp(computedStartHour + 1, 24);

    return (startHour: computedStartHour, endHour: computedEndHour);
  }

  void _applyInitialScrollIfNeeded() {
    if (!mounted) return;
    if (_hasAppliedInitialScroll) return;
    if (!_scrollController.hasClients) return;

    final int desiredHour = _mode == CalendarMode.add ? 9 : _visibleStartHour;
    final int clampedHour = desiredHour.clamp(_visibleStartHour, _visibleEndHour - 1);
    final double offset = (clampedHour - _visibleStartHour) * 4 * _minSlotHeight;

    final double maxExtent = _scrollController.position.maxScrollExtent;
    final double targetOffset = offset.clamp(0.0, maxExtent);

    if (_scrollController.offset != targetOffset) {
      _scrollController.jumpTo(targetOffset);
    }

    _hasAppliedInitialScroll = true;
  }

  void _updateVisibleRangeForCurrentState() {
    final range = _calculateVisibleHourRange();
    if (_visibleStartHour != range.startHour || _visibleEndHour != range.endHour) {
      _visibleStartHour = range.startHour;
      _visibleEndHour = range.endHour;
      _hasAppliedInitialScroll = false;
    }
  }

  @override
  void didUpdateWidget(covariant WeeklyScheduleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newRange = _calculateVisibleHourRange();
    if (newRange.startHour != _visibleStartHour || newRange.endHour != _visibleEndHour) {
      setState(() {
        _visibleStartHour = newRange.startHour;
        _visibleEndHour = newRange.endHour;
        _hasAppliedInitialScroll = false;
      });
    } else if (widget.weekStart != oldWidget.weekStart || widget.externalEvents != oldWidget.externalEvents) {
      _hasAppliedInitialScroll = false;
    }
  }

  // --- External Event Processing ---

  /// Convert GroupEvent to internal Event format
  /// Filters events within the current week
  List<Event> _convertGroupEventsToEvents(List<GroupEvent> groupEvents, DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final List<Event> convertedEvents = [];

    // Only log when there are events to process
    if (groupEvents.isEmpty) {
      return convertedEvents;
    }

    debugPrint('[WeeklyScheduleEditor] Converting ${groupEvents.length} events for week: $weekStart ~ $weekEnd');

    for (final groupEvent in groupEvents) {
      // Filter events within the current week
      if (groupEvent.startDateTime.isBefore(weekEnd) && groupEvent.endDateTime.isAfter(weekStart)) {
        // Calculate day (0=Monday, 6=Sunday)
        int eventDay = groupEvent.startDateTime.weekday - 1;
        if (eventDay >= _daysInWeek) eventDay = _daysInWeek - 1; // Cap at Sunday

        // Calculate start slot (15-minute intervals)
        final startHour = groupEvent.startDateTime.hour;
        final startMinute = groupEvent.startDateTime.minute;
        final startSlot = (startHour - _startHour) * 4 + (startMinute ~/ 15);

        // Calculate end slot
        final endHour = groupEvent.endDateTime.hour;
        final endMinute = groupEvent.endDateTime.minute;
        int endSlot = (endHour - _startHour) * 4 + (endMinute ~/ 15);

        // Handle all-day events or events extending beyond current view
        final totalSlots = (_endHour - _startHour) * 4;
        if (endSlot >= totalSlots) {
          endSlot = totalSlots - 1;
        }

        if (startSlot < totalSlots && endSlot >= 0 && startSlot <= endSlot) {
          convertedEvents.add((
            id: 'ext-${groupEvent.id}', // Prefix to distinguish external events
            title: groupEvent.title,
            start: (day: eventDay, slot: startSlot),
            end: (day: eventDay, slot: endSlot),
            startTime: groupEvent.startDateTime,  // Add DateTime for precise rendering
            endTime: groupEvent.endDateTime,      // Add DateTime for precise rendering
          ));
          debugPrint('  ✓ Added: ${groupEvent.title} (Day: $eventDay, ${startSlot}-${endSlot})');
        }
      }
    }

    debugPrint('[WeeklyScheduleEditor] Result: ${convertedEvents.length}/${groupEvents.length} events rendered');
    return convertedEvents;
  }

  /// Get all events including external group events
  List<Event> _getAllEvents() {
    final allEvents = List<Event>.from(_events);

    // Add external group events
    if (widget.externalEvents != null && widget.weekStart != null) {
      final externalEvents = _convertGroupEventsToEvents(widget.externalEvents!, widget.weekStart!);
      allEvents.addAll(externalEvents);
    }

    return allEvents;
  }

  // --- Helper Functions ---

  /// New layout algorithm based on the provided Javascript snippet.
  Map<String, ({int columnIndex, int totalColumns, int span})> _calculateEventLayout(List<Event> events) {
    final Map<String, ({int columnIndex, int totalColumns, int span})> layout = {};
    final Map<int, List<Event>> eventsByDay = {};

    // 1. Group events by day
    for (final event in events) {
      eventsByDay.putIfAbsent(event.start.day, () => []).add(event);
    }

    // 2. Process each day independently
    for (final day in eventsByDay.keys) {
      final dayEvents = eventsByDay[day]!;
      // Sort events by start time to process them in order
      dayEvents.sort((a, b) => a.start.slot.compareTo(b.start.slot));

      final List<List<Event>> columns = [];

      // 3. Place events into columns
      for (final event in dayEvents) {
        bool placed = false;
        for (int i = 0; i < columns.length; i++) {
          bool overlaps = columns[i].any((existingEvent) => _eventsOverlap(event, existingEvent));
          if (!overlaps) {
            columns[i].add(event);
            placed = true;
            break;
          }
        }
        if (!placed) {
          columns.add([event]);
        }
      }

      final int totalColumns = columns.length;

      // Create a temporary map to store column index for each event
      final Map<String, int> eventColumnMap = {};
      for (int i = 0; i < columns.length; i++) {
        for (final event in columns[i]) {
          eventColumnMap[event.id] = i;
        }
      }

      // 4. Calculate column spans
      for (int i = 0; i < columns.length; i++) {
        for (final event in columns[i]) {
          int span = 1;
          for (int j = i + 1; j < columns.length; j++) {
            bool canSpan = !columns[j].any((otherEvent) => _eventsOverlap(event, otherEvent));
            if (canSpan) {
              span++;
            } else {
              break;
            }
          }
          layout[event.id] = (
            columnIndex: i,
            totalColumns: totalColumns,
            span: span,
          );
        }
      }
    }
    return layout;
  }


  /// Handle auto-scrolling when drag reaches screen edge
  void _handleEdgeScrolling(Offset globalPosition, double dayColumnWidth) {
    if (!_scrollController.hasClients) return;
    if (_currentViewportHeight <= 0) return; // 뷰포트 높이가 아직 설정되지 않음

    // Convert global position to local position (relative to calendar content area)
    final localPosition = _globalToGestureLocal(globalPosition);

    // Get current scroll offset
    final scrollOffset = _scrollController.offset;

    // Calculate viewport-relative Y position
    // localPosition.dy is relative to the entire content (including scrolled-away parts)
    // We need to convert it to viewport-relative position
    final viewportY = localPosition.dy - scrollOffset;

    // Top threshold: 현재 화면에 보이는 영역의 상단 기준
    const double topThreshold = _edgeScrollThreshold;

    // Bottom threshold: 현재 화면에 보이는 영역의 하단 기준
    // Use the saved viewport height instead of renderBox size
    final double bottomThreshold = _currentViewportHeight - _edgeScrollThreshold;

    int direction = 0;

    if (viewportY <= topThreshold) {
      direction = -1; // Scroll up
    } else if (viewportY >= bottomThreshold) {
      direction = 1; // Scroll down
    }

    if (direction == 0) {
      _stopAutoScroll();
    } else {
      _autoScrollDirection = direction;
      _autoScrollDayColumnWidth = dayColumnWidth;
      _autoScrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
        _performAutoScrollTick();
      });
    }
  }

  /// Enhanced haptic feedback with fallback to direct vibration
  Future<void> _triggerHaptic(HapticFeedbackType type) async {
    if (kIsWeb) return; // No haptic on web

    try {
      // 1️⃣ Try system haptic first
      switch (type) {
        case HapticFeedbackType.medium:
          HapticFeedback.mediumImpact();
          break;
        case HapticFeedbackType.light:
          HapticFeedback.lightImpact();
          break;
        case HapticFeedbackType.selection:
          HapticFeedback.selectionClick();
          break;
      }

      // 2️⃣ Fallback to direct vibration if system haptic might not work
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        final hasAmplitudeControl = await Vibration.hasAmplitudeControl();
        if (!hasAmplitudeControl) {
          // Device doesn't support amplitude control, use simple vibration
          switch (type) {
            case HapticFeedbackType.medium:
              Vibration.vibrate(duration: 100);
              break;
            case HapticFeedbackType.light:
              Vibration.vibrate(duration: 70);
              break;
            case HapticFeedbackType.selection:
              Vibration.vibrate(duration: 100); // Same as medium for noticeable feedback
              break;
          }
        }
      }
    } catch (e) {
      debugPrint('Haptic error: $e');
    }
  }

  ({int day, int slot}) _pixelToCell(Offset position, double dayColumnWidth) {
    final double slotHeight = _minSlotHeight;
    final int visibleSlots = (_visibleEndHour - _startHour) * 4;

    int day = ((position.dx - _timeColumnWidth) / dayColumnWidth).floor();
    day = day.clamp(0, _daysInWeek - 1);

    int slotOffset = (position.dy / slotHeight).floor();
    slotOffset = slotOffset.clamp(0, visibleSlots - 1);

    final int slot = slotOffset + _visibleStartHour * 4;

    return (day: day, slot: slot);
  }

  Rect _cellToRect(({int day, int slot}) start, ({int day, int slot}) end, double dayColumnWidth) {
    final double slotHeight = _minSlotHeight;

    final startDay = start.day < end.day ? start.day : end.day;
    final endDay = start.day > end.day ? start.day : end.day;
    final startSlot = start.slot < end.slot ? start.slot : end.slot;
    final endSlot = start.slot > end.slot ? start.slot : end.slot;

    return Rect.fromLTRB(
      _timeColumnWidth + startDay * dayColumnWidth,
      (startSlot - _visibleStartHour * 4) * slotHeight,
      _timeColumnWidth + (endDay + 1) * dayColumnWidth,
      (endSlot - _visibleStartHour * 4 + 1) * slotHeight,
    );
  }

  /// Convert Event to Rect with precise minute-level positioning
  /// Uses DateTime if available, falls back to slot-based calculation
  Rect _eventToRect(Event event, double dayColumnWidth) {
    // If event has precise DateTime, use minute-based calculation
    if (event.startTime != null && event.endTime != null) {
      return _eventToRectPrecise(event, dayColumnWidth);
    }

    // Fallback to slot-based calculation (15-minute granularity)
    return _cellToRect(event.start, event.end, dayColumnWidth);
  }

  /// Precise minute-based rect calculation for events with DateTime
  /// Uses shared calculateEventPosition() utility
  Rect _eventToRectPrecise(Event event, double dayColumnWidth) {
    // Use shared utility function for position calculation
    final position = calculateEventPosition(
      event: event,
      slotHeight: _minSlotHeight,
      referenceStartHour: _visibleStartHour,
    );

    // Day position (use the day from the cell for consistency)
    final int day = event.start.day;

    return Rect.fromLTRB(
      _timeColumnWidth + day * dayColumnWidth,
      position.top,
      _timeColumnWidth + (day + 1) * dayColumnWidth,
      position.top + position.height,
    );
  }
  int _eventStartSlot(Event event) => math.min(event.start.slot, event.end.slot);

  int _eventEndSlotExclusive(Event event) => math.max(event.start.slot, event.end.slot) + 1;

  bool _eventsOverlap(Event a, Event b) {
    // Check if events are on the same day. If not, they don't overlap.
    if (a.start.day != b.start.day) {
      return false;
    }
    final startA = _eventStartSlot(a);
    final endA = _eventEndSlotExclusive(a);
    final startB = _eventStartSlot(b);
    final endB = _eventEndSlotExclusive(b);
    return startA < endB && endA > startB;
  }

  bool _isOverlapping(({int day, int slot}) startCell, ({int day, int slot}) endCell) {
    final newStartSlot = startCell.slot < endCell.slot ? startCell.slot : endCell.slot;
    final newEndSlot = startCell.slot > endCell.slot ? startCell.slot : endCell.slot;

    for (final event in _events) {
      if (event.start.day == startCell.day) {
        final existingStartSlot = event.start.slot < event.end.slot ? event.start.slot : event.end.slot;
        final existingEndSlot = event.start.slot > event.end.slot ? event.start.slot : event.end.slot;

        if (newStartSlot < existingEndSlot && newEndSlot > existingStartSlot) {
          return true;
        }
      }
    }
    return false;
  }

  /// Find all events at a specific cell (including external group events)
  List<Event> _findEventsAtCell(({int day, int slot}) cell) {
    final List<Event> overlappingEvents = [];

    // Get all events including external group events
    final allEvents = _getAllEvents();

    for (final event in allEvents) {
      final eventStartSlot = event.start.slot < event.end.slot ? event.start.slot : event.end.slot;
      final eventEndSlot = event.start.slot > event.end.slot ? event.start.slot : event.end.slot;

      // Check if event is on the same day and overlaps with the cell
      if (event.start.day == cell.day && cell.slot >= eventStartSlot && cell.slot <= eventEndSlot) {
        overlappingEvents.add(event);
      }
    }

    return overlappingEvents;
  }

  /// Check if a cell is disabled (unavailable for selection)
  bool _isCellDisabled(({int day, int slot}) cell) {
    if (widget.disabledSlots == null || widget.disabledSlots!.isEmpty) {
      return false;
    }

    // Convert cell (day, slot) to DateTime
    final cellDate = _effectiveWeekStart.add(Duration(days: cell.day));
    final slotHour = _startHour + (cell.slot ~/ 4);
    final slotMinute = (cell.slot % 4) * 15;

    final cellDateTime = DateTime(
      cellDate.year,
      cellDate.month,
      cellDate.day,
      slotHour,
      slotMinute,
    );

    return widget.disabledSlots!.contains(cellDateTime);
  }

  // --- Fixed Duration Mode Helpers ---

  /// Check if we're in fixed duration mode
  bool get _isFixedDurationMode => widget.requiredDuration != null;

  /// Calculate end cell from start cell based on required duration (same day only)
  ({int day, int slot})? _calculateFixedDurationEndCell(({int day, int slot}) startCell) {
    if (widget.requiredDuration == null) return null;

    final int durationSlots = (widget.requiredDuration!.inMinutes / 15).ceil();
    final int endSlot = startCell.slot + durationSlots - 1;

    // Ensure we don't exceed 24 hours (96 slots)
    if (endSlot >= (_endHour - _startHour) * 4) {
      return null; // Duration exceeds day boundary
    }

    return (day: startCell.day, slot: endSlot);
  }

  /// Check if fixed duration selection is valid (no disabled slots, same day only)
  bool _isFixedDurationSelectionValid(({int day, int slot}) startCell) {
    final endCell = _calculateFixedDurationEndCell(startCell);
    if (endCell == null) return false;

    // Only check if the START cell is valid (white cell)
    // Allow preview even if end cells contain disabled slots
    // The user can see the preview and decide whether to book

    // Check if start cell is disabled
    if (_isCellDisabled(startCell)) return false;

    // Check for event overlap at start cell only (if overlap is not allowed)
    if (!widget.allowEventOverlap && _findEventsAtCell(startCell).isNotEmpty) {
      return false;
    }

    return true;
  }

  /// Update fixed duration preview based on current pointer position
  void _updateFixedDurationPreview(Offset localPosition, double dayColumnWidth) {
    if (!_isFixedDurationMode) return;

    final cell = _pixelToCell(localPosition, dayColumnWidth);

    // Check if cell is disabled - hide preview on grey cells
    if (_isCellDisabled(cell)) {
      setState(() {
        _durationPreviewRect = null;
        _previewStartCell = null;
      });
      return;
    }

    final endCell = _calculateFixedDurationEndCell(cell);
    if (endCell == null || !_isFixedDurationSelectionValid(cell)) {
      setState(() {
        _durationPreviewRect = null;
        _previewStartCell = null;
      });
      return;
    }

    setState(() {
      _previewStartCell = cell;
      _durationPreviewRect = _cellToRect(cell, endCell, dayColumnWidth);
    });
  }

  /// Clear fixed duration preview
  void _clearFixedDurationPreview() {
    if (_durationPreviewRect != null || _previewStartCell != null) {
      setState(() {
        _durationPreviewRect = null;
        _previewStartCell = null;
      });
    }
  }

  /// Confirm fixed duration selection and open event dialog
  void _confirmFixedDurationSelection() {
    if (_previewStartCell == null) return;

    final startCell = _previewStartCell!;
    final endCell = _calculateFixedDurationEndCell(startCell);

    if (endCell == null || !_isFixedDurationSelectionValid(startCell)) return;

    // Clear preview
    _clearFixedDurationPreview();

    // Show event creation dialog
    _showCreateDialog(startCell, endCell);
  }

  // --- Dialogs ---

  /// Check if event is external (read-only)
  bool _isExternalEvent(Event event) {
    return event.id.startsWith('ext-');
  }

  /// Show detail view dialog (read-only)
  void _showEventDetailDialog(Event event) {
    // 🟢 수정: event.startTime/endTime 우선 사용 (정확한 분 단위)
    // 없으면 slot 기반 계산 사용 (fallback)
    final startTime = event.startTime ??
        DateTime(2024, 1, 1, _startHour).add(Duration(minutes: event.start.slot * 15));
    final endTime = event.endTime ??
        DateTime(2024, 1, 1, _startHour).add(Duration(minutes: (event.end.slot + 1) * 15));
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final isExternal = _isExternalEvent(event);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        title: Row(
          children: [
            Icon(
              isExternal ? Icons.group : Icons.event,
              color: isExternal ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('일정 상세', style: AppTheme.headlineSmall),
                  if (isExternal)
                    Text(
                      '(그룹 일정 - 읽기 전용)',
                      style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              event.title,
              style: AppTheme.headlineSmall,
            ),
            SizedBox(height: AppSpacing.sm),
            // Day
            Row(
              children: [
                Icon(Icons.calendar_today, size: AppComponents.infoIconSize, color: Colors.grey),
                SizedBox(width: AppSpacing.xxs),
                Text(
                  dayNames[event.start.day],
                  style: AppTheme.bodyMedium.copyWith(color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xxs),
            // Time range
            Row(
              children: [
                Icon(Icons.access_time, size: AppComponents.infoIconSize, color: Colors.grey),
                SizedBox(width: AppSpacing.xxs),
                Text(
                  '${DateFormat.jm().format(startTime)} - ${DateFormat.jm().format(endTime)}',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!isExternal && _mode == CalendarMode.edit)
            PrimaryButton(
              text: '수정',
              onPressed: () {
                Navigator.of(context).pop();
                _showEditDialog(event);
              },
              variant: PrimaryButtonVariant.action,
            ),
          NeutralOutlinedButton(
            text: '닫기',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Show overlapping events selection dialog
  void _showOverlappingEventsDialog(List<Event> events, ({int day, int slot}) cell) {
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        title: Row(
          children: [
            Icon(Icons.layers, color: Theme.of(context).colorScheme.primary, size: 24),
            SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: Text('겹친 일정 (${events.length}개)', style: AppTheme.headlineSmall),
            ),
            // X 닫기 버튼
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: '닫기',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 24,
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 500,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 시각화 영역 (리스트 뷰가 제거되어 확장됨)
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: _OverlappingEventsVisualization(
                      events: events,
                      mode: _mode,
                      dayName: dayNames[events.first.start.day],
                      startHour: _startHour,
                      onEventTap: (event) {
                        // 모달 닫지 않고 새 모달 띄우기 (중첩)
                        if (_mode == CalendarMode.view) {
                          _showEventDetailDialog(event);
                        } else {
                          if (_isExternalEvent(event)) {
                            AppSnackBar.info(context, '그룹 일정은 수정할 수 없습니다.');
                          } else {
                            _showEditDialog(event);
                          }
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          NeutralOutlinedButton(
            text: '닫기',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Event event) {
    // Prevent editing external events
    if (_isExternalEvent(event)) {
      AppSnackBar.info(context, '그룹 일정은 수정할 수 없습니다.');
      return;
    }

    final titleController = TextEditingController(text: event.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 수정'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: '제목'),
        ),
        actions: [
          ErrorButton(
            text: '삭제',
            onPressed: () {
              setState(() {
                _events.removeWhere((e) => e.id == event.id);
                _updateVisibleRangeForCurrentState();
              });
              Navigator.of(context).pop();
            },
          ),
          NeutralOutlinedButton(
            text: '취소',
            onPressed: () => Navigator.of(context).pop(),
          ),
          PrimaryButton(
            text: '저장',
            onPressed: () {
              setState(() {
                final index = _events.indexWhere((e) => e.id == event.id);
                if (index != -1) {
                  _events[index] = (
                    id: event.id,
                    title: titleController.text,
                    start: event.start,
                    end: event.end,
                    startTime: event.startTime,  // Preserve DateTime
                    endTime: event.endTime,      // Preserve DateTime
                  );
                  _updateVisibleRangeForCurrentState();
                }
              });
              Navigator.of(context).pop();
            },
            variant: PrimaryButtonVariant.brand,
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(({int day, int slot}) startCell, ({int day, int slot}) endCell) async {
    // Calculate actual DateTime from cell positions and weekStart
    final weekStart = widget.weekStart ?? DateTime.now();
    final startDate = weekStart.add(Duration(days: startCell.day));
    final endDate = weekStart.add(Duration(days: endCell.day));

    final startTime = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      _startHour,
    ).add(Duration(minutes: startCell.slot * 15));

    final endTime = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      _startHour,
    ).add(Duration(minutes: (endCell.slot + 1) * 15));

    final result = await showDialog<EventCreateResult>(
      context: context,
      builder: (context) => EventCreateDialog(
        startTime: startTime,
        endTime: endTime,
        availablePlaces: widget.availablePlaces ?? [],
        disabledSlotsByPlace: widget.disabledSlotsByPlace ?? {},
        preSelectedPlaceId: widget.preSelectedPlaceId,
      ),
    );

    if (result == null) return; // User cancelled

    // Extract updated times from dialog result (if user modified them)
    final finalStartTime = result.startTime ?? startTime;
    final finalEndTime = result.endTime ?? endTime;

    // Check for overlap
    final isOverlapping = _isOverlapping(startCell, endCell);

    if (!widget.allowEventOverlap && isOverlapping) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('생성 불가'),
          content: const Text('겹치는 시��에는 일정을 생성할 수 없습니다.'),
          actions: [
            PrimaryButton(
              text: '확인',
              onPressed: () => Navigator.of(context).pop(),
              variant: PrimaryButtonVariant.brand,
            ),
          ],
        ),
      );
      return;
    }

    if (isOverlapping && mounted) {
      AppSnackBar.warning(context, '경고: 다른 일정과 겹칩니다.');
    }

    // Create event with DateTime info for precise rendering
    setState(() {
      _events.add((
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: result.title,
        start: startCell,
        end: endCell,
        startTime: finalStartTime,  // Store precise time
        endTime: finalEndTime,      // Store precise time
      ));
      _updateVisibleRangeForCurrentState();
    });

    // TODO: Handle location data (result.locationSelection)
    // This will require extending the Event typedef or creating a proper Event class
  }

  // --- Event Handlers ---

  /// Common logic to update selection during drag (used by both web and mobile)
  void _updateSelectionCell(
    Offset position,
    double dayColumnWidth, {
    bool enableHaptics = false,
  }) {
    if (!widget.isEditable || _startCell == null) return;

    final clampedPosition = _clampLocalToContent(position, dayColumnWidth);

    var currentCell = _pixelToCell(clampedPosition, dayColumnWidth);

    // Restrict to same day if multi-day selection is disabled
    if (!widget.allowMultiDaySelection) {
      currentCell = (day: _startCell!.day, slot: currentCell.slot);
    }

    // Haptic feedback when crossing cell boundary (mobile only)
    if (enableHaptics && _endCell != null && currentCell != _endCell) {
      _triggerHaptic(HapticFeedbackType.selection);
    }

    // Prevent backward time selection (hide selection rect as visual feedback)
    if (currentCell.slot < _startCell!.slot) {
      setState(() {
        _endCell = currentCell;
        _selectionRect = null;
        // Show current cell highlight during drag
        _highlightRect = _cellToRect(currentCell, currentCell, dayColumnWidth);
      });
    } else if (currentCell != _endCell) {
      setState(() {
        _endCell = currentCell;
        _selectionRect = _cellToRect(_startCell!, currentCell, dayColumnWidth);
        // Show current cell highlight during drag
        _highlightRect = _cellToRect(currentCell, currentCell, dayColumnWidth);
      });
    }
  }

  /// Complete the selection and show create dialog
  void _completeSelection() {
    final finalStartCell = _startCell;
    final finalEndCell = _endCell;

    _activePointerGlobalPosition = null;
    _stopAutoScroll();

    setState(() {
      _isSelecting = false;
      _startCell = null;
      _endCell = null;
      _selectionRect = null;
      _highlightRect = null; // Clear highlight on completion
    });

    if (finalStartCell != null && finalEndCell != null && finalEndCell.slot >= finalStartCell.slot) {
      _showCreateDialog(finalStartCell, finalEndCell);
    }
  }

  /// Handle tap for web (two-click mode)
  void _handleTap(Offset position, double dayColumnWidth, List<({Rect rect, Event event})> eventRects) {
    if (!widget.isEditable) return;

    final clampedPosition = _clampLocalToContent(position, dayColumnWidth);
    final cell = _pixelToCell(clampedPosition, dayColumnWidth);

    // Check if cell is disabled (gray cell)
    if (_isCellDisabled(cell)) {
      // Show snackbar message
      AppSnackBar.info(context, '이 시간대는 예약할 수 없습니다');
      return;
    }

    // Edit mode or View mode: check for overlapping events
    if (_mode == CalendarMode.edit || _mode == CalendarMode.view) {
      final overlappingEvents = _findEventsAtCell(cell);

      if (overlappingEvents.isNotEmpty) {
        // 1 event: show edit dialog directly (existing behavior)
        if (overlappingEvents.length == 1) {
          if (_mode == CalendarMode.edit) {
            _showEditDialog(overlappingEvents.first);
          } else {
            _showEventDetailDialog(overlappingEvents.first);
          }
          return;
        }
        // 2+ events: show overlapping events modal
        else {
          _showOverlappingEventsDialog(overlappingEvents, cell);
          return;
        }
      }
    }

    // View mode: no further interaction if no events
    if (_mode == CalendarMode.view) return;

    // Add mode or Edit mode (when not tapping an event): create new event
    if (!_isSelecting) {
      setState(() {
        _isSelecting = true;
        _startCell = _pixelToCell(clampedPosition, dayColumnWidth);
        _endCell = _startCell;
        _selectionRect = _cellToRect(_startCell!, _endCell!, dayColumnWidth);
      });
    } else {
      _completeSelection();
    }
  }

  /// Handle long press start for mobile
  void _handleLongPressStart(LongPressStartDetails details, double dayColumnWidth) {
    if (!widget.isEditable) return;

    // View mode: no interaction
    if (_mode == CalendarMode.view) return;

    final localPosition =
        _clampLocalToContent(_globalToGestureLocal(details.globalPosition), dayColumnWidth);
    final cell = _pixelToCell(localPosition, dayColumnWidth);

    // Check if cell is disabled (gray cell)
    if (_isCellDisabled(cell)) {
      // Show snackbar message
      AppSnackBar.info(context, '이 시간대는 예약할 수 없습니다');
      return;
    }

    _triggerHaptic(HapticFeedbackType.medium);
    _activePointerGlobalPosition = details.globalPosition;
    setState(() {
      _isSelecting = true;
      _startCell = cell;
      _endCell = _startCell;
      _selectionRect = _cellToRect(_startCell!, _endCell!, dayColumnWidth);
      _highlightRect = _cellToRect(cell, cell, dayColumnWidth);
    });
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    _activePointerGlobalPosition = null;
    _stopAutoScroll();
  }

  void _updateSelectionFromPointer(
    Offset globalPosition,
    double dayColumnWidth, {
    bool checkAutoScroll = true,
  }) {
    if (!widget.isEditable || _startCell == null) return;

    _activePointerGlobalPosition = globalPosition;
    final localPosition =
        _clampLocalToContent(_globalToGestureLocal(globalPosition), dayColumnWidth);

    _updateSelectionCell(
      localPosition,
      dayColumnWidth,
      enableHaptics: true,
    );

    if (checkAutoScroll) {
      _handleEdgeScrolling(globalPosition, dayColumnWidth);
    }
  }

  /// Handle mobile tap (for editing existing events only)
  void _handleMobileTap(Offset globalPosition, double dayColumnWidth) {
    if (!widget.isEditable) return;

    // Edit mode or View mode: check for overlapping events
    if (_mode == CalendarMode.edit || _mode == CalendarMode.view) {
      final localPosition =
          _clampLocalToContent(_globalToGestureLocal(globalPosition), dayColumnWidth);
      final cell = _pixelToCell(localPosition, dayColumnWidth);
      final overlappingEvents = _findEventsAtCell(cell);

      if (overlappingEvents.isNotEmpty) {
        // 1 event: show edit dialog directly (existing behavior)
        if (overlappingEvents.length == 1) {
          if (_mode == CalendarMode.edit) {
            _showEditDialog(overlappingEvents.first);
          } else {
            _showEventDetailDialog(overlappingEvents.first);
          }
        }
        // 2+ events: show overlapping events modal
        else {
          _showOverlappingEventsDialog(overlappingEvents, cell);
        }
      }
    }
    // Add mode: ignore event taps (handled by long press)
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mode selector and overlap view toggle
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<CalendarMode>(
                  segments: const [
                    ButtonSegment(
                      value: CalendarMode.add,
                      label: Text('추가 모드'),
                      icon: Icon(Icons.add_circle_outline),
                    ),
                    ButtonSegment(
                      value: CalendarMode.edit,
                      label: Text('수정 모드'),
                      icon: Icon(Icons.edit_outlined),
                    ),
                    ButtonSegment(
                      value: CalendarMode.view,
                      label: Text('고정 모드'),
                      icon: Icon(Icons.visibility_outlined),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (Set<CalendarMode> newSelection) {
                    final nextMode = newSelection.first;
                    final range = _calculateVisibleHourRange(modeOverride: nextMode);
                    setState(() {
                      _mode = nextMode;
                      _isSelecting = false;
                      _startCell = null;
                      _endCell = null;
                      _selectionRect = null;
                      _highlightRect = null;
                      _visibleStartHour = range.startHour;
                      _visibleEndHour = range.endHour;
                      _hasAppliedInitialScroll = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Overlap view toggle
              Tooltip(
                message: _isOverlapView ? '겹친 일정 펼치기' : '겹친 일정 접기',
                child: IconButton(
                  icon: Icon(_isOverlapView ? Icons.view_week : Icons.layers),
                  onPressed: () {
                    setState(() {
                      _isOverlapView = !_isOverlapView;
                    });
                  },
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        // Calendar content
        Expanded(
          child: Column(
            children: [
              SizedBox(
                height: _dayRowHeight,
                child: IgnorePointer(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomPaint(
                        size: Size(constraints.maxWidth, _dayRowHeight),
                        painter: TimeGridPainter(
                          startHour: _visibleStartHour,
                          endHour: _visibleEndHour,
                          timeColumnWidth: _timeColumnWidth,
                          weekStart: _effectiveWeekStart,
                          paintHeader: true,
                          paintGrid: false,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double dayColumnWidth = (constraints.maxWidth - _timeColumnWidth) / _daysInWeek;
                    final double contentHeight = (_visibleEndHour - _visibleStartHour) * 4 * _minSlotHeight;

                    _currentDayColumnWidth = dayColumnWidth;
                    _currentContentHeight = contentHeight;
                    _currentViewportHeight = constraints.maxHeight; // 실제 뷰포트 높이 저장

                    final allEvents = _getAllEvents();
                    final List<({Rect rect, Event event})> eventRects = allEvents.map((event) {
                      return (rect: _eventToRect(event, dayColumnWidth), event: event);
                    }).toList();

                    WidgetsBinding.instance.addPostFrameCallback((_) => _applyInitialScrollIfNeeded());

                    return SingleChildScrollView(
                      controller: _scrollController,
                      physics: _isSelecting ? const NeverScrollableScrollPhysics() : const ClampingScrollPhysics(),
                      child: SizedBox(
                        height: contentHeight,
                        child: kIsWeb
                            ? _buildWebGestureHandler(dayColumnWidth, eventRects, contentHeight)
                            : _buildMobileGestureHandler(dayColumnWidth, eventRects, contentHeight),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Web: MouseRegion + GestureDetector (hover + two-click mode)
  Widget _buildWebGestureHandler(
    double dayColumnWidth,
    List<({Rect rect, Event event})> eventRects,
    double contentHeight,
  ) {
    return MouseRegion(
      cursor: _mode == CalendarMode.view ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onHover: (event) {
        if (!widget.isEditable || _mode == CalendarMode.view) return;

        // Fixed Duration Mode: Show preview on hover
        if (_isFixedDurationMode) {
          _updateFixedDurationPreview(event.localPosition, dayColumnWidth);
          return;
        }

        // Normal Mode: existing behavior
        if (_isSelecting) {
          _updateSelectionCell(event.localPosition, dayColumnWidth);
        } else {
          final currentCell = _pixelToCell(event.localPosition, dayColumnWidth);
          setState(() {
            _highlightRect = _cellToRect(currentCell, currentCell, dayColumnWidth);
          });
        }
      },
      onExit: (event) {
        // Fixed Duration Mode: Clear preview on exit
        if (_isFixedDurationMode) {
          _clearFixedDurationPreview();
        }

        setState(() {
          _highlightRect = null;
        });
      },
      child: GestureDetector(
        onTapDown: (details) {
          // Fixed Duration Mode: Confirm on click
          if (_isFixedDurationMode && widget.isEditable && _mode != CalendarMode.view) {
            _confirmFixedDurationSelection();
            return;
          }

          // Normal Mode: existing behavior
          _handleTap(details.localPosition, dayColumnWidth, eventRects);
        },
        behavior: HitTestBehavior.opaque,
        child: _buildCalendarStack(eventRects, dayColumnWidth, contentHeight),
      ),
    );
  }

  /// Mobile: Long press + drag mode
  Widget _buildMobileGestureHandler(
    double dayColumnWidth,
    List<({Rect rect, Event event})> eventRects,
    double contentHeight,
  ) {
    return GestureDetector(
      key: _gestureContentKey,
      // Show gray highlight immediately on touch down
      onTapDown: (details) {
        if (_mode == CalendarMode.view) return;

        final localPosition =
            _clampLocalToContent(_globalToGestureLocal(details.globalPosition), dayColumnWidth);
        final touchedCell = _pixelToCell(localPosition, dayColumnWidth);

        // Fixed Duration Mode: Show preview immediately on touch
        if (_isFixedDurationMode) {
          _updateFixedDurationPreview(localPosition, dayColumnWidth);
        } else {
          // Normal Mode: existing highlight behavior
          setState(() {
            _highlightRect = _cellToRect(touchedCell, touchedCell, dayColumnWidth);
          });
        }

        // Handle existing event tap
        _handleMobileTap(details.globalPosition, dayColumnWidth);
      },
      onTapUp: (details) {
        // Fixed Duration Mode: Confirm on tap release
        if (_isFixedDurationMode && !_isSelecting) {
          _confirmFixedDurationSelection();
        }

        // Clear highlight/preview if it was just a tap (not long press)
        if (!_isSelecting) {
          if (_isFixedDurationMode) {
            _clearFixedDurationPreview();
          }
          setState(() {
            _highlightRect = null;
          });
        }
      },
      onTapCancel: () {
        // Fixed Duration Mode: Clear preview on cancel
        if (_isFixedDurationMode) {
          _clearFixedDurationPreview();
        }

        // Clear highlight if tap was cancelled
        if (!_isSelecting) {
          setState(() {
            _highlightRect = null;
          });
        }
      },
      // Long press to start selection (Normal Mode) or move preview (Fixed Duration Mode)
      onLongPressStart: (details) {
        if (_isFixedDurationMode) {
          // Fixed Duration Mode: Haptic feedback and show preview
          _triggerHaptic(HapticFeedbackType.medium);
          final localPosition =
              _clampLocalToContent(_globalToGestureLocal(details.globalPosition), dayColumnWidth);
          _updateFixedDurationPreview(localPosition, dayColumnWidth);
          _activePointerGlobalPosition = details.globalPosition;
        } else {
          // Normal Mode: existing behavior
          _handleLongPressStart(details, dayColumnWidth);
        }
      },
      onLongPressMoveUpdate: (details) {
        if (_isFixedDurationMode) {
          // Fixed Duration Mode: Update preview position as user drags
          _activePointerGlobalPosition = details.globalPosition;
          final localPosition =
              _clampLocalToContent(_globalToGestureLocal(details.globalPosition), dayColumnWidth);
          _updateFixedDurationPreview(localPosition, dayColumnWidth);

          // Handle edge scrolling
          _handleEdgeScrolling(details.globalPosition, dayColumnWidth);
        } else if (_isSelecting) {
          // Normal Mode: existing behavior
          _updateSelectionFromPointer(details.globalPosition, dayColumnWidth);
        }
      },
      onLongPressEnd: (details) {
        if (_isFixedDurationMode) {
          // Fixed Duration Mode: Confirm selection and clear state
          _triggerHaptic(HapticFeedbackType.light);
          _confirmFixedDurationSelection();
          _activePointerGlobalPosition = null;
          _stopAutoScroll();
        } else if (_isSelecting) {
          // Normal Mode: existing behavior
          _triggerHaptic(HapticFeedbackType.light);
          _updateSelectionFromPointer(details.globalPosition, dayColumnWidth, checkAutoScroll: false);
          _completeSelection();
          _handleLongPressEnd(details);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: _buildCalendarStack(eventRects, dayColumnWidth, contentHeight),
    );
  }

  /// Common calendar visualization stack
  Widget _buildCalendarStack(
    List<({Rect rect, Event event})> eventRects,
    double dayColumnWidth,
    double contentHeight,
  ) {
    // Prepare event data for EventPainter
    List<({Rect rect, String title, String id, int? columnIndex, int? totalColumns, int? span})> eventData;

    if (_isOverlapView) {
      // Overlap view: analyze and assign columns
      final allEvents = _getAllEvents();
      final layoutInfo = _calculateEventLayout(allEvents);

      eventData = eventRects.map<({Rect rect, String title, String id, int? columnIndex, int? totalColumns, int? span})>((e) {
        final info = layoutInfo[e.event.id];
        return (
          rect: e.rect,
          title: e.event.title,
          id: e.event.id,
          columnIndex: info?.columnIndex,
          totalColumns: info?.totalColumns,
          span: info?.span,
        );
      }).toList();
    } else {
      // Compact view: no column layout
      eventData = eventRects.map<({Rect rect, String title, String id, int? columnIndex, int? totalColumns, int? span})>((e) => (
        rect: e.rect,
        title: e.event.title,
        id: e.event.id,
        columnIndex: null,
        totalColumns: null,
        span: null,
      )).toList();
    }

    return SizedBox(
      height: contentHeight,
      child: Stack(
        children: [
          // 1. Grid lines (base layer)
          Positioned.fill(
            child: CustomPaint(
              painter: TimeGridPainter(
                startHour: _visibleStartHour,
                endHour: _visibleEndHour,
                timeColumnWidth: _timeColumnWidth,
                weekStart: _effectiveWeekStart,
                paintHeader: false,
                paintGrid: true,
              ),
            ),
          ),

          // 2. Events
          Positioned.fill(
            child: CustomPaint(
              painter: EventPainter(events: eventData),
            ),
          ),

          // 3. Disabled slots (gray cells) - painted AFTER events but BEFORE preview
          // This ensures preview blocks are visible above disabled slots
          if (widget.disabledSlots != null)
            Positioned.fill(
              child: CustomPaint(
                painter: DisabledSlotsPainter(
                  disabledSlots: widget.disabledSlots,
                  weekStart: _effectiveWeekStart,
                  visibleStartHour: _visibleStartHour,
                  visibleEndHour: _visibleEndHour,
                  timeColumnWidth: _timeColumnWidth,
                  slotHeight: _minSlotHeight,
                  dayColumnWidth: dayColumnWidth,
                ),
              ),
            ),


          // 4. Interactive overlays (only when editable)
          if (widget.isEditable) ...[
            // 4a. Fixed Duration Mode Preview - renders ABOVE disabled slots
            // This allows preview to be visible even when hovering over areas
            // that will extend into disabled slots
            if (_durationPreviewRect != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: FixedDurationPreviewPainter(previewRect: _durationPreviewRect),
                ),
              ),

            // 4b. Highlight (current cell)
            Positioned.fill(
              child: CustomPaint(
                painter: HighlightPainter(highlightRect: _highlightRect),
              ),
            ),

            // 4c. Selection (normal mode selection rect)
            Positioned.fill(
              child: CustomPaint(
                painter: SelectionPainter(selection: _selectionRect),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 겹친 일정 시각화 위젯
///
/// 주간 뷰의 축소뷰 알고리즘을 사용하여 겹친 일정들을 시간 기반으로 렌더링합니다.
/// - 왼쪽: 시간 눈금 (시간 범위만큼)
/// - 오른쪽: 색상 구분된 일정 블록들 (시간 비례 높이)
class _OverlappingEventsVisualization extends StatelessWidget {
  const _OverlappingEventsVisualization({
    required this.events,
    required this.mode,
    required this.dayName,
    required this.startHour,
    required this.onEventTap,
  });

  final List<Event> events;
  final CalendarMode mode;
  final String dayName;
  final int startHour;
  final Function(Event) onEventTap;

  // 시각화 영역 상수
  static const double _timeColumnWidth = 50.0;
  static const double _baseBlockWidth = 120.0;
  static const double _maxModalWidth = 900.0;
  static const double _minModalWidth = 400.0;
  static const double _slotHeight = 32.0; // 15분 단위 높이
  static const double _minBlockWidth = 60.0; // 최소 블록 너비
  static const int _maxDisplayHours = 5; // 최대 표시 시간 범위 (5시간)

  /// 시간 범위 계산 (min start slot ~ max end slot, 최대 5시간)
  ({int minSlot, int maxSlot}) _calculateTimeRange() {
    int minSlot = events.first.start.slot;
    int maxSlot = events.first.end.slot;

    for (final event in events) {
      final startSlot = math.min(event.start.slot, event.end.slot);
      final endSlot = math.max(event.start.slot, event.end.slot);
      if (startSlot < minSlot) minSlot = startSlot;
      if (endSlot > maxSlot) maxSlot = endSlot;
    }

    // 범위가 5시간을 초과하면 조정
    final slotsInRange = maxSlot - minSlot + 1;
    final maxSlots = _maxDisplayHours * 4; // 5시간 = 20슬롯 (15분 단위)

    if (slotsInRange > maxSlots) {
      // 범위를 5시간으로 제한 (가장 먼저 시작하는 일정을 기준으로)
      maxSlot = minSlot + maxSlots - 1;
    }

    return (minSlot: minSlot, maxSlot: maxSlot);
  }

  /// 모달 너비 계산
  double _calculateModalWidth() {
    final totalWidth = events.length * _baseBlockWidth;
    return totalWidth.clamp(_minModalWidth, _maxModalWidth);
  }

  /// 사용 가능한 블록 너비 계산
  double _calculateBlockWidth(double modalWidth) {
    final totalWidth = modalWidth - _timeColumnWidth;
    final blockWidth = totalWidth / events.length;
    return blockWidth.clamp(_minBlockWidth, _baseBlockWidth);
  }

  /// DateTime을 시간:분 형식으로 변환 (정확한 분 단위)
  String _formatTimeFromDateTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// 시간을 슬롯에서 시간:분 형식으로 변환 (15분 단위)
  String _formatTime(int slot) {
    final hour = startHour + (slot ~/ 4);
    final minute = (slot % 4) * 15;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// 일정 블록 색상 결정
  Color _getEventColor(Event event) {
    return event.id.startsWith('ext-') ? AppColors.action : AppColors.brand;
  }

  @override
  Widget build(BuildContext context) {
    final timeRange = _calculateTimeRange();
    final totalSlots = timeRange.maxSlot - timeRange.minSlot + 1;
    final totalHeight = totalSlots * _slotHeight;
    final modalWidth = _calculateModalWidth();
    final blockWidth = _calculateBlockWidth(modalWidth);

    return SizedBox(
      width: modalWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 날짜 헤더
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              '$dayName요일',
              style: AppTheme.bodyMedium.copyWith(color: AppColors.neutral600),
            ),
          ),

          // 시간 그리드 + 블록 (TimeGridPainter 사용)
          Container(
            width: modalWidth,
            height: totalHeight,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.lightOutline),
              borderRadius: BorderRadius.circular(AppRadius.button),
              color: AppColors.lightBackground,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.button - 1),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: math.max(
                    _timeColumnWidth + blockWidth * events.length,
                    modalWidth,
                  ),
                  height: totalHeight,
                  child: Stack(
                    children: [
                      // TimeGridPainter로 시간 눈금 + 그리드 라인 렌더링
                      Positioned.fill(
                        child: CustomPaint(
                          painter: OverlapModalTimeGridPainter(
                            minSlot: timeRange.minSlot,
                            maxSlot: timeRange.maxSlot,
                            startHour: startHour,
                            slotHeight: _slotHeight,
                            timeColumnWidth: _timeColumnWidth,
                          ),
                        ),
                      ),

                      // 일정 블록들
                      ...events.map((event) {
                        final eventStartSlot = math.min(event.start.slot, event.end.slot);
                        final eventEndSlot = math.max(event.start.slot, event.end.slot);

                        // 이벤트가 시간 ���위 밖에 있으면 렌더링하지 않음
                        if (eventEndSlot < timeRange.minSlot || eventStartSlot > timeRange.maxSlot) {
                          return const Positioned(child: SizedBox.shrink());
                        }

                        // 🟢 사용: 공통 위치 계산 함수 (calculateEventPosition)
                        // - DateTime 기반 정확한 계산 (분 단위)
                        // - slot 기반 fallback (15분 단위)
                        final position = calculateEventPosition(
                          event: event,
                          slotHeight: _slotHeight,
                          referenceStartHour: startHour,
                          minSlot: timeRange.minSlot,
                        );

                        final double top = position.top;
                        final double height = position.height;

                        // duration: slot 단위 길이 (텍스트 표시 조건용)
                        final int duration = event.startTime != null && event.endTime != null
                            ? ((event.endTime!.difference(event.startTime!).inMinutes) / 15.0).ceil()
                            : eventEndSlot - eventStartSlot + 1;

                        final totalVisibleHeight = (timeRange.maxSlot - timeRange.minSlot + 1) * _slotHeight;

                        // 뷰포트를 벗어나는 높이 클리핑
                        final clippedHeight = math.min(top + height, totalVisibleHeight) - top;

                        return Positioned(
                          left: _timeColumnWidth + events.indexOf(event) * blockWidth + 4,
                          top: top,
                          width: blockWidth - 8,
                          height: clippedHeight - 2, // -2 for padding
                          child: GestureDetector(
                            onTap: () => onEventTap(event),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getEventColor(event).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getEventColor(event),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getEventColor(event).withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      event.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (duration > 2)
                                    SizedBox(height: 2),
                                  if (duration > 2)
                                    Text(
                                      // 🟢 수정: event.startTime/endTime 우선 사용 (정확한 분 단위)
                                      // 없으면 slot 기반 계산 (fallback)
                                      event.startTime != null && event.endTime != null
                                          ? '${_formatTimeFromDateTime(event.startTime!)} - ${_formatTimeFromDateTime(event.endTime!)}'
                                          : '${_formatTime(eventStartSlot)} - ${_formatTime(eventEndSlot + 1)}',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 9,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
