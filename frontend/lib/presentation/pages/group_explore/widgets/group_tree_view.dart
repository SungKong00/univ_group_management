import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/group_tree_state_provider.dart';
import 'group_tree_node_widget.dart';
import 'group_tree_filter_chip_bar.dart';

/// GroupTreeView - Hierarchical group browser
///
/// Displays all groups in a nested card structure showing their hierarchical relationships.
class GroupTreeView extends ConsumerStatefulWidget {
  const GroupTreeView({super.key});

  @override
  ConsumerState<GroupTreeView> createState() => _GroupTreeViewState();
}

class _GroupTreeViewState extends ConsumerState<GroupTreeView> {
  @override
  void initState() {
    super.initState();
    // Load hierarchy on first mount
    Future.microtask(() {
      ref.read(groupTreeStateProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rootNodes = ref.watch(treeRootNodesProvider);
    final isLoading = ref.watch(treeIsLoadingProvider);
    final errorMessage = ref.watch(treeErrorMessageProvider);

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () {
                ref.read(groupTreeStateProvider.notifier).loadHierarchy();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (rootNodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 48,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '표시할 그룹이 없습니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.neutral600,
                  ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                '그룹 계층 구조',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.neutral900,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '그룹의 계층 관계를 확인하고 탐색할 수 있습니다',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral600,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Filter Chips
              const GroupTreeFilterChipBar(),
              const SizedBox(height: AppSpacing.md),

              // Tree Structure
              ...rootNodes.map((node) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: GroupTreeNodeWidget(
                    node: node,
                    depth: 0,
                    onToggle: (nodeId) {
                      ref.read(groupTreeStateProvider.notifier).toggleNode(nodeId);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
