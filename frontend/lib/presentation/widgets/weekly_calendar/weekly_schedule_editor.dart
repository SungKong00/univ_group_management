import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';
import '../../../core/models/calendar/group_event.dart';
import '../../../core/theme/app_theme.dart';
import 'event_painter.dart';
import 'highlight_painter.dart';
import 'selection_painter.dart';
import 'time_grid_painter.dart';

typedef Event = ({String id, String title, ({int day, int slot}) start, ({int day, int slot}) end});

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

  const WeeklyScheduleEditor({
    super.key,
    this.allowMultiDaySelection = false,
    this.isEditable = true,
    this.allowEventOverlap = true,
    this.externalEvents,
    this.weekStart,
    this.groupColors,
  });

  @override
  State<WeeklyScheduleEditor> createState() => _WeeklyScheduleEditorState();
}

class _WeeklyScheduleEditorState extends State<WeeklyScheduleEditor> {
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

  // Auto-scroll
  late ScrollController _scrollController;
  Timer? _autoScrollTimer;
  static const double _edgeScrollThreshold = 50.0; // Pixels from edge to trigger scroll
  static const double _scrollSpeed = 5.0; // Pixels per timer tick (reduced from 30.0)

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // --- External Event Processing ---

  /// Convert GroupEvent to internal Event format
  /// Filters events within the current week
  List<Event> _convertGroupEventsToEvents(List<GroupEvent> groupEvents, DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final List<Event> convertedEvents = [];

    debugPrint('[WeeklyScheduleEditor] Converting events:');
    debugPrint('[WeeklyScheduleEditor] Week: $weekStart ~ $weekEnd');
    debugPrint('[WeeklyScheduleEditor] Input: ${groupEvents.length} events');

    for (final groupEvent in groupEvents) {
      debugPrint('[Event] ${groupEvent.title}');
      debugPrint('  Start: ${groupEvent.startDateTime}');
      debugPrint('  End: ${groupEvent.endDateTime}');

      // Filter events within the current week
      if (groupEvent.startDateTime.isBefore(weekEnd) && groupEvent.endDateTime.isAfter(weekStart)) {
        debugPrint('  ✓ Date filter passed');

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

        debugPrint('  Day: $eventDay, StartSlot: $startSlot, EndSlot: $endSlot, TotalSlots: $totalSlots');

        if (startSlot < totalSlots && endSlot >= 0 && startSlot <= endSlot) {
          convertedEvents.add((
            id: 'ext-${groupEvent.id}', // Prefix to distinguish external events
            title: groupEvent.title,
            start: (day: eventDay, slot: startSlot),
            end: (day: eventDay, slot: endSlot),
          ));
          debugPrint('  ✓ Slot filter passed → Added');
        } else {
          debugPrint('  ✗ Slot filter failed (startSlot<totalSlots=${startSlot < totalSlots}, endSlot>=0=${endSlot >= 0}, startSlot<=endSlot=${startSlot <= endSlot})');
        }
      } else {
        debugPrint('  ✗ Date filter failed');
      }
    }

    debugPrint('[Result] ${convertedEvents.length} events ready for rendering');
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

  /// Analyze overlapping events and assign column positions
  /// Returns a map: eventId -> (columnIndex, totalColumns)
  Map<String, ({int columnIndex, int totalColumns})> _analyzeOverlappingGroups(
    List<Event> events,
    double dayColumnWidth,
  ) {
    final Map<String, ({int columnIndex, int totalColumns})> result = {};

    // Group events by day
    final Map<int, List<Event>> eventsByDay = {};
    for (final event in events) {
      final day = event.start.day;
      eventsByDay.putIfAbsent(day, () => []).add(event);
    }

    // Process each day separately
    for (final entry in eventsByDay.entries) {
      final dayEvents = entry.value;

      // Sort by start time, then by duration (longer first)
      final sortedEvents = List<Event>.from(dayEvents)
        ..sort((a, b) {
          final startCompare = a.start.slot.compareTo(b.start.slot);
          if (startCompare != 0) return startCompare;

          final durationA = (a.end.slot - a.start.slot).abs();
          final durationB = (b.end.slot - b.start.slot).abs();
          return durationB.compareTo(durationA);
        });

      // Find overlapping groups and assign columns (Google Calendar algorithm)
      final List<List<Event>> columns = [];

      for (final event in sortedEvents) {
        final eventStart = event.start.slot < event.end.slot ? event.start.slot : event.end.slot;
        final eventEnd = event.start.slot > event.end.slot ? event.start.slot : event.end.slot;

        // Try to place in existing column
        bool placed = false;
        for (final column in columns) {
          bool canPlace = true;
          for (final existing in column) {
            final existingStart = existing.start.slot < existing.end.slot ? existing.start.slot : existing.end.slot;
            final existingEnd = existing.start.slot > existing.end.slot ? existing.start.slot : event.end.slot;

            // Check overlap
            if (eventStart < existingEnd && eventEnd > existingStart) {
              canPlace = false;
              break;
            }
          }

          if (canPlace) {
            column.add(event);
            placed = true;
            break;
          }
        }

        // Create new column if no suitable column found
        if (!placed) {
          columns.add([event]);
        }
      }

      // Assign column positions
      for (int colIndex = 0; colIndex < columns.length; colIndex++) {
        for (final event in columns[colIndex]) {
          result[event.id] = (columnIndex: colIndex, totalColumns: columns.length);
        }
      }
    }

    return result;
  }

  /// Handle auto-scrolling when drag reaches screen edge
  void _handleEdgeScrolling(Offset localPosition) {
    // Convert local coordinates to global screen coordinates
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final globalPosition = box.localToGlobal(localPosition);
    final screenHeight = MediaQuery.of(context).size.height;

    // Bottom navigation bar height (typically 56-80px)
    const navBarHeight = 80.0;

    // Define thresholds accounting for navigation bar
    final topThreshold = _edgeScrollThreshold;
    final bottomThreshold = screenHeight - navBarHeight - _edgeScrollThreshold;

    bool shouldScroll = false;
    bool scrollDown = false;

    if (globalPosition.dy < topThreshold) {
      shouldScroll = true;
      scrollDown = false;
    } else if (globalPosition.dy > bottomThreshold) {
      shouldScroll = true;
      scrollDown = true;
    }

    if (shouldScroll) {
      // Start auto-scroll timer if not already running
      _autoScrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (_scrollController.hasClients) {
          final newOffset = scrollDown
              ? _scrollController.offset + _scrollSpeed
              : (_scrollController.offset - _scrollSpeed).clamp(0.0, _scrollController.position.maxScrollExtent);

          if (newOffset != _scrollController.offset) {
            _scrollController.jumpTo(newOffset.clamp(0.0, _scrollController.position.maxScrollExtent));
          }
        }
      });
    } else {
      // Stop auto-scroll if not at edge
      _autoScrollTimer?.cancel();
      _autoScrollTimer = null;
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
    final int totalSlots = (_endHour - _startHour) * 4;

    int day = ((position.dx - _timeColumnWidth) / dayColumnWidth).floor();
    int slot = ((position.dy - _dayRowHeight) / slotHeight).floor();

    day = day.clamp(0, _daysInWeek - 1);
    slot = slot.clamp(0, totalSlots - 1);

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
      _dayRowHeight + startSlot * slotHeight,
      _timeColumnWidth + (endDay + 1) * dayColumnWidth,
      _dayRowHeight + (endSlot + 1) * slotHeight,
    );
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

