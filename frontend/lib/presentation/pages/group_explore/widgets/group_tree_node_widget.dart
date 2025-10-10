import 'package:flutter/material.dart';
import '../../../../core/models/group_tree_node.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';

/// GroupTreeNodeWidget - Recursive card-based tree view
///
/// Displays hierarchical group structure with nested cards.
/// Supports up to 8 levels of depth with specific styling per level.
///
/// Design Specifications:
/// - Depth 0: padding 16px, white background, neutral400 border, elevation 1
/// - Depth 1-8: padding 12px, alternating backgrounds, varying borders/elevations
/// - Background: even depths → neutral100, odd depths → white
/// - Border: depths 2,4,6,8 → neutral400, others → neutral300
/// - Elevation: depth 0→1, depth 1→2, depth 2-8→[1,0,1,0,1,0,1]
/// - Animation: 120ms expand/collapse transition
class GroupTreeNodeWidget extends StatelessWidget {
  final GroupTreeNode node;
  final int depth;
  final Function(int nodeId) onToggle;

  const GroupTreeNodeWidget({
    super.key,
    required this.node,
    this.depth = 0,
    required this.onToggle,
  }) : assert(depth >= 0 && depth <= 8, 'Depth must be between 0 and 8');

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: _getElevation(),
      color: _getBackgroundColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(_getPadding()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            if (node.isExpanded && node.hasChildren) ...[
              const SizedBox(height: 8),
              ..._buildChildren(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return InkWell(
      onTap: node.hasChildren ? () => onToggle(node.id) : null,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        child: Row(
          children: [
            // Expand/Collapse Icon
            if (node.hasChildren)
              Icon(
                node.isExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                size: 20,
                color: AppColors.neutral700,
              )
            else
              const SizedBox(width: 20),
            const SizedBox(width: 8),

            // Group Icon/Avatar
            if (node.profileImageUrl != null)
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(node.profileImageUrl!),
              )
            else
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.brandLight.withValues(alpha: 0.2),
                child: Icon(
                  Icons.group,
                  size: 16,
                  color: AppColors.brand,
                ),
              ),
            const SizedBox(width: 12),

            // Group Name and Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutral900,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 14,
                        color: AppColors.neutral600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${node.memberCount}명',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.neutral600,
                            ),
                      ),
                      if (node.isRecruiting) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '모집중',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.success,
                                      fontSize: 10,
                                    ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Depth Indicator (for debugging - can be removed)
            if (depth > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'L$depth',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.neutral600,
                        fontSize: 9,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChildren() {
    return node.children.map((child) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: GroupTreeNodeWidget(
          node: child,
          depth: depth + 1,
          onToggle: onToggle,
        ),
      );
    }).toList();
  }

  // Styling helpers based on depth
  double _getPadding() {
    if (depth == 0) return 16.0;
    return 12.0;
  }

  Color _getBackgroundColor() {
    // Even depths: neutral100, Odd depths: white
    if (depth % 2 == 0) {
      return AppColors.neutral100;
    }
    return Colors.white;
  }

  Color _getBorderColor() {
    // Depths 2, 4, 6, 8: neutral400
    // Others: neutral300
    if (depth == 2 || depth == 4 || depth == 6 || depth == 8) {
      return AppColors.neutral400;
    }
    return AppColors.neutral300;
  }

  double _getElevation() {
    if (depth == 0) return 1.0;
    if (depth == 1) return 2.0;

    // Depth 2-8: [1, 0, 1, 0, 1, 0, 1]
    // depth 2→1, 3→0, 4→1, 5→0, 6→1, 7→0, 8→1
    final pattern = [1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0];
    final index = depth - 2;
    if (index >= 0 && index < pattern.length) {
      return pattern[index];
    }
    return 0.0;
  }
}
