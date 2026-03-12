import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/place_time_models.dart';
import '../../../../core/providers/place_time_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/app_form_field.dart';
import '../../../../presentation/widgets/buttons/primary_button.dart';
import '../../../../presentation/widgets/buttons/error_button.dart';
import '../../../../presentation/widgets/buttons/neutral_outlined_button.dart';
import '../../../../presentation/widgets/buttons/outlined_link_button.dart';

/// 금지시간 목록 위젯
class RestrictedTimeListWidget extends ConsumerWidget {
  final int placeId;

  const RestrictedTimeListWidget({super.key, required this.placeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restrictedTimesAsync = ref.watch(restrictedTimesProvider(placeId));

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text('금지시간', style: AppTheme.titleLarge),
                Flexible(
                  child: PrimaryButton(
                    text: '추가',
                    variant: PrimaryButtonVariant.brand,
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) =>
                            AddRestrictedTimeDialog(placeId: placeId),
                      );

                      if (result == true) {
                        ref.invalidate(restrictedTimesProvider(placeId));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            restrictedTimesAsync.when(
              data: (times) {
                if (times.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('설정된 금지시간이 없습니다'),
                    ),
                  );
                }

                // 요일별로 정렬
                final sortedTimes = List<RestrictedTimeResponse>.from(times)
                  ..sort((a, b) {
                    final dayOrder = {
                      'MONDAY': 1,
                      'TUESDAY': 2,
                      'WEDNESDAY': 3,
                      'THURSDAY': 4,
                      'FRIDAY': 5,
                      'SATURDAY': 6,
                      'SUNDAY': 7,
                    };
                    final aOrder = dayOrder[a.dayOfWeek] ?? 8;
                    final bOrder = dayOrder[b.dayOfWeek] ?? 8;
                    if (aOrder != bOrder) return aOrder.compareTo(bOrder);
                    return a.displayOrder.compareTo(b.displayOrder);
                  });

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedTimes.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final time = sortedTimes[index];
                    return _RestrictedTimeItem(time: time, placeId: placeId);
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('오류: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 금지시간 단일 아이템
class _RestrictedTimeItem extends ConsumerWidget {
  final RestrictedTimeResponse time;
  final int placeId;

  const _RestrictedTimeItem({required this.time, required this.placeId});

  static const Map<String, String> _dayLabels = {
    'MONDAY': '월요일',
    'TUESDAY': '화요일',
    'WEDNESDAY': '수요일',
    'THURSDAY': '목요일',
    'FRIDAY': '금요일',
    'SATURDAY': '토요일',
    'SUNDAY': '일요일',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Chip(
            label: Text(
              _dayLabels[time.dayOfWeek] ?? time.dayOfWeek,
              style: AppTheme.bodySmall,
            ),
            backgroundColor: AppColors.brandLight,
          ),
          const SizedBox(width: 8),
          Text(
            '${time.startTime} - ${time.endTime}',
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      subtitle: time.reason != null && time.reason!.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                time.reason!,
                style: AppTheme.bodySmall.copyWith(color: AppColors.neutral600),
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) =>
                    EditRestrictedTimeDialog(placeId: placeId, time: time),
              );

              if (result == true) {
                ref.invalidate(restrictedTimesProvider(placeId));
              }
            },
            tooltip: '수정',
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            color: AppColors.error,
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('금지시간 삭제'),
                  content: const Text('이 금지시간을 삭제하시겠습니까?'),
                  actions: [
                    NeutralOutlinedButton(
                      text: '취소',
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    ErrorButton(
                      text: '삭제',
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  final params = DeleteRestrictedTimeParams(
                    placeId: placeId,
                    restrictedTimeId: time.id,
                  );
                  await ref.read(deleteRestrictedTimeProvider(params).future);
                  // 삭제 성공 시 목록 자동 갱신 (ref.invalidate는 호출 측에서 처리)
                } catch (e) {
                  // 에러 발생 시에도 다이얼로그는 닫히지 않음
                  // TODO: 에러 처리 개선 필요 (Toast 또는 Dialog)
                }
              }
            },
            tooltip: '삭제',
          ),
        ],
      ),
    );
  }
}

/// 금지시간 추가 다이얼로그
class AddRestrictedTimeDialog extends ConsumerStatefulWidget {
  final int placeId;

  const AddRestrictedTimeDialog({super.key, required this.placeId});

  @override
  ConsumerState<AddRestrictedTimeDialog> createState() =>
      _AddRestrictedTimeDialogState();
}

