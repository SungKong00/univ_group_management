import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../widgets/place_operating_hours_dialog.dart';
import '../widgets/restricted_time_widgets.dart';
import '../widgets/place_closure_widgets.dart';
import '../widgets/available_times_widget.dart';

/// 장소 관리 설정 페이지
///
/// 장소 시간 관리 기능을 통합한 메인 페이지입니다.
/// - 운영시간 설정
/// - 금지시간 관리
/// - 임시 휴무 관리
/// - 예약 가능 시간 조회
class PlaceAdminSettingsPage extends StatelessWidget {
  final int placeId;
  final String placeName;

  const PlaceAdminSettingsPage({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$placeName 관리'),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 설명
            Card(
              elevation: 0,
              color: AppColors.brandLight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.brandPrimary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '장소의 운영시간, 금지시간, 임시 휴무를 설정하여 예약 가능 시간을 관리할 수 있습니다.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.neutral700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 섹션 1: 운영시간
            Text(
              '1. 운영시간 설정',
              style: AppTypography.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '요일별 기본 운영시간을 설정합니다',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: 12),
            PlaceOperatingHoursDisplay(placeId: placeId),
            const SizedBox(height: 32),

            // 섹션 2: 금지시간
            Text(
              '2. 금지시간 설정',
              style: AppTypography.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '운영시간 내에서 특정 요일의 시간대를 예약 불가로 설정합니다',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: 12),
            RestrictedTimeListWidget(placeId: placeId),
            const SizedBox(height: 32),

            // 섹션 3: 임시 휴무
            Text(
              '3. 임시 휴무 설정',
              style: AppTypography.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '특정 날짜의 전일 또는 부분 시간대를 예약 불가로 설정합니다',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: 12),
            PlaceClosureCalendarWidget(placeId: placeId),
            const SizedBox(height: 32),

            // 섹션 4: 예약 가능 시간 조회
            Text(
              '4. 예약 가능 시간 조회',
              style: AppTypography.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '설정된 규칙에 따라 특정 날짜의 예약 가능 시간을 확인합니다',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: 12),
            AvailableTimesWidget(placeId: placeId),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
