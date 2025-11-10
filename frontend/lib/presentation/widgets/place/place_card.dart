import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/place/place.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/group_permission_provider.dart';

class PlaceCard extends ConsumerWidget {
  final Place place;
  final int groupId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onManageAvailability; // 운영시간 설정 모달 호출

  const PlaceCard({
    required this.place,
    required this.groupId,
    this.onEdit,
    this.onDelete,
    this.onManageAvailability,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsAsync = ref.watch(groupPermissionsProvider(groupId));

    final hasCalendarManage = permissionsAsync.when(
      data: (perms) => perms.contains('CALENDAR_MANAGE'),
      loading: () => false,
      error: (_, __) => false,
    );

    final isManagingGroup = place.managingGroupId == groupId;
    final canManage = hasCalendarManage && isManagingGroup;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs / 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.neutral300, width: 1),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs / 2,
        ),
        title: Text(
          place.displayName,
          style: AppTheme.titleLarge.copyWith(
            color: AppColors.neutral900,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              place.fullLocation,
              style: AppTheme.bodyMedium.copyWith(color: AppColors.neutral700),
            ),
            if (place.capacity != null) ...[
              SizedBox(height: 2),
              Text(
                '수용 인원: ${place.capacity}명',
                style: AppTheme.bodySmall.copyWith(color: AppColors.neutral600),
              ),
            ],
            if (!isManagingGroup) ...[
              SizedBox(height: 2),
              Text(
                '다른 그룹이 관리하는 장소입니다',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.neutral500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: canManage
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Availability settings button
                  IconButton(
                    icon: Icon(
                      Icons.schedule,
                      color: AppColors.action,
                      size: 20,
                    ),
                    onPressed: onManageAvailability,
                    tooltip: '운영시간 설정',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),

                  // Edit button
                  IconButton(
                    icon: Icon(Icons.edit, color: AppColors.action, size: 20),
                    onPressed: onEdit,
                    tooltip: '수정',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),

                  // Delete button
                  IconButton(
                    icon: Icon(Icons.delete, color: AppColors.error, size: 20),
                    onPressed: onDelete,
                    tooltip: '삭제',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
