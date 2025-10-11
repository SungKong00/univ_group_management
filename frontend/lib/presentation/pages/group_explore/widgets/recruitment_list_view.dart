import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/recruitment_explore_state_provider.dart';
import 'recruitment_search_bar.dart';
import 'recruitment_card.dart';

/// Recruitment List View
///
/// Displays a list of recruitment announcements with infinite scroll pagination
class RecruitmentListView extends ConsumerStatefulWidget {
  const RecruitmentListView({super.key});

  @override
  ConsumerState<RecruitmentListView> createState() =>
      _RecruitmentListViewState();
}

class _RecruitmentListViewState extends ConsumerState<RecruitmentListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initialize: load recruitments on first access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recruitmentExploreStateProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when user scrolls near the bottom (200px threshold)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(recruitmentExploreStateProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final recruitments = ref.watch(exploreRecruitmentsProvider);
    final isLoading = ref.watch(exploreRecruitmentIsLoadingProvider);
    final hasMore = ref.watch(exploreRecruitmentHasMoreProvider);
    final errorMessage = ref.watch(exploreRecruitmentErrorMessageProvider);
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          const RecruitmentSearchBar(),
          const SizedBox(height: AppSpacing.sm),

          // Error Banner (if any)
          if (errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: AppTheme.bodyMediumTheme(context).copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Recruitment List
          _buildRecruitmentList(
            context,
            recruitments,
            isLoading,
            hasMore,
            isDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildRecruitmentList(
    BuildContext context,
    List recruitments,
    bool isLoading,
    bool hasMore,
    bool isDesktop,
  ) {
    // Empty state
    if (recruitments.isEmpty && !isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.campaign_outlined,
                size: 64,
                color: AppColors.neutral400,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '모집 공고가 없습니다',
                style: AppTheme.titleMediumTheme(context).copyWith(
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '다른 검색어를 시도해보세요',
                style: AppTheme.bodyMediumTheme(context).copyWith(
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Initial loading state
    if (recruitments.isEmpty && isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Desktop: 2-column grid, Mobile: 1-column list
    final crossAxisCount = isDesktop ? 2 : 1;
    final childAspectRatio = isDesktop ? 1.5 : 1.8;

    return SizedBox(
      height: MediaQuery.of(context).size.height - 300,
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
        ),
        itemCount: recruitments.length + (hasMore && isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at the end
          if (index == recruitments.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.action,
                ),
              ),
            );
          }

          final recruitment = recruitments[index];
          return RecruitmentCard(recruitment: recruitment);
        },
      ),
    );
  }
}
