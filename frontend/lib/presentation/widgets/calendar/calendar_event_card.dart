import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';

/// Reusable calendar event card component for all calendar types.
///
/// This component provides a consistent design across:
/// - Personal Calendar (PersonalEvent)
/// - Group Calendar (GroupEvent)
/// - Place Calendar (PlaceReservation)
///
/// Features:
/// - Color bar on the left (6px width, configurable height)
/// - Title, time, location, and optional reserved-by info
/// - Two display modes:
///   1. Text-only mode (Personal/Group): Simple text labels
///   2. Icon mode (Place): Icons with labels for better visual hierarchy
/// - Responsive layout: Reserved-by info appears inline with time (saves vertical space)
/// - Overflow handling: Flexible text wrapping with ellipsis
///
/// Design tokens:
/// - Spacing: AppSpacing.xs (12px), AppSpacing.sm (16px)
/// - Colors: AppColors.neutral600 (secondary text), AppColors.lightOutline (border)
/// - Radius: 16px (card), 3px (color bar)
/// - Typography: titleMedium (title), bodySmall (info)
class CalendarEventCard extends StatelessWidget {
  /// Event title (required)
  final String title;

  /// Color for the left bar indicator (required)
  final Color color;

  /// Time label (e.g., "HH:mm ~ HH:mm" or "종일")
  final String timeLabel;

  /// Location information (optional)
  final String? location;

  /// Reserved by user name (optional, Place Calendar only)
  final String? reservedBy;

  /// Show icons before labels (default: false)
  /// - false: Text-only mode (Personal/Group Calendar)
  /// - true: Icon mode (Place Calendar)
  final bool showIcons;

  /// Tap callback
  final VoidCallback? onTap;

  /// Color bar height (default: 48px)
  /// Place Calendar uses 60px for better visual balance
  final double colorBarHeight;

  const CalendarEventCard({
    super.key,
    required this.title,
    required this.color,
    required this.timeLabel,
    this.location,
    this.reservedBy,
    this.showIcons = false,
    this.onTap,
    this.colorBarHeight = 48,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final cardContent = Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightOutline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color bar indicator
          Container(
            width: 6,
            height: colorBarHeight,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Event information
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Location (Place Calendar only, before time)
                if (showIcons && location != null) ...[
                  _buildInfoRow(context, Icons.place, location!),
                  const SizedBox(height: 2),
                ],
                // Time + Reserved By (inline for space efficiency)
                if (showIcons)
                  _buildTimeWithReservedBy(context)
                else
                  Text(
                    timeLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                // Location (Personal/Group Calendar, after time)
                if (!showIcons && location != null && location!.isNotEmpty)
                  Text(
                    location!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    // Wrap with InkWell if onTap is provided
    if (onTap != null) {
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  /// Build info row with icon and text (Place Calendar mode)
  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.neutral600),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.neutral600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build time row with optional reserved-by info inline
  /// Layout: [⏰ time] [spacer] [👤 reserved-by]
  /// This saves vertical space compared to stacking them
  Widget _buildTimeWithReservedBy(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textStyle = textTheme.bodySmall?.copyWith(
      color: AppColors.neutral600,
    );

    return Row(
      children: [
        // Time icon + label
        Icon(Icons.schedule, size: 14, color: AppColors.neutral600),
        const SizedBox(width: 4),
        Text(timeLabel, style: textStyle),
        // Reserved-by info (optional)
        if (reservedBy != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.person, size: 14, color: AppColors.neutral600),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              reservedBy!,
              style: textStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
