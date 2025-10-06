import 'package:flutter/material.dart';
import '../../../core/models/channel_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import 'unread_badge.dart';

/// Channel Item Widget
///
/// Displays a single channel item with icon, name, and optional unread badge.
/// Shows selection state with background color change.
class ChannelItem extends StatelessWidget {
  final Channel channel;
  final bool isSelected;
  final int unreadCount; // Dummy data for now
  final VoidCallback onTap;

  const ChannelItem({
    super.key,
    required this.channel,
    required this.isSelected,
    required this.unreadCount,
    required this.onTap,
  });

  IconData _getChannelIcon() {
    switch (channel.type) {
      case 'ANNOUNCEMENT':
        return Icons.campaign_outlined;
      case 'TEXT':
      default:
        return Icons.tag;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.actionTonalBg : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                _getChannelIcon(),
                size: 20,
                color: isSelected ? AppColors.action : AppColors.neutral600,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  channel.name,
                  style: AppTheme.bodyMedium.copyWith(
                    color: isSelected ? AppColors.action : AppColors.lightOnSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: AppSpacing.xxs),
                UnreadBadge(count: unreadCount),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
