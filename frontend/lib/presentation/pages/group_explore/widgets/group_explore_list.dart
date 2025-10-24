import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/group_explore_state_provider.dart';
import 'group_explore_card.dart';

/// Group Explore List
///
/// Displays a scrollable list/grid of groups with infinite scroll pagination.
class GroupExploreList extends ConsumerStatefulWidget {
  const GroupExploreList({super.key});

  @override
  ConsumerState<GroupExploreList> createState() => _GroupExploreListState();
}

class _GroupExploreListState extends ConsumerState<GroupExploreList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
      ref.read(groupExploreStateProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(exploreGroupsProvider);
    final isLoading = ref.watch(exploreIsLoadingProvider);
    final hasMore = ref.watch(exploreHasMoreProvider);

    // Empty state
    if (groups.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.neutral400),
            const SizedBox(height: AppSpacing.md),
            Text(
              '검색 결과가 없습니다',
              style: AppTheme.headlineSmallTheme(context).copyWith(
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '다른 검색어나 필터를 시도해보세요',
              style: AppTheme.bodyMediumTheme(context).copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
      );
    }

    // Initial loading state
    if (groups.isEmpty && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildGroupGrid(groups, isLoading, hasMore);
  }

  Widget _buildGroupGrid(List<dynamic> groups, bool isLoading, bool hasMore) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final int crossAxisCount = (screenWidth / 350).floor().clamp(1, 4);
        final double cardWidth = (screenWidth - (crossAxisCount - 1) * AppSpacing.sm) / crossAxisCount;

        return SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ...groups.map((group) {
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 300,
                    maxWidth: cardWidth,
                  ),
                  child: GroupExploreCard(group: group),
                );
              }),
              if (hasMore && isLoading)
                SizedBox(
                  width: screenWidth,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.action,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
