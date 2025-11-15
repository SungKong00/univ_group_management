import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/snack_bar_helper.dart';
import '../../../adapters/personal_schedule_adapter.dart';
import '../../../providers/timetable_provider.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/calendar/calendar_error_banner.dart';
import '../../../widgets/calendar/calendar_navigator.dart';
import '../../../widgets/dialogs/confirm_dialog.dart';
import '../../../widgets/weekly_calendar/weekly_schedule_editor.dart';
import '../widgets/schedule_form_dialog.dart';

/// 시간표 탭 (개인 일정 주간 뷰)
class TimetableTab extends ConsumerStatefulWidget {
  const TimetableTab({super.key});

  @override
  ConsumerState<TimetableTab> createState() => _TimetableTabState();
}

class _TimetableTabState extends ConsumerState<TimetableTab> {
  final GlobalKey<State<WeeklyScheduleEditor>> _scheduleEditorKey =
      GlobalKey<State<WeeklyScheduleEditor>>();

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
          .map(
            (schedule) =>
                PersonalScheduleAdapter.toEvent(schedule, state.weekStart),
          )
          .toList();

      content = WeeklyScheduleEditor(
        key: _scheduleEditorKey,
        allowMultiDaySelection: false, // Timetable: single day only
        isEditable: true,
        allowEventOverlap: true, // Show warning but allow overlap
        weekStart: state.weekStart,
        initialEvents: events,
        initialMode: state.isAddMode ? CalendarMode.add : CalendarMode.edit,
        initialOverlapView: state.isOverlapView,
        // Callbacks for CRUD operations
        onEventCreate: (event) =>
            _handleEventCreate(context, notifier, event, state.weekStart),
        onEventUpdate: (event) =>
            _handleEventUpdate(context, notifier, event, state.weekStart),
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
              // Toggle mode in both Provider and WeeklyScheduleEditor
              if (state.schedules.isNotEmpty) {
                notifier.toggleAddMode();
                (_scheduleEditorKey.currentState as dynamic)?.toggleMode();
              }
            },
            onShowCourseComingSoon: () {
              AppSnackBar.info(context, '🚧 추후 구현 예정입니다');
            },
            onToggleShowAllEvents: () {
              // Toggle overlap view in both Provider and WeeklyScheduleEditor
              if (state.schedules.isNotEmpty) {
                notifier.toggleOverlapView();
                (_scheduleEditorKey.currentState as dynamic)
                    ?.toggleOverlapView();
              }
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
            child: CalendarErrorBanner(
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
      final confirmed = await showConfirmDialog(
        context,
        title: '시간 겹침 확인',
        message: '⚠️ 해당 시간대에 다른 일정이 있습니다. 계속 진행하시겠습니까?',
        confirmLabel: '계속 진행',
        cancelLabel: '아니요',
      );
      if (!context.mounted) return;
      if (!confirmed) return;
    }

    await notifier.createSchedule(request);
  }

