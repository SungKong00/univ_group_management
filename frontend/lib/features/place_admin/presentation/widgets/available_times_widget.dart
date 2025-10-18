import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/place_time_models.dart';
import '../../../../core/providers/place_time_providers.dart';
import '../../../../core/theme/theme.dart';

/// 예약 가능 시간 조회 위젯
///
/// 특정 날짜를 선택하여 예약 가능한 시간대를 확인합니다.
/// 색상 구분:
/// - 초록색: 예약 가능
/// - 회색: 운영시간 외
/// - 주황색: 금지시간
/// - 빨강색: 임시 휴무
/// - 파랑색: 기존 예약
class AvailableTimesWidget extends ConsumerStatefulWidget {
  final int placeId;

  const AvailableTimesWidget({
    super.key,
    required this.placeId,
  });

  @override
  ConsumerState<AvailableTimesWidget> createState() =>
      _AvailableTimesWidgetState();
}

class _AvailableTimesWidgetState extends ConsumerState<AvailableTimesWidget> {
  DateTime _selectedDate = DateTime.now();

  String _formatDateForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.brandPrimary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
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
    final params = GetAvailableTimesParams(
      placeId: widget.placeId,
      date: _formatDateForApi(_selectedDate),
    );

    final availableTimesAsync = ref.watch(availableTimesProvider(params));

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 + 날짜 선택
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '예약 가능 시간',
                  style: AppTypography.titleLarge,
                ),
                OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    '${_selectedDate.month}/${_selectedDate.day} (${_dayLabels[_selectedDate.weekday == 1 ? 'MONDAY' : _selectedDate.weekday == 2 ? 'TUESDAY' : _selectedDate.weekday == 3 ? 'WEDNESDAY' : _selectedDate.weekday == 4 ? 'THURSDAY' : _selectedDate.weekday == 5 ? 'FRIDAY' : _selectedDate.weekday == 6 ? 'SATURDAY' : 'SUNDAY']})',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 조회 결과
            availableTimesAsync.when(
              data: (data) => _buildAvailableTimesDisplay(data),
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
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTimesDisplay(AvailableTimesResponse data) {
    // 휴무 체크
    if (data.isClosed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            children: [
              Icon(
                Icons.block,
                size: 48,
                color: AppColors.neutral400,
              ),
              const SizedBox(height: 12),
              Text(
                '운영하지 않는 요일입니다',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 운영시간 체크
    if (data.operatingHours == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Text(
            '운영시간이 설정되지 않았습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.neutral600,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 운영시간
        _buildInfoRow(
          '운영시간',
          '${data.operatingHours!.startTime} - ${data.operatingHours!.endTime}',
          AppColors.success,
        ),
        const SizedBox(height: 8),

        // 금지시간
        if (data.restrictedTimes.isNotEmpty) ...[
          _buildInfoRow(
            '금지시간',
            data.restrictedTimes
                .map((t) =>
                    '${t.startTime}-${t.endTime}${t.reason != null ? ' (${t.reason})' : ''}')
                .join(', '),
            Colors.orange,
          ),
          const SizedBox(height: 8),
        ],

        // 임시 휴무
        if (data.closures.isNotEmpty) ...[
          for (final closure in data.closures)
            _buildInfoRow(
              closure.isFullDay ? '전일 휴무' : '부분 휴무',
              closure.isFullDay
                  ? (closure.reason ?? '사유 없음')
                  : '${closure.startTime}-${closure.endTime}${closure.reason != null ? ' (${closure.reason})' : ''}',
              AppColors.error,
            ),
          const SizedBox(height: 8),
        ],

        // 기존 예약
        if (data.existingReservations.isNotEmpty) ...[
          _buildInfoRow(
            '기존 예약',
            data.existingReservations
                .map((r) => '${r.startTime}-${r.endTime} (${r.groupName})')
                .join(', '),
            Colors.blue,
          ),
          const SizedBox(height: 8),
        ],

        const Divider(height: 32),

        // 예약 가능 슬롯
        Text(
          '예약 가능 시간대',
          style: AppTypography.labelLarge,
        ),
        const SizedBox(height: 12),
        if (data.availableSlots.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                '예약 가능한 시간대가 없습니다',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.availableSlots.map((slot) {
              return Chip(
                label: Text(
                  '${slot.startTime} - ${slot.endTime}',
                  style: AppTypography.bodySmall,
                ),
                backgroundColor: AppColors.success.withOpacity(0.1),
                side: BorderSide(color: AppColors.success),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral900,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
