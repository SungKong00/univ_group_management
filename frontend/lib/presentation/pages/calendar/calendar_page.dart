import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/calendar_models.dart';
import '../../../core/services/local_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../providers/calendar_events_provider.dart';
import '../../providers/timetable_provider.dart';
import '../../widgets/buttons/primary_button.dart';
import 'calendar_week_grid_view.dart';
import 'widgets/calendar_month_with_sidebar.dart';
import 'widgets/event_detail_sheet.dart';
import 'widgets/event_form_dialog.dart';
import 'widgets/month_event_chip.dart';
import 'widgets/schedule_detail_sheet.dart';
import 'widgets/schedule_form_dialog.dart';
import 'widgets/timetable_weekly_view.dart';

/// LocalStorage Provider
final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage.instance;
});

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// 정적 변수: 마지막 탭 인덱스 (메모리에 보존)
  static int? _lastTabIndex;

  @override
  void initState() {
    super.initState();

    // TabController 즉시 초기화 (동기)
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _lastTabIndex ?? 0,
    );

    // 탭 변경 리스너 등록
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        _lastTabIndex = _tabController.index;
        // 비동기로 LocalStorage에 저장 (초기화 블로킹 안 함)
        ref
            .read(localStorageProvider)
            .saveLastCalendarTab(_tabController.index);
      }
    });

    // LocalStorage에서 저장된 탭 인덱스 복원 (비동기, 백그라운드)
    _restoreTabFromLocalStorage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timetableStateProvider.notifier).loadSchedules();
    });
  }

  /// LocalStorage에서 마지막 탭 인덱스 복원 (비동기)
  Future<void> _restoreTabFromLocalStorage() async {
    if (_lastTabIndex != null) return; // 이미 정적 변수에 값이 있으면 스킵

    final localStorage = ref.read(localStorageProvider);
    final savedTab = await localStorage.getLastCalendarTab();

    if (savedTab != null && mounted && savedTab != _tabController.index) {
      _lastTabIndex = savedTab;
      _tabController.index = savedTab;
    }
  }

  @override
  void dispose() {
    // CalendarEventsNotifier의 dispose에서 스냅샷이 자동 저장됨
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TimetableState>(timetableStateProvider, (previous, next) {
      if (!mounted) return;
      final snackMessage = next.snackbarMessage;
      if (snackMessage != null && snackMessage != previous?.snackbarMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackMessage),
            backgroundColor: next.snackbarIsError ? AppColors.error : null,
          ),
        );
        ref.read(timetableStateProvider.notifier).clearSnackbar();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            _buildTabBar(context),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [TimetableTab(), CalendarTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightOutline, width: 1),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: AppColors.neutral500,
          indicator: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: '시간표'),
            Tab(text: '캘린더'),
          ],
        ),
      ),
    );
  }
}

