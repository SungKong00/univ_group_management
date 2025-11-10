import 'package:flutter/material.dart';

import '../../../../../../core/models/calendar/group_event.dart';
import '../../../../../../core/theme/app_colors.dart';

/// Compact event card widget for calendar month view cells
///
/// Features:
/// - 24px height compact design
/// - "HH:mm | Title" format
/// - Official/Unofficial color coding (purple/gray)
/// - Text overflow handling with ellipsis
/// - Tap gesture support
class EventCard extends StatelessWidget {
  final GroupEvent event;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: event.isOfficial
              ? AppColors.brandLight.withValues(alpha: 0.3)
              : AppColors.neutral200,
          borderRadius: BorderRadius.circular(4),
          border: Border(
            left: BorderSide(
              color: event.isOfficial ? AppColors.brand : AppColors.neutral600,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            // Time
            Text(
              _formatTime(event.startDate, event.isAllDay),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: event.isOfficial
                    ? AppColors.brand
                    : AppColors.neutral700,
              ),
            ),
            const SizedBox(width: 4),
            // Divider
            Text(
              '|',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: AppColors.neutral500,
              ),
            ),
            const SizedBox(width: 4),
            // Title
            Expanded(
              child: Text(
                event.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime, bool isAllDay) {
    if (isAllDay) {
      return '종일';
    }
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
