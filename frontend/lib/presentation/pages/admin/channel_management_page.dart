import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../providers/workspace_state_provider.dart';
import '../workspace/widgets/workspace_state_view.dart';
import 'widgets/channel_list_section.dart';

/// 채널 관리 페이지
///
/// 그룹의 채널 목록 조회 및 관리
class ChannelManagementPage extends ConsumerWidget {
  const ChannelManagementPage({super.key});

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
              '채널 관리',
              style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                color: AppColors.neutral900,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              '그룹 채널 목록을 조회하고 새 채널을 추가하세요.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            // 채널 목록 섹션
            ChannelListSection(
              groupId: groupId,
              isDesktop: isDesktop,
            ),
          ],
        ),
      ),
    );
  }
}
