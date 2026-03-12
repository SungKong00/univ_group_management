import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/enums/calendar_view.dart';
import '../../../../../core/models/place/place.dart';
import '../../../../../core/models/place/place_reservation.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/utils/place_availability_helper.dart';
import '../../../../adapters/place_reservation_adapter.dart';
import '../../../../providers/place_calendar_provider.dart';
import '../../../../widgets/calendar/calendar_event_card.dart';
import '../../../../widgets/weekly_calendar/weekly_schedule_editor.dart';
import '../../../calendar/widgets/calendar_month_with_sidebar.dart';
import 'place_picker_dialog.dart';
import 'place_reservation_dialog.dart';

/// Multi-place calendar view showing reservations for selected places
/// Displays all reservations with place-specific colors
/// Supports both month and week views
class MultiPlaceCalendarView extends ConsumerWidget {
  final int groupId;
  final DateTime focusedDate;
  final DateTime? selectedDate;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDateSelected;
  final void Function(DateTime focusedDay) onPageChanged;
  final void Function(PlaceReservation reservation) onReservationTap;
  final CalendarView view;

  const MultiPlaceCalendarView({
    super.key,
    required this.groupId,
    required this.focusedDate,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onPageChanged,
    required this.onReservationTap,
    this.view = CalendarView.month,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(placeCalendarProvider);
    final reservations = state.selectedPlaceReservations;

    // Week view - using WeeklyScheduleEditor
    if (view == CalendarView.week) {
      return _buildWeekView(context, ref, state);
    }

    // Month view (default)
    return CalendarMonthWithSidebar<PlaceReservation>(
      events: reservations,
      focusedDate: focusedDate,
      selectedDate: selectedDate,
      onDateSelected: onDateSelected,
      onPageChanged: onPageChanged,
      onEventTap: onReservationTap,
      eventChipBuilder: (reservation) =>
          _buildReservationChip(context, reservation),
      eventCardBuilder: (reservation) =>
          _buildReservationCard(context, reservation),
    );
  }

  /// Build week view using WeeklyScheduleEditor
  Widget _buildWeekView(
    BuildContext context,
    WidgetRef ref,
    PlaceCalendarState state,
  ) {
    final weekStart = _getWeekStart(focusedDate);

    // 1. Convert PlaceReservation → Event
    final events = state.selectedPlaceReservations
        .map(
          (reservation) =>
              PlaceReservationAdapter.toEvent(reservation, weekStart),
        )
        .whereType<Event>()
        .toList();

    // 2. Prepare availability & reservation data for selected places
    final availabilitiesMap = state.selectedPlaceAvailabilities;
    final reservationsMap = <int, List<PlaceReservation>>{};
    for (final reservation in state.selectedPlaceReservations) {
      reservationsMap
          .putIfAbsent(reservation.placeId, () => [])
          .add(reservation);
    }

    // 3. Calculate per-place disabled slots (operating hours + reservations)
    final disabledSlotsByPlace = <int, Set<DateTime>>{};
    final hasFullAvailabilityData = state.selectedPlaceIds.every(
      (id) => availabilitiesMap.containsKey(id),
    );

    for (final place in state.selectedPlaces) {
      final availabilities = availabilitiesMap[place.id] ?? [];
      final reservations = reservationsMap[place.id] ?? [];
      disabledSlotsByPlace[place.id] =
          PlaceAvailabilityHelper.calculateDisabledSlotsForPlace(
            availabilities: availabilities,
            reservations: reservations,
            weekStart: weekStart,
          );
    }

    // 4. Calculate merged disabled slots for grid rendering
    Set<DateTime> disabledSlots = {};
    final requiredDuration = state.selectedPlaces.length > 1
        ? state.requiredDuration
        : null;

    if (state.selectedPlaces.isEmpty) {
      disabledSlots = {};
    } else if (state.selectedPlaces.length == 1) {
      final singleId = state.selectedPlaces.first.id;
      disabledSlots = disabledSlotsByPlace[singleId] ?? {};
    } else if (requiredDuration != null) {
      if (hasFullAvailabilityData) {
        disabledSlots =
            PlaceAvailabilityHelper.calculateDisabledSlotsWithDuration(
              availabilitiesMap: availabilitiesMap,
              reservationsMap: reservationsMap,
              requiredDuration: requiredDuration,
              weekStart: weekStart,
            );
      } else {
        disabledSlots = {};
      }
    } else if (disabledSlotsByPlace.isNotEmpty) {
      disabledSlots = disabledSlotsByPlace.values.reduce(
        (value, element) => value.intersection(element),
      );
    }

    // 5. Render WeeklyScheduleEditor
    return WeeklyScheduleEditor(
      allowMultiDaySelection: false, // Place reservations are single-day only
      isEditable: true,
      allowEventOverlap: false, // CRITICAL: Place reservations cannot overlap
      weekStart: weekStart,
      initialEvents: events,
      disabledSlots: disabledSlots,
      requiredDuration: requiredDuration,
      availablePlaces: state.selectedPlaces,
      disabledSlotsByPlace: disabledSlotsByPlace,
      onEventCreate: (event) =>
          _handleReservationCreate(context, ref, event, weekStart),
      onEventUpdate: (event) =>
          _handleReservationUpdate(context, ref, event, weekStart),
      onEventDelete: (event) => _handleReservationDelete(context, ref, event),
    );
  }

  /// Handle reservation creation
  ///
  /// **Flow**:
  /// 1. Validate selected time range
  /// 2. Filter places that can accommodate the reservation
  /// 3. Prompt the user to choose a place when multiple options exist
  /// 4. Trigger the reservation form dialog prefilled with the chosen place/time
  Future<bool> _handleReservationCreate(
    BuildContext context,
    WidgetRef ref,
    Event event,
    DateTime weekStart,
  ) async {
    final state = ref.read(placeCalendarProvider);

    if (event.startTime == null || event.endTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('선택한 시간 정보를 불러오지 못했습니다')));
      return false;
    }

