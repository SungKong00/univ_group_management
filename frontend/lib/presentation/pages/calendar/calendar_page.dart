import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/calendar_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../providers/timetable_provider.dart';
import 'widgets/schedule_detail_sheet.dart';
import 'widgets/schedule_form_dialog.dart';
import 'widgets/timetable_weekly_view.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timetableStateProvider.notifier).loadSchedules();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TimetableState>(timetableStateProvider, (previous, next) {
      if (!mounted) return;
      final snackMessage = next.snackbarMessage;
      if (snackMessage != null &&
          snackMessage != previous?.snackbarMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackMessage),
            backgroundColor:
                next.snackbarIsError ? AppColors.error : null,
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
            _buildPageHeader(context),
            const SizedBox(height: AppSpacing.sm),
            _buildTabBar(context),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  TimetableTab(),
                  CalendarPlaceholderTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('캘린더', style: textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            '개인 시간표와 단발성 이벤트를 한 곳에서 관리하세요.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.neutral600),
          ),
        ],
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
            color: theme.colorScheme.primary.withOpacity(0.08),
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
      content = _EmptyTimetable(onCreatePressed: () async {
        await _handleCreate(context, notifier, isBusy);
      });
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
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
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: AnimatedSwitcher(
              duration: AppMotion.quick,
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
    if (request == null) return;

    final hasOverlap = notifier.hasOverlap(request);
    if (hasOverlap) {
      final confirmed = await _showOverlapDialog(context);
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
    if (action == null) return;

    if (action == ScheduleDetailAction.edit) {
      final request = await showScheduleFormDialog(
        context,
        initial: schedule,
      );
      if (request == null) return;
      final hasOverlap = notifier.hasOverlap(request, excludeId: schedule.id);
      if (hasOverlap) {
        final confirmed = await _showOverlapDialog(context);
        if (!confirmed) return;
      }
      await notifier.updateSchedule(schedule.id, request);
    } else if (action == ScheduleDetailAction.delete) {
      final confirmed = await _showDeleteConfirmDialog(context, schedule);
      if (!confirmed) return;
      await notifier.deleteSchedule(schedule.id);
    }
  }

  static Future<bool> _showOverlapDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('시간 겹침 확인'),
        content: const Text(
          '⚠️ 해당 시간대에 다른 일정이 있습니다. 계속 진행하시겠습니까?',
        ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: '이전 주',
              onPressed: isBusy ? null : onPreviousWeek,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    weekLabel,
                    style: textTheme.titleLarge,
                  ),
                  Text(
                    weekRange,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '다음 주',
              onPressed: isBusy ? null : onNextWeek,
              icon: const Icon(Icons.chevron_right),
            ),
            TextButton(
              onPressed: isBusy ? null : onToday,
              child: const Text('오늘'),
            ),
            IconButton(
              tooltip: '새로고침',
              onPressed: isBusy ? null : onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
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
            const SizedBox(width: AppSpacing.xs),
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
      ],
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
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('다시 시도'),
          ),
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
            const Icon(Icons.calendar_today_outlined,
                size: 64, color: AppColors.neutral400),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '등록된 일정이 없습니다.',
              style: textTheme.titleLarge,
            ),
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

class CalendarPlaceholderTab extends StatelessWidget {
  const CalendarPlaceholderTab({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_outlined,
                size: 64, color: AppColors.neutral400),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '캘린더 뷰는 준비 중입니다.',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '월간/주간/일간 캘린더는 Phase 4에서 제공될 예정이에요.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
