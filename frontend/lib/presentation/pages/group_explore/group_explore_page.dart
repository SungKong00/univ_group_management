import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import 'providers/group_explore_state_provider.dart';
import 'widgets/group_search_bar.dart';
import 'widgets/group_filter_chip_bar.dart';
import 'widgets/group_explore_list.dart';

/// Group Explore Page
///
/// Allows users to search and filter groups with infinite scroll pagination.
class GroupExplorePage extends ConsumerStatefulWidget {
  const GroupExplorePage({super.key});

  @override
  ConsumerState<GroupExplorePage> createState() => _GroupExplorePageState();
}

class _GroupExplorePageState extends ConsumerState<GroupExplorePage> {
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

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('그룹 탐색'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleTextStyle: AppTheme.titleLargeTheme(context),
        iconTheme: IconThemeData(color: AppColors.onSurface),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? AppSpacing.lg : AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Column(
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
              const Expanded(child: GroupExploreList()),
            ],
          ),
        ),
      ),
    );
  }
}
