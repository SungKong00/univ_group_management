import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import '../../../core/models/calendar/group_event.dart';
import '../../../core/models/place/place.dart';
import '../../../core/models/place/place_availability.dart';
import '../../../core/models/place/place_reservation.dart';
import '../../../core/services/group_calendar_service.dart';
import '../../../core/services/group_service.dart';
import '../../../core/services/place_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/weekly_calendar/duration_input_dialog.dart';
import '../../widgets/weekly_calendar/group_picker_bottom_sheet.dart';
import '../../widgets/weekly_calendar/group_selection_header.dart';
import '../../widgets/weekly_calendar/place_selector_bottom_sheet.dart';
import '../../widgets/weekly_calendar/weekly_navigation_header.dart';
import '../../widgets/weekly_calendar/weekly_schedule_editor.dart';

/// Demo Calendar Page - Integrated group calendar display
///
/// Features:
/// - Multi-group selection with color-coded events
/// - Week navigation
/// - Loading/error state per group
/// - Group event overlay on personal calendar
///
/// Design Pattern:
/// - GroupSelectionHeader: Shows selected groups with event counts
/// - GroupPickerBottomSheet: Bottom sheet for group selection
/// - WeeklyScheduleEditor: Personal calendar with external events
class DemoCalendarPage extends StatefulWidget {
  const DemoCalendarPage({super.key});

  @override
  State<DemoCalendarPage> createState() => _DemoCalendarPageState();
}

class _DemoCalendarPageState extends State<DemoCalendarPage> {
  // Available groups (user's memberships)
  List<({int id, String name})> _availableGroups = [];

  // Loading/error state for group list
  bool _isLoadingGroups = false;
  String? _groupLoadError;

  // Selected group IDs
  final Set<int> _selectedGroupIds = {};

  // Event data by group
  final Map<int, List<GroupEvent>> _eventsByGroup = {};
  final Map<int, int> _eventCountByGroup = {};

  // Loading/error state by group
  final Map<int, bool> _loadingByGroup = {};
  final Map<int, String?> _errorByGroup = {};

  // Current week start (Monday)
  late DateTime _weekStart;

  // Services
  final _groupService = GroupService();
  final _groupCalendarService = GroupCalendarService();
  final _placeService = PlaceService();

