import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';

/// 캘린더 네비게이션 바 (공통 컴포넌트)
///
/// 주간 뷰와 월간 뷰 모두에서 사용 가능한 날짜 네비게이션 컴포넌트
/// - 주간 뷰: 2줄 라벨 (주 라벨 + 날짜 범위)
/// - 월간 뷰: 1줄 라벨 (연월)
class CalendarNavigator extends StatelessWidget {
  const CalendarNavigator({
    required this.currentDate,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.label,
    this.subtitle,
    this.isWeekView = false,
    super.key,
  });

  /// 현재 선택된 날짜
  final DateTime currentDate;

  /// 이전 버튼 핸들러
  final VoidCallback onPrevious;

  /// 다음 버튼 핸들러
  final VoidCallback onNext;

  /// 오늘 버튼 핸들러
  final VoidCallback onToday;

  /// 주 라벨 또는 연월 라벨
  final String label;

  /// 부제목 (주간 뷰에서 날짜 범위 표시)
  final String? subtitle;

  /// 주간 뷰 여부 (true: 주간, false: 월간)
  final bool isWeekView;

  bool get _isToday {
    final now = DateTime.now();
    final normalized = DateTime(now.year, now.month, now.day);
    final current = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    if (isWeekView) {
      // 주간 뷰: 현재 주에 오늘이 포함되어 있는지 확인
      final weekStart = current.subtract(Duration(days: current.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      return !normalized.isBefore(weekStart) && !normalized.isAfter(weekEnd);
    } else {
      // 월간 뷰: 같은 연월인지 확인
      return normalized.year == current.year &&
          normalized.month == current.month;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: isWeekView ? '이전 주' : '이전',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          visualDensity: VisualDensity.compact,
        ),
        Flexible(child: _buildLabelSection(textTheme)),
        IconButton(
          tooltip: isWeekView ? '다음 주' : '다음',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: AppSpacing.xs),
        if (!_isToday)
          TextButton(
            onPressed: onToday,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.lightSecondary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              minimumSize: const Size(64, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '오늘',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  Widget _buildLabelSection(TextTheme textTheme) {
    if (subtitle != null) {
      // 주간 뷰: 2줄 라벨
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: textTheme.titleLarge,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle!,
            style: textTheme.bodySmall?.copyWith(color: AppColors.neutral500),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      // 월간 뷰: 1줄 라벨
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 140),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
  }
}