  // --- Dialogs ---

  /// Check if event is external (read-only)
  bool _isExternalEvent(Event event) {
    return event.id.startsWith('ext-');
  }

  /// Show detail view dialog (read-only)
  void _showEventDetailDialog(Event event) {
    final startTime = DateTime(2024, 1, 1, _startHour).add(Duration(minutes: event.start.slot * 15));
    final endTime = DateTime(2024, 1, 1, _startHour).add(Duration(minutes: (event.end.slot + 1) * 15));
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showEditDialog(event);
              },
              child: const Text('수정'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
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
            Text('겹친 일정 (${events.length}개)', style: AppTheme.headlineSmall),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: events.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outline,
            ),
            itemBuilder: (context, index) {
              final event = events[index];
              final startTime = DateTime(2024, 1, 1, _startHour).add(Duration(minutes: event.start.slot * 15));
              final endTime = DateTime(2024, 1, 1, _startHour).add(Duration(minutes: (event.end.slot + 1) * 15));

              return ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xxs, vertical: AppSpacing.xxs / 2),
                leading: Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                title: Text(
                  event.title,
                  style: AppTheme.titleMedium,
                ),
                subtitle: Text(
                  '${dayNames[event.start.day]} · ${DateFormat.jm().format(startTime)} - ${DateFormat.jm().format(endTime)}',
                  style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEventDetailDialog(event);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Event event) {
    // Prevent editing external events
    if (_isExternalEvent(event)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('그룹 일정은 수정할 수 없습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
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
          TextButton(
            onPressed: () {
              setState(() {
                _events.removeWhere((e) => e.id == event.id);
              });
              Navigator.of(context).pop();
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final index = _events.indexWhere((e) => e.id == event.id);
                if (index != -1) {
                  _events[index] = (
                    id: event.id,
                    title: titleController.text,
                    start: event.start,
                    end: event.end,
                  );
                }
              });
              Navigator.of(context).pop();
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(({int day, int slot}) startCell, ({int day, int slot}) endCell) {
    final titleController = TextEditingController();
    final startTime = DateTime(2024, 1, 1, _startHour).add(Duration(minutes: startCell.slot * 15));
    final endTime = DateTime(2024, 1, 1, _startHour).add(Duration(minutes: (endCell.slot + 1) * 15));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 생성'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('요일: ${startCell.day + 1}\n'
                '시작: ${DateFormat.jm().format(startTime)}\n'
                '종료: ${DateFormat.jm().format(endTime)}'),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '제목'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final isOverlapping = _isOverlapping(startCell, endCell);

              if (!widget.allowEventOverlap && isOverlapping) {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('생성 불가'),
                    content: const Text('겹치는 시간에는 일정을 생성할 수 없습니다.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                );
                return;
              }

              if (isOverlapping) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('경고: 다른 일정과 겹칩니다.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }

              setState(() {
                _events.add((
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text.isNotEmpty ? titleController.text : '제목 없음',
                  start: startCell,
                  end: endCell,
                ));
              });
              Navigator.of(context).pop();
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // --- Event Handlers ---

  /// Common logic to update selection during drag (used by both web and mobile)
  void _updateSelectionCell(Offset position, double dayColumnWidth) {
    if (!widget.isEditable || _startCell == null) return;

    // Handle auto-scroll at screen edges (mobile only)
    if (!kIsWeb) {
      _handleEdgeScrolling(position);
    }

    var currentCell = _pixelToCell(position, dayColumnWidth);

    // Restrict to same day if multi-day selection is disabled
    if (!widget.allowMultiDaySelection) {
      currentCell = (day: _startCell!.day, slot: currentCell.slot);
    }

    // Haptic feedback when crossing cell boundary (mobile only)
    if (!kIsWeb && _endCell != null && currentCell != _endCell) {
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

    // Stop auto-scroll timer
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;

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

    // Edit mode or View mode: check for overlapping events
    if (_mode == CalendarMode.edit || _mode == CalendarMode.view) {
      final cell = _pixelToCell(position, dayColumnWidth);
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
        _startCell = _pixelToCell(position, dayColumnWidth);
        _endCell = _startCell;
        _selectionRect = _cellToRect(_startCell!, _endCell!, dayColumnWidth);
      });
    } else {
      _completeSelection();
    }
  }

  /// Handle long press start for mobile
  void _handleLongPressStart(Offset position, double dayColumnWidth) {
    if (!widget.isEditable) return;

    // View mode: no interaction
    if (_mode == CalendarMode.view) return;

    _triggerHaptic(HapticFeedbackType.medium);
    setState(() {
      _isSelecting = true;
      _startCell = _pixelToCell(position, dayColumnWidth);
      _endCell = _startCell;
      _selectionRect = _cellToRect(_startCell!, _endCell!, dayColumnWidth);
    });
  }

  /// Handle mobile tap (for editing existing events only)
  void _handleMobileTap(Offset position, double dayColumnWidth) {
    if (!widget.isEditable) return;

    // Edit mode or View mode: check for overlapping events
    if (_mode == CalendarMode.edit || _mode == CalendarMode.view) {
      final cell = _pixelToCell(position, dayColumnWidth);
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
                    setState(() {
                      _mode = newSelection.first;
                      // Clear any ongoing selection when switching modes
                      _isSelecting = false;
                      _startCell = null;
                      _endCell = null;
                      _selectionRect = null;
                      _highlightRect = null;
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
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: _isSelecting ? const NeverScrollableScrollPhysics() : null,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double dayColumnWidth = (constraints.maxWidth - _timeColumnWidth) / _daysInWeek;
                final double contentHeight = _dayRowHeight + (_endHour - _startHour) * 4 * _minSlotHeight;

                // Get all events including external group events
                final allEvents = _getAllEvents();
                final List<({Rect rect, Event event})> eventRects = allEvents.map((event) {
                  return (rect: _cellToRect(event.start, event.end, dayColumnWidth), event: event);
                }).toList();

                // Platform-specific gesture handler selection
                // Web: MouseRegion for hover feedback
                // Mobile: Long press + drag for touch-friendly interaction
                return SizedBox(
                  height: contentHeight,
                  child: kIsWeb ? _buildWebGestureHandler(dayColumnWidth, eventRects) : _buildMobileGestureHandler(dayColumnWidth, eventRects),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Web: MouseRegion + GestureDetector (hover + two-click mode)
  Widget _buildWebGestureHandler(double dayColumnWidth, List<({Rect rect, Event event})> eventRects) {
    return MouseRegion(
      cursor: _mode == CalendarMode.view ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onHover: (event) {
        if (!widget.isEditable || _mode == CalendarMode.view) return;

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
        setState(() {
          _highlightRect = null;
        });
      },
      child: GestureDetector(
        onTapDown: (details) => _handleTap(details.localPosition, dayColumnWidth, eventRects),
        behavior: HitTestBehavior.opaque,
        child: _buildCalendarStack(eventRects, dayColumnWidth),
      ),
    );
  }

  /// Mobile: Long press + drag mode
  Widget _buildMobileGestureHandler(double dayColumnWidth, List<({Rect rect, Event event})> eventRects) {
    return GestureDetector(
      // Show gray highlight immediately on touch down
      onTapDown: (details) {
        if (_mode == CalendarMode.view) return;

        // Show highlight for touched cell
        final touchedCell = _pixelToCell(details.localPosition, dayColumnWidth);
        setState(() {
          _highlightRect = _cellToRect(touchedCell, touchedCell, dayColumnWidth);
        });
        // Handle existing event tap
        _handleMobileTap(details.localPosition, dayColumnWidth);
      },
      onTapUp: (details) {
        // Clear highlight if it was just a tap (not long press)
        if (!_isSelecting) {
          setState(() {
            _highlightRect = null;
          });
        }
      },
      onTapCancel: () {
        // Clear highlight if tap was cancelled
        if (!_isSelecting) {
          setState(() {
            _highlightRect = null;
          });
        }
      },
      // Long press to start selection
      onLongPressStart: (details) => _handleLongPressStart(details.localPosition, dayColumnWidth),
      onLongPressMoveUpdate: (details) => _updateSelectionCell(details.localPosition, dayColumnWidth),
      onLongPressEnd: (details) {
        if (_isSelecting) {
          _triggerHaptic(HapticFeedbackType.light);
          _completeSelection();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: _buildCalendarStack(eventRects, dayColumnWidth),
    );
  }

  /// Common calendar visualization stack
  Widget _buildCalendarStack(List<({Rect rect, Event event})> eventRects, double dayColumnWidth) {
    // Prepare event data for EventPainter
    List<({Rect rect, String title, int? columnIndex, int? totalColumns})> eventData;

    if (_isOverlapView) {
      // Overlap view: analyze and assign columns
      // Get all events including external group events for overlap analysis
      final allEvents = _getAllEvents();
      final overlapInfo = _analyzeOverlappingGroups(
        allEvents,
        dayColumnWidth,
      );

      eventData = eventRects.map((e) {
        final info = overlapInfo[e.event.id];
        return (
          rect: e.rect,
          title: e.event.title,
          columnIndex: info?.columnIndex,
          totalColumns: info?.totalColumns,
        );
      }).toList();
    } else {
      // Compact view: no column layout
      eventData = eventRects.map((e) => (
        rect: e.rect,
        title: e.event.title,
        columnIndex: null,
        totalColumns: null,
      )).toList();
    }

    return Stack(
      children: [
        CustomPaint(
          painter: TimeGridPainter(
            startHour: _startHour,
            endHour: _endHour,
            timeColumnWidth: _timeColumnWidth,
            dayRowHeight: _dayRowHeight,
          ),
          size: Size.infinite,
        ),
        CustomPaint(
          painter: EventPainter(events: eventData),
          size: Size.infinite,
        ),
        if (widget.isEditable) ...[
          CustomPaint(
            painter: HighlightPainter(highlightRect: _highlightRect),
            size: Size.infinite,
          ),
          CustomPaint(
            painter: SelectionPainter(selection: _selectionRect),
            size: Size.infinite,
          ),
        ],
      ],
    );
  }
}
