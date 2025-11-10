import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/place_time_models.dart';
import '../../../../core/providers/place_time_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/components.dart';
import '../../../../presentation/widgets/buttons/primary_button.dart';
import '../../../../presentation/widgets/buttons/error_button.dart';
import '../../../../presentation/widgets/buttons/neutral_outlined_button.dart';
import '../../../../presentation/widgets/buttons/outlined_link_button.dart';

/// 임시 휴무 캘린더 위젯
///
/// 월간 캘린더 형식으로 휴무 날짜를 표시하고 관리합니다.
class PlaceClosureCalendarWidget extends ConsumerStatefulWidget {
  final int placeId;

  const PlaceClosureCalendarWidget({super.key, required this.placeId});

  @override
  ConsumerState<PlaceClosureCalendarWidget> createState() =>
      _PlaceClosureCalendarWidgetState();
}

class _PlaceClosureCalendarWidgetState
    extends ConsumerState<PlaceClosureCalendarWidget> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // 현재 월의 시작/끝 날짜
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    final params = GetClosuresParams(
      placeId: widget.placeId,
      from: _formatDateForApi(firstDay),
      to: _formatDateForApi(lastDay),
    );

    final closuresAsync = ref.watch(closuresProvider(params));

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('임시 휴무', style: AppTheme.titleLarge),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _previousMonth,
                      tooltip: '이전 달',
                    ),
                    Text(
                      '${_currentMonth.year}년 ${_currentMonth.month}월',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextMonth,
                      tooltip: '다음 달',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 캘린더
            closuresAsync.when(
              data: (closures) {
                // 날짜별 휴무 맵 생성
                final closureMap = <String, List<PlaceClosureResponse>>{};
                for (final closure in closures) {
                  closureMap
                      .putIfAbsent(closure.closureDate, () => [])
                      .add(closure);
                }

                return _buildCalendar(closureMap);
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
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

            const SizedBox(height: 16),

            // 범례
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem('전일 휴무', AppColors.error),
                _buildLegendItem('부분 휴무', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(Map<String, List<PlaceClosureResponse>> closureMap) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday; // 1 (Monday) ~ 7 (Sunday)

    // 요일 헤더
    const weekDays = ['월', '화', '수', '목', '금', '토', '일'];

    return Column(
      children: [
        // 요일 헤더
        Row(
          children: weekDays.map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: AppTheme.titleMedium.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // 날짜 그리드
        ...List.generate((lastDay.day + startWeekday - 1) ~/ 7 + 1, (
          weekIndex,
        ) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              children: List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - (startWeekday - 2);
                if (dayNumber < 1 || dayNumber > lastDay.day) {
                  return Expanded(child: Container());
                }

                final date = DateTime(
                  _currentMonth.year,
                  _currentMonth.month,
                  dayNumber,
                );
                final dateStr = _formatDateForApi(date);
                final closures = closureMap[dateStr] ?? [];

                return Expanded(child: _buildDayCell(date, closures));
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDayCell(DateTime date, List<PlaceClosureResponse> closures) {
    final hasFullDay = closures.any((c) => c.isFullDay);
    final hasPartial = closures.any((c) => !c.isFullDay);

    Color? bgColor;
    if (hasFullDay) {
      bgColor = AppColors.error.withOpacity(0.1);
    } else if (hasPartial) {
      bgColor = Colors.orange.withOpacity(0.1);
    }

    final isToday =
        date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return InkWell(
      onTap: () async {
        if (closures.isEmpty) {
          // 휴무 추가 다이얼로그
          final result = await _showAddClosureDialog(date);
          if (result == true) {
            // 목록 새로고침
            ref.invalidate(closuresProvider);
          }
        } else {
          // 휴무 상세 보기 + 삭제
          await _showClosureDetailDialog(date, closures);
        }
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: isToday ? AppColors.brand : AppColors.neutral300,
            width: isToday ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  color: hasFullDay
                      ? AppColors.error
                      : hasPartial
                      ? Colors.orange
                      : AppColors.neutral900,
                ),
              ),
              if (closures.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: hasFullDay ? AppColors.error : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.bodySmall),
      ],
    );
  }

  Future<bool?> _showAddClosureDialog(DateTime date) {
    return showDialog<bool>(
      context: context,
      builder: (context) =>
          AddClosureDialogSelector(placeId: widget.placeId, date: date),
    );
  }

  Future<void> _showClosureDetailDialog(
    DateTime date,
    List<PlaceClosureResponse> closures,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => ClosureDetailDialog(
        placeId: widget.placeId,
        date: date,
        closures: closures,
        onDeleted: () {
          // 목록 새로고침
          ref.invalidate(closuresProvider);
        },
      ),
    );
  }
}

/// 휴무 추가 다이얼로그 선택기 (전일/부분)
class AddClosureDialogSelector extends StatelessWidget {
  final int placeId;
  final DateTime date;

  const AddClosureDialogSelector({
    super.key,
    required this.placeId,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${date.month}월 ${date.day}일 휴무 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text('전일 휴무'),
            subtitle: const Text('하루 종일 예약 불가'),
            onTap: () {
              Navigator.of(context).pop();
              _showFullDayDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule, color: Colors.orange),
            title: const Text('부분 시간 휴무'),
            subtitle: const Text('특정 시간대만 예약 불가'),
            onTap: () {
              Navigator.of(context).pop();
              _showPartialDialog(context);
            },
          ),
        ],
      ),
      actions: [
        NeutralOutlinedButton(
          text: '취소',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<void> _showFullDayDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AddFullDayClosureDialog(placeId: placeId, date: date),
    );

    if (result == true && context.mounted) {
      Navigator.of(context).pop(true); // 상위 다이얼로그로 성공 전달
    }
  }

  Future<void> _showPartialDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AddPartialClosureDialog(placeId: placeId, date: date),
    );

    if (result == true && context.mounted) {
      Navigator.of(context).pop(true); // 상위 다이얼로그로 성공 전달
    }
  }
}

/// 전일 휴무 추가 다이얼로그
class AddFullDayClosureDialog extends ConsumerStatefulWidget {
  final int placeId;
  final DateTime date;

  const AddFullDayClosureDialog({
    super.key,
    required this.placeId,
    required this.date,
  });

  @override
  ConsumerState<AddFullDayClosureDialog> createState() =>
      _AddFullDayClosureDialogState();
}

class _AddFullDayClosureDialogState
    extends ConsumerState<AddFullDayClosureDialog> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final request = AddFullDayClosureRequest(
        closureDate: _formatDateForApi(widget.date),
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      );

      final params = AddFullDayClosureParams(
        placeId: widget.placeId,
        request: request,
      );

      await ref.read(addFullDayClosureProvider(params).future);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // 오류는 로그만 출력 (ScaffoldMessenger 사용 금지 - workspace-level 페이지)
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.date.month}월 ${widget.date.day}일 전일 휴무 추가'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFormField(
              label: '사유 (선택)',
              controller: _reasonController,
              hintText: '휴무 사유를 입력하세요',
              maxLines: 2,
            ),
          ],
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

