import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/calendar_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';

Future<PersonalEventRequest?> showEventFormDialog(
  BuildContext context, {
  PersonalEvent? initial,
  DateTime? anchorDate,
}) {
  return showDialog<PersonalEventRequest>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _EventFormDialog(
      initial: initial,
      anchorDate: anchorDate,
    ),
  );
}

class _EventFormDialog extends StatefulWidget {
  const _EventFormDialog({
    this.initial,
    this.anchorDate,
  });

  final PersonalEvent? initial;
  final DateTime? anchorDate;

  @override
  State<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<_EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;

  late DateTime _startDateTime;
  late DateTime _endDateTime;
  late bool _isAllDay;
  late Color _selectedColor;

  bool get _isEditing => widget.initial != null;

  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormatter = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final now = DateTime.now();
    final anchor = widget.anchorDate ?? now;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _descriptionController =
        TextEditingController(text: initial?.description ?? '');
    _locationController = TextEditingController(text: initial?.location ?? '');
    _isAllDay = initial?.isAllDay ?? false;
    _selectedColor = initial?.color ?? kPersonalScheduleColors.first;

    if (initial != null) {
      _startDateTime = initial.startDateTime;
      _endDateTime = initial.endDateTime;
    } else {
      final normalizedAnchor = DateTime(anchor.year, anchor.month, anchor.day, 9);
      _startDateTime = normalizedAnchor;
      _endDateTime = normalizedAnchor.add(const Duration(hours: 1));
    }

    if (_isAllDay) {
      _startDateTime = _normalizeDateTime(_startDateTime);
      _endDateTime = _allDayEnd(_startDateTime);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text(
        _isEditing ? '이벤트 수정' : '이벤트 추가',
        style: textTheme.titleLarge,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    hintText: '예: 프로젝트 회의',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '제목을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: '설명 (선택)',
                    hintText: '회의 안건, 준비물 등을 기록해보세요.',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _locationController,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: '장소 (선택)',
                    hintText: '예: 도서관 세미나룸',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile.adaptive(
                  value: _isAllDay,
                  onChanged: (value) {
                    setState(() {
                      _isAllDay = value;
                      if (_isAllDay) {
                        _startDateTime = _normalizeDateTime(_startDateTime);
                        _endDateTime = _allDayEnd(_startDateTime);
                      }
                    });
                  },
                  title: const Text('종일 이벤트'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _buildDateTimeField(context, isStart: true)),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: _buildDateTimeField(context, isStart: false)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '색상 선택',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: kPersonalScheduleColors.map((color) {
                    final isSelected = color == _selectedColor;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: AnimatedContainer(
                        duration: AppMotion.quick,
                        curve: AppMotion.easing,
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.brand
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _handleSubmit,
          child: Text(_isEditing ? '수정' : '추가'),
        ),
      ],
    );
  }

  Widget _buildDateTimeField(BuildContext context, {required bool isStart}) {
    final dateTime = isStart ? _startDateTime : _endDateTime;
    final dateText = _dateFormatter.format(dateTime);
    final timeText = _timeFormatter.format(dateTime);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: isStart ? '시작' : '종료',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => _pickDate(context, isStart: isStart),
            icon: const Icon(Icons.calendar_today_outlined, size: 16),
            label: Text(dateText),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _isAllDay
                ? null
                : () => _pickTime(context, isStart: isStart),
            icon: const Icon(Icons.schedule, size: 16),
            label: Text(_isAllDay ? '종일' : timeText),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, {required bool isStart}) async {
    final current = isStart ? _startDateTime : _endDateTime;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      final updated = DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour,
        current.minute,
      );
      if (isStart) {
        _startDateTime = updated;
        if (_isAllDay) {
          _startDateTime = _normalizeDateTime(_startDateTime);
          _endDateTime = _allDayEnd(_startDateTime);
        } else if (!_endDateTime.isAfter(_startDateTime)) {
          _endDateTime = _startDateTime.add(const Duration(hours: 1));
        }
      } else {
        _endDateTime = updated;
        if (_isAllDay) {
          _endDateTime = _allDayEnd(_startDateTime);
        } else if (!_endDateTime.isAfter(_startDateTime)) {
          _endDateTime = _startDateTime.add(const Duration(hours: 1));
        }
      }
    });
  }

  Future<void> _pickTime(BuildContext context, {required bool isStart}) async {
    final current = isStart ? _startDateTime : _endDateTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;

    setState(() {
      final updated = DateTime(
        current.year,
        current.month,
        current.day,
        picked.hour,
        picked.minute,
      );
      if (isStart) {
        _startDateTime = updated;
        if (!_endDateTime.isAfter(_startDateTime)) {
          _endDateTime = _startDateTime.add(const Duration(hours: 1));
        }
      } else {
        _endDateTime = updated;
        if (!_endDateTime.isAfter(_startDateTime)) {
          _endDateTime = _startDateTime.add(const Duration(hours: 1));
        }
      }
    });
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_endDateTime.isAfter(_startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료 시간은 시작 시간보다 이후여야 합니다.')),
      );
      return;
    }

    final request = PersonalEventRequest(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      startDateTime: _isAllDay ? _normalizeDateTime(_startDateTime) : _startDateTime,
      endDateTime: _isAllDay ? _allDayEnd(_startDateTime) : _endDateTime,
      isAllDay: _isAllDay,
      color: _selectedColor,
    );
    Navigator.of(context).pop(request);
  }

  DateTime _normalizeDateTime(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);

  DateTime _allDayEnd(DateTime start) =>
      DateTime(start.year, start.month, start.day, 23, 59, 59);
}
