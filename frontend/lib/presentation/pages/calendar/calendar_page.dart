import 'package:flutter/material.dart';
import '../../../core/utils/snack_bar_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/calendar_models.dart';
import '../../../core/services/local_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../providers/calendar_events_provider.dart';
import '../../providers/timetable_provider.dart';
import '../../widgets/buttons/error_button.dart';
import '../../widgets/buttons/neutral_outlined_button.dart';
import '../../widgets/buttons/outlined_link_button.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/compact_tab_bar.dart';
import 'calendar_week_grid_view.dart';
import 'widgets/calendar_month_with_sidebar.dart';
import 'widgets/event_detail_sheet.dart';
import 'widgets/event_form_dialog.dart';
import 'widgets/month_event_chip.dart';
import 'widgets/schedule_detail_sheet.dart';
import 'widgets/schedule_form_dialog.dart';
import '../../adapters/personal_schedule_adapter.dart';
import '../../widgets/weekly_calendar/weekly_schedule_editor.dart';

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
        AppSnackBar.error(context, snackMessage);
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: CompactTabBar(
        controller: _tabController,
        tabs: const [
          CompactTab(label: '시간표'),
          CompactTab(label: '캘린더'),
        ],
      ),
    );
  }
}

class TimetableTab extends ConsumerStatefulWidget {
  const TimetableTab({super.key});

  @override
  ConsumerState<TimetableTab> createState() => _TimetableTabState();
}

