import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/home_state_provider.dart';
import '../../../widgets/common/compact_tab_bar.dart';
import '../../../../core/providers/unified_group_provider.dart';
import '../../../../presentation/pages/group_explore/providers/unified_group_selectors.dart';
import '../../group_explore/widgets/group_search_bar.dart';
import '../../group_explore/widgets/group_filter_chip_bar.dart';
import '../../group_explore/widgets/group_explore_list.dart';
import '../../group_explore/widgets/group_tree_view.dart';
import '../../group_explore/widgets/recruitment_list_view.dart';
import '../../group_explore/widgets/recruitment_search_bar.dart';

/// Group Explore Content Widget
///
/// Displays group exploration interface with three tabs:
/// - List View: Search, filters, and flat list of groups
/// - Tree View: Hierarchical tree structure of groups
/// - Recruitment View: List of group recruitment announcements
class GroupExploreContentWidget extends ConsumerStatefulWidget {
  const GroupExploreContentWidget({super.key});

  @override
  ConsumerState<GroupExploreContentWidget> createState() =>
      _GroupExploreContentWidgetState();
}

class _GroupExploreContentWidgetState
    extends ConsumerState<GroupExploreContentWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();

    final initialTab = ref.read(homeStateProvider).groupExploreInitialTab;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialTab, // 초기 탭 설정
    );

    // 탭 변경 감지 리스너 추가
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return; // 애니메이션 중복 방지

      // HomeStateNotifier에 탭 변경 알림
      ref.read(homeStateProvider.notifier).setGroupExploreTab(_tabController.index);
    });

    // Initialize state: load first page of groups
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(unifiedGroupProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final errorMessage = ref.watch(groupErrorProvider);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.lg : AppSpacing.md,
        vertical: isDesktop ? AppSpacing.md : AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CompactTabBar로 교체
          CompactTabBar(
            controller: _tabController,
            tabs: const [
              CompactTab(icon: Icons.view_list, label: '리스트'),
              CompactTab(icon: Icons.account_tree, label: '계층 구조'),
              CompactTab(icon: Icons.campaign, label: '모집 공고'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // List View
                _buildListView(context, isDesktop, errorMessage),

                // Tree View
                const GroupTreeView(),

                // Recruitment View
                _buildRecruitmentView(context, isDesktop, errorMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecruitmentView(BuildContext context, bool isDesktop, String? errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        RecruitmentSearchBar(),
        const SizedBox(height: AppSpacing.sm),

        // Error Banner (if any)
        if (errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
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
        const Expanded(
          child: RecruitmentListView(),
        ),
      ],
    );
  }

  Widget _buildListView(BuildContext context, bool isDesktop, String? errorMessage) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          const GroupSearchBar(),
          const SizedBox(height: AppSpacing.sm),

          // Filter Chips
          const GroupFilterChipBar(),
          const SizedBox(height: AppSpacing.sm),

          // Error Banner (if any)
          if (errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
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

          // Group List (with infinite scroll)
          SizedBox(
            height: MediaQuery.of(context).size.height - 350,
            child: const GroupExploreList(),
          ),
        ],
      ),
    );
  }
}
