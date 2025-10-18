import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';

/// 모집 공고 정보를 보여주는 가로 스크롤 카드 위젯
///
/// 토스 디자인 철학 적용:
/// - 단순함: 핵심 정보만 표시 (그룹명, 모집 제목, 마감일, 지원자 수)
/// - 위계: 그룹명 → 모집 제목 → 마감일 → 지원자 수
/// - 여백: 일관된 spacing으로 구조 명확화
/// - 피드백: 터치 시 InkWell 효과
///
/// Usage:
/// ```dart
/// RecruitmentCard(
///   groupName: 'AISC',
///   recruitmentTitle: '2025 1학기 신입 기수 모집',
///   applicantCount: 15,
///   endDate: DateTime.now().add(Duration(days: 7)),
///   avatarText: 'AI',
///   onTap: () => navigateToRecruitment(recruitmentId),
/// )
/// ```
class RecruitmentCard extends StatelessWidget {
  final String groupName;
  final String recruitmentTitle;
  final int? applicantCount;
  final DateTime? endDate;
  final bool showApplicantCount;
  final String avatarText;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  const RecruitmentCard({
    super.key,
    required this.groupName,
    required this.recruitmentTitle,
    this.applicantCount,
    this.endDate,
    this.showApplicantCount = true,
    required this.avatarText,
    this.onTap,
    this.semanticsLabel,
  });

  String _formatEndDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays > 0) {
      return 'D-${difference.inDays}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 남음';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 남음';
    } else {
      return '마감';
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedEndDate = endDate != null ? _formatEndDate(endDate!) : null;

    return Semantics(
      button: true,
      label: semanticsLabel ??
          '$groupName. $recruitmentTitle. ${formattedEndDate ?? ''}${showApplicantCount && applicantCount != null ? '. 지원자 $applicantCount명' : ''}',
      child: Container(
        width: AppComponents.groupCardWidth + 20, // Slightly wider for more content
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        child: Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Avatar + Group Name
                  Row(
                    children: [
                      CircleAvatar(
                        radius: AppComponents.avatarSmall,
                        backgroundColor: AppColors.brand,
                        child: Text(
                          avatarText,
                          style: TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          groupName,
                          style: AppTheme.bodySmallTheme(context).copyWith(
                            color: AppColors.neutral600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),

                  // Recruitment Title
                  Expanded(
                    child: Text(
                      recruitmentTitle,
                      style: AppTheme.titleMediumTheme(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),

                  // Footer: End Date + Applicant Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // End Date Badge
                      if (formattedEndDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxs,
                            vertical: AppSpacing.xxs / 2,
                          ),
                          decoration: BoxDecoration(
                            color: _isEndingSoon(endDate!)
                                ? AppColors.error.withAlpha(26) // 0.1 opacity
                                : AppColors.brandLight,
                            borderRadius: BorderRadius.circular(
                              AppComponents.badgeRadius,
                            ),
                          ),
                          child: Text(
                            formattedEndDate,
                            style: AppTheme.labelSmallTheme(context).copyWith(
                              color: _isEndingSoon(endDate!)
                                  ? AppColors.error
                                  : AppColors.brand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                      // Applicant Count
                      if (showApplicantCount && applicantCount != null)
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 14,
                              color: AppColors.neutral600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$applicantCount명',
                              style:
                                  AppTheme.labelSmallTheme(context).copyWith(
                                color: AppColors.neutral600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isEndingSoon(DateTime endDate) {
    final difference = endDate.difference(DateTime.now());
    return difference.inDays <= 3; // Consider "ending soon" if 3 days or less
  }
}
