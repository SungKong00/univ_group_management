import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/enums/calendar_view.dart';
import '../../../../../core/models/place/place_reservation.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../providers/calendar_view_provider.dart';
import '../../../../providers/focused_date_provider.dart';
import '../../../../providers/group_permission_provider.dart';
import '../../../../providers/place_calendar_provider.dart';
import '../../../../providers/place_provider.dart';
import '../../place/place_list_page.dart';
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
    // Load places data when the tab is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlaces();
    });
  }

  /// Load places from API and set them to the place calendar provider
  Future<void> _loadPlaces() async {
    try {
      final places = await ref.read(placesProvider(widget.groupId).future);
      ref.read(placeCalendarProvider.notifier).setPlaces(places);
    } catch (e) {
      // Error handling is done by the provider
      // The UI will show the error state automatically
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placeCalendarProvider);
    final focusedDate = ref.watch(focusedDateProvider);
    final currentView = ref.watch(calendarViewProvider);

    return Stack(
      children: [
        Column(
          children: [
            // Header with place management button
            _buildHeader(context),

            // View controls (Week/Month toggle + Date navigation)
            _buildViewControls(context, currentView, focusedDate),

            // Building and place selector
            BuildingPlaceSelector(),

            // Calendar view or empty state
            Expanded(
              child: _buildContent(state, focusedDate, currentView),
            ),
          ],
        ),

        // Floating action button for adding reservations
        // Show button when places are available, regardless of selection
        if (state.places.isNotEmpty)
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

  Widget _buildContent(
    PlaceCalendarState state,
    DateTime focusedDate,
    CalendarView view,
  ) {
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

    // Calendar view - always show calendar, even if no places are selected
    // When no places are selected, calendar will be empty
    // When places are selected, their reservations will be displayed
    return MultiPlaceCalendarView(
      view: view,
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
      groupId: widget.groupId,
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
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
              _buildDetailRow(
                Icons.person,
                '예약자',
                reservation.reservedByName,
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
            .cancelReservation(reservation.id);

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

  Widget _buildViewControls(
    BuildContext context,
    CalendarView currentView,
    DateTime focusedDate,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // View toggle (Week/Month)
          ToggleButtons(
            isSelected: CalendarView.values
                .map((option) => option == currentView)
                .toList(growable: false),
            onPressed: (index) {
              ref
                  .read(calendarViewProvider.notifier)
                  .setView(CalendarView.values.elementAt(index));
            },
            borderRadius: BorderRadius.circular(12),
            fillColor: AppColors.brand.withValues(alpha: 0.08),
            selectedColor: AppColors.brand,
            constraints: const BoxConstraints(minHeight: 40),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text('주간'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text('월간'),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),

          // Date navigation
          Expanded(
            child: _buildDateNavigator(context, currentView, focusedDate),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigator(
    BuildContext context,
    CalendarView view,
    DateTime focusedDate,
  ) {
    final label = _formatFocusedLabel(focusedDate, view);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: '이전',
          onPressed: () => _handlePrevious(view),
          icon: const Icon(Icons.chevron_left),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 120),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        IconButton(
          tooltip: '다음',
          onPressed: () => _handleNext(view),
          icon: const Icon(Icons.chevron_right),
        ),
        TextButton(
          onPressed: () => ref.read(focusedDateProvider.notifier).resetToToday(),
          child: const Text('오늘'),
        ),
      ],
    );
  }

  String _formatFocusedLabel(DateTime date, CalendarView view) {
    switch (view) {
      case CalendarView.week:
        final weekStart = _getWeekStart(date);
        final weekEnd = weekStart.add(const Duration(days: 6));
        if (weekStart.month == weekEnd.month) {
          return '${weekStart.year}년 ${weekStart.month}월 ${weekStart.day}일 ~ ${weekEnd.day}일';
        }
        return '${DateFormat('M월 d일', 'ko_KR').format(weekStart)} ~ '
            '${DateFormat('M월 d일', 'ko_KR').format(weekEnd)}';
      case CalendarView.month:
        return DateFormat('yyyy년 M월', 'ko_KR').format(date);
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1 (Monday) to 7 (Sunday)
    return date.subtract(Duration(days: weekday - 1));
  }

  void _handlePrevious(CalendarView view) {
    final notifier = ref.read(focusedDateProvider.notifier);
    switch (view) {
      case CalendarView.week:
        notifier.previousWeek();
        break;
      case CalendarView.month:
        notifier.previous(1);
        break;
    }
  }

  void _handleNext(CalendarView view) {
    final notifier = ref.read(focusedDateProvider.notifier);
    switch (view) {
      case CalendarView.week:
        notifier.nextWeek();
        break;
      case CalendarView.month:
        notifier.next(1);
        break;
    }
  }

  Widget _buildHeader(BuildContext context) {
    final permissions = ref.watch(groupPermissionsProvider(widget.groupId));
    final hasCalendarManage = permissions.when(
      data: (perms) => perms.contains('CALENDAR_MANAGE'),
      loading: () => false,
      error: (_, __) => false,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '장소 예약 현황',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (hasCalendarManage)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaceListPage(groupId: widget.groupId),
                  ),
                );
              },
              icon: const Icon(Icons.settings, size: 20),
              label: const Text('장소 관리'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brand,
              ),
            ),
        ],
      ),
    );
  }
}
