import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
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
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    // Empty state
    if (groups.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '검색 결과가 없습니다',
              style: AppTheme.titleMediumTheme(context).copyWith(
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '다른 검색어나 필터를 시도해보세요',
              style: AppTheme.bodyMediumTheme(context).copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
      );
    }

    // Initial loading state
    if (groups.isEmpty && isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Desktop: 2-column grid, Mobile: 1-column list
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isDesktop ? 2 : 1;
        final childAspectRatio = isDesktop ? 1.8 : 2.5;

        return GridView.builder(
          controller: _scrollController,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemCount: groups.length + (hasMore && isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            // Loading indicator at the end
            if (index == groups.length) {
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

            final group = groups[index];
            return GroupExploreCard(group: group);
          },
        );
      },
    );
  }
}