class _TimetableTabState extends ConsumerState<TimetableTab> {
  final GlobalKey<State<WeeklyScheduleEditor>> _scheduleEditorKey = GlobalKey<State<WeeklyScheduleEditor>>();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetableStateProvider);
    final notifier = ref.read(timetableStateProvider.notifier);

    final isInitialLoading = state.isLoading && !state.hasLoaded;
    final isBusy = state.isSubmitting || state.isLoading;
    final showProgressBar =
        state.isSubmitting || (state.isLoading && state.hasLoaded);

    Widget content;
    if (isInitialLoading) {
      content = const Center(
        key: ValueKey('timetable-loading'),
        child: CircularProgressIndicator(),
      );
    } else if (state.schedules.isEmpty) {
      content = _EmptyTimetable(
        key: const ValueKey('timetable-empty'),
        onCreatePressed: () async {
          await _handleCreate(context, notifier, isBusy);
        },
      );
    } else {
      // Convert PersonalSchedule to Event for WeeklyScheduleEditor
      final events = state.schedules
          .map((schedule) => PersonalScheduleAdapter.toEvent(schedule, state.weekStart))
          .toList();

      content = WeeklyScheduleEditor(
        key: _scheduleEditorKey,
        allowMultiDaySelection: false, // Timetable: single day only
        isEditable: true,
        allowEventOverlap: true, // Show warning but allow overlap
        weekStart: state.weekStart,
        initialEvents: events,
        // Callbacks for CRUD operations
        onEventCreate: (event) => _handleEventCreate(context, notifier, event, state.weekStart),
        onEventUpdate: (event) => _handleEventUpdate(context, notifier, event, state.weekStart),
        onEventDelete: (event) => _handleEventDelete(context, notifier, event),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: _TimetableToolbar(
            state: state,
            isBusy: isBusy,
            onCreate: () {
              // Toggle WeeklyScheduleEditor mode instead of opening dialog
              if (state.schedules.isNotEmpty) {
                (_scheduleEditorKey.currentState as dynamic)?.toggleMode();
              }
            },
            onShowCourseComingSoon: () {
              AppSnackBar.info(context, '🚧 추후 구현 예정입니다');
            },
            onRefresh: () {
              notifier.refresh();
            },
            onPreviousWeek: notifier.goToPreviousWeek,
            onNextWeek: notifier.goToNextWeek,
            onToday: notifier.goToCurrentWeek,
            isAddMode: state.schedules.isNotEmpty &&
                ((_scheduleEditorKey.currentState as dynamic)?.currentMode == CalendarMode.add),
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

  /// Handle event creation from WeeklyScheduleEditor
  static Future<bool> _handleEventCreate(
    BuildContext context,
    TimetableStateNotifier notifier,
    Event event,
    DateTime weekStart,
  ) async {
    // Convert Event to PersonalScheduleRequest
    final request = PersonalScheduleAdapter.fromEvent(event, weekStart);

    // Check for overlap
    final hasOverlap = notifier.hasOverlap(request);
    if (hasOverlap) {
      final confirmed = await _showOverlapDialog(context);
      if (!context.mounted) return false;
      if (!confirmed) return false;
    }

    // Call provider to create schedule
    return await notifier.createSchedule(request);
  }

  /// Handle event update from WeeklyScheduleEditor
  static Future<bool> _handleEventUpdate(
    BuildContext context,
    TimetableStateNotifier notifier,
    Event event,
    DateTime weekStart,
  ) async {
    // Extract schedule ID from event ID
    final scheduleId = PersonalScheduleAdapter.extractScheduleId(event.id);
    if (scheduleId == null) {
      AppSnackBar.error(context, '잘못된 일정 ID');
      return false;
    }

    // Convert Event to PersonalScheduleRequest
    final request = PersonalScheduleAdapter.fromEvent(event, weekStart);

    // Check for overlap (excluding current schedule)
    final hasOverlap = notifier.hasOverlap(request, excludeId: scheduleId);
    if (hasOverlap) {
      final confirmed = await _showOverlapDialog(context);
      if (!context.mounted) return false;
      if (!confirmed) return false;
    }

    // Call provider to update schedule
    return await notifier.updateSchedule(scheduleId, request);
  }

  /// Handle event deletion from WeeklyScheduleEditor
  static Future<bool> _handleEventDelete(
    BuildContext context,
    TimetableStateNotifier notifier,
    Event event,
  ) async {
    // Extract schedule ID from event ID
    final scheduleId = PersonalScheduleAdapter.extractScheduleId(event.id);
    if (scheduleId == null) {
      AppSnackBar.error(context, '잘못된 일정 ID');
      return false;
    }

    // Confirm deletion (using event title since we don't have full schedule)
    final confirmed = await _showDeleteConfirmDialogSimple(context, event.title);
    if (!context.mounted) return false;
    if (!confirmed) return false;

    // Call provider to delete schedule
    return await notifier.deleteSchedule(scheduleId);
  }

  static Future<bool> _showOverlapDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('시간 겹침 확인'),
        content: const Text('⚠️ 해당 시간대에 다른 일정이 있습니다. 계속 진행하시겠습니까?'),
        actions: [
          NeutralOutlinedButton(
            text: '아니요',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          PrimaryButton(
            text: '계속 진행',
            onPressed: () => Navigator.of(context).pop(true),
            variant: PrimaryButtonVariant.action,
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
          NeutralOutlinedButton(
            text: '취소',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ErrorButton(
            text: '삭제',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<bool> _showDeleteConfirmDialogSimple(
    BuildContext context,
    String title,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 삭제'),
        content: Text('정말 "$title" 일정을 삭제하시겠습니까?'),
        actions: [
          NeutralOutlinedButton(
            text: '취소',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ErrorButton(
            text: '삭제',
            onPressed: () => Navigator.of(context).pop(true),
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
    this.isAddMode = false,
  });

  final TimetableState state;
  final bool isBusy;
  final VoidCallback onCreate;
  final VoidCallback onShowCourseComingSoon;
  final VoidCallback onRefresh;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onToday;
  final bool isAddMode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final weekLabel = _buildWeekLabel(state.weekStart);
    final weekRange = _buildWeekRange(state.weekStart);

    // 액션 버튼들 - 모드에 따라 동적으로 변경
    final actionButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary: 일정 추가 모드 토글
        SizedBox(
          width: isAddMode ? 90 : 110,
          height: 40,
          child: FilledButton.icon(
            onPressed: isBusy || state.schedules.isEmpty ? null : onCreate,
            icon: Icon(
              isAddMode ? Icons.check : Icons.add_circle_outline,
              size: 16,
            ),
            label: Text(
              isAddMode ? '완료' : '일정 추가',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: isAddMode
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Secondary: 수업 추가 (보조 액션)
        SizedBox(
          width: 110,
          height: 40,
          child: OutlinedButton.icon(
            onPressed: isBusy ? null : onShowCourseComingSoon,
            icon: const Icon(Icons.school_outlined, size: 16),
            label: Text('수업 추가',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        // Tertiary: 새로고침 (아이콘만)
        IconButton(
          onPressed: isBusy ? null : onRefresh,
          icon: const Icon(Icons.refresh),
          tooltip: '새로고침',
          iconSize: 18,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
        ),
      ],
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 750;

            if (isCompact) {
              // 모바일(<750px): Column으로 날짜 네비게이션과 버튼들 세로 배치
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 날짜 네비게이션 (상단 중앙)
                  Center(
                    child: _DateNavigator(
                      weekLabel: weekLabel,
                      weekRange: weekRange,
                      textTheme: textTheme,
                      onPrevious: isBusy ? null : onPreviousWeek,
                      onNext: isBusy ? null : onNextWeek,
                      onToday: isBusy ? null : onToday,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // 하단: 액션 버튼들 (중앙 정렬, 스크롤 가능)
                  Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: actionButtons,
                      ),
                    ),
                  ),
                ],
              );
            }

            // 데스크톱(≥750px): Row로 깔끔한 배치
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 좌측: 수업 추가 버튼 (Secondary)
                SizedBox(
                  width: 120,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onShowCourseComingSoon,
                    icon: const Icon(Icons.school_outlined, size: 16),
                    label: Text('수업 추가',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // 중앙: 날짜 네비게이션 (확장)
                Expanded(
                  child: Center(
                    child: _DateNavigator(
                      weekLabel: weekLabel,
                      weekRange: weekRange,
                      textTheme: textTheme,
                      onPrevious: isBusy ? null : onPreviousWeek,
                      onNext: isBusy ? null : onNextWeek,
                      onToday: isBusy ? null : onToday,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // 우측: 새로고침 + 일정 추가 버튼
                Row(
                  children: [
                    // Tertiary: 새로고침
                    IconButton(
                      onPressed: isBusy ? null : onRefresh,
                      icon: const Icon(Icons.refresh),
                      tooltip: '새로고침',
                      iconSize: 18,
                      padding: const EdgeInsets.all(10),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // Primary: 일정 추가 모드 토글
                    SizedBox(
                      width: isAddMode ? 90 : 110,
                      height: 44,
                      child: FilledButton.icon(
                        onPressed: isBusy || state.schedules.isEmpty ? null : onCreate,
                        icon: Icon(
                          isAddMode ? Icons.check : Icons.add_circle_outline,
                          size: 16,
                        ),
                        label: Text(
                          isAddMode ? '완료' : '일정 추가',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          backgroundColor: isAddMode
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _buildWeekLabel(DateTime weekStart) {
    final anchor = weekStart.add(const Duration(days: 3));
    final weekNumber = ((anchor.day - 1) ~/ 7) + 1;
    return '${anchor.year}년 ${anchor.month}월 $weekNumber주차';
  }

  String _buildWeekRange(DateTime weekStart) {
    final weekEnd = DateUtils.addDaysToDate(weekStart, 6);
    return '${DateFormat('yyyy.MM.dd').format(weekStart)} ~ ${DateFormat('MM.dd').format(weekEnd)}';
  }
}

/// 날짜 네비게이션 컴포넌트 (주차 표시 + 이전/다음/오늘)
class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.weekLabel,
    required this.weekRange,
    required this.textTheme,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final String weekLabel;
  final String weekRange;
  final TextTheme textTheme;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: '이전 주',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          visualDensity: VisualDensity.compact,
        ),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                weekLabel,
                style: textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                weekRange,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.neutral500,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: '다음 주',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: AppSpacing.xxs),
        SizedBox(
          width: 64,
          height: 36,
          child: NeutralOutlinedButton(
            text: '오늘',
            onPressed: onToday,
          ),
        ),
      ],
    );
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
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: NeutralOutlinedButton(text: '다시 시도', onPressed: onRetry),
          ),
        ],
      ),
    );
  }
}

class _EmptyTimetable extends StatelessWidget {
  const _EmptyTimetable({super.key, required this.onCreatePressed});

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
            PrimaryButton(
              text: '일정 추가',
              onPressed: () async {
                await onCreatePressed();
              },
              icon: const Icon(Icons.add_circle_outline, size: 18),
              variant: PrimaryButtonVariant.action,
              width: 140,
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
      borderRadius: BorderRadius.circular(AppRadius.button),
      fillColor: AppColors.brand.withValues(alpha: 0.08),
      selectedColor: AppColors.brand,
      constraints: const BoxConstraints(minHeight: 36, minWidth: 56),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text('월간', style: TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text('주간', style: TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text('일간', style: TextStyle(fontSize: 13)),
        ),
      ],
    );

    final addButton = PrimaryButton(
      text: '일정 추가',
      onPressed: onCreateEvent,
      icon: const Icon(Icons.add_circle_outline, size: 18),
      isLoading: state.isMutating,
      semanticsLabel: '새 일정 추가',
      variant: PrimaryButtonVariant.brand,
      width: 140,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 750;

            if (isCompact) {
              // 좁은 화면: 세로 배치
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 날짜 네비게이션 (상단 중앙)
                  _CalendarNavigator(
                    label: label,
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
                // 중앙: 날짜 네비게이션
                Expanded(
                  child: _CalendarNavigator(
                    label: label,
                    onPrevious: onPrevious,
                    onNext: onNext,
                    onToday: onToday,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: '이전',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          visualDensity: VisualDensity.compact,
        ),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 140),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        IconButton(
          tooltip: '다음',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: AppSpacing.xxs),
        SizedBox(
          width: 64,
          height: 36,
          child: NeutralOutlinedButton(
            text: '오늘',
            onPressed: onToday,
          ),
        ),
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
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('이벤트 삭제'),
          content: Text('정말 "${event.title}" 이벤트를 삭제하시겠습니까?'),
          actions: [
            NeutralOutlinedButton(
              text: '취소',
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ErrorButton(
              text: '삭제',
              onPressed: () => Navigator.of(context).pop(true),
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
