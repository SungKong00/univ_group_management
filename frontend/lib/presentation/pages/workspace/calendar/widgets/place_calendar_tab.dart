import 'package:flutter/material.dart';
import '../../../../../core/utils/snack_bar_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/enums/calendar_view.dart';
import '../../../../../core/models/place/place.dart';
import '../../../../../core/models/place/place_reservation.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../providers/calendar_view_provider.dart';
import '../../../../providers/focused_date_provider.dart';
import '../../../../providers/group_permission_provider.dart';
import '../../../../providers/place_calendar_provider.dart';
import '../../../../providers/place_provider.dart';
import '../../../../providers/workspace_state_provider.dart';
import '../../../../utils/responsive_layout_helper.dart';
import '../../../../widgets/place/place_card.dart';
import 'multi_place_calendar_view.dart';
import 'place_reservation_dialog.dart';
import 'place_selector_button.dart';

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
  Set<int>? _previousSelectedPlaceIds;
  DateTime? _previousFocusedDate;
  CalendarView? _previousCalendarView;

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

  /// Load reservations for the current calendar view and focused date
  Future<void> _loadReservationsForCurrentView() async {
    final focusedDate = ref.read(focusedDateProvider);
    final currentView = ref.read(calendarViewProvider);

    final dateRange = _calculateDateRange(focusedDate, currentView);

    await ref.read(placeCalendarProvider.notifier).loadReservations(
          startDate: dateRange.start,
          endDate: dateRange.end,
        );
  }

  /// Calculate date range based on calendar view and focused date
  DateTimeRange _calculateDateRange(DateTime focusedDate, CalendarView view) {
    switch (view) {
      case CalendarView.week:
        // For week view, get the week start (Monday) and end (Sunday)
        final weekStart = _getWeekStart(focusedDate);
        final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return DateTimeRange(start: weekStart, end: weekEnd);

      case CalendarView.month:
        // For month view, get the first and last day of the month
        final monthStart = DateTime(focusedDate.year, focusedDate.month, 1);
        final monthEnd = DateTime(focusedDate.year, focusedDate.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: monthStart, end: monthEnd);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placeCalendarProvider);
    final focusedDate = ref.watch(focusedDateProvider);
    final currentView = ref.watch(calendarViewProvider);

    // Check if we need to reload reservations based on state changes
    // This replaces ref.listen to avoid lifecycle issues in TabBarView

    // Determine if we need to load reservations
    bool shouldLoadReservations = false;

    // Check for selected place IDs changes (use identical comparison for Set)
    if (!identical(state.selectedPlaceIds, _previousSelectedPlaceIds)) {
      _previousSelectedPlaceIds = state.selectedPlaceIds;
      if (state.selectedPlaceIds.isNotEmpty) {
        shouldLoadReservations = true;
      }
    }

    // Check for focused date changes
    if (focusedDate != _previousFocusedDate) {
      _previousFocusedDate = focusedDate;
      if (state.selectedPlaceIds.isNotEmpty) {
        shouldLoadReservations = true;
      }
    }

    // Check for calendar view changes
    if (currentView != _previousCalendarView) {
      _previousCalendarView = currentView;
      if (state.selectedPlaceIds.isNotEmpty) {
        shouldLoadReservations = true;
      }
    }

    // Schedule reservation load after build (only once per build cycle)
    if (shouldLoadReservations) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadReservationsForCurrentView();
        }
      });
    }

    // Use LayoutBuilder to get actual widget width (not screen width)
    // This ensures correct responsive behavior when navigation bars are present
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use project standard: 850px breakpoint for wide desktop
        final helper = ResponsiveLayoutHelper(context: context, constraints: constraints);
        final isWideMode = helper.isWideDesktop;

        return _buildContent(
          state,
          focusedDate,
          currentView,
          isWideMode,
        );
      },
    );
  }

  Widget _buildContent(
    PlaceCalendarState state,
    DateTime focusedDate,
    CalendarView currentView,
    bool isWideMode,
  ) {
    return Stack(
      children: [
        Column(
          children: [
            // Responsive header: 1 row in wide mode, 2 rows in compact mode
            _buildResponsiveHeader(context, currentView, focusedDate, isWideMode),

            // Selected places chips (from BuildingPlaceSelector)
            _buildSelectedPlacesChips(state),

            // Calendar view or empty state
            Expanded(
              child: _buildCalendarView(state, focusedDate, currentView),
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

  Widget _buildCalendarView(
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

        // Success: Show success message
        if (mounted) {
          AppSnackBar.success(context, '예약이 취소되었습니다');
        }
      } catch (e) {
        // Error: Show detailed error message
        if (mounted) {
          // Extract meaningful error message
          String errorMessage = '예약 취소에 실패했습니다';
          final errorString = e.toString();

          // Remove "Exception: " prefix if present
          if (errorString.startsWith('Exception: ')) {
            errorMessage = errorString.substring(11);
          } else {
            errorMessage = '$errorMessage: $errorString';
          }

          AppSnackBar.error(context, errorMessage);
        }
      }
    }
  }

  /// Build responsive header that adapts to screen width
  /// Wide mode (>=850px): 1 row with all controls, max width 1200px, centered
  /// Compact mode (<850px): 2 rows (date nav + other controls)
  Widget _buildResponsiveHeader(
    BuildContext context,
    CalendarView currentView,
    DateTime focusedDate,
    bool isWideMode,
  ) {
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
      child: isWideMode
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _buildWideHeader(context, currentView, focusedDate, hasCalendarManage),
              ),
            )
          : _buildCompactHeader(context, currentView, focusedDate, hasCalendarManage),
    );
  }

  /// Wide mode layout: [주간/월간] | [◀ 2025년 11월 ▶ 오늘] | [건물▼ 장소▼ ⚙️]
  Widget _buildWideHeader(
    BuildContext context,
    CalendarView currentView,
    DateTime focusedDate,
    bool hasCalendarManage,
  ) {
    return Row(
      children: [
        // View toggle (Week/Month)
        _buildViewToggle(currentView),
        const SizedBox(width: AppSpacing.md),

        // Date navigation (centered, takes remaining space)
        Expanded(
          child: _buildDateNavigator(context, currentView, focusedDate),
        ),
        const SizedBox(width: AppSpacing.md),

        // Place selector + Settings button
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PlaceSelectorButton(),
            const SizedBox(width: AppSpacing.xs),
            if (hasCalendarManage) _buildPlaceManageButton(context),
          ],
        ),
      ],
    );
  }

  /// Compact mode layout (2 rows):
  /// Row 1: [주간/월간] | [◀ 2025년 11월 ▶ 오늘]
  /// Row 2: [건물▼ 장소▼] | [⚙️]
  Widget _buildCompactHeader(
    BuildContext context,
    CalendarView currentView,
    DateTime focusedDate,
    bool hasCalendarManage,
  ) {
    return Column(
      children: [
        // Row 1: View toggle and Date navigation
        Row(
          children: [
            _buildViewToggle(currentView),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildDateNavigator(context, currentView, focusedDate),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Row 2: Place selector + Settings
        Row(
          children: [
            // Place selector
            const PlaceSelectorButton(),
            const Spacer(),

            // Settings button
            if (hasCalendarManage) _buildPlaceManageButton(context),
          ],
        ),
      ],
    );
  }

  /// View toggle button (Week/Month)
  Widget _buildViewToggle(CalendarView currentView) {
    return ToggleButtons(
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
      constraints: const BoxConstraints(minHeight: 40, minWidth: 50),
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
    );
  }

  /// Place management button (icon only with tooltip)
  Widget _buildPlaceManageButton(BuildContext context) {
    return IconButton(
      tooltip: '장소 관리',
      onPressed: () => _showPlaceListModal(),
      icon: const Icon(Icons.settings),
      color: AppColors.brand,
      iconSize: 24,
    );
  }

  /// Selected places chips display
  Widget _buildSelectedPlacesChips(PlaceCalendarState state) {
    if (state.selectedPlaces.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
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
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: state.selectedPlaces.map((place) {
          final color = state.getColorForPlace(place.id);
          return Chip(
            label: Text(
              place.displayName,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: color,
            deleteIconColor: Colors.white,
            onDeleted: () {
              ref.read(placeCalendarProvider.notifier).deselectPlace(place.id);
            },
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
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

  /// Show place list modal dialog for selecting a place to manage
  Future<void> _showPlaceListModal() async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            children: [
              // Header with title and close button
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.card),
                    topRight: Radius.circular(AppRadius.card),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.settings,
                      color: Colors.white,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Text(
                      '장소 관리',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: '닫기',
                    ),
                  ],
                ),
              ),

              // Place list content - wrapped in Consumer to provide ref context
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final placesAsync = ref.watch(placesProvider(widget.groupId));

                    return placesAsync.when(
                      data: (places) => _buildModalPlaceList(places),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppColors.error,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const Text(
                                '오류가 발생했습니다',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.neutral900,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                error.toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.neutral600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build place list for modal (reusing PlaceListPage structure)
  Widget _buildModalPlaceList(List<Place> places) {
    if (places.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 64,
                color: AppColors.neutral400,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '등록된 장소가 없습니다',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.neutral600,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '장소를 추가해주세요',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral500,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Group places by building
    final groupedPlaces = <String, List<Place>>{};
    for (final place in places) {
      groupedPlaces.putIfAbsent(place.building, () => []).add(place);
    }

    // Sort buildings alphabetically
    final sortedBuildings = groupedPlaces.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: sortedBuildings.length,
      itemBuilder: (context, index) {
        final building = sortedBuildings[index];
        final buildingPlaces = groupedPlaces[building]!;

        // Sort places by room number
        buildingPlaces.sort((a, b) => a.roomNumber.compareTo(b.roomNumber));

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: const BorderSide(
              color: AppColors.neutral300,
              width: 1,
            ),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            childrenPadding: const EdgeInsets.only(
              bottom: AppSpacing.xxs,
            ),
            title: Text(
              building,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral900,
              ),
            ),
            subtitle: Text(
              '${buildingPlaces.length}개 장소',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.neutral600,
              ),
            ),
            children: buildingPlaces.map((place) {
              return PlaceCard(
                place: place,
                groupId: widget.groupId,
                onManageAvailability: () {
                  // Close modal first
                  Navigator.of(context).pop();
                  // Navigate to time management page using WorkspaceProvider
                  ref.read(workspaceStateProvider.notifier).showPlaceTimeManagementPage(
                    place.id,
                    place.displayName,
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
