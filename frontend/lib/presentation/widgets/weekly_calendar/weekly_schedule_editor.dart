
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'event_painter.dart';
import 'selection_painter.dart';
import 'time_grid_painter.dart';

class WeeklyScheduleEditor extends StatefulWidget {
  const WeeklyScheduleEditor({super.key});

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
  final List<Rect> _events = [];
  bool _isSelecting = false;
  ({int day, int slot})? _startCell;
  ({int day, int slot})? _endCell;
  Rect? _selectionRect;

  ({int day, int slot}) _pixelToCell(Offset position, Size size) {
    final double dayColumnWidth = (size.width - _timeColumnWidth) / _daysInWeek;
    final double hourHeight = (size.height - _dayRowHeight) / (_endHour - _startHour);
    final double slotHeight = hourHeight / 4; // 15-minute slots

    int day = ((position.dx - _timeColumnWidth) / dayColumnWidth).floor();
    int slot = ((position.dy - _dayRowHeight) / slotHeight).floor();

    day = day.clamp(0, _daysInWeek - 1);
    slot = slot.clamp(0, (_endHour - _startHour) * 4 - 1);

    return (day: day, slot: slot);
  }

  Rect _cellToRect(({int day, int slot}) start, ({int day, int slot}) end, Size size) {
    final double dayColumnWidth = (size.width - _timeColumnWidth) / _daysInWeek;
    final double hourHeight = (size.height - _dayRowHeight) / (_endHour - _startHour);
    final double slotHeight = hourHeight / 4; // 15-minute slots

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

  void _handleTap(Offset position, Size size) {
    final currentCell = _pixelToCell(position, size);

    if (!_isSelecting) {
      setState(() {
        _isSelecting = true;
        _startCell = currentCell;
        _endCell = currentCell;
        _selectionRect = _cellToRect(_startCell!, _endCell!, size);
      });
    } else {
      final Rect? finalSelection = _selectionRect;
      final ({int day, int slot})? finalStartCell = _startCell;
      final ({int day, int slot})? finalEndCell = _endCell;

      setState(() {
        _isSelecting = false;
        _startCell = null;
        _endCell = null;
        _selectionRect = null;
      });

      if (finalSelection != null) {
        final startTime = DateTime(2024, 1, 1, _startHour).add(Duration(minutes: finalStartCell!.slot * 15));
        final endTime = DateTime(2024, 1, 1, _startHour).add(Duration(minutes: (finalEndCell!.slot + 1) * 15));

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('일정 생성'),
            content: Text(
                '요일: ${finalStartCell.day + 1}\n'
                '시작: ${DateFormat.jm().format(startTime)}\n'
                '종료: ${DateFormat.jm().format(endTime)}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _events.add(finalSelection);
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('저장'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return MouseRegion(
          onHover: (event) {
            if (_isSelecting) {
              final currentCell = _pixelToCell(event.localPosition, size);
              if (currentCell != _endCell) {
                setState(() {
                  _endCell = currentCell;
                  _selectionRect = _cellToRect(_startCell!, _endCell!, size);
                });
              }
            }
          },
          child: GestureDetector(
            onTapDown: (details) => _handleTap(details.localPosition, size),
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
                  painter: EventPainter(events: _events),
                  size: Size.infinite,
                ),
                CustomPaint(
                  painter: SelectionPainter(selection: _selectionRect),
                  size: Size.infinite,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
