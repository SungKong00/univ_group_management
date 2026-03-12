import 'package:flutter/material.dart';

import '../../../../core/models/calendar_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';

enum ScheduleDetailAction { edit, delete }

Future<ScheduleDetailAction?> showScheduleDetailSheet(
  BuildContext context, {
  required PersonalSchedule schedule,
}) {
  return showModalBottomSheet<ScheduleDetailAction>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.dialog),
      ),
    ),
    builder: (context) => ScheduleDetailSheet(schedule: schedule),
  );
}

class ScheduleDetailSheet extends StatelessWidget {
  const ScheduleDetailSheet({super.key, required this.schedule});

  final PersonalSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                  color: schedule.color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(schedule.title, style: textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      '${schedule.dayOfWeek.longLabel} · ${schedule.formattedTimeRange}',
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
          if (schedule.location != null && schedule.location!.trim().isNotEmpty)
            _InfoRow(
              icon: Icons.place_outlined,
              label: '장소',
              value: schedule.location!,
            ),
          _InfoRow(
            icon: Icons.palette_outlined,
            label: '색상',
            value: schedule.colorHex,
            trailing: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: schedule.color,
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
                      Navigator.of(context).pop(ScheduleDetailAction.edit),
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
                      Navigator.of(context).pop(ScheduleDetailAction.delete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
