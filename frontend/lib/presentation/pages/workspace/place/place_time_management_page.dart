import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/place_admin/presentation/widgets/place_operating_hours_dialog.dart';
import '../../../../features/place_admin/presentation/widgets/restricted_time_widgets.dart';
import '../../../../features/place_admin/presentation/widgets/place_closure_widgets.dart';
import '../../../../features/place_admin/presentation/widgets/available_times_widget.dart';

/// Place time management page (workspace-level page without Scaffold)
/// Displays time slot management UI for a specific place
class PlaceTimeManagementPage extends ConsumerWidget {
  final int placeId;
  final String placeName;

  const PlaceTimeManagementPage({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.lightBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 페이지 타이틀
            Text(
              '장소 시간 관리',
              style: AppTheme.displaySmall,
            ),
            const SizedBox(height: 8.0),
            Text(
              '$placeName의 운영시간, 금지시간, 임시 휴무를 설정하고 예약 가능 시간을 조회할 수 있습니다.',
              style: AppTheme.bodyMedium.copyWith(color: AppColors.neutral600),
            ),
            const SizedBox(height: 32.0),

            // 섹션 1: 운영시간
            _buildSection(
              title: '운영시간 설정',
              description: '요일별 기본 운영시간을 설정합니다',
              child: PlaceOperatingHoursDisplay(placeId: placeId),
            ),
            const SizedBox(height: 32.0),

            // 섹션 2: 금지시간
            _buildSection(
              title: '금지시간 설정',
              description: '운영시간 내에서 특정 요일의 시간대를 예약 불가로 설정합니다',
              child: RestrictedTimeListWidget(placeId: placeId),
            ),
            const SizedBox(height: 32.0),

            // 섹션 3: 임시 휴무
            _buildSection(
              title: '임시 휴무 설정',
              description: '특정 날짜의 전일 또는 부분 시간대를 예약 불가로 설정합니다',
              child: PlaceClosureCalendarWidget(placeId: placeId),
            ),
            const SizedBox(height: 32.0),

            // 섹션 4: 예약 가능 시간
            _buildSection(
              title: '예약 가능 시간 조회',
              description: '설정된 규칙에 따라 특정 날짜의 예약 가능 시간을 확인합니다',
              child: AvailableTimesWidget(placeId: placeId),
            ),
            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.headlineMedium),
        const SizedBox(height: 8.0),
        Text(
          description,
          style: AppTheme.bodySmall.copyWith(color: AppColors.neutral600),
        ),
        const SizedBox(height: 12.0),
        child,
      ],
    );
  }
}
