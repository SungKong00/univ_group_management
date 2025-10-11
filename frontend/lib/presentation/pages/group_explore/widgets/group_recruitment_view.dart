import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';

/// Group Recruitment View Widget
///
/// Displays a list of group recruitment announcements.
/// This is a placeholder implementation that will be connected to the backend API in the future.
class GroupRecruitmentView extends ConsumerWidget {
  const GroupRecruitmentView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign,
              size: 64,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '모집 공고',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.neutral700,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '그룹 모집 공고 목록이 여기에 표시됩니다.',
              style: AppTheme.bodyMediumTheme(context).copyWith(
                color: AppColors.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '(백엔드 API 연동 예정)',
              style: AppTheme.bodySmallTheme(context).copyWith(
                color: AppColors.neutral500,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