  // Place selection state
  List<Place> _selectedPlaces = [];
  Duration? _requiredDuration;
  Set<DateTime> _disabledSlots = {};

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(DateTime.now());
    _loadAvailableGroups();
  }

  /// Get week start (Monday) from any date
  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Load user's available groups with proper error handling
  Future<void> _loadAvailableGroups() async {
    if (!mounted) return;

    setState(() {
      _isLoadingGroups = true;
      _groupLoadError = null;
    });

    try {
      developer.log('Loading available groups...', name: 'DemoCalendarPage');
      final groups = await _groupService.getMyGroups();
      developer.log(
        'Loaded ${groups.length} groups successfully',
        name: 'DemoCalendarPage',
      );

      if (!mounted) return;

      setState(() {
        _availableGroups = groups.map((g) => (id: g.id, name: g.name)).toList();
        _isLoadingGroups = false;
        _groupLoadError = null;
      });

      // Show success message if groups found
      if (groups.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${groups.length}개의 그룹을 불러왔습니다'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      developer.log(
        'Error loading groups: $e',
        name: 'DemoCalendarPage',
        level: 1000,
      );

      if (!mounted) return;

      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _isLoadingGroups = false;
        _groupLoadError = errorMessage;
      });

      // Show error snackbar with retry option
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('그룹 목록 로드 실패: $errorMessage'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: '재시도',
            onPressed: _loadAvailableGroups,
          ),
        ),
      );
    }
  }

  /// Toggle group selection
  void _toggleGroup(int groupId, bool selected) {
    setState(() {
      if (selected) {
        _selectedGroupIds.add(groupId);
        _loadEventsForGroup(groupId);
      } else {
        _selectedGroupIds.remove(groupId);
        _eventsByGroup.remove(groupId);
        _eventCountByGroup.remove(groupId);
        _loadingByGroup.remove(groupId);
        _errorByGroup.remove(groupId);
      }
    });
  }

  /// Load events for a specific group
  Future<void> _loadEventsForGroup(int groupId) async {
    setState(() {
      _loadingByGroup[groupId] = true;
      _errorByGroup.remove(groupId);
    });

    try {
      // Week end: Sunday (backend will add +1 day internally for exclusive range)
      final weekEnd = _weekStart.add(const Duration(days: 6));
      final events = await _groupCalendarService.getEvents(
        groupId: groupId,
        startDate: _weekStart,
        endDate: weekEnd,
        enableLogging: false,
      );

      setState(() {
        _eventsByGroup[groupId] = events;
        _eventCountByGroup[groupId] = events.length;
        _loadingByGroup[groupId] = false;
      });
    } catch (e) {
      setState(() {
        _errorByGroup[groupId] = e.toString().replaceFirst('Exception: ', '');
        _loadingByGroup[groupId] = false;
      });
    }
  }


  /// Get group color (cycling through palette)
  Color _getGroupColor(int groupId) {
    final colors = [
      const Color(0xFF5C068C), // primary (violet)
      const Color(0xFF1E6FFF), // blue
      const Color(0xFF10B981), // green
      const Color(0xFFF59E0B), // orange
      const Color(0xFFE63946), // red
      const Color(0xFF8B5CF6), // purple
    ];
    return colors[groupId.hashCode % colors.length];
  }

  /// Get all external group events for the current week
  List<GroupEvent> _getAllGroupEvents() {
    final allEvents = <GroupEvent>[];
    for (final groupId in _selectedGroupIds) {
      final events = _eventsByGroup[groupId] ?? [];
      allEvents.addAll(events);
    }
    return allEvents;
  }

  /// Get group colors map for event rendering
  Map<int, Color> _getGroupColorsMap() {
    final colorMap = <int, Color>{};
    for (final groupId in _selectedGroupIds) {
      colorMap[groupId] = _getGroupColor(groupId);
    }
    return colorMap;
  }

  /// Show group picker bottom sheet with loading/error states
  void _showGroupPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupPickerBottomSheet(
        availableGroups: _availableGroups,
        selectedGroupIds: _selectedGroupIds,
        onChanged: _toggleGroup,
        isLoading: _isLoadingGroups,
        errorMessage: _groupLoadError,
        onRetry: () {
          Navigator.of(context).pop(); // Close bottom sheet
          _loadAvailableGroups(); // Retry loading
        },
      ),
    );
  }

  /// Show place picker bottom sheet
  void _showPlacePicker() {
    showModalBottomSheet<List<Place>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaceSelectorBottomSheet(
        onPlacesSelected: (selectedPlaces) {
          // This callback is kept for compatibility but not used
          // The actual data is returned via Navigator.pop in the BottomSheet
        },
      ),
    ).then((selectedPlaces) async {
      // Handle the returned data from BottomSheet
      if (selectedPlaces == null || selectedPlaces.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('선택된 장소가 없습니다'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Single place: update immediately and show message
      if (selectedPlaces.length == 1) {
        setState(() {
          _selectedPlaces = selectedPlaces;
          _requiredDuration = null; // Reset duration for single place
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${selectedPlaces[0].building} ${selectedPlaces[0].roomNumber}가 선택되었습니다',
              ),
              duration: const Duration(seconds: 2),
            ),
          );

          // Calculate disabled slots for single place
          _calculateDisabledSlots();
        }
      }
      // Multiple places: show duration input dialog
      else if (selectedPlaces.length >= 2) {
        final duration = await showDialog<Duration>(
          context: context,
          builder: (context) => const DurationInputDialog(),
        );

        if (duration != null && mounted) {
          setState(() {
            _selectedPlaces = selectedPlaces;
            _requiredDuration = duration;
          });

          // Display selected places and duration
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${selectedPlaces.length}개의 장소 선택 완료 (소요시간: ${_formatDuration(duration)})',
              ),
              duration: const Duration(seconds: 2),
            ),
          );

          // Calculate disabled slots for multiple places
          _calculateDisabledSlots();
        }
      }
    });
  }

  /// Format duration to display string
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (minutes == 0) {
      return '${hours}시간';
    } else {
      return '${hours}시간 ${minutes}분';
    }
  }

  /// Calculate disabled time slots based on selected places
  ///
  /// Queries place availability and reservations for each selected place,
  /// then calculates the union of unavailable time slots.
  ///
  /// For single place: Returns unavailable slots (outside operating hours or reserved)
  /// For multiple places: Returns slots where ANY place is unavailable (union)
  Future<void> _calculateDisabledSlots() async {
    if (_selectedPlaces.isEmpty) {
      setState(() {
        _disabledSlots = {};
      });
      return;
    }

    try {
      developer.log(
        'Calculating disabled slots for ${_selectedPlaces.length} places',
        name: 'DemoCalendarPage',
      );

      // Week end: Sunday (6 days from week start)
      final weekEnd = _weekStart.add(const Duration(days: 6));

      // Collect unavailable slots for all places
      final Set<DateTime> allDisabledSlots = {};

      for (final place in _selectedPlaces) {
        // 1. Get place detail (includes availability)
        final placeDetail = await _placeService.getPlaceDetail(place.id);
        if (placeDetail == null) {
          developer.log(
            'Failed to fetch place detail for place ${place.id}',
            name: 'DemoCalendarPage',
            level: 900,
          );
          continue;
        }

        // 2. Get reservations for the week
        final reservations = await _placeService.getReservations(
          placeId: place.id,
          startDate: _weekStart,
          endDate: weekEnd,
        );

        // 3. Calculate disabled slots for this place
        final placeDisabledSlots = _calculateDisabledSlotsForPlace(
          availabilities: placeDetail.availabilities,
          reservations: reservations,
          weekStart: _weekStart,
        );

        // 4. Add to union
        allDisabledSlots.addAll(placeDisabledSlots);
      }

      if (!mounted) return;

      setState(() {
        _disabledSlots = allDisabledSlots;
      });

      developer.log(
        'Calculated ${allDisabledSlots.length} disabled slots',
        name: 'DemoCalendarPage',
      );
    } catch (e) {
      developer.log(
        'Error calculating disabled slots: $e',
        name: 'DemoCalendarPage',
        level: 1000,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('예약 가능 시간 계산 실패: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Calculate disabled slots for a single place
  ///
  /// Returns a set of DateTime objects representing 30-minute time slots
  /// that are unavailable (outside operating hours or reserved).
  Set<DateTime> _calculateDisabledSlotsForPlace({
    required List<PlaceAvailability> availabilities,
    required List<PlaceReservation> reservations,
    required DateTime weekStart,
  }) {
    final Set<DateTime> disabled = {};

    // Iterate through 7 days of the week
    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final currentDate = weekStart.add(Duration(days: dayIndex));

      // Get day of week (1=Monday, 7=Sunday)
      final dayOfWeek = currentDate.weekday;

      // Convert to DayOfWeek enum (MONDAY, TUESDAY, etc.)
      final dayOfWeekEnum = _getDayOfWeekEnum(dayOfWeek);

      // Get availability for this day
      final dayAvailabilities = availabilities
          .where((a) => a.dayOfWeek == dayOfWeekEnum)
          .toList();

      // Debug log: print operating hours for each day
      developer.log(
        'Day $dayOfWeekEnum (${currentDate.month}/${currentDate.day}): '
        '${dayAvailabilities.length} availability(s)',
        name: 'DemoCalendarPage',
      );
      if (dayAvailabilities.isNotEmpty) {
        for (final avail in dayAvailabilities) {
          developer.log(
            '  → ${avail.startTime.hour.toString().padLeft(2, '0')}:'
            '${avail.startTime.minute.toString().padLeft(2, '0')} ~ '
            '${avail.endTime.hour.toString().padLeft(2, '0')}:'
            '${avail.endTime.minute.toString().padLeft(2, '0')}',
            name: 'DemoCalendarPage',
          );
        }
      } else {
        developer.log(
          '  ⚠️ No operating hours for this day (all slots will be disabled)',
          name: 'DemoCalendarPage',
          level: 900,
        );
      }

      // Iterate through 30-minute slots (00:00 ~ 23:30)
      for (int hour = 0; hour < 24; hour++) {
        for (int minute = 0; minute < 60; minute += 30) {
          final slot = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            hour,
            minute,
          );

          // Check if slot is outside operating hours
          if (!_isWithinOperatingHours(slot, dayAvailabilities)) {
            disabled.add(slot);
            continue;
          }

          // Check if slot overlaps with existing reservation
          if (_overlapsWithReservation(slot, reservations)) {
            disabled.add(slot);
            continue;
          }
        }
      }
    }

    return disabled;
  }

  /// Convert weekday int (1-7) to DayOfWeek enum
  dynamic _getDayOfWeekEnum(int weekday) {
    // Import statement for DayOfWeek enum is already present via place_availability.dart
    switch (weekday) {
      case 1:
        return DayOfWeek.MONDAY;
      case 2:
        return DayOfWeek.TUESDAY;
      case 3:
        return DayOfWeek.WEDNESDAY;
      case 4:
        return DayOfWeek.THURSDAY;
      case 5:
        return DayOfWeek.FRIDAY;
      case 6:
        return DayOfWeek.SATURDAY;
      case 7:
        return DayOfWeek.SUNDAY;
      default:
        return DayOfWeek.MONDAY;
    }
  }

  /// Check if a time slot is within operating hours
  ///
  /// Returns true if the slot falls within any of the availability time ranges
  bool _isWithinOperatingHours(
    DateTime slot,
    List<PlaceAvailability> availabilities,
  ) {
    if (availabilities.isEmpty) {
      return false; // No availability = closed
    }

    for (final availability in availabilities) {
      final startTime = availability.startTime;
      final endTime = availability.endTime;

      // Convert slot to TimeOfDay
      final slotTime = TimeOfDay(hour: slot.hour, minute: slot.minute);

      // Compare time only (ignore date)
      if (_isTimeInRange(slotTime, startTime, endTime)) {
        return true;
      }
    }

    return false;
  }

  /// Check if a TimeOfDay is within a time range
  ///
  /// IMPORTANT: Checks if a 30-minute slot starting at [time] is fully within [start]-[end].
  /// A slot is available only if both its start AND end (+30min) are within operating hours.
  bool _isTimeInRange(TimeOfDay time, TimeOfDay start, TimeOfDay end) {
    final timeInMinutes = time.hour * 60 + time.minute;
    final startInMinutes = start.hour * 60 + start.minute;
    final endInMinutes = end.hour * 60 + end.minute;

    // Calculate slot end time (+30 minutes)
    final slotEndInMinutes = timeInMinutes + 30;

    // Slot is available if: slot_start >= operating_start AND slot_end <= operating_end
    return timeInMinutes >= startInMinutes && slotEndInMinutes <= endInMinutes;
  }

  /// Check if a time slot overlaps with any reservation
  bool _overlapsWithReservation(
    DateTime slot,
    List<PlaceReservation> reservations,
  ) {
    // 30-minute slot: [slot, slot+30min)
    final slotEnd = slot.add(const Duration(minutes: 30));

    for (final reservation in reservations) {
      final resStart = reservation.startDateTime;
      final resEnd = reservation.endDateTime;

      // Check overlap: slot overlaps if it starts before reservation ends
      // and ends after reservation starts
      if (slot.isBefore(resEnd) && slotEnd.isAfter(resStart)) {
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Build selected groups list for header
    final selectedGroupsList = _availableGroups
        .where((g) => _selectedGroupIds.contains(g.id))
        .map((g) => (
              id: g.id,
              name: g.name,
              color: _getGroupColor(g.id),
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('데모 캘린더'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly navigation header with place selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: WeeklyNavigationHeader(
                    initialWeekStart: _weekStart,
                    onWeekChanged: (newWeekStart) {
                      setState(() {
                        _weekStart = newWeekStart;
                      });
                      // Reload events for all selected groups with new week
                      for (final groupId in _selectedGroupIds) {
                        _loadEventsForGroup(groupId);
                      }
                    },
                    onAddPressed: (_) => _showGroupPicker(),
                    showAddButton: true,
                    showTodayButton: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Place selection button
                Flexible(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.place),
                      label: const Text('장소'),
                      onPressed: _showPlacePicker,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Group selection header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: GroupSelectionHeader(
              selectedGroups: selectedGroupsList,
              eventCounts: _eventCountByGroup,
              loadingByGroup: _loadingByGroup,
              errorByGroup: _errorByGroup,
              onAddGroupPressed: _showGroupPicker,
              onRemoveGroupPressed: (groupId) => _toggleGroup(groupId, false),
              onRetryPressed: _loadEventsForGroup,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Weekly schedule editor with group events
          Expanded(
            child: WeeklyScheduleEditor(
              allowMultiDaySelection: false,
              isEditable: true,
              allowEventOverlap: true,
              externalEvents: _getAllGroupEvents(),
              weekStart: _weekStart,
              groupColors: _getGroupColorsMap(),
              disabledSlots: _disabledSlots,
            ),
          ),
        ],
      ),
    );
  }
}
