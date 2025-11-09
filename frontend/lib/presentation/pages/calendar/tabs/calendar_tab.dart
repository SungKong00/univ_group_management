import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/calendar_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/snack_bar_helper.dart';
import '../../../adapters/personal_event_adapter.dart';
import '../../../providers/calendar_events_provider.dart';
import '../../../widgets/buttons/calendar_add_button.dart';
import '../../../widgets/calendar/calendar_error_banner.dart';
import '../../../widgets/calendar/calendar_event_card.dart';
import '../../../widgets/calendar/calendar_navigator.dart';
import '../../../widgets/dialogs/confirm_dialog.dart';
import '../../../widgets/weekly_calendar/weekly_schedule_editor.dart';
import '../widgets/calendar_month_with_sidebar.dart';
import '../widgets/event_detail_sheet.dart';
import '../widgets/event_form_dialog.dart';
import '../widgets/month_event_chip.dart';

/// 캘린더 탭 (개인 일정 월간/주간/일간 뷰)
class CalendarTab extends ConsumerStatefulWidget {
  const CalendarTab({super.key});

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calendarEventsProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarEventsProvider);
    final notifier = ref.read(calendarEventsProvider.notifier);

    ref.listen<CalendarEventsState>(calendarEventsProvider, (previous, next) {
      final message = next.snackbarMessage;
      if (message != null && message != previous?.snackbarMessage) {
        AppSnackBar.error(context, message);
        notifier.clearSnackbar();
      }
    });

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: _CalendarHeader(
          state: state,
          onPrevious: notifier.goToPreviousRange,
          onNext: notifier.goToNextRange,
          onToday: notifier.goToToday,
          onChangeView: notifier.changeView,
          onCreateEvent: state.isMutating
              ? null
              : () async {
                  final request = await showEventFormDialog(
                    context,
                    anchorDate: state.selectedDate,
                  );
                  if (request != null) {
                    await notifier.createEvent(request);
                  }
                },
        ),
      ),
      if (state.loadErrorMessage != null)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: CalendarErrorBanner(
            message: state.loadErrorMessage!,
            onRetry: notifier.refresh,
          ),
        ),
      if (state.isLoading)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: LinearProgressIndicator(minHeight: 2),
        ),
      if (state.isMutating)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: Colors.transparent,
            color: AppColors.brand,
          ),
        ),
      Expanded(child: _buildCalendarBody(context, state, notifier)),
    ];

    final screenWidth = MediaQuery.sizeOf(context).width;
    final shouldCenter = screenWidth < 1024;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );

    if (shouldCenter) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: SizedBox(width: double.infinity, child: content),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: content,
    );
  }

  Widget _buildCalendarBody(
    BuildContext context,
    CalendarEventsState state,
    CalendarEventsNotifier notifier,
  ) {
    switch (state.view) {
      case CalendarViewType.month:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: CalendarMonthWithSidebar<PersonalEvent>(
            events: state.events,
            focusedDate: state.focusedDate,
            selectedDate: state.selectedDate,
            onDateSelected: (selected, focused) => notifier.selectDate(selected),
            onPageChanged: notifier.setFocusedDate,
            onEventTap: (event) => _handleEventTap(context, notifier, event),
            eventChipBuilder: (event) => MonthEventChip(
              label: event.title,
              color: event.color,
            ),
          ),
        );
      case CalendarViewType.week:
        return _WeekCalendarView(state: state, notifier: notifier);
      case CalendarViewType.day:
        return _DayCalendarView(state: state, notifier: notifier);
    }
  }
}

/// 캘린더 헤더 (뷰 전환 + 네비게이션 + 일정 추가)
class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.state,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onChangeView,
    required this.onCreateEvent,
  });

  final CalendarEventsState state;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final void Function(CalendarViewType view) onChangeView;
  final VoidCallback? onCreateEvent;

  @override
  Widget build(BuildContext context) {
    final label = _buildLabel(
      state.view,
      state.focusedDate,
      state.selectedDate,
    );
    final subtitle = _buildSubtitle(
      state.view,
      state.focusedDate,
    );

    final viewTypes = [
      CalendarViewType.day,
      CalendarViewType.week,
      CalendarViewType.month,
    ];
    final viewToggle = ToggleButtons(
      isSelected: viewTypes.map((view) => view == state.view).toList(),
      onPressed: (index) => onChangeView(viewTypes[index]),
      borderRadius: BorderRadius.circular(AppRadius.button),
      fillColor: AppColors.brand.withValues(alpha: 0.08),
      selectedColor: AppColors.brand,
      constraints: const BoxConstraints(minHeight: 36, minWidth: 56),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text('일간', style: TextStyle(fontSize: 13)),
        ),
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
      onPressed: onCreateEvent,
      isLoading: state.isMutating,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;

            if (isCompact) {
              // 좁은 화면: 세로 배치
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 날짜 네비게이션 (상단 중앙)
                  CalendarNavigator(
                    currentDate: state.focusedDate,
                    label: label,
                    subtitle: subtitle,
                    isWeekView: state.view == CalendarViewType.week,
                    onPrevious: onPrevious,
                    onNext: onNext,
                    onToday: onToday,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // 하단: 뷰 토글 + 일정 추가
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: viewToggle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      addButton,
                    ],
                  ),
                ],
              );
            }

            // 넓은 화면: 가로 배치 (좌: 뷰 토글, 중앙: 네비게이션, 우: 일정 추가)
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 좌측: 뷰 전환 토글
                viewToggle,
                const SizedBox(width: AppSpacing.md),
                // 중앙: 날짜 네비게이션 (확장)
                Expanded(
                  child: Center(
                    child: CalendarNavigator(
                      currentDate: state.focusedDate,
                      label: label,
                      subtitle: subtitle,
                      isWeekView: state.view == CalendarViewType.week,
                      onPrevious: onPrevious,
                      onNext: onNext,
                      onToday: onToday,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // 우측: 일정 추가 버튼
                addButton,
              ],
            );
          },
        ),
      ),
    );
  }

  String _buildLabel(
    CalendarViewType view,
    DateTime focused,
    DateTime selected,
  ) {
    switch (view) {
      case CalendarViewType.month:
        return '${focused.year}년 ${focused.month}월';
      case CalendarViewType.week:
        final range = DateFormatter.weekRange(focused);
        return DateFormatter.formatWeekHeader(range.start);
      case CalendarViewType.day:
        return DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(selected);
    }
  }

  String? _buildSubtitle(
    CalendarViewType view,
    DateTime focused,
  ) {
    switch (view) {
      case CalendarViewType.week:
        final range = DateFormatter.weekRange(focused);
        return DateFormatter.formatWeekRangeDetailed(range.start);
      default:
        return null;
    }
  }
}

