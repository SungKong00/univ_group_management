import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/recruitment_explore_state_provider.dart';
import 'recruitment_card.dart';
import 'recruitment_detail_view.dart';

/// Recruitment List View
///
/// Displays a list of recruitment announcements with infinite scroll pagination
/// or shows detail view when a recruitment is selected
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
    final selectedId = ref.watch(selectedRecruitmentIdProvider);

    // Show detail view if a recruitment is selected
    if (selectedId != null) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: RecruitmentDetailView(
          key: ValueKey('detail-$selectedId'),
          recruitmentId: selectedId,
          onBack: () {
            ref.read(selectedRecruitmentIdProvider.notifier).state = null;
          },
        ),
      );
    }

    // Show list view
    final recruitments = ref.watch(exploreRecruitmentsProvider);
    final isLoading = ref.watch(exploreRecruitmentIsLoadingProvider);
    final hasMore = ref.watch(exploreRecruitmentHasMoreProvider);
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return _buildRecruitmentList(
      context,
      recruitments,
      isLoading,
      hasMore,
      isDesktop,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final int crossAxisCount = (screenWidth / 350).floor().clamp(1, 4);
        final double cardWidth = (screenWidth - (crossAxisCount - 1) * AppSpacing.sm) / crossAxisCount;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ...recruitments.map((recruitment) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 300,
                  maxWidth: cardWidth,
                ),
                child: RecruitmentCard(recruitment: recruitment),
              );
            }).toList(),
            if (hasMore && isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.action,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
