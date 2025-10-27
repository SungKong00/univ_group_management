import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/place_time_models.dart';
import '../../../../core/providers/place_time_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../presentation/widgets/buttons/primary_button.dart';
import '../../../../presentation/widgets/buttons/neutral_outlined_button.dart';
import '../../../../presentation/widgets/buttons/outlined_link_button.dart';

/// 운영시간 설정 다이얼로그
///
/// 요일별 운영시간을 설정하는 다이얼로그입니다.
/// - 요일별 휴무 토글
/// - 시작/종료 시간 선택 (TimeOfDay picker)
/// - 저장/취소 액션
class PlaceOperatingHoursDialog extends ConsumerStatefulWidget {
  final int placeId;
  final List<OperatingHoursResponse>? initialHours;

  const PlaceOperatingHoursDialog({
    super.key,
    required this.placeId,
    this.initialHours,
  });

  @override
  ConsumerState<PlaceOperatingHoursDialog> createState() =>
      _PlaceOperatingHoursDialogState();
}

class _PlaceOperatingHoursDialogState
    extends ConsumerState<PlaceOperatingHoursDialog> {
  final Map<String, OperatingHoursItem> _hoursMap = {};
  bool _isLoading = false;
  bool _isInitializing = true;

  static const List<String> _daysOfWeek = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

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
  void initState() {
    super.initState();
    _loadOperatingHours();
  }

  /// 백엔드에서 최신 운영시간 데이터를 가져옵니다
  Future<void> _loadOperatingHours() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      // 백엔드에서 최신 데이터 가져오기
      final hours = await ref.read(operatingHoursProvider(widget.placeId).future);

      if (hours.isNotEmpty) {
        // 백엔드 데이터로 초기화
        for (final hour in hours) {
          _hoursMap[hour.dayOfWeek] = OperatingHoursItem(
            dayOfWeek: hour.dayOfWeek,
            startTime: hour.startTime,
            endTime: hour.endTime,
            isClosed: hour.isClosed,
          );
        }
      } else {
        // 데이터가 없으면 기본값으로 초기화
        _initializeWithDefaults();
      }
    } catch (e) {
      // 오류 발생 시 기본값으로 초기화
      _initializeWithDefaults();
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _initializeWithDefaults() {
    // 기본값: 평일 09:00-18:00, 주말 휴무
    for (final day in _daysOfWeek) {
      _hoursMap[day] = OperatingHoursItem(
        dayOfWeek: day,
        startTime: '09:00',
        endTime: '18:00',
        isClosed: day == 'SATURDAY' || day == 'SUNDAY',
      );
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final request = SetOperatingHoursRequest(
        operatingHours: _hoursMap.values.toList(),
      );

      final params = SetOperatingHoursParams(
        placeId: widget.placeId,
        request: request,
      );

      await ref.read(setOperatingHoursProvider(params).future);

      if (mounted) {
        Navigator.of(context).pop(true); // true: 성공
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

  Future<void> _selectTime(String dayOfWeek, bool isStartTime) async {
    final currentHours = _hoursMap[dayOfWeek]!;
    final currentTime = isStartTime
        ? _parseTime(currentHours.startTime ?? '09:00')
        : _parseTime(currentHours.endTime ?? '18:00');

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString = _formatTime(picked);
      setState(() {
        _hoursMap[dayOfWeek] = isStartTime
            ? currentHours.copyWith(startTime: timeString)
            : currentHours.copyWith(endTime: timeString);
      });
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('운영시간 설정'),
      content: _isInitializing
          ? const SizedBox(
              width: 500,
              height: 300,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _daysOfWeek.map((day) => _buildDayRow(day)).toList(),
                ),
              ),
            ),
      actions: [
        NeutralOutlinedButton(
          text: '취소',
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        PrimaryButton(
          text: '저장',
          variant: PrimaryButtonVariant.brand,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _handleSave,
        ),
      ],
    );
  }

  Widget _buildDayRow(String dayOfWeek) {
    final hours = _hoursMap[dayOfWeek]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // 요일 라벨
          SizedBox(
            width: 60,
            child: Text(
              _dayLabels[dayOfWeek]!,
              style: AppTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),

          // 휴무 토글
          SizedBox(
            width: 80,
            child: Row(
              children: [
                Checkbox(
                  value: hours.isClosed,
                  onChanged: (value) {
                    setState(() {
                      _hoursMap[dayOfWeek] = hours.copyWith(isClosed: value);
                    });
                  },
                ),
                const Text('휴무'),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 시작 시간
          Expanded(
            child: OutlinedLinkButton(
              text: hours.startTime ?? '09:00',
              onPressed: !hours.isClosed ? () => _selectTime(dayOfWeek, true) : null,
            ),
          ),
          const SizedBox(width: 8),
          const Text('-'),
          const SizedBox(width: 8),

          // 종료 시간
          Expanded(
            child: OutlinedLinkButton(
              text: hours.endTime ?? '18:00',
              onPressed: !hours.isClosed ? () => _selectTime(dayOfWeek, false) : null,
            ),
          ),
        ],
      ),
    );
  }

}

/// 운영시간 표시 + 수정 버튼 위젯
class PlaceOperatingHoursDisplay extends ConsumerWidget {
  final int placeId;

  const PlaceOperatingHoursDisplay({
    super.key,
    required this.placeId,
  });

  static const Map<String, String> _dayLabels = {
    'MONDAY': '월',
    'TUESDAY': '화',
    'WEDNESDAY': '수',
    'THURSDAY': '목',
    'FRIDAY': '금',
    'SATURDAY': '토',
    'SUNDAY': '일',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoursAsync = ref.watch(operatingHoursProvider(placeId));

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
                  '운영시간',
                  style: AppTheme.titleLarge,
                ),
                OutlinedLinkButton(
                  text: '설정 수정',
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => PlaceOperatingHoursDialog(
                        placeId: placeId,
                        initialHours:
                            hoursAsync.valueOrNull, // 기존 데이터 전달
                      ),
                    );

                    if (result == true) {
                      // 성공 시 목록 새로고침
                      ref.invalidate(operatingHoursProvider(placeId));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            hoursAsync.when(
              data: (hours) {
                if (hours.isEmpty) {
                  return const Text('운영시간이 설정되지 않았습니다');
                }
                return Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: hours.map((hour) {
                    return Chip(
                      label: Text(
                        '${_dayLabels[hour.dayOfWeek] ?? hour.dayOfWeek}: ${hour.isClosed ? '휴무' : '${hour.startTime ?? ''}-${hour.endTime ?? ''}'}',
                        style: AppTheme.bodySmall,
                      ),
                      backgroundColor: hour.isClosed
                          ? AppColors.disabledBgLight
                          : AppColors.brandContainerLight,
                    );
                  }).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('오류: $error'),
            ),
          ],
        ),
      ),
    );
  }
}
