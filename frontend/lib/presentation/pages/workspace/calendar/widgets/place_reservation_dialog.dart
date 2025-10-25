import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/models/place/place_reservation.dart';
import '../../../../../core/components/app_dialog_title.dart';
import '../../../../providers/place_calendar_provider.dart';
import '../../../../providers/group_calendar_provider.dart';

class PlaceReservationDialog extends ConsumerStatefulWidget {
  const PlaceReservationDialog({
    super.key,
    required this.groupId,
    this.initialDate,
    this.initialStartTime,
  });

  final int groupId;
  final DateTime? initialDate;
  final TimeOfDay? initialStartTime;

  @override
  ConsumerState<PlaceReservationDialog> createState() =>
      _PlaceReservationDialogState();
}

class _PlaceReservationDialogState
    extends ConsumerState<PlaceReservationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  int? _selectedPlaceId;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isSubmitting = false;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placeCalendarProvider);
    final places = state.places;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with brand color
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.brandLight.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available,
                    color: AppColors.brand,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: AppDialogTitle(
                      title: '장소 예약',
                      onClose: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),

            // Content area with form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 제목 입력
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: '제목',
                          hintText: '예약 제목을 입력하세요',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '제목을 입력해주세요';
                          }
                          return null;
                        },
                        maxLength: 100,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // 장소 선택 드롭다운
                      DropdownButtonFormField<int>(
                        initialValue: _selectedPlaceId,
                        decoration: const InputDecoration(
                          labelText: '장소',
                          prefixIcon: Icon(Icons.place),
                        ),
                        isExpanded: true,
                        items: places.isEmpty
                            ? []
                            : places.map((place) {
                                return DropdownMenuItem(
                                  value: place.id,
                                  child: Text(place.displayName),
                                );
                              }).toList(),
                        onChanged: places.isEmpty
                            ? null
                            : (value) {
                                setState(() => _selectedPlaceId = value);
                              },
                        validator: (value) {
                          if (value == null) return '장소를 선택해주세요';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // 날짜 선택
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: '날짜',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _selectedDate != null
                                ? '${_selectedDate!.year}년 ${_selectedDate!.month}월 ${_selectedDate!.day}일'
                                : '날짜를 선택하세요',
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // 시간 선택 (시작/종료)
                      Row(
                        children: [
                          Expanded(child: _buildTimeSelector(isStart: true)),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.xxs,
                            ),
                            child: Icon(Icons.arrow_forward, size: 20),
                          ),
                          Expanded(child: _buildTimeSelector(isStart: false)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions with background
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(80, 44),
                    ),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(100, 44),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('예약하기'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Check all required fields
    if (_selectedPlaceId == null ||
        _selectedDate == null ||
        _startTime == null ||
        _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 필드를 입력해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate time range
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    if (startMinutes >= endMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('종료 시간은 시작 시간보다 늦어야 합니다'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Step 1: Create GroupEvent first
      final startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      final endDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      // Create the event using GroupCalendarNotifier
      await ref.read(groupCalendarProvider(widget.groupId).notifier).createEvent(
            groupId: widget.groupId,
            title: _titleController.text.trim(),
            description: '장소 예약',
            startDate: startDateTime,
            endDate: endDateTime,
            isAllDay: false,
            isOfficial: false,
            color: '#9C27B0', // 보라색 (장소 예약 기본 색상)
          );

      // Get the created event from the state
      final state = ref.read(groupCalendarProvider(widget.groupId));
      if (state.events.isEmpty) {
        throw Exception('GroupEvent 생성 실패');
      }

      // Find the most recently created event (should be the last one)
      final createdEvent = state.events.last;

      // Step 2: Create PlaceReservation with the GroupEvent ID
      final reservationRequest = CreatePlaceReservationRequest(
        placeId: _selectedPlaceId!,
        groupEventId: createdEvent.id, // ✅ 실제 존재하는 ID
      );

      await ref.read(placeCalendarProvider.notifier).createReservation(
            placeId: _selectedPlaceId!,
            request: reservationRequest,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예약이 성공적으로 추가되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);

        // TODO: 향후 개선 - GroupEvent 생성 성공 후 PlaceReservation 실패 시
        // GroupEvent 삭제 API 호출하여 롤백 구현

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예약 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildTimeSelector({required bool isStart}) {
    final time = isStart ? _startTime : _endTime;
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? const TimeOfDay(hour: 9, minute: 0),
        );
        if (picked != null) {
          setState(() {
            if (isStart) {
              _startTime = picked;
            } else {
              _endTime = picked;
            }
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: isStart ? '시작 시간' : '종료 시간',
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, size: 20),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              time != null
                  ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                  : '--:--',
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function
Future<bool?> showPlaceReservationDialog(
  BuildContext context, {
  required int groupId,
  DateTime? initialDate,
  TimeOfDay? initialStartTime,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => PlaceReservationDialog(
      groupId: groupId,
      initialDate: initialDate,
      initialStartTime: initialStartTime,
    ),
  );
}
