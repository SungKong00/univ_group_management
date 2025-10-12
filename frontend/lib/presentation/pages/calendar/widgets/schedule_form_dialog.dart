import 'package:flutter/material.dart';

import '../../../../core/models/calendar_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';
import '../../../widgets/dialogs/confirm_cancel_actions.dart';

Future<PersonalScheduleRequest?> showScheduleFormDialog(
  BuildContext context, {
  PersonalSchedule? initial,
}) {
  return showDialog<PersonalScheduleRequest>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ScheduleFormDialog(initial: initial),
  );
}

class ScheduleFormDialog extends StatefulWidget {
  const ScheduleFormDialog({super.key, this.initial});

  final PersonalSchedule? initial;

  @override
  State<ScheduleFormDialog> createState() => _ScheduleFormDialogState();
}

class _ScheduleFormDialogState extends State<ScheduleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late DayOfWeek _dayOfWeek;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late Color _selectedColor;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _locationController = TextEditingController(text: initial?.location ?? '');
    _dayOfWeek = initial?.dayOfWeek ?? DayOfWeek.monday;
    _startTime = initial?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    _endTime = initial?.endTime ?? const TimeOfDay(hour: 10, minute: 0);
    _selectedColor = initial?.color ?? kPersonalScheduleColors.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return AlertDialog(
      title: Text(
        _isEditing ? '일정 수정' : '개인 일정 추가',
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
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    hintText: '예: 자료구조 수업',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '제목을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<DayOfWeek>(
                  value: _dayOfWeek,
                  decoration: const InputDecoration(labelText: '요일'),
                  items: DayOfWeek.values
                      .map(
                        (day) => DropdownMenuItem<DayOfWeek>(
                          value: day,
                          child: Text(day.longLabel),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _dayOfWeek = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _buildTimeField(context, true)),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: _buildTimeField(context, false)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: '장소 (선택)',
                    hintText: '예: 정보관 301호',
                  ),
                  maxLength: 200,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('색상 선택', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: kPersonalScheduleColors.map((color) {
                    final isSelected = color.value == _selectedColor.value;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: AnimatedContainer(
                        duration: AppMotion.quick,
                        curve: AppMotion.easing,
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(14),
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
        ConfirmCancelActions(
          confirmText: _isEditing ? '수정' : '추가',
          onConfirm: _handleSubmit,
          confirmSemanticsLabel: _isEditing ? '일정 수정 완료' : '개인 일정 추가 완료',
          onCancel: () => Navigator.of(context).pop(),
          cancelSemanticsLabel: _isEditing ? '일정 수정 취소' : '개인 일정 추가 취소',
          confirmVariant: PrimaryButtonVariant.brand,
        ),
      ],
    );
  }

  Widget _buildTimeField(BuildContext context, bool isStart) {
    return FormField<TimeOfDay>(
      validator: (_) {
        if (!_isValidTimeRange()) {
          return '종료 시간은 시작 시간보다 이후여야 합니다.';
        }
        return null;
      },
      builder: (field) {
        final time = isStart ? _startTime : _endTime;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputDecorator(
              decoration: InputDecoration(
                labelText: isStart ? '시작 시간' : '종료 시간',
                suffixIcon: const Icon(Icons.schedule_outlined),
                errorText: field.errorText,
              ),
              child: InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: time,
                    initialEntryMode: TimePickerEntryMode.dial,
                    builder: (context, child) {
                      return MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(alwaysUse24HourFormat: true),
                        child: child ?? const SizedBox.shrink(),
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      if (isStart) {
                        _startTime = picked;
                      } else {
                        _endTime = picked;
                      }
                    });
                    field.didChange(picked);
                  }
                },
                borderRadius: BorderRadius.circular(AppRadius.input),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatTimeOfDay(time)),
                      const Icon(
                        Icons.expand_more,
                        color: AppColors.neutral500,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isValidTimeRange() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    return endMinutes > startMinutes;
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final request = PersonalScheduleRequest(
      title: _titleController.text.trim(),
      dayOfWeek: _dayOfWeek,
      startTime: _startTime,
      endTime: _endTime,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      color: _selectedColor,
    );
    Navigator.of(context).pop(request);
  }

  String _formatTimeOfDay(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
