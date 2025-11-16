import 'package:flutter/material.dart';
import '../../../../core/utils/snack_bar_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/enums/calendar_view.dart';
import '../../../../core/models/calendar/group_event.dart';
import '../../../../core/models/calendar/update_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../adapters/group_event_adapter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/calendar_view_provider.dart';
import '../../../providers/focused_date_provider.dart';
import '../../../providers/group_calendar_provider.dart';
import '../../../providers/group_permission_provider.dart';
import '../../../utils/responsive_layout_helper.dart';
import '../../../widgets/common/compact_tab_bar.dart';
import '../../../widgets/organisms/organisms.dart';
import '../../../widgets/calendar/calendar_navigator.dart';
import '../../calendar/widgets/calendar_month_with_sidebar.dart';
import '../../calendar/widgets/month_event_chip.dart';
import '../../../widgets/weekly_calendar/weekly_schedule_editor.dart';
import 'widgets/group_event_form_dialog.dart';
import 'widgets/place_calendar_tab.dart';
import '../../../widgets/buttons/neutral_outlined_button.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/buttons/calendar_add_button.dart';

/// Event formality categories for single-step selector
/// Matches Phase 6 UI design: Step 1 - Official/Unofficial selection
enum EventFormalityCategory {
  official('공식 일정', Icons.event, '그룹 전체에 공지되는 공식 행사'),
  unofficial('비공식 일정', Icons.event_note, '개인 또는 소그룹 모임');

  const EventFormalityCategory(this.title, this.icon, this.description);
  final String title;
  final IconData icon;
  final String description;
}

/// Main page for group calendar.
class GroupCalendarPage extends ConsumerStatefulWidget {
  final int groupId;
  final DateTime? initialSelectedDate;

  const GroupCalendarPage({
    super.key,
    required this.groupId,
    this.initialSelectedDate,
  });

  @override
  ConsumerState<GroupCalendarPage> createState() => _GroupCalendarPageState();
}

