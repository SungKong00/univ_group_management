import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/place_time_models.dart';
import '../../../../core/providers/place_time_providers.dart';
import '../../../../core/theme/theme.dart';

/// 금지시간 목록 위젯
class RestrictedTimeListWidget extends ConsumerWidget {
  final int placeId;

  const RestrictedTimeListWidget({
    super.key,
    required this.placeId,
  });

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
              children: [
                Text(
                  '금지시간',
                  style: AppTypography.titleLarge,
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => AddRestrictedTimeDialog(
                        placeId: placeId,
                      ),
                    );

                    if (result == true) {
                      ref.invalidate(restrictedTimesProvider(placeId));
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
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
                    return _RestrictedTimeItem(
                      time: time,
                      placeId: placeId,
                    );
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

  const _RestrictedTimeItem({
    required this.time,
    required this.placeId,
  });

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
              style: AppTypography.bodySmall,
            ),
            backgroundColor: AppColors.brandLight,
          ),
          const SizedBox(width: 8),
          Text(
            '${time.startTime} - ${time.endTime}',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      subtitle: time.reason != null && time.reason!.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                time.reason!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.neutral600,
                ),
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
                builder: (context) => EditRestrictedTimeDialog(
                  placeId: placeId,
                  time: time,
                ),
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
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('취소'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('삭제'),
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

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('금지시간이 삭제되었습니다')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류가 발생했습니다: $e')),
                    );
                  }
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

  const AddRestrictedTimeDialog({
    super.key,
    required this.placeId,
  });

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('금지시간이 추가되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
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
              Text('요일', style: AppTypography.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedDayOfWeek,
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
              Text('시간', style: AppTypography.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectTime(true),
                      child: Text(_formatTime(_startTime)),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('-'),
                  ),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectTime(false),
                      child: Text(_formatTime(_endTime)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 사유 입력 (선택)
              Text('사유 (선택)', style: AppTypography.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '금지 사유를 입력하세요',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPrimary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('추가'),
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
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('금지시간이 수정되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
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
              Text('요일', style: AppTypography.labelLarge),
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
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 시간 선택
              Text('시간', style: AppTypography.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectTime(true),
                      child: Text(_formatTime(_startTime)),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('-'),
                  ),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectTime(false),
                      child: Text(_formatTime(_endTime)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 사유 입력 (선택)
              Text('사유 (선택)', style: AppTypography.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '금지 사유를 입력하세요',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleUpdate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPrimary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('수정'),
        ),
      ],
    );
  }
}