class TimetableTab extends ConsumerWidget {
  const TimetableTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timetableStateProvider);
    final notifier = ref.read(timetableStateProvider.notifier);

    final isInitialLoading = state.isLoading && !state.hasLoaded;
    final isBusy = state.isSubmitting || state.isLoading;
    final showProgressBar =
        state.isSubmitting || (state.isLoading && state.hasLoaded);

    Widget content;
    if (isInitialLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (state.schedules.isEmpty) {
      content = _EmptyTimetable(
        onCreatePressed: () async {
          await _handleCreate(context, notifier, isBusy);
        },
      );
    } else {
      content = TimetableWeeklyView(
        schedules: state.schedules,
        weekStart: state.weekStart,
        onScheduleTap: (schedule) async {
          await _handleScheduleTap(context, notifier, schedule);
        },
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: _TimetableToolbar(
            state: state,
            isBusy: isBusy,
            onCreate: () => _handleCreate(context, notifier, isBusy),
            onShowCourseComingSoon: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚧 추후 구현 예정입니다'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            onRefresh: () {
              notifier.refresh();
            },
            onPreviousWeek: notifier.goToPreviousWeek,
            onNextWeek: notifier.goToNextWeek,
            onToday: notifier.goToCurrentWeek,
          ),
        ),
        if (state.loadErrorMessage != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              bottom: AppSpacing.xxs,
            ),
            child: _ErrorBanner(
              message: state.loadErrorMessage!,
              onRetry: () {
                notifier.refresh();
              },
            ),
          ),
        if (showProgressBar)
          const Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              bottom: AppSpacing.xxs,
            ),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              right: AppSpacing.sm,
            ),
            child: AnimatedSwitcher(
              duration: AppMotion.quick,
              // 콘텐츠를 상단에 붙여 배치하여 상단 버튼/네비게이션과의 불필요한 간격 제거
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: content,
            ),
          ),
        ),
      ],
    );
  }

  static Future<void> _handleCreate(
    BuildContext context,
    TimetableStateNotifier notifier,
    bool isBusy,
  ) async {
    if (isBusy) return;
    final request = await showScheduleFormDialog(context);
    if (!context.mounted) return;
    if (request == null) return;

    final hasOverlap = notifier.hasOverlap(request);
    if (hasOverlap) {
      final confirmed = await _showOverlapDialog(context);
      if (!context.mounted) return;
      if (!confirmed) return;
    }

    await notifier.createSchedule(request);
  }

  static Future<void> _handleScheduleTap(
    BuildContext context,
    TimetableStateNotifier notifier,
    PersonalSchedule schedule,
  ) async {
    final action = await showScheduleDetailSheet(context, schedule: schedule);
    if (!context.mounted) return;
    if (action == null) return;

    if (action == ScheduleDetailAction.edit) {
      final request = await showScheduleFormDialog(context, initial: schedule);
      if (!context.mounted) return;
      if (request == null) return;
      final hasOverlap = notifier.hasOverlap(request, excludeId: schedule.id);
      if (hasOverlap) {
        final confirmed = await _showOverlapDialog(context);
        if (!context.mounted) return;
        if (!confirmed) return;
      }
      await notifier.updateSchedule(schedule.id, request);
    } else if (action == ScheduleDetailAction.delete) {
      final confirmed = await _showDeleteConfirmDialog(context, schedule);
      if (!context.mounted) return;
      if (!confirmed) return;
      await notifier.deleteSchedule(schedule.id);
    }
  }

  static Future<bool> _showOverlapDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('시간 겹침 확인'),
        content: const Text('⚠️ 해당 시��대에 다른 일정이 있습니다. 계속 진행하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('아니요'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('계속 진행'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<bool> _showDeleteConfirmDialog(
    BuildContext context,
    PersonalSchedule schedule,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 삭제'),
        content: Text('정말 "${schedule.title}" 일정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _TimetableToolbar extends StatelessWidget {
  const _TimetableToolbar({
    required this.state,
    required this.isBusy,
    required this.onCreate,
    required this.onShowCourseComingSoon,
    required this.onRefresh,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onToday,
  });

  final TimetableState state;
  final bool isBusy;
  final Future<void> Function() onCreate;
  final VoidCallback onShowCourseComingSoon;
  final VoidCallback onRefresh;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final weekLabel = _buildWeekLabel(state.weekStart);
    final weekRange = _buildWeekRange(state.weekStart);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, AppComponents.buttonHeight),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: isBusy ? null : onShowCourseComingSoon,
              icon: const Icon(Icons.school_outlined),
              label: const Text('수업 추가'),
            ),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '이전 주',
                      onPressed: isBusy ? null : onPreviousWeek,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(weekLabel, style: textTheme.titleLarge),
                        Text(
                          weekRange,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: isBusy ? null : onToday,
                      child: const Text('오늘'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: '다음 주',
                      onPressed: isBusy ? null : onNextWeek,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppComponents.buttonHeight),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: isBusy
                  ? null
                  : () async {
                      await onCreate();
                    },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('개인 일정 추가'),
            ),
          ],
        ),
      ),
    );
  }

  String _buildWeekLabel(DateTime weekStart) {
    final anchor = weekStart.add(const Duration(days: 3));
    final weekNumber = ((anchor.day - 1) ~/ 7) + 1;
    return '${anchor.year}년 ${anchor.month}월 ${weekNumber}주차';
  }

  String _buildWeekRange(DateTime weekStart) {
    final weekEnd = DateUtils.addDaysToDate(weekStart, 6);
    return '${DateFormat('yyyy.MM.dd').format(weekStart)} ~ ${DateFormat('MM.dd').format(weekEnd)}';
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class _EmptyTimetable extends StatelessWidget {
  const _EmptyTimetable({required this.onCreatePressed});

  final Future<void> Function() onCreatePressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('등록된 일정이 없습니다.', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '새로운 개인 일정을 추가해 주간 시간표를 채워보세요.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: () async {
                await onCreatePressed();
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('개인 일정 추가'),
            ),
          ],
        ),
      ),
    );
  }
}

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: next.snackbarIsError ? AppColors.error : null,
          ),
        );
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
          child: _ErrorBanner(
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

    final viewToggle = ToggleButtons(
      isSelected:
          CalendarViewType.values.map((view) => view == state.view).toList(),
      onPressed: (index) =>
          onChangeView(CalendarViewType.values.elementAt(index)),
      borderRadius: BorderRadius.circular(12),
      fillColor: AppColors.brand.withValues(alpha: 0.08),
      selectedColor: AppColors.brand,
      constraints: const BoxConstraints(minHeight: 40),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text('월간'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text('주간'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text('일간'),
        ),
      ],
    );

    final addButton = PrimaryButton(
      text: '일정 추가',
      onPressed: onCreateEvent,
      isLoading: state.isMutating,
      semanticsLabel: '새 개인 일정 추가',
      variant: PrimaryButtonVariant.brand,
      width: 160,
    );

    final navigator = _CalendarNavigator(
      label: label,
      onPrevious: onPrevious,
      onNext: onNext,
      onToday: onToday,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 850;

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
                Expanded(
                  child: navigator,
                ),
                const SizedBox(width: AppSpacing.sm),
                addButton,
              ],
            ),
          ),
        );
      },
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
        final range = _weekRange(focused);
        return '${DateFormat('M월 d일').format(range.start)} ~ ${DateFormat('M월 d일').format(range.end)}';
      case CalendarViewType.day:
        return DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(selected);
    }
  }
}

