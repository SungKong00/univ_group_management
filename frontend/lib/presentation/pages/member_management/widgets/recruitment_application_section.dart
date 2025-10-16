import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/recruitment_models.dart';
import '../../../../core/models/member_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';
import '../../../widgets/member/member_avatar.dart';
import '../providers/recruitment_application_provider.dart';
import '../providers/role_management_provider.dart';

/// 모집 공고 지원자 섹션
///
/// 모집 공고에 지원한 지원자 목록 및 승인/거절 기능
class RecruitmentApplicationSection extends ConsumerWidget {
  final int groupId;
  final bool isDesktop;

  const RecruitmentApplicationSection({
    super.key,
    required this.groupId,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 활성 모집 공고 조회
    final recruitmentAsync = ref.watch(activeRecruitmentProvider(groupId));

    return recruitmentAsync.when(
      data: (recruitment) {
        if (recruitment == null) {
          return _buildNoRecruitmentState();
        }

        // 2. 지원자 목록 조회 (활성 모집이 있을 때만)
        final applicationsAsync =
            ref.watch(recruitmentApplicationsProvider(recruitment.id));

        return applicationsAsync.when(
          data: (applications) {
            if (applications.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: applications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final application = applications[index];
                return _ApplicationCard(
                  application: application,
                  recruitmentId: recruitment.id,
                  groupId: groupId,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('지원자 목록을 불러올 수 없습니다',
                    style: AppTheme.bodyLarge),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('모집 공고를 불러올 수 없습니다', style: AppTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRecruitmentState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined,
                size: 64, color: AppColors.neutral400),
            const SizedBox(height: 16),
            Text(
              '활성 모집 공고가 없습니다',
              style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.neutral400),
            const SizedBox(height: 16),
            Text(
              '대기 중인 지원자가 없습니다',
              style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral600),
            ),
          ],
        ),
      ),
    );
  }
}

/// 지원자 카드
class _ApplicationCard extends ConsumerWidget {
  final ApplicationSummaryResponse application;
  final int recruitmentId;
  final int groupId;

  const _ApplicationCard({
    required this.application,
    required this.recruitmentId,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(roleListProvider(groupId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 지원자 정보
          MemberAvatarWithName(
            name: application.applicant.name,
            imageUrl: application.applicant.profileImageUrl,
            subtitle: application.applicant.email,
            avatarSize: 40,
          ),
          const SizedBox(height: 12),
          // 지원 동기
          if (application.motivation != null && application.motivation!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '지원 동기',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    application.motivation!,
                    style:
                        TextStyle(fontSize: 13, color: AppColors.neutral900),
                  ),
                ],
              ),
            ),
          if (application.motivation != null &&
              application.motivation!.isNotEmpty)
            const SizedBox(height: 8),
          // 지원 날짜
          Text(
            '지원일: ${_formatDate(application.appliedAt)}',
            style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
          ),
          // 상태 배지
          const SizedBox(height: 8),
          _buildStatusBadge(application.status),
          const SizedBox(height: 16),
          // 액션 버튼
          rolesAsync.when(
            data: (roles) => Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: application.status == ApplicationStatus.pending
                        ? () => _handleReject(context, ref)
                        : null,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('거절'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: application.status == ApplicationStatus.pending
                            ? AppColors.error
                            : AppColors.neutral300,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: application.status == ApplicationStatus.pending
                        ? () => _showApprovalDialog(context, ref, roles)
                        : null,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('승인'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: application.status ==
                              ApplicationStatus.pending
                          ? AppColors.brand
                          : AppColors.neutral300,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ApplicationStatus status) {
    Color bgColor;
    Color textColor;
    String statusText;

    switch (status) {
      case ApplicationStatus.pending:
        bgColor = AppColors.neutral100;
        textColor = AppColors.neutral600;
        statusText = '대기 중';
        break;
      case ApplicationStatus.approved:
        bgColor = Color(0xFFECF7FF);
        textColor = AppColors.brand;
        statusText = '승인됨';
        break;
      case ApplicationStatus.rejected:
        bgColor = Color(0xFFFFECEC);
        textColor = AppColors.error;
        statusText = '거절됨';
        break;
      case ApplicationStatus.withdrawn:
        bgColor = AppColors.neutral100;
        textColor = AppColors.neutral600;
        statusText = '철회됨';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  void _showApprovalDialog(
    BuildContext context,
    WidgetRef ref,
    List<GroupRole> roles,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('지원 승인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${application.applicant.name}님의 지원을 승인하시겠습니까?',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '승인 시 "멤버" 역할로 자동 추가됩니다.',
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _handleApprove(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
            ),
            child: const Text('승인'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      await ref.read(
        reviewApplicationProvider(
          ReviewApplicationParams(
            applicationId: application.id,
            action: 'APPROVE',
          ),
        ).future,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${application.applicant.name}님의 지원을 승인했습니다'),
            backgroundColor: AppColors.success,
          ),
        );

        // 지원자 목록 새로고침
        ref.invalidate(recruitmentApplicationsProvider(recruitmentId));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('승인 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지원 거절'),
        content: Text('${application.applicant.name}님의 지원을 거절하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('거절'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(
          reviewApplicationProvider(
            ReviewApplicationParams(
              applicationId: application.id,
              action: 'REJECT',
            ),
          ).future,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${application.applicant.name}님의 지원을 거절했습니다')),
          );

          // 지원자 목록 새로고침
          ref.invalidate(recruitmentApplicationsProvider(recruitmentId));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('거절 처리 중 오류가 발생했습니다: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}
