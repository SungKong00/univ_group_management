import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/unified_group_provider.dart';
import '../providers/unified_group_selectors.dart';
import 'group_explore_card.dart';

/// Group Explore List
///
/// Displays a scrollable list/grid of groups using the unified group provider.
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
    final usePagination = ref.read(usePaginationProvider);

    // 전체 로드 모드면 무한 스크롤 비활성화
    if (!usePagination) return;

    if (_isNearBottom()) {
      ref.read(unifiedGroupProvider.notifier).loadMore();
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(listViewGroupsProvider);
    final isLoading = ref.watch(groupLoadingProvider);
    final isLoadingMore = ref.watch(isLoadingMoreProvider);

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
              style: AppTheme.headlineSmallTheme(
                context,
              ).copyWith(color: AppColors.neutral900),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '다른 검색어나 필터를 시도해보세요',
              style: AppTheme.bodyMediumTheme(
                context,
              ).copyWith(color: AppColors.neutral600),
            ),
          ],
        ),
      );
    }

    // Initial loading state
    if (groups.isEmpty && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildGroupGrid(groups, isLoadingMore);
  }

  Widget _buildGroupGrid(List<dynamic> groups, bool isLoadingMore) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final int crossAxisCount = (screenWidth / 350).floor().clamp(1, 4);
        final double cardWidth =
            (screenWidth - (crossAxisCount - 1) * AppSpacing.sm) /
            crossAxisCount;

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
              if (isLoadingMore)
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
