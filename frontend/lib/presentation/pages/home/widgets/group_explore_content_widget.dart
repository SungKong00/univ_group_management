import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../group_explore/providers/group_explore_state_provider.dart';
import '../../group_explore/widgets/group_search_bar.dart';
import '../../group_explore/widgets/group_filter_chip_bar.dart';
import '../../group_explore/widgets/group_explore_list.dart';

/// Group Explore Content Widget
///
/// Displays group exploration interface (search, filters, list) without AppBar.
/// Used within HomePage as a view state.
class GroupExploreContentWidget extends ConsumerStatefulWidget {
  const GroupExploreContentWidget({super.key});

  @override
  ConsumerState<GroupExploreContentWidget> createState() =>
      _GroupExploreContentWidgetState();
}

class _GroupExploreContentWidgetState
    extends ConsumerState<GroupExploreContentWidget> {
  @override
  void initState() {
    super.initState();
    // Initialize state: load first page of groups
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupExploreStateProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final errorMessage = ref.watch(exploreErrorMessageProvider);

    return SingleChildScrollView(
      // Use SingleChildScrollView for consistent behavior with HomePage
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? AppSpacing.lg : AppSpacing.md,
          vertical: isDesktop ? AppSpacing.offsetMax : AppSpacing.offsetMin,
        ),
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

            // Group List (with infinite scroll)
            // Note: Wrapped in SizedBox with fixed height for scrolling within SingleChildScrollView
            SizedBox(
              height: MediaQuery.of(context).size.height - 300,
              child: const GroupExploreList(),
            ),
          ],
        ),
      ),
    );
  }
}
