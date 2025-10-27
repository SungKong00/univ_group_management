import 'package:flutter/material.dart';
import '../../../../../core/utils/snack_bar_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/place/place.dart';
import '../../../../../core/models/place/place_usage_group.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../providers/place_provider.dart';

/// Tab for managing place usage permissions
///
/// Shows pending requests and approved groups for places managed by this group.
/// Allows approving/rejecting requests and revoking permissions.
class PlaceUsageManagementTab extends ConsumerWidget {
  final int groupId;

  const PlaceUsageManagementTab({
    required this.groupId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placesAsync = ref.watch(placesProvider(groupId));

    return placesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              '오류가 발생했습니다',
              style: AppTheme.titleLarge.copyWith(
                color: AppColors.neutral900,
              ),
            ),
            SizedBox(height: AppSpacing.xxs),
            Text(
              e.toString(),
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (places) {
        final managedPlaces = places
            .where((p) => p.managingGroupId == groupId)
            .toList();

        if (managedPlaces.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  size: 64,
                  color: AppColors.neutral400,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  '관리하는 장소가 없습니다',
                  style: AppTheme.titleLarge.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  '장소를 추가하면 예약 권한을 관리할 수 있습니다',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(AppSpacing.sm),
          itemCount: managedPlaces.length,
          itemBuilder: (context, index) {
            return _buildPlaceSection(context, ref, managedPlaces[index]);
          },
        );
      },
    );
  }

  Widget _buildPlaceSection(BuildContext context, WidgetRef ref, Place place) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: AppColors.neutral300,
          width: 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        childrenPadding: EdgeInsets.only(
          bottom: AppSpacing.xxs,
        ),
        title: Text(
          place.displayName,
          style: AppTheme.headlineSmall.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        subtitle: Text(
          '${place.building} ${place.roomNumber}',
          style: AppTheme.bodySmall.copyWith(
            color: AppColors.neutral600,
          ),
        ),
        children: [
          _PendingRequestsList(placeId: place.id, groupId: groupId),
          Divider(
            color: AppColors.neutral300,
            thickness: 1,
            indent: AppSpacing.sm,
            endIndent: AppSpacing.sm,
          ),
          _ApprovedGroupsList(placeId: place.id, groupId: groupId),
        ],
      ),
    );
  }
}

/// Displays pending usage requests for a place
class _PendingRequestsList extends ConsumerWidget {
  final int placeId;
  final int groupId;

  const _PendingRequestsList({
    required this.placeId,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingUsageRequestsProvider(placeId));

    return pendingAsync.when(
      loading: () => Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.brand),
          ),
        ),
      ),
      error: (e, _) => ListTile(
        leading: Icon(Icons.error, color: AppColors.error),
        title: Text(
          '오류: $e',
          style: AppTheme.bodySmall.copyWith(
            color: AppColors.error,
          ),
        ),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return ListTile(
            leading: Icon(Icons.check_circle, color: AppColors.success),
            title: Text(
              '대기 중인 신청이 없습니다',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral700,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                '대기 중인 신청 (${requests.length})',
                style: AppTheme.titleMedium.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...requests.map((request) => _RequestCard(
                  placeId: placeId,
                  request: request,
                )),
          ],
        );
      },
    );
  }
}

/// Card showing a single usage request
class _RequestCard extends ConsumerWidget {
  final int placeId;
  final PlaceUsageGroup request;

