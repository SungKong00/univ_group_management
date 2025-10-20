import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import '../../../core/models/calendar/group_event.dart';
import '../../../core/models/place/place.dart';
import '../../../core/models/place/operating_hours_response.dart';
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
  Map<int, Set<DateTime>> _disabledSlotsByPlace = {};

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(DateTime.now());
    _loadAvailableGroups();
  }

  /// Get week start (Monday) from any date
  DateTime _getWeekStart(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    // Normalize to 00:00:00 to prevent dayIndex calculation errors
    return DateTime(monday.year, monday.month, monday.day);
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
        developer.log(
          '🏢 Single place selected: ${selectedPlaces[0].displayName}',
          name: 'DemoCalendarPage',
        );

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

          developer.log(
            '🔄 Calling _calculateDisabledSlots() for single place',
            name: 'DemoCalendarPage',
          );

          // Calculate disabled slots for single place
          _calculateDisabledSlots();
        }
      }
      // Multiple places: show duration input dialog
      else if (selectedPlaces.length >= 2) {
        developer.log(
          '🏢 Multiple places selected: ${selectedPlaces.length} places',
          name: 'DemoCalendarPage',
        );

        final duration = await showDialog<Duration>(
          context: context,
          builder: (context) => const DurationInputDialog(),
        );

        if (duration != null && mounted) {
          developer.log(
            '⏱️ Duration selected: ${_formatDuration(duration)}',
            name: 'DemoCalendarPage',
          );

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

          developer.log(
            '🔄 Calling _calculateDisabledSlots() for multiple places',
            name: 'DemoCalendarPage',
          );

          // Calculate disabled slots for multiple places
          _calculateDisabledSlots();
        } else {
          developer.log(
            '⚠️ Duration dialog cancelled or widget unmounted',
            name: 'DemoCalendarPage',
          );
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
    developer.log(
      '🔍 === _calculateDisabledSlots() CALLED ===',
      name: 'DemoCalendarPage',
    );

    developer.log(
      '📋 Selected places: ${_selectedPlaces.length}',
      name: 'DemoCalendarPage',
    );
    for (final place in _selectedPlaces) {
      developer.log(
        '  - Place ID: ${place.id}, Name: ${place.displayName}',
        name: 'DemoCalendarPage',
      );
    }

    if (_selectedPlaces.isEmpty) {
      developer.log(
        '⚠️ No places selected, clearing disabled slots',
        name: 'DemoCalendarPage',
      );
      setState(() {
        _disabledSlots = {};
      });
      return;
    }

    try {
      developer.log(
        '🔍 Calculating disabled slots for ${_selectedPlaces.length} places',
        name: 'DemoCalendarPage',
      );

      // Week end: Sunday (6 days from week start)
      final weekEnd = _weekStart.add(const Duration(days: 6));

      // Collect unavailable slots for all places
      final Set<DateTime> allDisabledSlots = {};
      final Map<int, Set<DateTime>> disabledSlotsByPlace = {};

      for (final place in _selectedPlaces) {
        developer.log(
          '📡 Fetching place detail for place ${place.id} (${place.displayName})',
          name: 'DemoCalendarPage',
        );

        // 1. Get place detail (includes availability)
        final placeDetail = await _placeService.getPlaceDetail(place.id);
        if (placeDetail == null) {
          developer.log(
            '❌ Failed to fetch place detail for place ${place.id}',
            name: 'DemoCalendarPage',
            level: 900,
          );
          continue;
        }

        developer.log(
          '✅ Successfully fetched place detail for place ${place.id}',
          name: 'DemoCalendarPage',
        );
        developer.log(
          '📊 Place has ${placeDetail.operatingHours.length} operating hours entries',
          name: 'DemoCalendarPage',
        );
        for (final oh in placeDetail.operatingHours) {
          final status = oh.isClosed ? '(CLOSED)' : '';
          developer.log(
            '  - ${oh.dayOfWeek.displayName}: ${oh.startTime.format(context)} ~ ${oh.endTime.format(context)} $status',
            name: 'DemoCalendarPage',
          );
        }

        // 2. Get reservations for the week
        final reservations = await _placeService.getReservations(
          placeId: place.id,
          startDate: _weekStart,
          endDate: weekEnd,
        );

        // 3. Calculate disabled slots for this place
        final placeDisabledSlots = _calculateDisabledSlotsForPlace(
          operatingHours: placeDetail.operatingHours,
          reservations: reservations,
          weekStart: _weekStart,
        );

        // 4. Store per-place disabled slots
        disabledSlotsByPlace[place.id] = placeDisabledSlots;

        // 5. Add to union for global disabled slots
        allDisabledSlots.addAll(placeDisabledSlots);
      }

      if (!mounted) return;

      setState(() {
        _disabledSlots = allDisabledSlots;
        _disabledSlotsByPlace = disabledSlotsByPlace;
      });

      developer.log(
        'Calculated ${allDisabledSlots.length} total disabled slots '
        'across ${disabledSlotsByPlace.length} places',
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
    required List<OperatingHoursResponse> operatingHours,
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

      // Get operating hours for this day
      final dayOperatingHours = operatingHours
          .where((oh) => oh.dayOfWeek == dayOfWeekEnum)
          .firstOrNull;

      // Debug log: print operating hours for each day
      developer.log(
        'Day $dayOfWeekEnum (${currentDate.month}/${currentDate.day}): '
        'Operating Hours: ${dayOperatingHours != null ? "${dayOperatingHours.startTime.hour.toString().padLeft(2, '0')}:${dayOperatingHours.startTime.minute.toString().padLeft(2, '0')} ~ ${dayOperatingHours.endTime.hour.toString().padLeft(2, '0')}:${dayOperatingHours.endTime.minute.toString().padLeft(2, '0')}" : "CLOSED"}',
        name: 'DemoCalendarPage',
      );

      if (dayOperatingHours != null && !dayOperatingHours.isClosed) {
        developer.log(
          '  → ${dayOperatingHours.startTime.hour.toString().padLeft(2, '0')}:'
          '${dayOperatingHours.startTime.minute.toString().padLeft(2, '0')} ~ '
          '${dayOperatingHours.endTime.hour.toString().padLeft(2, '0')}:'
          '${dayOperatingHours.endTime.minute.toString().padLeft(2, '0')}',
          name: 'DemoCalendarPage',
        );
      } else {
        developer.log(
          '  ⚠️ Place is closed on this day (all slots will be disabled)',
          name: 'DemoCalendarPage',
          level: 900,
        );
      }

      // Iterate through 15-minute slots (00:00 ~ 23:45)
      // UI uses 15-minute granularity by splitting 30-minute cells in half
      for (int hour = 0; hour < 24; hour++) {
        for (int minute = 0; minute < 60; minute += 15) {
          final slot = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            hour,
            minute,
          );

          // Check if slot is outside operating hours
          if (!_isWithinOperatingHours(slot, dayOperatingHours)) {
            disabled.add(slot);
            continue;
          }

          // Check if slot overlaps with existing reservation
          if (_overlapsWithReservation(slot, reservations)) {
            disabled.add(slot);
            continue;
          }

          // TODO: Add PlaceBlockedTime check when backend API is implemented
          // if (_isBlockedTime(slot, blockedTimes)) {
          //   disabled.add(slot);
          //   continue;
          // }
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
  /// Returns true if the slot falls within the place's operating hours for that day
  bool _isWithinOperatingHours(
    DateTime slot,
    OperatingHoursResponse? operatingHours,
  ) {
    if (operatingHours == null || operatingHours.isClosed) {
      return false; // Closed = not available
    }

    final startTime = operatingHours.startTime;
    final endTime = operatingHours.endTime;

    // Convert slot to TimeOfDay
    final slotTime = TimeOfDay(hour: slot.hour, minute: slot.minute);

    // Compare time only (ignore date)
    if (_isTimeInRange(slotTime, startTime, endTime)) {
      return true;
    }

    return false;
  }

  /// Check if a TimeOfDay is within a time range
  ///
  /// IMPORTANT: Checks if a 15-minute slot starting at [time] is fully within [start]-[end].
  /// A slot is available only if both its start AND end (+15min) are within operating hours.
  /// Example: Operating hours 09:00-18:00 allows slots from 09:00 to 17:45 (last slot ends at 18:00)
  bool _isTimeInRange(TimeOfDay time, TimeOfDay start, TimeOfDay end) {
    final timeInMinutes = time.hour * 60 + time.minute;
    final startInMinutes = start.hour * 60 + start.minute;
    final endInMinutes = end.hour * 60 + end.minute;

    // Calculate slot end time (+15 minutes)
    final slotEndInMinutes = timeInMinutes + 15;

    // Slot is available if: slot_start >= operating_start AND slot_end <= operating_end
    return timeInMinutes >= startInMinutes && slotEndInMinutes <= endInMinutes;
  }

  /// Check if a time slot overlaps with any reservation
  bool _overlapsWithReservation(
    DateTime slot,
    List<PlaceReservation> reservations,
  ) {
    // 15-minute slot: [slot, slot+15min)
    final slotEnd = slot.add(const Duration(minutes: 15));

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
          // Row 1: Weekly navigation header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: WeeklyNavigationHeader(
              initialWeekStart: _weekStart,
              onWeekChanged: (newWeekStart) {
                developer.log(
                  '📅 Week changed: ${newWeekStart.toString().substring(0, 10)}',
                  name: 'DemoCalendarPage',
                );
                developer.log(
                  '📍 Currently selected places: ${_selectedPlaces.length}',
                  name: 'DemoCalendarPage',
                );

                setState(() {
                  _weekStart = newWeekStart;
                });

                // Reload events for all selected groups with new week
                for (final groupId in _selectedGroupIds) {
                  _loadEventsForGroup(groupId);
                }

                // Reload place data for new week if places are selected
                if (_selectedPlaces.isNotEmpty) {
                  developer.log(
                    '🔄 Recalculating disabled slots for new week',
                    name: 'DemoCalendarPage',
                  );
                  _calculateDisabledSlots();
                }
              },
              showAddButton: false,
              showTodayButton: true,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Row 2: Chips (left) + Buttons (right)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                // Left: Group chips + Place chips (horizontal scroll)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Group chips
                        ...selectedGroupsList.map((group) {
                          final isLoading = _loadingByGroup[group.id] ?? false;
                          final error = _errorByGroup[group.id];
                          final eventCount = _eventCountByGroup[group.id] ?? 0;

                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.xs),
                            child: Chip(
                              avatar: CircleAvatar(
                                backgroundColor: group.color,
                                radius: 6,
                              ),
                              label: Text(
                                '${group.name} ($eventCount개)',
                                style: const TextStyle(fontSize: 12),
                              ),
                              deleteIcon: isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : error != null
                                      ? Tooltip(
                                          message: '재시도: $error',
                                          child: const Icon(Icons.error_outline, size: 16),
                                        )
                                      : Tooltip(
                                          message: '제거',
                                          child: const Icon(Icons.close, size: 16),
                                        ),
                              onDeleted: error != null
                                  ? () => _loadEventsForGroup(group.id)
                                  : () => _toggleGroup(group.id, false),
                            ),
                          );
                        }).toList(),
                        // Place chips
                        ..._selectedPlaces.map((place) {
                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.xs),
                            child: Chip(
                              avatar: const Icon(Icons.place, size: 16),
                              label: Text(
                                '${place.building} ${place.roomNumber}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              onDeleted: () {
                                setState(() {
                                  _selectedPlaces.removeWhere((p) => p.id == place.id);
                                  _requiredDuration = null;
                                  _calculateDisabledSlots();
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${place.building} ${place.roomNumber} 선택이 해제되었습니다',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              deleteIconColor: AppColors.neutral600,
                              backgroundColor: AppColors.brandLight,
                              labelStyle: TextStyle(color: AppColors.neutral900),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Right: Place button
                OutlinedButton.icon(
                  icon: const Icon(Icons.place, size: 16),
                  label: const Text('장소추가', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  ),
                  onPressed: _showPlacePicker,
                ),
                const SizedBox(width: AppSpacing.xs),

                // Right: Group button
                OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('그룹추가', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  ),
                  onPressed: _showGroupPicker,
                ),
              ],
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
              availablePlaces: _selectedPlaces,
              disabledSlotsByPlace: _disabledSlotsByPlace,
              preSelectedPlaceId: _selectedPlaces.length == 1 ? _selectedPlaces.first.id : null,
            ),
          ),
        ],
      ),
    );
  }
}
