import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/common/app_empty_state.dart';
import '../providers/recruitment_explore_state_provider.dart';
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

    return _buildRecruitmentList(context, recruitments, isLoading, hasMore);
  }

  Widget _buildRecruitmentList(
    BuildContext context,
    List recruitments,
    bool isLoading,
    bool hasMore,
  ) {
    // Empty state
    if (recruitments.isEmpty && !isLoading) {
      return AppEmptyState.noRecruitments();
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
        final double cardWidth =
            (screenWidth - (crossAxisCount - 1) * AppSpacing.sm) /
            crossAxisCount;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ...recruitments.map((recruitment) {
              return ConstrainedBox(
                constraints: BoxConstraints(minWidth: 300, maxWidth: cardWidth),
                child: RecruitmentCard(recruitment: recruitment),
              );
            }),
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
