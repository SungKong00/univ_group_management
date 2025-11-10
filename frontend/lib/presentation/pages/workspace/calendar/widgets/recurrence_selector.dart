import 'package:flutter/material.dart';

import '../../../../../core/models/calendar/recurrence_pattern.dart';

/// Widget for selecting recurrence patterns for group events.
class RecurrenceSelector extends StatefulWidget {
  final RecurrencePattern? initialPattern;
  final ValueChanged<RecurrencePattern?> onChanged;

  const RecurrenceSelector({
    super.key,
    this.initialPattern,
    required this.onChanged,
  });

  @override
  State<RecurrenceSelector> createState() => _RecurrenceSelectorState();
}

class _RecurrenceSelectorState extends State<RecurrenceSelector> {
  bool _isRecurring = false;
  RecurrenceType _type = RecurrenceType.daily;
  Set<int> _selectedDays = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialPattern != null) {
      _isRecurring = true;
      _type = widget.initialPattern!.type;
      _selectedDays = widget.initialPattern!.daysOfWeek?.toSet() ?? {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('반복 일정'),
          value: _isRecurring,
          onChanged: (value) {
            setState(() {
              _isRecurring = value;
              _notifyChange();
            });
          },
        ),
        if (_isRecurring) ...[
          const SizedBox(height: 16),
          SegmentedButton<RecurrenceType>(
            segments: const [
              ButtonSegment(value: RecurrenceType.daily, label: Text('매일')),
              ButtonSegment(value: RecurrenceType.weekly, label: Text('요일 선택')),
            ],
            selected: {_type},
            onSelectionChanged: (Set<RecurrenceType> newSelection) {
              setState(() {
                _type = newSelection.first;
                _notifyChange();
              });
            },
          ),
          if (_type == RecurrenceType.weekly) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (int day = 1; day <= 7; day++)
                  FilterChip(
                    label: Text(_getDayLabel(day)),
                    selected: _selectedDays.contains(day),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                        _notifyChange();
                      });
                    },
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  void _notifyChange() {
    if (!_isRecurring) {
      widget.onChanged(null);
      return;
    }

    RecurrencePattern? pattern;
    if (_type == RecurrenceType.daily) {
      pattern = RecurrencePattern.daily();
    } else if (_type == RecurrenceType.weekly && _selectedDays.isNotEmpty) {
      pattern = RecurrencePattern.weekly(_selectedDays.toList()..sort());
    }

    widget.onChanged(pattern);
  }

  String _getDayLabel(int day) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return labels[day - 1];
  }
}
