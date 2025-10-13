import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/models/place/place_reservation.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../providers/place_calendar_provider.dart';

/// Dialog for creating a place reservation
/// Allows users to select a place, date/time, and provide a title/description
class PlaceReservationDialog extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialStartTime;

  const PlaceReservationDialog({
    super.key,
    this.initialDate,
    this.initialStartTime,
  });

  @override
  ConsumerState<PlaceReservationDialog> createState() =>
      _PlaceReservationDialogState();
}

class _PlaceReservationDialogState
    extends ConsumerState<PlaceReservationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _selectedPlaceId;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _startTime = widget.initialStartTime ?? const TimeOfDay(hour: 9, minute: 0);
    _endTime = TimeOfDay(
      hour: (_startTime!.hour + 2) % 24,
      minute: _startTime!.minute,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placeCalendarProvider);
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.add_location,
                      color: AppColors.brand,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '장소 예약',
                      style: textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Place selection
                _buildPlaceSelector(state),
                const SizedBox(height: AppSpacing.sm),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    hintText: '예약 제목을 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '제목을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                // Date selection
                _buildDateSelector(),
                const SizedBox(height: AppSpacing.sm),

                // Time selection
                Row(
                  children: [
                    Expanded(child: _buildTimeSelector(isStart: true)),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.arrow_forward, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: _buildTimeSelector(isStart: false)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Description (optional)
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: '설명 (선택)',
                    hintText: '추가 설명을 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.md),

                // Error message
                if (state.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    FilledButton(
                      onPressed: state.isLoading ? null : _handleSave,
                      child: state.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('예약'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceSelector(PlaceCalendarState state) {
    final places = state.places;

    return DropdownButtonFormField<int>(
      value: _selectedPlaceId,
      decoration: const InputDecoration(
        labelText: '장소',
        prefixIcon: Icon(Icons.place),
        border: OutlineInputBorder(),
      ),
      hint: Text(
        places.isEmpty ? '예약 가능한 장소가 없습니다' : '장소를 선택하세요',
        style: AppTheme.bodyMedium.copyWith(
          color: AppColors.neutral500,
        ),
      ),
      items: places.isEmpty
          ? []
          : places.map((place) {
              return DropdownMenuItem<int>(
                value: place.id,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        place.displayName,
                        style: AppTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (place.capacity != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${place.capacity}명)',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedPlaceId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return '장소를 선택해주세요';
        }
        return null;
      },
    );
  }

  Widget _buildDateSelector() {
    final dateFormat = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR');

    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '날짜',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        child: Text(
          _selectedDate != null
              ? dateFormat.format(_selectedDate!)
              : '날짜 선택',
          style: AppTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildTimeSelector({required bool isStart}) {
    final time = isStart ? _startTime : _endTime;
    final label = isStart ? '시작 시간' : '종료 시간';

    return InkWell(
      onTap: () => _selectTime(isStart: isStart),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, size: 20),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              time != null ? _formatTimeOfDay(time) : '--:--',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime({required bool isStart}) async {
    final initialTime = isStart ? _startTime : _endTime;

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          // Auto-adjust end time if it's before start time
          if (_endTime != null) {
            final startMinutes = picked.hour * 60 + picked.minute;
            final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
            if (endMinutes <= startMinutes) {
              _endTime = TimeOfDay(
                hour: (picked.hour + 1) % 24,
                minute: picked.minute,
              );
            }
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('날짜와 시간을 모두 선택해주세요')),
      );
      return;
    }

    // Validate time range
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료 시간은 시작 시간보다 늦어야 합니다')),
      );
      return;
    }

    // Note: Currently, the API requires a groupEventId which contains the date/time info.
    // These DateTime variables are kept for future use when we allow direct reservation
    // without requiring an existing group event.
    // ignore: unused_local_variable
    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    // ignore: unused_local_variable
    final endDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    // Create reservation request
    final request = CreatePlaceReservationRequest(
      placeId: _selectedPlaceId!,
      groupEventId: DateTime.now().millisecondsSinceEpoch ~/
          1000, // Temporary mock group event ID
    );

    try {
      await ref.read(placeCalendarProvider.notifier).createReservation(
        placeId: _selectedPlaceId!,
        request: request,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('예약이 추가되었습니다')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('예약 실패: ${e.toString()}')),
        );
      }
    }
  }
}

/// Helper function to show the dialog
Future<bool?> showPlaceReservationDialog(
  BuildContext context, {
  DateTime? initialDate,
  TimeOfDay? initialStartTime,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => PlaceReservationDialog(
      initialDate: initialDate,
      initialStartTime: initialStartTime,
    ),
  );
}
