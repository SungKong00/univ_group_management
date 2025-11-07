import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../providers/workspace_state_provider.dart';
import '../member_management/widgets/recruitment_application_section.dart';
import '../workspace/widgets/workspace_state_view.dart';

/// 모집 지원자 관리 페이지
///
/// 그룹의 모집 공고에 대한 지원자 관리
class ApplicationManagementPage extends ConsumerWidget {
  const ApplicationManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupIdStr = ref.watch(currentGroupIdProvider);

    if (groupIdStr == null) {
      return const WorkspaceStateView(type: WorkspaceStateType.noGroup);
    }

    final groupId = int.tryParse(groupIdStr);
    if (groupId == null) {
      return WorkspaceStateView(
        type: WorkspaceStateType.error,
        errorMessage: '그룹 정보를 불러오지 못했습니다.',
      );
    }

    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final paddingHorizontal = isDesktop ? AppSpacing.lg : AppSpacing.sm;
    final paddingVertical = isDesktop ? AppSpacing.lg : AppSpacing.sm;

    return Container(
      color: AppColors.neutral100,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: paddingHorizontal,
          vertical: paddingVertical,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Text(
              '지원자 관리',
              style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                color: AppColors.neutral900,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              '모집 공고에 대한 지원자를 확인하고 승인/거절 처리하세요.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            // 지원자 목록 섹션 (모집 공고 기반)
            RecruitmentApplicationSection(
              groupId: groupId,
              isDesktop: isDesktop,
            ),
          ],
        ),
      ),
    );
  }
}