/// 주간 캘린더 뷰
class _WeekCalendarView extends StatelessWidget {
  const _WeekCalendarView({required this.state, required this.notifier});

  final CalendarEventsState state;
  final CalendarEventsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final range = DateFormatter.weekRange(state.focusedDate);
    final weekStart = range.start;

    // Convert PersonalEvent to Event for WeeklyScheduleEditor
    final events = state.events
        .map((event) => PersonalEventAdapter.toEvent(event, weekStart))
        .toList();

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        bottom: 80,
      ),
      child: WeeklyScheduleEditor(
        allowMultiDaySelection: false,
        isEditable: false, // Read-only mode for calendar view
        allowEventOverlap: true,
        weekStart: weekStart,
        initialEvents: events,
        initialMode: CalendarMode.view,
        // Event tap callback: convert Event back to PersonalEvent and show detail sheet
        onEventUpdate: (event) async {
          final eventId = PersonalEventAdapter.extractEventId(event.id);
          if (eventId == null) return false;

          // Find original PersonalEvent
          final personalEvent = state.events.firstWhere(
            (e) => e.id == eventId,
            orElse: () => throw Exception('Event not found'),
          );

          // Show detail sheet
          _handleEventTap(context, notifier, personalEvent);
          return false; // Don't update anything (detail sheet handles it)
        },
      ),
    );
  }
}

/// 일간 캘린더 뷰
class _DayCalendarView extends StatelessWidget {
  const _DayCalendarView({required this.state, required this.notifier});

  final CalendarEventsState state;
  final CalendarEventsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final events = state.events
        .where((event) => event.occursOn(state.selectedDate))
        .toList();
    return _EventListView(
      events: events,
      emptyMessage: '이 날에는 일정이 없습니다.',
      onEventTap: (event) => _handleEventTap(context, notifier, event),
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        bottom: 80,
      ),
    );
  }
}

/// 일정 리스트 뷰
class _EventListView extends StatelessWidget {
  const _EventListView({
    required this.events,
    required this.emptyMessage,
    required this.onEventTap,
    this.padding,
  });

  final List<PersonalEvent> events;
  final String emptyMessage;
  final ValueChanged<PersonalEvent> onEventTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        const EdgeInsets.only(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          bottom: 80,
        );
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: effectivePadding,
          child: Text(
            emptyMessage,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.neutral500),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: effectivePadding,
      itemBuilder: (context, index) {
        final event = events[index];
        return _EventCard(event: event, onTap: () => onEventTap(event));
      },
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemCount: events.length,
    );
  }
}

/// 일정 카드
/// Uses CalendarEventCard component (Personal Calendar mode)
class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});

  final PersonalEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timeFormatter = DateFormat('HH:mm');
    final timeLabel = event.isAllDay
        ? '종일'
        : '${timeFormatter.format(event.startDateTime)} ~ ${timeFormatter.format(event.endDateTime)}';

    return CalendarEventCard(
      title: event.title,
      color: event.color,
      timeLabel: timeLabel,
      location: event.location,
      showIcons: false,
      onTap: onTap,
    );
  }
}

/// 일정 탭 핸들러
void _handleEventTap(
  BuildContext context,
  CalendarEventsNotifier notifier,
  PersonalEvent event,
) async {
  final action = await showEventDetailSheet(context, event: event);
  if (!context.mounted) return;
  if (action == null) return;

  switch (action) {
    case EventDetailAction.edit:
      final request = await showEventFormDialog(
        context,
        initial: event,
        anchorDate: event.startDateTime,
      );
      if (!context.mounted) return;
      if (request != null) {
        await notifier.updateEvent(event.id, request);
      }
      break;
    case EventDetailAction.delete:
      final confirmed = await showConfirmDialog(
        context,
        title: '이벤트 삭제',
        message: '정말 "${event.title}" 이벤트를 삭제하시겠습니까?',
        confirmLabel: '삭제',
        isDestructive: true,
      );
      if (!context.mounted) return;
      if (confirmed) {
        await notifier.deleteEvent(event.id);
      }
      break;
  }
}