  /// Handle event creation from WeeklyScheduleEditor
  static Future<bool> _handleEventCreate(
    BuildContext context,
    TimetableStateNotifier notifier,
    Event event,
    DateTime weekStart,
  ) async {
    // Convert Event to PersonalScheduleRequest
    final request = PersonalScheduleAdapter.fromEvent(
      event,
      weekStart,
      color: event.color,
    );

    // Check for overlap
    final hasOverlap = notifier.hasOverlap(request);
    if (hasOverlap) {
      final confirmed = await showConfirmDialog(
        context,
        title: '시간 겹침 확인',
        message: '⚠️ 해당 시간대에 다른 일정이 있습니다. 계속 진행하시겠습니까?',
        confirmLabel: '계속 진행',
        cancelLabel: '아니요',
      );
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
    final request = PersonalScheduleAdapter.fromEvent(
      event,
      weekStart,
      color: event.color,
    );

    // Check for overlap (excluding current schedule)
    final hasOverlap = notifier.hasOverlap(request, excludeId: scheduleId);
    if (hasOverlap) {
      final confirmed = await showConfirmDialog(
        context,
        title: '시간 겹침 확인',
        message: '⚠️ 해당 시간대에 다른 일정이 있습니다. 계속 진행하시겠습니까?',
        confirmLabel: '계속 진행',
        cancelLabel: '아니요',
      );
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
    final confirmed = await showConfirmDialog(
      context,
      title: '일정 삭제',
      message: '정말 "${event.title}" 일정을 삭제하시겠습니까?',
      confirmLabel: '삭제',
      isDestructive: true,
    );
    if (!context.mounted) return false;
    if (!confirmed) return false;

    // Call provider to delete schedule
    return await notifier.deleteSchedule(scheduleId);
  }
}

/// 시간표 툴바 (주간 네비게이션 + 버튼들)
class _TimetableToolbar extends StatelessWidget {
  const _TimetableToolbar({
    required this.state,
    required this.isBusy,
    required this.onCreate,
    required this.onShowCourseComingSoon,
    required this.onToggleShowAllEvents,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onToday,
  });

  final TimetableState state;
  final bool isBusy;
  final VoidCallback onCreate;
  final VoidCallback onShowCourseComingSoon;
  final VoidCallback onToggleShowAllEvents;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final weekRange = DateFormatter.weekRange(state.weekStart);
    final weekLabel = DateFormatter.formatWeekHeader(state.weekStart);
    final weekRangeLabel = DateFormatter.formatWeekRangeDetailed(
      weekRange.start,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;

            // Row 1행 레이아웃으로 통일 (모바일/데스크톱 반응형)
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 좌측: 수업 추가 버튼 (조건부 렌더링)
                if (isCompact)
                  IconButton(
                    onPressed: isBusy ? null : onShowCourseComingSoon,
                    icon: const Icon(Icons.school_outlined, size: 20),
                    tooltip: '수업 추가',
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  )
                else
                  SizedBox(
                    width: 120,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : onShowCourseComingSoon,
                      icon: const Icon(Icons.school_outlined, size: 16),
                      label: Text(
                        '수업 추가',
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
                    child: CalendarNavigator(
                      currentDate: state.weekStart,
                      label: weekLabel,
                      subtitle: weekRangeLabel,
                      isWeekView: true,
                      onPrevious: isBusy ? () {} : onPreviousWeek,
                      onNext: isBusy ? () {} : onNextWeek,
                      onToday: isBusy ? () {} : onToday,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // 우측: 일정 추가 + 겹친 일정 펼치기 버튼
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Primary: 일정 추가 모드 토글 (조건부 렌더링)
                    if (isCompact)
                      IconButton(
                        onPressed: isBusy || state.schedules.isEmpty
                            ? null
                            : onCreate,
                        icon: Icon(
                          state.isAddMode
                              ? Icons.check
                              : Icons.add_circle_outline,
                          size: 20,
                        ),
                        tooltip: state.isAddMode ? '완료' : '일정 추가',
                        color: state.isAddMode
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.primary,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                      )
                    else
                      SizedBox(
                        width: state.isAddMode ? 90 : 110,
                        height: 44,
                        child: FilledButton.icon(
                          onPressed: isBusy || state.schedules.isEmpty
                              ? null
                              : onCreate,
                          icon: Icon(
                            state.isAddMode
                                ? Icons.check
                                : Icons.add_circle_outline,
                            size: 16,
                          ),
                          label: Text(
                            state.isAddMode ? '완료' : '일정 추가',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            backgroundColor: state.isAddMode
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    const SizedBox(width: AppSpacing.xs),
                    // Overlap view toggle (항상 아이콘)
                    IconButton(
                      onPressed: isBusy ? null : onToggleShowAllEvents,
                      icon: Icon(
                        state.isOverlapView ? Icons.view_week : Icons.layers,
                      ),
                      tooltip: state.isOverlapView ? '겹친 일정 펼치기' : '겹친 일정 접기',
                      iconSize: 20,
                      padding: const EdgeInsets.all(10),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
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
}

/// 빈 시간표 안내 화면
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