  const _RequestCard({
    required this.placeId,
    required this.request,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      elevation: 0,
      color: AppColors.neutral100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: AppColors.neutral300,
          width: 1,
        ),
      ),
      child: ListTile(
        title: Text(
          request.groupName,
          style: AppTheme.titleMedium.copyWith(
            color: AppColors.neutral900,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '신청 일시: ${_formatDateTime(request.createdAt)}',
          style: AppTheme.bodySmall.copyWith(
            color: AppColors.neutral600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.check, color: AppColors.success),
              onPressed: () => _showApproveDialog(context, ref, placeId, request),
              tooltip: '승인',
            ),
            IconButton(
              icon: Icon(Icons.close, color: AppColors.error),
              onPressed: () => _showRejectDialog(context, ref, placeId, request),
              tooltip: '거절',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showApproveDialog(
    BuildContext context,
    WidgetRef ref,
    int placeId,
    PlaceUsageGroup request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '승인 확인',
          style: AppTheme.titleLarge.copyWith(
            color: AppColors.neutral900,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '${request.groupName}의 예약 권한을 승인하시겠습니까?',
          style: AppTheme.bodyMedium.copyWith(
            color: AppColors.neutral700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: AppTheme.titleLarge.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Text(
              '승인',
              style: AppTheme.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(placeServiceProvider).updateUsageStatus(
              placeId: placeId,
              groupId: request.groupId,
              status: UsageStatus.approved,
            );

        ref.invalidate(pendingUsageRequestsProvider(placeId));
        ref.invalidate(approvedUsageGroupsProvider(placeId));

        if (context.mounted) {
          AppSnackBar.success(context, '승인되었습니다');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '승인 실패: ${e.toString().replaceFirst('Exception: ', '')}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    int placeId,
    PlaceUsageGroup request,
  ) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '거절 확인',
          style: AppTheme.titleLarge.copyWith(
            color: AppColors.neutral900,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${request.groupName}의 예약 권한을 거절하시겠습니까?',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.neutral700,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: '거절 사유 (선택)',
                  labelStyle: AppTheme.bodyMedium.copyWith(
                    color: AppColors.neutral700,
                  ),
                  hintText: '예: 현재 장소 사용이 제한됩니다',
                  hintStyle: AppTheme.bodySmall.copyWith(
                    color: AppColors.neutral500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(color: AppColors.neutral300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(color: AppColors.neutral300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(color: AppColors.brand, width: 2),
                  ),
                  counterText: '${reasonController.text.length}/500',
                ),
                maxLines: 3,
                maxLength: 500,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: AppTheme.titleLarge.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Text(
              '거절',
              style: AppTheme.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(placeServiceProvider).updateUsageStatus(
              placeId: placeId,
              groupId: request.groupId,
              status: UsageStatus.rejected,
              rejectionReason: reasonController.text.trim().isEmpty
                  ? null
                  : reasonController.text.trim(),
            );

        ref.invalidate(pendingUsageRequestsProvider(placeId));

        if (context.mounted) {
          AppSnackBar.success(context, '거절되었습니다');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '거절 실패: ${e.toString().replaceFirst('Exception: ', '')}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Displays approved groups for a place
class _ApprovedGroupsList extends ConsumerWidget {
  final int placeId;
  final int groupId;

  const _ApprovedGroupsList({
    required this.placeId,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvedAsync = ref.watch(approvedUsageGroupsProvider(placeId));

    return approvedAsync.when(
      loading: () => Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.brand),
          ),
        ),
      ),
      error: (e, _) => ListTile(
        leading: Icon(Icons.error, color: AppColors.error),
        title: Text(
          '오류: $e',
          style: AppTheme.bodySmall.copyWith(
            color: AppColors.error,
          ),
        ),
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return ListTile(
            leading: Icon(Icons.people_outline, color: AppColors.neutral600),
            title: Text(
              '승인된 사용 그룹이 없습니다',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral700,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                '승인된 그룹 (${groups.length})',
                style: AppTheme.titleMedium.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...groups.map((group) => ListTile(
                  title: Text(
                    group.groupName,
                    style: AppTheme.titleMedium.copyWith(
                      color: AppColors.neutral900,
                    ),
                  ),
                  subtitle: Text(
                    '승인 일시: ${_formatDateTime(group.updatedAt)}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.remove_circle, color: AppColors.error),
                    onPressed: () =>
                        _showRevokeDialog(context, ref, placeId, group),
                    tooltip: '권한 취소',
                  ),
                )),
          ],
        );
      },
    );
  }

  Future<void> _showRevokeDialog(
    BuildContext context,
    WidgetRef ref,
    int placeId,
    PlaceUsageGroup group,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '권한 취소 확인',
          style: AppTheme.titleLarge.copyWith(
            color: AppColors.neutral900,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${group.groupName}의 예약 권한을 취소하시겠습니까?',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral700,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: AppColors.error),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '미래의 모든 예약이 취소됩니다',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: AppTheme.titleLarge.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Text(
              '권한 취소',
              style: AppTheme.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await ref.read(placeServiceProvider).revokeUsagePermission(
              placeId: placeId,
              groupId: group.groupId,
            );

        ref.invalidate(approvedUsageGroupsProvider(placeId));

        if (context.mounted) {
          final deletedCount = result['deletedReservations'] ?? 0;
          AppSnackBar.success(context, '권한이 취소되었습니다 (예약 $deletedCount개 취소됨)');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '권한 취소 실패: ${e.toString().replaceFirst('Exception: ', '')}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
