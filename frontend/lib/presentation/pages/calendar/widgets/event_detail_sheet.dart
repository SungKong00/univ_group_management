import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/calendar_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';

enum EventDetailAction { edit, delete }

Future<EventDetailAction?> showEventDetailSheet(
  BuildContext context, {
  required PersonalEvent event,
}) {
  return showModalBottomSheet<EventDetailAction>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.dialog),
      ),
    ),
    builder: (context) => _EventDetailSheet(event: event),
  );
}

class _EventDetailSheet extends StatelessWidget {
  const _EventDetailSheet({required this.event});

  final PersonalEvent event;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dateFormatter = DateFormat('yyyy.MM.dd (E)', 'ko_KR');
    final timeFormatter = DateFormat('HH:mm');

    String timeLabel;
    if (event.isAllDay) {
      timeLabel = '종일';
    } else {
      timeLabel =
          '${timeFormatter.format(event.startDateTime)} ~ ${timeFormatter.format(event.endDateTime)}';
    }

    final dateLabel = _buildDateLabel(
      dateFormatter,
      event.startDateTime,
      event.endDateTime,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 48,
                decoration: BoxDecoration(
                  color: event.color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (event.location != null && event.location!.trim().isNotEmpty)
            _InfoRow(
              icon: Icons.place_outlined,
              label: '장소',
              value: event.location!,
            ),
          if (event.description != null && event.description!.trim().isNotEmpty)
            _InfoRow(
              icon: Icons.notes_outlined,
              label: '메모',
              value: event.description!,
            ),
          _InfoRow(
            icon: Icons.palette_outlined,
            label: '색상',
            value: event.color.toString(),
            trailing: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: event.color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.lightOutline),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('수정'),
                  onPressed: () =>
                      Navigator.of(context).pop(EventDetailAction.edit),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('삭제'),
                  onPressed: () =>
                      Navigator.of(context).pop(EventDetailAction.delete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildDateLabel(DateFormat formatter, DateTime start, DateTime end) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    if (normalizedStart == normalizedEnd) {
      return formatter.format(start);
    }
    return '${formatter.format(start)} ~ ${formatter.format(end)}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.neutral500),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