/// 부분 시간 휴무 추가 다이얼로그
class AddPartialClosureDialog extends ConsumerStatefulWidget {
  final int placeId;
  final DateTime date;

  const AddPartialClosureDialog({
    super.key,
    required this.placeId,
    required this.date,
  });

  @override
  ConsumerState<AddPartialClosureDialog> createState() =>
      _AddPartialClosureDialogState();
}

class _AddPartialClosureDialogState
    extends ConsumerState<AddPartialClosureDialog> {
  final _reasonController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 13, minute: 0);
  bool _isLoading = false;

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

  String _formatDateForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _handleAdd() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final request = AddPartialClosureRequest(
        closureDate: _formatDateForApi(widget.date),
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      );

      final params = AddPartialClosureParams(
        placeId: widget.placeId,
        request: request,
      );

      await ref.read(addPartialClosureProvider(params).future);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // 오류는 로그만 출력 (ScaffoldMessenger 사용 금지 - workspace-level 페이지)
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
      title: Text('${widget.date.month}월 ${widget.date.day}일 부분 휴무 추가'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            // 사유
            AppFormField(
              label: '사유 (선택)',
              controller: _reasonController,
              hintText: '휴무 사유를 입력하세요',
              maxLines: 2,
            ),
          ],
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

/// 휴무 상세 보기 + 삭제 다이얼로그
class ClosureDetailDialog extends ConsumerWidget {
  final int placeId;
  final DateTime date;
  final List<PlaceClosureResponse> closures;
  final VoidCallback onDeleted;

  const ClosureDetailDialog({
    super.key,
    required this.placeId,
    required this.date,
    required this.closures,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text('${date.month}월 ${date.day}일 휴무'),
      content: SizedBox(
        width: 400,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: closures.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final closure = closures[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  Icon(
                    closure.isFullDay ? Icons.block : Icons.schedule,
                    color: closure.isFullDay ? AppColors.error : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    closure.isFullDay
                        ? '전일 휴무'
                        : '${closure.startTime} - ${closure.endTime}',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              subtitle: closure.reason != null && closure.reason!.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        closure.reason!,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.neutral600,
                        ),
                      ),
                    )
                  : null,
              trailing: IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: AppColors.error,
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('휴무 삭제'),
                      content: const Text('이 휴무를 삭제하시겠습니까?'),
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
                      final params = DeleteClosureParams(
                        placeId: placeId,
                        closureId: closure.id,
                      );
                      await ref.read(deleteClosureProvider(params).future);

                      if (context.mounted) {
                        onDeleted();
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      // 오류는 로그만 출력 (ScaffoldMessenger 사용 금지 - workspace-level 페이지)
                    }
                  }
                },
              ),
            );
          },
        ),
      ),
      actions: [
        NeutralOutlinedButton(
          text: '닫기',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