class _CalendarNavigator extends StatelessWidget {
  const _CalendarNavigator({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: '이전',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 160),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge,
          ),
        ),
        IconButton(
          tooltip: '다음',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
        TextButton(onPressed: onToday, child: const Text('오늘')),
      ],
    );
  }
}

// _MonthCalendarView removed - replaced by CalendarMonthWithSidebar
// _MonthEventChip removed - replaced by shared MonthEventChip widget
// Sorting helpers removed - now inside CalendarMonthWithSidebar

class _WeekCalendarView extends StatelessWidget {
  const _WeekCalendarView({required this.state, required this.notifier});

  final CalendarEventsState state;
  final CalendarEventsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final range = _weekRange(state.focusedDate);
    final weekStart = range.start;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        bottom: 80,
      ),
      child: CalendarWeekGridView<PersonalEvent>(
        events: state.events,
        weekStart: weekStart,
        onEventTap: (event) => _handleEventTap(context, notifier, event),
      ),
    );
  }
}

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

// _DaySection removed - not used anymore

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
    final effectivePadding =
        padding ??
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral500),
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

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});

  final PersonalEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final timeFormatter = DateFormat('HH:mm');
    final timeLabel = event.isAllDay
        ? '종일'
        : '${timeFormatter.format(event.startDateTime)} ~ ${timeFormatter.format(event.endDateTime)}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightOutline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 48,
                decoration: BoxDecoration(
                  color: event.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      timeLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                    if (event.location != null && event.location!.isNotEmpty)
                      Text(
                        event.location!,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.neutral600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _handleEventTap(
  BuildContext context,
  CalendarEventsNotifier notifier,
  PersonalEvent event,
) async {
  final action = await showEventDetailSheet(context, event: event);
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
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('이벤트 삭제'),
          content: Text('정말 "${event.title}" 이벤트를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제'),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      if (confirmed == true) {
        await notifier.deleteEvent(event.id);
      }
      break;
  }
}

DateTimeRange _weekRange(DateTime focused) {
  final start = focused.subtract(
    Duration(days: focused.weekday - DateTime.monday),
  );
  final normalizedStart = _normalizeDate(start);
  final normalizedEnd = _normalizeDate(
    normalizedStart.add(const Duration(days: 6)),
  );
  return DateTimeRange(start: normalizedStart, end: normalizedEnd);
}

DateTime _normalizeDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);
