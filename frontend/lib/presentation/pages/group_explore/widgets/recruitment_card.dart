import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/recruitment_models.dart';
import '../providers/recruitment_explore_state_provider.dart';

/// Recruitment Card Widget
///
/// Displays a single recruitment announcement in a card format
class RecruitmentCard extends ConsumerWidget {
  const RecruitmentCard({
    required this.recruitment,
    super.key,
  });

  final RecruitmentSummaryResponse recruitment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: AppColors.neutral300, width: 1),
      ),
      child: InkWell(
        onTap: () {
          ref.read(selectedRecruitmentIdProvider.notifier).state = recruitment.id;
        },
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Name
              Row(
                children: [
                  Icon(
                    Icons.groups,
                    size: 16,
                    color: AppColors.brand,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      recruitment.groupName,
                      style: AppTheme.titleMediumTheme(context).copyWith(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Recruitment Title
              Text(
                recruitment.title,
                style: AppTheme.titleLargeTheme(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Content Preview
              if (recruitment.content != null) ...[
                Text(
                  recruitment.content!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyMediumTheme(context).copyWith(
                    color: AppColors.neutral700,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Bottom Info Row
              Row(
                children: [
                  // Deadline
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppColors.neutral600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDeadline(recruitment.recruitmentEndDate),
                    style: AppTheme.bodySmallTheme(context).copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                  const Spacer(),

                  // Applicant Count (if visible)
                  if (recruitment.showApplicantCount &&
                      recruitment.maxApplicants != null) ...[
                    Icon(
                      Icons.people,
                      size: 16,
                      color: AppColors.neutral600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${recruitment.currentApplicantCount ?? 0}/${recruitment.maxApplicants}',
                      style: AppTheme.bodySmallTheme(context).copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Format deadline as D-day format
  String _formatDeadline(DateTime? endDate) {
    if (endDate == null) return '상시 모집';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadline = DateTime(endDate.year, endDate.month, endDate.day);
    final diff = deadline.difference(today).inDays;

    if (diff < 0) return '마감';
    if (diff == 0) return '오늘 마감';
    return 'D-$diff';
  }
}