class _AddRestrictedTimeDialogState
    extends ConsumerState<AddRestrictedTimeDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedDayOfWeek = 'MONDAY';
  TimeOfDay _startTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 13, minute: 0);
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  static const Map<String, String> _dayLabels = {
    'MONDAY': '월요일',
    'TUESDAY': '화요일',
    'WEDNESDAY': '수요일',
    'THURSDAY': '목요일',
    'FRIDAY': '금요일',
    'SATURDAY': '토요일',
    'SUNDAY': '일요일',
  };

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleAdd() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final request = AddRestrictedTimeRequest(
        dayOfWeek: _selectedDayOfWeek,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      );

      final params = AddRestrictedTimeParams(
        placeId: widget.placeId,
        request: request,
      );

      await ref.read(addRestrictedTimeProvider(params).future);

      if (mounted) {
        Navigator.of(context).pop(true);
        // 추가 성공 시 목록 자동 갱신 (ref.invalidate는 호출 측에서 처리)
      }
    } catch (e) {
      // 에러 발생 시 다이얼로그는 닫히지 않음
      // TODO: 에러 처리 개선 필요 (Toast 또는 Dialog)
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('금지시간 추가'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 요일 선택
              Text('요일', style: AppTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedDayOfWeek,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: _dayLabels.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedDayOfWeek = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // 시간 선택
              Text('시간', style: AppTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedLinkButton(
                      text: _formatTime(_startTime),
                      onPressed: () => _selectTime(true),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('-'),
                  ),
                  Expanded(
                    child: OutlinedLinkButton(
                      text: _formatTime(_endTime),
                      onPressed: () => _selectTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 사유 입력 (선택)
              AppFormField(
                label: '사유 (선택)',
                controller: _reasonController,
                hintText: '금지 사유를 입력하세요',
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        NeutralOutlinedButton(
          text: '취소',
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        PrimaryButton(
          text: '추가',
          variant: PrimaryButtonVariant.brand,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _handleAdd,
        ),
      ],
    );
  }
}

/// 금지시간 수정 다이얼로그
class EditRestrictedTimeDialog extends ConsumerStatefulWidget {
  final int placeId;
  final RestrictedTimeResponse time;

  const EditRestrictedTimeDialog({
    super.key,
    required this.placeId,
    required this.time,
  });

  @override
  ConsumerState<EditRestrictedTimeDialog> createState() =>
      _EditRestrictedTimeDialogState();
}

class _EditRestrictedTimeDialogState
    extends ConsumerState<EditRestrictedTimeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TextEditingController _reasonController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTime = _parseTime(widget.time.startTime);
    _endTime = _parseTime(widget.time.endTime);
    _reasonController = TextEditingController(text: widget.time.reason ?? '');
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final request = AddRestrictedTimeRequest(
        dayOfWeek: widget.time.dayOfWeek,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      );

      final params = UpdateRestrictedTimeParams(
        placeId: widget.placeId,
        restrictedTimeId: widget.time.id,
        request: request,
      );

      await ref.read(updateRestrictedTimeProvider(params).future);

      if (mounted) {
        Navigator.of(context).pop(true);
        // 수정 성공 시 목록 자동 갱신 (ref.invalidate는 호출 측에서 처리)
      }
    } catch (e) {
      // 에러 발생 시 다이얼로그는 닫히지 않음
      // TODO: 에러 처리 개선 필요 (Toast 또는 Dialog)
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  static const Map<String, String> _dayLabels = {
    'MONDAY': '월요일',
    'TUESDAY': '화요일',
    'WEDNESDAY': '수요일',
    'THURSDAY': '목요일',
    'FRIDAY': '금요일',
    'SATURDAY': '토요일',
    'SUNDAY': '일요일',
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('금지시간 수정'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 요일 표시 (수정 불가)
              Text('요일', style: AppTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.neutral300),
                  borderRadius: BorderRadius.circular(4),
                  color: AppColors.neutral100,
                ),
                child: Text(
                  _dayLabels[widget.time.dayOfWeek] ?? widget.time.dayOfWeek,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 시간 선택
              Text('시간', style: AppTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedLinkButton(
                      text: _formatTime(_startTime),
                      onPressed: () => _selectTime(true),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('-'),
                  ),
                  Expanded(
                    child: OutlinedLinkButton(
                      text: _formatTime(_endTime),
                      onPressed: () => _selectTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 사유 입력 (선택)
              AppFormField(
                label: '사유 (선택)',
                controller: _reasonController,
                hintText: '금지 사유를 입력하세요',
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        NeutralOutlinedButton(
          text: '취소',
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        PrimaryButton(
          text: '수정',
          variant: PrimaryButtonVariant.brand,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _handleUpdate,
        ),
      ],
    );
  }
}