    final startTime = event.startTime!;
    final endTime = event.endTime!;

    if (!startTime.isBefore(endTime)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('종료 시간은 시작 시간보다 늦어야 합니다')));
      return false;
    }

    final selectedPlaces = state.selectedPlaces;
    if (selectedPlaces.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('예약할 장소를 먼저 선택해주세요')));
      return false;
    }

    final availabilitiesMap = state.selectedPlaceAvailabilities;
    final reservationsMap = <int, List<PlaceReservation>>{};
    for (final reservation in state.selectedPlaceReservations) {
      reservationsMap
          .putIfAbsent(reservation.placeId, () => [])
          .add(reservation);
    }

    final availablePlaces = <Place>[];
    final unavailablePlaces = <Place>[];

    for (final place in selectedPlaces) {
      final availabilities = availabilitiesMap[place.id] ?? [];
      final reservations = reservationsMap[place.id] ?? [];
      final canReserve = PlaceAvailabilityHelper.canReservePlaceForRange(
        startTime: startTime,
        endTime: endTime,
        availabilities: availabilities,
        reservations: reservations,
      );

      if (canReserve) {
        availablePlaces.add(place);
      } else {
        unavailablePlaces.add(place);
      }
    }

    if (selectedPlaces.length == 1 && availablePlaces.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('선택한 장소가 해당 시간에 예약 불가합니다')));
      return false;
    }

    if (selectedPlaces.length > 1 && availablePlaces.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('선택한 장소 중 예약 가능한 장소가 없습니다')));
      return false;
    }

    Place? chosenPlace;
    if (selectedPlaces.length == 1) {
      chosenPlace = availablePlaces.isNotEmpty ? availablePlaces.first : null;
    } else {
      if (availablePlaces.length == 1) {
        chosenPlace = availablePlaces.first;
      } else {
        chosenPlace = await showPlacePickerDialog(
          context: context,
          groupId: groupId,
          startTime: startTime,
          endTime: endTime,
          availablePlaces: availablePlaces,
          unavailablePlaces: unavailablePlaces,
        );

        if (chosenPlace == null) {
          return false; // User cancelled
        }
      }
    }

    if (!context.mounted) return false;
    return _showReservationForm(
      context: context,
      placeId: chosenPlace!.id,
      startTime: startTime,
      endTime: endTime,
    );
  }

  Future<bool> _showReservationForm({
    required BuildContext context,
    required int placeId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final result = await showPlaceReservationDialog(
      context,
      groupId: groupId,
      initialDate: DateTime(startTime.year, startTime.month, startTime.day),
      initialStartTime: TimeOfDay.fromDateTime(startTime),
      initialEndTime: TimeOfDay.fromDateTime(endTime),
      initialPlaceId: placeId,
    );

    return result ?? false;
  }

  /// Handle reservation update
  ///
  /// **Flow**:
  /// 1. Extract reservation ID
  /// 2. Find original reservation
  /// 3. Check permissions
  /// 4. Show update form dialog
  /// 5. Update reservation via API
  Future<bool> _handleReservationUpdate(
    BuildContext context,
    WidgetRef ref,
    Event event,
    DateTime weekStart,
  ) async {
    // Step 1: Extract reservation ID
    final reservationId = PlaceReservationAdapter.extractReservationId(
      event.id,
    );
    if (reservationId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('잘못된 예약 ID입니다')));
      return false;
    }

    // Step 2: Verify reservation exists
    final state = ref.read(placeCalendarProvider);
    try {
      state.reservations.firstWhere((r) => r.id == reservationId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('예약을 찾을 수 없습니다')));
      return false;
    }

    // Step 3: TODO - Check permissions (only owner or place manager can update)

    // Step 4: TODO - Show update form dialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('예약 수정 폼 다이얼로그 구현 예정')));
    return false;
  }

  /// Handle reservation deletion
  ///
  /// **Flow**:
  /// 1. Extract reservation ID
  /// 2. Find original reservation
  /// 3. Show confirmation dialog
  /// 4. Delete reservation via API
  Future<bool> _handleReservationDelete(
    BuildContext context,
    WidgetRef ref,
    Event event,
  ) async {
    // Step 1: Extract reservation ID
    final reservationId = PlaceReservationAdapter.extractReservationId(
      event.id,
    );
    if (reservationId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('잘못된 예약 ID입니다')));
      return false;
    }

    // Step 2: Find original reservation
    final state = ref.read(placeCalendarProvider);
    PlaceReservation? originalReservation;
    try {
      originalReservation = state.reservations.firstWhere(
        (r) => r.id == reservationId,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('예약을 찾을 수 없습니다')));
      return false;
    }

    // Step 3: Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('예약 취소'),
        content: Text(
          '${originalReservation!.title} 예약을 취소하시겠습니까?\n'
          '장소: ${originalReservation.placeName}\n'
          '시간: ${originalReservation.formattedTimeRange}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    // Step 4: Delete reservation via API
    try {
      await ref
          .read(placeCalendarProvider.notifier)
          .cancelReservation(reservationId);

      if (!context.mounted) return true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('예약이 취소되었습니다')));
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('예약 취소 실패: ${e.toString()}')));
      return false;
    }
  }

  /// Get Monday of the week containing the given date (at 00:00:00)
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1 (Monday) to 7 (Sunday)
    final monday = date.subtract(Duration(days: weekday - 1));
    // Normalize to 00:00:00 to ensure consistent slot calculations
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Build custom reservation chip for calendar cells
  Widget _buildReservationChip(
    BuildContext context,
    PlaceReservation reservation,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: reservation.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: reservation.color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reservation.title,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.neutral900,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            reservation.placeName,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.neutral600,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  /// Build custom reservation card for sidebar list
  /// Uses CalendarEventCard component with Place Calendar mode
  Widget _buildReservationCard(
    BuildContext context,
    PlaceReservation reservation,
  ) {
    return CalendarEventCard(
      title: reservation.title,
      color: reservation.color,
      timeLabel: reservation.formattedTimeRange,
      location: reservation.placeName,
      reservedBy: reservation.reservedByName,
      showIcons: true,
      colorBarHeight: 60,
      onTap: null, // onTap is handled by parent InkWell
    );
  }
}
