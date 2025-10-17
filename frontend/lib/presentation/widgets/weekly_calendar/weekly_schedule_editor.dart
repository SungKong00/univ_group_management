
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'event_painter.dart';
import 'highlight_painter.dart';
import 'selection_painter.dart';
import 'time_grid_painter.dart';

typedef Event = ({String id, String title, ({int day, int slot}) start, ({int day, int slot}) end});

class WeeklyScheduleEditor extends StatefulWidget {
  final bool allowMultiDaySelection;
  final bool isEditable;
  final bool allowEventOverlap;

  const WeeklyScheduleEditor({
    super.key,
    this.allowMultiDaySelection = false,
    this.isEditable = true,
    this.allowEventOverlap = true,
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

  // State
  final List<Event> _events = [];
  bool _isSelecting = false;
  ({int day, int slot})? _startCell;
  ({int day, int slot})? _endCell;
  Rect? _selectionRect;
  Rect? _highlightRect;

  // --- Helper Functions ---

  ({int day, int slot}) _pixelToCell(Offset position, Size size) {
    final double dayColumnWidth = (size.width - _timeColumnWidth) / _daysInWeek;
    final double hourHeight = (size.height - _dayRowHeight) / (_endHour - _startHour);
    final double slotHeight = hourHeight / 4;

    int day = ((position.dx - _timeColumnWidth) / dayColumnWidth).floor();
    int slot = ((position.dy - _dayRowHeight) / slotHeight).floor();

    day = day.clamp(0, _daysInWeek - 1);
    slot = slot.clamp(0, (_endHour - _startHour) * 4 - 1);

    return (day: day, slot: slot);
  }

  Rect _cellToRect(({int day, int slot}) start, ({int day, int slot}) end, Size size) {
    final double dayColumnWidth = (size.width - _timeColumnWidth) / _daysInWeek;
    final double hourHeight = (size.height - _dayRowHeight) / (_endHour - _startHour);
    final double slotHeight = hourHeight / 4;

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

  Event? _findTappedEvent(Offset position, List<({Rect rect, Event event})> eventRects) {
    for (final eventRect in eventRects) {
      if (eventRect.rect.contains(position)) {
        return eventRect.event;
      }
    }
    return null;
  }

  // --- Dialogs ---

  void _showEditDialog(Event event) {
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

  void _handleTap(Offset position, Size size, List<({Rect rect, Event event})> eventRects) {
    if (!widget.isEditable) return;

    final tappedEvent = _findTappedEvent(position, eventRects);
    if (tappedEvent != null) {
      _showEditDialog(tappedEvent);
      return;
    }

    if (!_isSelecting) {
      setState(() {
        _isSelecting = true;
        _startCell = _pixelToCell(position, size);
        _endCell = _startCell;
        _selectionRect = _cellToRect(_startCell!, _endCell!, size);
      });
    } else {
      final finalStartCell = _startCell;
      final finalEndCell = _endCell;

      setState(() {
        _isSelecting = false;
        _startCell = null;
        _endCell = null;
        _selectionRect = null;
      });

      if (finalStartCell != null && finalEndCell != null && finalEndCell.slot >= finalStartCell.slot) {
        _showCreateDialog(finalStartCell, finalEndCell);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final List<({Rect rect, Event event})> eventRects = _events.map((event) {
          return (rect: _cellToRect(event.start, event.end, size), event: event);
        }).toList();

        return MouseRegion(
          onHover: (event) {
            if (!widget.isEditable) return;

            if (_isSelecting) {
              var currentCell = _pixelToCell(event.localPosition, size);

              if (!widget.allowMultiDaySelection) {
                currentCell = (day: _startCell!.day, slot: currentCell.slot);
              }

              if (currentCell.slot < _startCell!.slot) {
                setState(() {
                  _endCell = currentCell;
                  _selectionRect = null;
                });
              } else if (currentCell != _endCell) {
                setState(() {
                  _endCell = currentCell;
                  _selectionRect = _cellToRect(_startCell!, currentCell, size);
                });
              }
            } else {
              // Highlight the cell under the mouse when not selecting
              final currentCell = _pixelToCell(event.localPosition, size);
              setState(() {
                _highlightRect = _cellToRect(currentCell, currentCell, size);
              });
            }
          },
          onExit: (event) {
            setState(() {
              _highlightRect = null;
            });
          },
          child: GestureDetector(
            onTapDown: (details) => _handleTap(details.localPosition, size, eventRects),
            behavior: HitTestBehavior.opaque,
            child: Stack(
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
                  painter: EventPainter(events: eventRects.map((e) => (rect: e.rect, title: e.event.title)).toList()),
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
            ),
          ),
        );
      },
    );
  }
}
