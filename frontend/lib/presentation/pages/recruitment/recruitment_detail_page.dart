import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/app_colors.dart';

/// Recruitment Detail Page (Placeholder)
///
/// Displays detailed information about a recruitment announcement
/// This is a placeholder implementation that will be completed in Phase 2
class RecruitmentDetailPage extends StatelessWidget {
  const RecruitmentDetailPage({
    required this.recruitmentId,
    super.key,
  });

  final String recruitmentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('모집 공고 상세'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.campaign,
                size: 80,
                color: AppColors.brand,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '모집 공고 상세',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.neutral900,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Recruitment ID: $recruitmentId',
                style: AppTheme.bodyLargeTheme(context).copyWith(
                  color: AppColors.neutral700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '이 페이지는 Phase 2에서 구현될 예정입니다.',
                style: AppTheme.bodyMediumTheme(context).copyWith(
                  color: AppColors.neutral600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
