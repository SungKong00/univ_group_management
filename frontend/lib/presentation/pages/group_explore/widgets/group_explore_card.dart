import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/group_models.dart';
import '../../../providers/workspace_state_provider.dart';

/// Group Explore Card
///
/// Displays a single group's summary information with a clickable card.
class GroupExploreCard extends ConsumerWidget {
  const GroupExploreCard({
    super.key,
    required this.group,
  });

  final GroupSummaryResponse group;

  void _navigateToGroup(BuildContext context, WidgetRef ref) {
    // Navigate to group workspace
    ref
        .read(workspaceStateProvider.notifier)
        .enterWorkspace(group.id.toString());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Build breadcrumb (university > college > department)
    final breadcrumbs = <String>[];
    if (group.university != null) breadcrumbs.add(group.university!);
    if (group.college != null) breadcrumbs.add(group.college!);
    if (group.department != null) breadcrumbs.add(group.department!);
    final breadcrumbText = breadcrumbs.join(' > ');

    return Semantics(
      button: true,
      label: '${group.name} 그룹 카드. ${group.isRecruiting ? "모집중" : "모집안함"}. ${group.memberCount}명.',
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: AppColors.outline, width: 1),
        ),
        child: InkWell(
          onTap: () => _navigateToGroup(context, ref),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group name + Recruiting badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: AppTheme.titleLargeTheme(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (group.isRecruiting) ...[
                      const SizedBox(width: AppSpacing.xxs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxs,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandLight,
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                        child: Text(
                          '모집중',
                          style: AppTheme.labelSmallTheme(context).copyWith(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (breadcrumbText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    breadcrumbText,
                    style: AppTheme.bodySmallTheme(context).copyWith(
                      color: AppColors.neutral600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (group.description != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    group.description!,
                    style: AppTheme.bodyMediumTheme(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                // Tags + Member count
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: group.tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xxs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neutral100,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.button),
                              border: Border.all(
                                color: AppColors.neutral300,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tag,
                              style:
                                  AppTheme.labelSmallTheme(context).copyWith(
                                color: AppColors.neutral700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: AppColors.neutral600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${group.memberCount}명',
                      style: AppTheme.bodySmallTheme(context).copyWith(
                        color: AppColors.neutral700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
