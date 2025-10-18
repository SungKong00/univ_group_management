import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import '../../../core/models/calendar/group_event.dart';
import '../../../core/services/group_calendar_service.dart';
import '../../../core/services/group_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/weekly_calendar/group_picker_bottom_sheet.dart';
import '../../widgets/weekly_calendar/group_selection_header.dart';
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
          // Weekly navigation header
          WeeklyNavigationHeader(
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
            ),
          ),
        ],
      ),
    );
  }
}
