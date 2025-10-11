import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/home_state_provider.dart';
import '../../widgets/cards/action_card.dart';
import '../../widgets/cards/group_card.dart';
import 'widgets/group_explore_content_widget.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(currentHomeViewProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: _buildViewForCurrentState(context, ref, currentView),
      ),
    );
  }

  Widget _buildViewForCurrentState(
    BuildContext context,
    WidgetRef ref,
    HomeView currentView,
  ) {
    switch (currentView) {
      case HomeView.dashboard:
        return _buildDashboardView(context, ref);
      case HomeView.groupExplore:
        return const GroupExploreContentWidget();
    }
  }

  Widget _buildDashboardView(BuildContext context, WidgetRef ref) {
    // 문서 스펙: TABLET(451px) 이상을 데스크톱 레이아웃으로 간주
    // largerThan(MOBILE) = 451px 이상 = TABLET, DESKTOP, 4K
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: SingleChildScrollView(
        // 문서 스펙: 모바일 96px, 데스크톱 120px 수직 여백
        // 수평 여백은 기존대로 lg/md 사용
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? AppSpacing.lg : AppSpacing.md,
          vertical: isDesktop ? AppSpacing.offsetMax : AppSpacing.offsetMin,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('안녕하세요! 👋', style: AppTheme.displayMediumTheme(context)),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '오늘도 활발한 그룹 활동을 시작해보세요',
              style: AppTheme.bodyLargeTheme(
                context,
              ).copyWith(color: AppColors.neutral600),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildQuickActions(context, ref, isDesktop),
            const SizedBox(height: AppSpacing.lg),
            _buildRecentGroups(context),
            const SizedBox(height: AppSpacing.lg),
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('빠른 실행', style: AppTheme.headlineSmallTheme(context)),
        const SizedBox(height: AppSpacing.sm),
        isDesktop
            ? Row(
                children: [
                  Expanded(
                    child: ActionCard(
                      icon: Icons.people_outline,
                      title: '모집 중인 그룹 보기',
                      description: '지금 모집 중인 그룹을 찾아보세요',
                      onTap: () => ref.read(homeStateProvider.notifier).showGroupExploreWithRecruitingFilter(),
                      semanticsLabel: '모집 중인 그룹 보기 버튼',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ActionCard(
                      icon: Icons.search,
                      title: '그룹 탐색',
                      description: '관심있는 그룹을 찾아보세요',
                      onTap: () => ref.read(homeStateProvider.notifier).showGroupExplore(),
                      semanticsLabel: '그룹 탐색 버튼',
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  ActionCard(
                    icon: Icons.people_outline,
                    title: '모집 중인 그룹 보기',
                    description: '지금 모집 중인 그룹을 찾아보세요',
                    onTap: () => ref.read(homeStateProvider.notifier).showGroupExploreWithRecruitingFilter(),
                    semanticsLabel: '모집 중인 그룹 보기 버튼',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ActionCard(
                    icon: Icons.search,
                    title: '그룹 탐색',
                    description: '관심있는 그룹을 찾아보세요',
                    onTap: () => ref.read(homeStateProvider.notifier).showGroupExplore(),
                    semanticsLabel: '그룹 탐색 버튼',
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildRecentGroups(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('최근 활동 그룹', style: AppTheme.headlineSmallTheme(context)),
            Semantics(
              button: true,
              label: '전체 그룹 보기',
              child: TextButton(onPressed: () {}, child: const Text('전체 보기')),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) => GroupCard(
              groupName: '샘플 그룹 ${index + 1}',
              memberCount: 20 + index * 5,
              isActive: true,
              avatarText: '그${index + 1}',
              onTap: () {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('최근 활동', style: AppTheme.headlineSmallTheme(context)),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: List.generate(
                3,
                (index) => _buildActivityItem(context, index),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, int index) {
    return Semantics(
      button: true,
      label: '샘플 그룹 ${index + 1}에서 새 게시글. ${index + 1}시간 전',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Row(
          children: [
            CircleAvatar(
              radius: AppComponents.avatarMedium,
              backgroundColor: AppColors.lightOutline,
              child: Icon(
                Icons.message_outlined,
                color: AppColors.neutral600,
                size: AppComponents.activityIconSize,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '샘플 그룹 ${index + 1}에서 새 게시글',
                    style: AppTheme.bodyMediumTheme(context),
                  ),
                  Text(
                    '${index + 1}시간 전',
                    style: AppTheme.bodySmallTheme(
                      context,
                    ).copyWith(color: AppColors.neutral600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
