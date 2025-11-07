import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_button_styles.dart';
import '../../../core/models/recruitment_models.dart';
import '../../../core/models/group_models.dart';
import '../../widgets/common/state_view.dart';
import '../../widgets/common/section_card.dart';
import 'providers/recruitment_detail_provider.dart';
import 'widgets/application_submit_dialog.dart';

/// Recruitment Detail Page
///
/// Displays detailed information about a recruitment announcement
/// and allows users to apply
class RecruitmentDetailPage extends ConsumerWidget {
  const RecruitmentDetailPage({
    required this.recruitmentId,
    super.key,
  });

  final String recruitmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recruitmentIdInt = int.parse(recruitmentId);
    final recruitmentAsync = ref.watch(recruitmentDetailProvider(recruitmentIdInt));

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: StateView<RecruitmentResponse>(
        value: recruitmentAsync,
        loadingMessage: '모집 공고를 불러오는 중...',
        errorMessageExtractor: (error) => '모집 공고를 불러올 수 없습니다',
        onRetry: () => ref.invalidate(recruitmentDetailProvider(recruitmentIdInt)),
        builder: (context, recruitment) => _buildContent(context, ref, recruitment),
      ),
      bottomNavigationBar: recruitmentAsync.maybeWhen(
        data: (recruitment) => _buildBottomBar(context, ref, recruitment),
        orElse: () => null,
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, RecruitmentResponse recruitment) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final maxWidth = isWide ? 800.0 : double.infinity;

    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: EdgeInsets.all(isWide ? AppSpacing.lg : AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 그룹 정보 섹션
              _buildGroupInfoSection(context, recruitment),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.md),

              // 모집 공고 헤더
              _buildRecruitmentHeader(context, recruitment),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.md),

              // 모집 내용
              if (recruitment.content != null && recruitment.content!.isNotEmpty)
                _buildContentSection(context, recruitment),

              // 지원 질문 섹션
              if (recruitment.applicationQuestions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                _buildQuestionsSection(context, recruitment),
              ],

              // 하단 여백 (버튼을 위한 공간)
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupInfoSection(BuildContext context, RecruitmentResponse recruitment) {
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.brand.withValues(alpha: 0.1),
            child: Icon(Icons.group, size: 32, color: AppColors.brand),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recruitment.group.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildGroupPath(recruitment.group),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral600,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: AppColors.neutral600),
                    const SizedBox(width: 4),
                    Text(
                      '멤버 ${recruitment.group.memberCount}명',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecruitmentHeader(BuildContext context, RecruitmentResponse recruitment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recruitment.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral900,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _buildInfoChip(
                icon: Icons.calendar_today,
                label: _formatDate(recruitment.recruitmentStartDate),
                color: AppColors.neutral600,
              ),
              if (recruitment.recruitmentEndDate != null)
                _buildInfoChip(
                  icon: Icons.schedule,
                  label: _formatDeadline(recruitment.recruitmentEndDate!),
                  color: _getDeadlineColor(recruitment.recruitmentEndDate!),
                ),
              if (recruitment.showApplicantCount && recruitment.maxApplicants != null)
                _buildInfoChip(
                  icon: Icons.people,
                  label: '${recruitment.currentApplicantCount}/${recruitment.maxApplicants}',
                  color: AppColors.brand,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(BuildContext context, RecruitmentResponse recruitment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '모집 내용',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            recruitment.content!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.neutral700,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsSection(BuildContext context, RecruitmentResponse recruitment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '지원 시 답변할 질문',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...recruitment.applicationQuestions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                elevation: 0,
                color: AppColors.neutral100,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          question,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.neutral700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, RecruitmentResponse recruitment) {
    final hasApplied = ref.watch(hasAppliedProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return BottomAppBar(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: FilledButton(
            style: AppButtonStyles.primary(colorScheme),
            onPressed: _canApply(recruitment, hasApplied)
                ? () => _showApplicationDialog(context, ref, recruitment)
                : null,
            child: Text(
              _getButtonText(recruitment, hasApplied),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  bool _canApply(RecruitmentResponse recruitment, bool hasApplied) {
    if (hasApplied) return false;
    if (recruitment.status != RecruitmentStatus.open) return false;
    if (recruitment.maxApplicants != null &&
        recruitment.currentApplicantCount >= recruitment.maxApplicants!) {
      return false;
    }
    return true;
  }

  String _getButtonText(RecruitmentResponse recruitment, bool hasApplied) {
    if (hasApplied) return '지원 완료';
    if (recruitment.status == RecruitmentStatus.closed) return '마감되었습니다';
    if (recruitment.maxApplicants != null &&
        recruitment.currentApplicantCount >= recruitment.maxApplicants!) {
      return '지원자가 마감되었습니다';
    }
    return '지원하기';
  }

  void _showApplicationDialog(
    BuildContext context,
    WidgetRef ref,
    RecruitmentResponse recruitment,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ApplicationSubmitDialog(
          recruitment: recruitment,
          onSubmitSuccess: () {
            ref.read(hasAppliedProvider.notifier).state = true;
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy.MM.dd').format(date);
  }

  String _formatDeadline(DateTime endDate) {
    final now = DateTime.now();
    final diff = endDate.difference(now).inDays;
    if (diff < 0) return '마감';
    if (diff == 0) return '오늘 마감';
    return 'D-$diff';
  }

  Color _getDeadlineColor(DateTime endDate) {
    final diff = endDate.difference(DateTime.now()).inDays;
    if (diff < 0) return AppColors.error;
    if (diff <= 3) return AppColors.warning;
    return AppColors.success;
  }

  String _buildGroupPath(GroupSummaryResponse group) {
    final parts = <String>[];
    if (group.university != null) parts.add(group.university!);
    if (group.college != null) parts.add(group.college!);
    if (group.department != null) parts.add(group.department!);
    return parts.isNotEmpty ? parts.join(' > ') : '그룹';
  }
}
