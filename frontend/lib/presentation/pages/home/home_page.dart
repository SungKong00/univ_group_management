import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/home_state_provider.dart';
import '../../providers/recruiting_groups_provider.dart';
import '../../widgets/cards/action_card.dart';
import '../../widgets/cards/recruitment_card.dart';
import 'widgets/group_explore_content_widget.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // 홈 페이지 초기화 (상태 복원)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeStateProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentView = ref.watch(currentHomeViewProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: _buildViewForCurrentState(context, currentView),
      ),
    );
  }

  Widget _buildViewForCurrentState(
    BuildContext context,
    HomeView currentView,
  ) {
    switch (currentView) {
      case HomeView.dashboard:
        return _buildDashboardView(context);
      case HomeView.groupExplore:
        return const GroupExploreContentWidget();
    }
  }

  Widget _buildDashboardView(BuildContext context) {
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
            _buildQuickActions(context, isDesktop),
            const SizedBox(height: AppSpacing.lg),
            _buildRecentGroups(context),
            const SizedBox(height: AppSpacing.lg),
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDesktop) {
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
                      icon: Icons.campaign,
                      title: '모집 공고 보기',
                      description: '지금 모집 중인 공고를 확인하세요',
                      onTap: () => ref.read(homeStateProvider.notifier).showGroupExplore(initialTab: 2),
                      semanticsLabel: '모집 공고 보기 버튼',
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
                    icon: Icons.campaign,
                    title: '모집 공고 보기',
                    description: '지금 모집 중인 공고를 확인하세요',
                    onTap: () => ref.read(homeStateProvider.notifier).showGroupExplore(initialTab: 2),
                    semanticsLabel: '모집 공고 보기 버튼',
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
    final recruitingGroupsState = ref.watch(recruitingGroupsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('모집 중인 그룹', style: AppTheme.headlineSmallTheme(context)),
            Semantics(
              button: true,
              label: '전체 그룹 보기',
              child: TextButton(
                onPressed: () => ref
                    .read(homeStateProvider.notifier)
                    .showGroupExploreWithRecruitingFilter(),
                child: const Text('전체 보기'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 120,
          child: _buildRecruitingGroupsList(recruitingGroupsState),
        ),
      ],
    );
  }

  Widget _buildRecruitingGroupsList(RecruitingGroupsState state) {
    // Loading state
    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.brand,
        ),
      );
    }

    // Error state
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              state.error!,
              style: AppTheme.bodySmallTheme(context).copyWith(
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () {
                ref.read(recruitingGroupsProvider.notifier).refresh();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (state.recruitments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: AppColors.neutral600,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '현재 모집 중인 그룹이 없습니다',
              style: AppTheme.bodySmallTheme(context).copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
      );
    }

    // Success state - display recruiting groups
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: state.recruitments.length,
      itemBuilder: (context, index) {
        final recruitment = state.recruitments[index];

        // Generate avatar text from group name (first 2 characters)
        final avatarText = recruitment.groupName.length >= 2
            ? recruitment.groupName.substring(0, 2)
            : recruitment.groupName;

        return RecruitmentCard(
          groupName: recruitment.groupName,
          recruitmentTitle: recruitment.title,
          applicantCount: recruitment.currentApplicantCount,
          endDate: recruitment.recruitmentEndDate,
          showApplicantCount: recruitment.showApplicantCount,
          avatarText: avatarText,
          onTap: () {
            context.go('/recruitment/${recruitment.id}');
          },
        );
      },
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
