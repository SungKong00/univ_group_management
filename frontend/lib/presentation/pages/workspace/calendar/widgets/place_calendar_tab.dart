import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/place/place_reservation.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../providers/focused_date_provider.dart';
import '../../../../providers/place_calendar_provider.dart';
import 'building_place_selector.dart';
import 'multi_place_calendar_view.dart';
import 'place_reservation_dialog.dart';

/// Place calendar tab component
/// Displays building/place selector, calendar view, and reservation actions
class PlaceCalendarTab extends ConsumerStatefulWidget {
  final int groupId;

  const PlaceCalendarTab({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<PlaceCalendarTab> createState() => _PlaceCalendarTabState();
}

class _PlaceCalendarTabState extends ConsumerState<PlaceCalendarTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load places for the group
      ref.read(placeCalendarProvider.notifier).loadPlaces(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placeCalendarProvider);
    final focusedDate = ref.watch(focusedDateProvider);

    return Stack(
      children: [
        Column(
          children: [
            // Building and place selector
            BuildingPlaceSelector(),

            // Calendar view or empty state
            Expanded(
              child: _buildContent(state, focusedDate),
            ),
          ],
        ),

        // Floating action button for adding reservations
        if (state.selectedPlaceIds.isNotEmpty)
          Positioned(
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: FloatingActionButton.extended(
              onPressed: () => _showReservationDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('예약 추가'),
              backgroundColor: AppColors.brand,
            ),
          ),
      ],
    );
  }

  Widget _buildContent(PlaceCalendarState state, DateTime focusedDate) {
    // Loading state
    if (state.isLoading && state.places.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Empty state: No places available
    if (state.places.isEmpty) {
      return _buildEmptyState(
        icon: Icons.location_off,
        title: '등록된 장소가 없습니다',
        subtitle: '관리자에게 문의하여 장소를 등록해주세요',
      );
    }

    // Empty state: No places selected
    if (state.selectedPlaceIds.isEmpty) {
      return _buildEmptyState(
        icon: Icons.place,
        title: '장소를 선택하세요',
        subtitle: '위의 드롭다운에서 건물과 장소를 선택하여 예약 현황을 확인하세요',
      );
    }

    // Calendar view with selected places
    return MultiPlaceCalendarView(
      focusedDate: focusedDate,
      selectedDate: focusedDate,
      onDateSelected: (selected, focused) {
        ref.read(focusedDateProvider.notifier).setDate(selected);
      },
      onPageChanged: (focused) {
        ref.read(focusedDateProvider.notifier).setDate(focused);
      },
      onReservationTap: _showReservationDetail,
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.neutral700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.neutral600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReservationDialog(BuildContext context) async {
    final focusedDate = ref.read(focusedDateProvider);

    final result = await showPlaceReservationDialog(
      context,
      initialDate: focusedDate,
    );

    if (result == true && mounted) {
      // Reservation added successfully, no additional action needed
      // The provider already updated the state
    }
  }

  Future<void> _showReservationDetail(PlaceReservation reservation) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ListView(
            controller: scrollController,
            children: [
              // Header with color indicator
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: reservation.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reservation.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reservation.placeName,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.neutral600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showReservationActions(reservation);
                    },
                  ),
                ],
              ),
              const Divider(height: AppSpacing.md),

              // Details
              _buildDetailRow(
                Icons.schedule,
                '시간',
                reservation.formattedDateRange,
              ),
              if (reservation.groupName.isNotEmpty)
                _buildDetailRow(
                  Icons.group,
                  '그룹',
                  reservation.groupName,
                ),
              if (reservation.description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildDetailRow(
                  Icons.notes,
                  '설명',
                  reservation.description!,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                '생성: ${_formatDateTime(reservation.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral600,
                    ),
              ),
              Text(
                '수정: ${_formatDateTime(reservation.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.neutral600),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.neutral600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showReservationActions(PlaceReservation reservation) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('예약 취소'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleDeleteReservation(reservation);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('닫기'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDeleteReservation(PlaceReservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('예약 취소'),
        content: const Text('이 예약을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('예약 취소'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(placeCalendarProvider.notifier)
            .deleteReservation(reservation.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('예약이 취소되었습니다')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('예약 취소 실패: ${e.toString()}')),
          );
        }
      }
    }
  }
}