class _GroupCalendarPageState extends ConsumerState<GroupCalendarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set initial selected date if provided
      if (widget.initialSelectedDate != null) {
        ref
            .read(focusedDateProvider.notifier)
            .setDate(widget.initialSelectedDate!);
      }
      _loadEvents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final focusedDate = ref.read(focusedDateProvider);
    final startOfMonth = DateTime(focusedDate.year, focusedDate.month, 1);
    final endOfMonth = DateTime(focusedDate.year, focusedDate.month + 1, 0);

    await ref
        .read(groupCalendarProvider(widget.groupId).notifier)
        .loadEvents(
          groupId: widget.groupId,
          startDate: startOfMonth,
          endDate: endOfMonth,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(child: _buildTabContent()),
      ],
    );
  }

  Widget _buildTabBar() {
    return CompactTabBar(
      controller: _tabController,
      tabs: const [
        CompactTab(label: '그룹 캘린더'),
        CompactTab(label: '장소 캘린더'),
      ],
      dividerColor: AppColors.neutral200,
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [_buildGroupCalendarTab(), _buildPlaceCalendarTab()],
    );
  }

  Widget _buildGroupCalendarTab() {
    final state = ref.watch(groupCalendarProvider(widget.groupId));
    final currentView = ref.watch(calendarViewProvider);
    final focusedDate = ref.watch(focusedDateProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: _buildCalendarHeader(
            currentView,
            focusedDate,
            state.isLoading,
          ),
        ),
        Expanded(child: _buildCalendarContent(state, currentView)),
      ],
    );
  }

  Widget _buildCalendarContent(dynamic state, CalendarView view) {
    final focusedDate = ref.watch(focusedDateProvider);

    // Phase 4: Month view with sidebar
    if (view == CalendarView.month) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: CalendarMonthWithSidebar<GroupEvent>(
          events: state.events,
          focusedDate: focusedDate,
          selectedDate: focusedDate, // Use focusedDate as default selection
          onDateSelected: (selected, focused) {
            ref.read(focusedDateProvider.notifier).setDate(selected);
          },
          onPageChanged: (focused) {
            ref.read(focusedDateProvider.notifier).setDate(focused);
          },
          onEventTap: _showEventDetail,
          eventChipBuilder: (event) =>
              MonthEventChip(label: event.title, color: event.color),
        ),
      );
    }

    // Phase 3: Week view
    if (view == CalendarView.week) {
      final weekStart = _getWeekStart(focusedDate);

      // Convert GroupEvent to Event for WeeklyScheduleEditor
      final events = state.events
          .map((event) => GroupEventAdapter.toEvent(event, weekStart))
          .whereType<Event>() // Filter out null values (all-day events)
          .toList();

      // Check permissions for editing
      final permissionsAsync = ref.watch(
        groupPermissionsProvider(widget.groupId),
      );
      final canEdit = permissionsAsync.maybeWhen(
        data: (permissions) => permissions.contains('CALENDAR_MANAGE'),
        orElse: () => false,
      );

      return Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          bottom: 80,
        ),
        child: WeeklyScheduleEditor(
          allowMultiDaySelection: false, // Group events are single-day only
          isEditable: canEdit,
          allowEventOverlap: true,
          weekStart: weekStart,
          initialEvents: events,
          onEventCreate: (event) => _handleEventCreate(event, weekStart),
          onEventUpdate: (event) => _handleEventUpdate(event, weekStart),
          onEventDelete: (event) => _handleEventDelete(event),
        ),
      );
    }

    // Fallback (should not reach here)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          '지원하지 않는 뷰: ${_getViewName(view)}',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Get Monday of the week containing the given date
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1 (Monday) to 7 (Sunday)
    return date.subtract(Duration(days: weekday - 1));
  }

  String _getViewName(CalendarView view) {
    switch (view) {
      case CalendarView.week:
        return '주간';
      case CalendarView.month:
        return '월간';
    }
  }

  String _formatFocusedLabel(DateTime date, CalendarView view) {
    switch (view) {
      case CalendarView.week:
        final weekStart = _getWeekStart(date);
        return DateFormatter.formatWeekHeader(weekStart);
      case CalendarView.month:
        return DateFormat('yyyy년 M월', 'ko_KR').format(date);
    }
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

  Widget _buildPlaceCalendarTab() {
    return PlaceCalendarTab(groupId: widget.groupId);
  }

  Widget _buildCalendarHeader(
    CalendarView currentView,
    DateTime focusedDate,
    bool isBusy,
  ) {
    final viewToggle = ToggleButtons(
      isSelected: CalendarView.values
          .map((option) => option == currentView)
          .toList(growable: false),
      onPressed: (index) {
        final newView = CalendarView.values.elementAt(index);
        if (newView != currentView) {
          ref.read(calendarViewProvider.notifier).setView(newView);
        }
      },
      borderRadius: BorderRadius.circular(AppRadius.button),
      fillColor: AppColors.brand.withValues(alpha: 0.08),
      selectedColor: AppColors.brand,
      constraints: const BoxConstraints(minHeight: 36, minWidth: 56),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text('주간', style: TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text('월간', style: TextStyle(fontSize: 13)),
        ),
      ],
    );

    final addButton = CalendarAddButton(
      onPressed: () => _showCreateDialog(),
      isLoading: isBusy,
    );

    final weekStart = currentView == CalendarView.week
        ? _getWeekStart(focusedDate)
        : null;

    final navigator = CalendarNavigator(
      currentDate: focusedDate,
      label: _formatFocusedLabel(focusedDate, currentView),
      subtitle: weekStart != null
          ? DateFormatter.formatWeekRangeDetailed(weekStart)
          : null,
      isWeekView: currentView == CalendarView.week,
      onPrevious: isBusy ? () {} : () => _handlePrevious(currentView),
      onNext: isBusy ? () {} : () => _handleNext(currentView),
      onToday: isBusy
          ? () {}
          : () => ref.read(focusedDateProvider.notifier).resetToToday(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final helper = ResponsiveLayoutHelper(
          context: context,
          constraints: constraints,
        );
        final isCompact = !helper.isWideDesktop;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: navigator),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: viewToggle,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  addButton,
                ],
              ),
            ],
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                viewToggle,
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Center(child: navigator)),
                const SizedBox(width: AppSpacing.sm),
                addButton,
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateRange(DateTime start, DateTime end, bool isAllDay) {
    final dateFormat = 'yyyy-MM-dd';
    final timeFormat = 'HH:mm';

    if (isAllDay) {
      if (start.year == end.year &&
          start.month == end.month &&
          start.day == end.day) {
        return '$dateFormat (종일)';
      }
      return '${_format(start, dateFormat)} ~ ${_format(end, dateFormat)} (종일)';
    }

    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '${_format(start, dateFormat)} ${_format(start, timeFormat)} ~ ${_format(end, timeFormat)}';
    }

    return '${_format(start, '$dateFormat $timeFormat')} ~ ${_format(end, '$dateFormat $timeFormat')}';
  }

  String _format(DateTime date, String pattern) {
    if (pattern == 'yyyy-MM-dd') {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } else if (pattern == 'HH:mm') {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _showCreateDialog() async {
    // Phase 6 UI Flow: Step 1 - Official/Unofficial selection (permission-based)
    final focusedDate = ref.read(focusedDateProvider);

    // Check user's CALENDAR_MANAGE permission
    final permissionsAsync = ref.read(groupPermissionsProvider(widget.groupId));

    // Wait for permissions to load if not already loaded
    final permissions = await permissionsAsync.when(
      data: (permissions) async => permissions,
      loading: () async {
        return await ref.read(groupPermissionsProvider(widget.groupId).future);
      },
      error: (_, __) async => <String>{},
    );

    if (!mounted) return;

    final canCreateOfficial = permissions.contains('CALENDAR_MANAGE');

    // Step 1: Official/Unofficial selection (only for users with permission)
    if (canCreateOfficial) {
      final selectedFormality =
          await showSingleStepSelector<EventFormalityCategory>(
            context: context,
            title: '새 일정 만들기',
            subtitle: '일정의 공개 범위를 선택하세요',
            options: [
              SelectableOption(
                value: EventFormalityCategory.official,
                title: EventFormalityCategory.official.title,
                description: EventFormalityCategory.official.description,
                icon: EventFormalityCategory.official.icon,
              ),
              SelectableOption(
                value: EventFormalityCategory.unofficial,
                title: EventFormalityCategory.unofficial.title,
                description: EventFormalityCategory.unofficial.description,
                icon: EventFormalityCategory.unofficial.icon,
              ),
            ],
          );

      if (selectedFormality == null) return;
      if (!mounted) return;

      // Step 2: Show event form with selected formality
      final isOfficial = selectedFormality == EventFormalityCategory.official;
      await _createGroupEvent(isOfficial: isOfficial, anchorDate: focusedDate);
    } else {
      // No permission: Skip Step 1, create unofficial event directly
      await _createGroupEvent(isOfficial: false, anchorDate: focusedDate);
    }
  }

  Future<void> _createGroupEvent({
    required bool isOfficial,
    required DateTime anchorDate,
  }) async {
    EventType selectedType = EventType.general;

    // Step 2: 공식 일정일 경우 유형 선택
    if (isOfficial) {
      final selected = await showSingleStepSelector<EventType>(
        context: context,
        title: '공식 일정 유형 선택',
        subtitle: '어떤 유형의 공식 일정을 만드시겠습니까?',
        options: EventType.values
            .map(
              (type) => SelectableOption(
                value: type,
                title: type.title,
                description: type.description,
                icon: type.icon,
              ),
            )
            .toList(),
      );

      if (selected == null) return; // 취소
      if (!mounted) return;

      selectedType = selected;
    }

    // Step 3: Show event form dialog with pre-determined formality and type
    final result = await showGroupEventFormDialog(
      context,
      groupId: widget.groupId,
      anchorDate: anchorDate,
      canCreateOfficial: isOfficial,
      initialIsOfficial: isOfficial,
      eventType: selectedType,
    );

    if (result != null) {
      if (!mounted) return;

      try {
        // Determine location parameters for API
        final locationText = result.locationText ?? '';
        final placeId = result.place?.id;

        await ref
            .read(groupCalendarProvider(widget.groupId).notifier)
            .createEvent(
              groupId: widget.groupId,
              title: result.title,
              description: result.description,
              locationText: locationText,
              placeId: placeId,
              startDate: result.startDate,
              endDate: result.endDate,
              isAllDay: result.isAllDay,
              isOfficial: result.isOfficial,
              color: result.color.toHex(),
              recurrence: result.recurrence,
            );

        if (!mounted) return;
        AppSnackBar.info(context, '일정이 추가되었습니다');
      } catch (e) {
        if (!mounted) return;
        AppSnackBar.info(context, '일정 추가 실패: ${e.toString()}');
      }
    }
  }

  /// Check if the current user can modify the given event.
  bool _canModifyEvent(GroupEvent event) {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return false;

    // Check if user has CALENDAR_MANAGE permission
    final permissionsAsync = ref.read(groupPermissionsProvider(widget.groupId));
    final hasCalendarManage = permissionsAsync.maybeWhen(
      data: (permissions) => permissions.contains('CALENDAR_MANAGE'),
      orElse: () => false,
    );

    // Official events: Require CALENDAR_MANAGE permission
    if (event.isOfficial) {
      return hasCalendarManage;
    }

    // Unofficial events: Creator or CALENDAR_MANAGE
    return event.creatorId == currentUser.id || hasCalendarManage;
  }

  Future<void> _showEventDetail(GroupEvent event) async {
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
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: event.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (event.isOfficial)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.brandLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '공식',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.brand,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            if (event.isRecurring) ...[
                              if (event.isOfficial) const SizedBox(width: 8),
                              const Icon(Icons.repeat, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '반복',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_canModifyEvent(event))
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showEventActions(event);
                      },
                    ),
                ],
              ),
              const Divider(height: AppSpacing.md),
              _buildDetailRow(
                Icons.schedule,
                '시간',
                _formatDateRange(
                  event.startDate,
                  event.endDate,
                  event.isAllDay,
                ),
              ),
              if (event.location != null)
                _buildDetailRow(Icons.place, '장소', event.location!),
              if (event.description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildDetailRow(Icons.notes, '설명', event.description!),
              ],
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(Icons.person, '작성자', event.creatorName),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '생성: ${_formatDateTime(event.createdAt)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.neutral600),
              ),
              Text(
                '수정: ${_formatDateTime(event.updatedAt)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.neutral600),
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
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.neutral600),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_format(dateTime, 'yyyy-MM-dd')} ${_format(dateTime, 'HH:mm')}';
  }

  Future<void> _showEventActions(GroupEvent event) async {
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
                leading: const Icon(Icons.edit, color: AppColors.action),
                title: const Text('수정'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleEditEvent(event);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('삭제'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleDeleteEvent(event);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('취소'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleEditEvent(GroupEvent event) async {
    UpdateScope? updateScope;

    if (event.isRecurring) {
      updateScope = await _showUpdateScopeDialog();
      if (updateScope == null) return; // User cancelled
      if (!mounted) return;
    }

    if (!mounted) return;

    final result = await showGroupEventFormDialog(
      context,
      groupId: widget.groupId,
      initial: event,
      canCreateOfficial: event.isOfficial, // Keep the same official status
    );

    if (result != null) {
      if (!mounted) return;

      try {
        // Determine location parameters for API
        final locationText = result.locationText ?? '';
        final placeId = result.place?.id;

        await ref
            .read(groupCalendarProvider(widget.groupId).notifier)
            .updateEvent(
              groupId: widget.groupId,
              eventId: event.id,
              title: result.title,
              description: result.description,
              locationText: locationText,
              placeId: placeId,
              startDate: result.startDate,
              endDate: result.endDate,
              isAllDay: result.isAllDay,
              color: result.color.toHex(),
              updateScope: updateScope ?? UpdateScope.thisEvent,
            );

        if (!mounted) return;
        AppSnackBar.info(context, '일정이 수정되었습니다');
      } catch (e) {
        if (!mounted) return;
        AppSnackBar.info(context, '일정 수정 실패: ${e.toString()}');
      }
    }
  }

  Future<void> _handleDeleteEvent(GroupEvent event) async {
    UpdateScope? deleteScope;

    if (event.isRecurring) {
      deleteScope = await _showUpdateScopeDialog(isDelete: true);
      if (deleteScope == null) return; // User cancelled
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 삭제'),
        content: Text(
          event.isRecurring && deleteScope == UpdateScope.allEvents
              ? '이후 모든 반복 일정이 삭제됩니다. 계속하시겠습니까?'
              : '이 일정을 삭제하시겠습니까?',
        ),
        actions: [
          NeutralOutlinedButton(
            text: '취소',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          PrimaryButton(
            text: '삭제',
            onPressed: () => Navigator.of(context).pop(true),
            variant: PrimaryButtonVariant.error,
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;

      try {
        await ref
            .read(groupCalendarProvider(widget.groupId).notifier)
            .deleteEvent(
              groupId: widget.groupId,
              eventId: event.id,
              deleteScope: deleteScope ?? UpdateScope.thisEvent,
            );

        if (!mounted) return;
        AppSnackBar.info(context, '일정이 삭제되었습니다');
      } catch (e) {
        if (!mounted) return;
        AppSnackBar.info(context, '일정 삭제 실패: ${e.toString()}');
      }
    }
  }

  Future<UpdateScope?> _showUpdateScopeDialog({bool isDelete = false}) async {
    return showDialog<UpdateScope>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDelete ? '반복 일정 삭제' : '반복 일정 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isDelete ? '어떤 일정을 삭제하시겠습니까?' : '어떤 일정을 수정하시겠습니까?'),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              text: '이 일정만',
              onPressed: () => Navigator.of(context).pop(UpdateScope.thisEvent),
              variant: PrimaryButtonVariant.brand,
            ),
            const SizedBox(height: AppSpacing.xs),
            PrimaryButton(
              text: '이후 모든 반복 일정',
              onPressed: () => Navigator.of(context).pop(UpdateScope.allEvents),
              variant: PrimaryButtonVariant.brand,
            ),
          ],
        ),
        actions: [
          NeutralOutlinedButton(
            text: '취소',
            onPressed: () => Navigator.of(context).pop(null),
          ),
        ],
      ),
    );
  }

  // --- CRUD Handlers for WeeklyScheduleEditor ---

  /// Handle event creation from drag gesture
  Future<bool> _handleEventCreate(Event event, DateTime weekStart) async {
    // Step 1: Check permissions
    final permissions = await ref.read(
      groupPermissionsProvider(widget.groupId).future,
    );
    final canCreateOfficial = permissions.contains('CALENDAR_MANAGE');

    // Step 2: Official/Unofficial selection (only for users with permission)
    bool isOfficial = false;
    if (canCreateOfficial) {
      if (!mounted) return false;
      final selectedFormality =
          await showSingleStepSelector<EventFormalityCategory>(
            context: context,
            title: '새 일정 만들기',
            subtitle: '일정의 공개 범위를 선택하세요',
            options: [
              SelectableOption(
                value: EventFormalityCategory.official,
                title: EventFormalityCategory.official.title,
                description: EventFormalityCategory.official.description,
                icon: EventFormalityCategory.official.icon,
              ),
              SelectableOption(
                value: EventFormalityCategory.unofficial,
                title: EventFormalityCategory.unofficial.title,
                description: EventFormalityCategory.unofficial.description,
                icon: EventFormalityCategory.unofficial.icon,
              ),
            ],
          );

      if (selectedFormality == null) return false; // User cancelled
      if (!mounted) return false;

      isOfficial = selectedFormality == EventFormalityCategory.official;
    }

    // Step 2.5: Event type selection for official events
    EventType selectedType = EventType.general;
    if (isOfficial) {
      if (!mounted) return false;
      final selected = await showSingleStepSelector<EventType>(
        context: context,
        title: '공식 일정 유형 선택',
        subtitle: '어떤 유형의 공식 일정을 만드시겠습니까?',
        options: EventType.values
            .map(
              (type) => SelectableOption(
                value: type,
                title: type.title,
                description: type.description,
                icon: type.icon,
              ),
            )
            .toList(),
      );

      if (selected == null) return false; // User cancelled
      if (!mounted) return false;
      selectedType = selected;
    }

    // Step 3: Show event form dialog with pre-filled time
    if (!mounted) return false;
    final result = await showGroupEventFormDialog(
      context,
      groupId: widget.groupId,
      anchorDate: weekStart.add(Duration(days: event.start.day)),
      canCreateOfficial: canCreateOfficial,
      initialIsOfficial: isOfficial,
      eventType: selectedType,
      // Pre-fill time from drag gesture
      initialStartTime: event.startTime,
      initialEndTime: event.endTime,
    );

    if (result == null) return false;
    if (!mounted) return false;

    // Step 4: API call
    try {
      await ref
          .read(groupCalendarProvider(widget.groupId).notifier)
          .createEvent(
            groupId: widget.groupId,
            title: result.title,
            description: result.description,
            locationText: result.locationText ?? '',
            placeId: result.place?.id,
            startDate: result.startDate,
            endDate: result.endDate,
            isAllDay: result.isAllDay,
            isOfficial: result.isOfficial,
            color: result.color.toHex(),
            recurrence: result.recurrence,
          );

      if (!mounted) return false;
      AppSnackBar.info(context, '일정이 추가되었습니다');
      return true;
    } catch (e) {
      if (!mounted) return false;
      AppSnackBar.error(context, '일정 추가 실패: ${e.toString()}');
      return false;
    }
  }

  /// Handle event update from drag gesture or click
  Future<bool> _handleEventUpdate(Event event, DateTime weekStart) async {
    // Step 1: Find original GroupEvent
    final eventId = GroupEventAdapter.extractEventId(event.id);
    if (eventId == null) {
      AppSnackBar.error(context, '잘못된 일정 ID입니다');
      return false;
    }

    final state = ref.read(groupCalendarProvider(widget.groupId));
    GroupEvent? originalEvent;
    try {
      originalEvent = state.events.firstWhere((e) => e.id == eventId);
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, '일정을 찾을 수 없습니다');
      }
      return false;
    }

    // Step 2: Check if recurring
    UpdateScope? updateScope;
    if (originalEvent.isRecurring) {
      updateScope = await _showUpdateScopeDialog();
      if (updateScope == null) return false; // User cancelled
      if (!mounted) return false;
    }

    // Step 3: Show event form dialog with updated time
    if (!mounted) return false;
    final result = await showGroupEventFormDialog(
      context,
      groupId: widget.groupId,
      initial: originalEvent,
      canCreateOfficial: originalEvent.isOfficial,
      // Pre-fill time from drag gesture
      initialStartTime: event.startTime,
      initialEndTime: event.endTime,
    );

    if (result == null) return false;
    if (!mounted) return false;

    // Step 4: API call
    try {
      await ref
          .read(groupCalendarProvider(widget.groupId).notifier)
          .updateEvent(
            groupId: widget.groupId,
            eventId: eventId,
            title: result.title,
            description: result.description,
            locationText: result.locationText ?? '',
            placeId: result.place?.id,
            startDate: result.startDate,
            endDate: result.endDate,
            isAllDay: result.isAllDay,
            color: result.color.toHex(),
            updateScope: updateScope ?? UpdateScope.thisEvent,
          );

      if (!mounted) return false;
      AppSnackBar.info(context, '일정이 수정되었습니다');
      return true;
    } catch (e) {
      if (!mounted) return false;
      AppSnackBar.error(context, '일정 수정 실패: ${e.toString()}');
      return false;
    }
  }

  /// Handle event deletion
  Future<bool> _handleEventDelete(Event event) async {
    // Step 1: Find original GroupEvent
    final eventId = GroupEventAdapter.extractEventId(event.id);
    if (eventId == null) {
      AppSnackBar.error(context, '잘못된 일정 ID입니다');
      return false;
    }

    final state = ref.read(groupCalendarProvider(widget.groupId));
    GroupEvent? originalEvent;
    try {
      originalEvent = state.events.firstWhere((e) => e.id == eventId);
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, '일정을 찾을 수 없습니다');
      }
      return false;
    }

    // Step 2: Confirmation dialog
    final eventTitle = originalEvent.title;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 삭제'),
        content: Text('정말 "$eventTitle" 일정을 삭제하시겠습니까?'),
        actions: [
          NeutralOutlinedButton(
            text: '취소',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          PrimaryButton(
            text: '삭제',
            onPressed: () => Navigator.of(context).pop(true),
            variant: PrimaryButtonVariant.error,
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return false;

    // Step 3: Check if recurring
    UpdateScope? deleteScope;
    if (originalEvent.isRecurring) {
      deleteScope = await _showUpdateScopeDialog(isDelete: true);
      if (deleteScope == null) return false;
      if (!mounted) return false;
    }

    // Step 4: API call
    try {
      await ref
          .read(groupCalendarProvider(widget.groupId).notifier)
          .deleteEvent(
            groupId: widget.groupId,
            eventId: eventId,
            deleteScope: deleteScope ?? UpdateScope.thisEvent,
          );

      if (!mounted) return false;
      AppSnackBar.info(context, '일정이 삭제되었습니다');
      return true;
    } catch (e) {
      if (!mounted) return false;
      AppSnackBar.error(context, '일정 삭제 실패: ${e.toString()}');
      return false;
    }
  }
}

extension on Color {
  String toHex() {
    return '#${(toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
